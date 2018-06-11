SET HEA ON LIN 500 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF;
COL signature FOR 99999999999999999999;
COL cnt FOR 999;
COL sql_text_100 FOR A100;
COL enabled_accepted FOR 99999999 HEA 'ENABLED|ACCEPTED';
COL enabled_accepted_fixed FOR 99999999 HEA 'ENABLED|ACCEPTED|FIXED';
COL min_created FOR A19;
COL plan_name FOR A30;
COL plan_hash_full FORMAT 99999999999999;
COL plan_hash      FORMAT 99999999999999;
COL plan_hash_2    FORMAT 99999999999999;
COL min_plan_id    FORMAT 99999999999999;
COL max_plan_id    FORMAT 99999999999999;

WITH 
dba_sql_plan_baselines_enh AS (
SELECT /*+ MATERIALIZE NO_MERGE dynamic_sampling(3) */
    so.signature,
    st.sql_handle,
    st.sql_text,
    so.plan_id,
    TO_NUMBER(extractvalue(xmltype(sp.other_xml),'/*/info[@type = "plan_hash"]')) plan_hash,
    TO_NUMBER(extractvalue(xmltype(sp.other_xml),'/*/info[@type = "plan_hash_2"]')) plan_hash_2,
    TO_NUMBER(extractvalue(xmltype(sp.other_xml),'/*/info[@type = "plan_hash_full"]')) plan_hash_full,
    so.name plan_name,
    ad.creator,
    DECODE(ad.origin, 1, 'MANUAL-LOAD',
                      2, 'AUTO-CAPTURE',
                      3, 'MANUAL-SQLTUNE',
                      4, 'AUTO-SQLTUNE',
                      5, 'STORED-OUTLINE',
                      6, 'EVOLVE-ADVISOR',
                         'UNKNOWN') origin,
    ad.parsing_schema_name,
    ad.description,
    ad.version,
    ad.created,
    ad.last_modified,
    so.last_executed,
    ad.last_verified,
    DECODE(BITAND(so.flags, 1),   0, 'NO', 'YES') enabled,
    DECODE(BITAND(so.flags, 2),   0, 'NO', 'YES') accepted,
    DECODE(BITAND(so.flags, 4),   0, 'NO', 'YES') fixed,
    DECODE(BITAND(so.flags, 64),  0, 'YES', 'NO') reproduced,
    DECODE(BITAND(so.flags, 8),   0, 'NO', 'YES') autopurge,
    DECODE(BITAND(so.flags, 256), 0, 'NO', 'YES') adaptive,
    ad.optimizer_cost,
    substrb(ad.module,1,(select ksumodlen from x$modact_length)) module,
    substrb(ad.action,1,(select ksuactlen from x$modact_length)) action,
    ad.executions,
    ad.elapsed_time,
    ad.cpu_time,
    ad.buffer_gets,
    ad.disk_reads,
    ad.direct_writes,
    ad.rows_processed,
    ad.fetches,
    ad.end_of_fetch_count
FROM
    sqlobj$        so,
    sqlobj$auxdata ad,
    sql$text       st,
    sqlobj$plan    sp
WHERE
    so.signature = st.signature AND
    ad.signature = st.signature AND
    so.signature = ad.signature AND
    so.category = ad.category AND
    so.plan_id = ad.plan_id AND
    so.obj_type = 2 AND
    ad.obj_type = 2 AND
    sp.signature = so.signature AND
    sp.signature = ad.signature AND
    sp.signature = st.signature AND
    sp.plan_id = so.plan_id AND
    sp.plan_id = ad.plan_id AND
    sp.obj_type = 2 AND
    sp.other_xml IS NOT NULL AND
    sp.id = 1
),
sql_using_baseline AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       sql_id,
       exact_matching_signature signature,
       sql_text
  FROM v$sql
 WHERE exact_matching_signature IS NOT NULL
   AND sql_text NOT LIKE '/* SQL Analyze%'
 GROUP BY
       sql_id,
       exact_matching_signature,
       sql_text
)
SELECT b.signature,
       s.sql_id,
       b.plan_hash,
       b.plan_hash_2,
       b.plan_hash_full,
       COUNT(*) cnt,
       SUM(CASE WHEN b.reproduced = 'YES' AND b.enabled = 'YES' AND b.accepted = 'YES' THEN 1 ELSE 0 END) enabled_accepted,
       SUM(CASE WHEN b.reproduced = 'YES' AND b.enabled = 'YES' AND b.accepted = 'YES' AND b.fixed = 'YES' THEN 1 ELSE 0 END) enabled_accepted_fixed,
       TO_CHAR(MIN(b.created), 'YYYY-MM-DD"T"HH24:MI:SS') min_created,
       MIN(b.plan_id) min_plan_id,
       MAX(b.plan_id) max_plan_id
  FROM dba_sql_plan_baselines_enh b, sql_using_baseline s
 WHERE s.signature(+) = b.signature
 GROUP BY
       b.signature,
       s.sql_id,
       b.plan_hash,
       b.plan_hash_2,
       b.plan_hash_full 
HAVING COUNT(*) > 1
   AND SUM(CASE WHEN b.reproduced = 'YES' AND b.enabled = 'YES' AND b.accepted = 'YES' THEN 1 ELSE 0 END) > 1
 ORDER BY
       1,2,3
/