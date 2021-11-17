SET TERM ON HEA ON LIN 2490 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF LONG 240000 LONGC 2400 NUM 20 SERVEROUT OFF;
-- COL sql_text FOR A80 TRUNC;
-- COL pdb_name FOR A30 TRUNC;
-- COL plan_name FOR A30 TRUNC;
-- COL signature FOR 99999999999999999999;
COL line FOR A300;
SPO /tmp/cli_wf_spbl_regress_fix_IMPLEMENT.sql;
WITH
cur AS (
SELECT con_id, sql_id, plan_hash_value, sql_text, exact_matching_signature AS signature, sql_plan_baseline AS plan_name, SUM(buffer_gets) / SUM(GREATEST(rows_processed, 10 * executions)) AS bgpcrp
  FROM v$sql
 WHERE (sql_text LIKE '%performScanQuery(leaseDecorators,ae_timestamp_index)%(1 = 1)%ASC%' OR sql_text LIKE '%performScanQuery(workflowInstances,I_GC_INDEX)%(1 = 1)%ASC%' OR sql_text LIKE '%performScanQuery(futureWork,resumptionTimestamp)%(1 = 1)%ASC%' OR sql_text LIKE '%populateBucketGCWorkspace%MAPPING_UPDATES_rgn%ASC%' OR sql_text LIKE '%populateBucketGCWorkspace%EVENTS_V2_rgn%ASC%')
   --AND plan_hash_value IN (610059206, 472260233, 549294716, 2784194979, 1172229985, 1742292103)
   AND con_id > 2 AND parsing_schema_name <> 'SYS' /*AND sql_plan_baseline IS NOT NULL*/ AND buffer_gets > 0 AND executions > 0 AND object_status = 'VALID' AND is_shareable = 'Y' AND last_active_time > SYSDATE - 1 AND ROWNUM >= 1
 GROUP BY con_id, sql_id, plan_hash_value, sql_text, exact_matching_signature, sql_plan_baseline
),
spbl AS (
SELECT con_id, signature, plan_name, SUM(buffer_gets) / SUM(GREATEST(rows_processed, 10 * executions)) AS bgpcrp
  FROM cdb_sql_plan_baselines
 WHERE (sql_text LIKE '%performScanQuery(leaseDecorators,ae_timestamp_index)%(1 = 1)%ASC%' OR sql_text LIKE '%performScanQuery(workflowInstances,I_GC_INDEX)%(1 = 1)%ASC%' OR sql_text LIKE '%performScanQuery(futureWork,resumptionTimestamp)%(1 = 1)%ASC%' OR sql_text LIKE '%populateBucketGCWorkspace%MAPPING_UPDATES_rgn%ASC%' OR sql_text LIKE '%populateBucketGCWorkspace%EVENTS_V2_rgn%ASC%')
   AND con_id > 2 AND parsing_schema_name <> 'SYS' AND buffer_gets > 0 AND executions > 0 AND enabled = 'YES' AND accepted = 'YES' AND ROWNUM >= 1
 GROUP BY con_id, signature, plan_name
)
--SELECT con.name AS pdb_name, cur.sql_id, cur.plan_hash_value, spbl.signature, spbl.plan_name, ROUND(cur.bgpcrp) AS cur_bgpcrp, ROUND(spbl.bgpcrp) AS spbl_bgpcrp, ROUND(ROUND(GREATEST(1, cur.bgpcrp)) / ROUND(GREATEST(1, spbl.bgpcrp))) AS regress, CASE WHEN cur.bgpcrp / spbl.bgpcrp > 10 THEN '*****' END AS risk, cur.sql_text
SELECT 'ALTER SESSION SET CONTAINER = '||con.name||';'||CHR(10)||
       'SET SERVEROUT ON;'||CHR(10)||
       'BEGIN FOR i IN (SELECT name FROM dba_sql_profiles WHERE signature = '||spbl.signature||' AND status = ''DISABLED'' AND description LIKE ''%[EXP]%'') LOOP DBMS_SQLTUNE.ALTER_SQL_PROFILE(i.name, ''STATUS'', ''ENABLED''); END LOOP; DBMS_OUTPUT.put_line(''sprf enable''); END;'||CHR(10)||'/'||CHR(10)||
       'DECLARE l_plans INTEGER; BEGIN l_plans := DBMS_SPM.drop_sql_plan_baseline(plan_name => '''||spbl.plan_name||'''); DBMS_OUTPUT.put_line(''spbl drop:''||l_plans); END;'||CHR(10)||'/'||CHR(10)||
       'EXEC DBMS_LOCK.sleep(5);'||CHR(10)||
       'DECLARE l_plans INTEGER; BEGIN l_plans := DBMS_SPM.load_plans_from_cursor_cache(sql_id => '''||cur.sql_id||'''); DBMS_OUTPUT.put_line(''spbl create:''||l_plans); END;'||CHR(10)||'/'
       AS line
  FROM cur, spbl, v$containers con
 WHERE spbl.con_id = cur.con_id AND spbl.signature = cur.signature AND spbl.plan_name = cur.plan_name
   AND con.con_id = cur.con_id
   AND cur.bgpcrp / spbl.bgpcrp > 100
ORDER BY 1
/
SPO OFF;
@/tmp/cli_wf_spbl_regress_fix_IMPLEMENT.sql