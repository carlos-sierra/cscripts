----------------------------------------------------------------------------------------
--
-- File name:   cs_kiev_bucket_growth_report.sql
--
-- Purpose:     KIEV Bucket Growth (inserts and deletes) Report
--
-- Author:      Carlos Sierra
--
-- Version:     2020/12/06
--
-- Usage:       Execute connected to PDB
--
--              Enter owner and table_name when requested.
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @cs_kiev_bucket_growth_report.sql
--
-- Notes:       Developed and tested on 12.1.0.2.
--
---------------------------------------------------------------------------------------
--
@@cs_internal/cs_primary.sql
@@cs_internal/cs_cdb_warn.sql
@@cs_internal/cs_set.sql
@@cs_internal/cs_def.sql
@@cs_internal/cs_file_prefix.sql
--
DEF cs_script_name = 'cs_kiev_bucket_growth_report';
--
COL username NEW_V username FOR A30 HEA 'OWNER';
SELECT u.username
  FROM dba_users u
 WHERE u.oracle_maintained = 'N' 
   AND u.username NOT LIKE 'C##'||CHR(37) 
   AND (SELECT COUNT(*) FROM dba_tables t WHERE t.owner = u.username AND t.table_name = 'KIEVBUCKETS') > 0
 ORDER BY u.username
/
PRO
COL owner NEW_V owner FOR A30;
PRO 1. Enter Owner
DEF owner = '&1.';
UNDEF 1;
SELECT UPPER(NVL('&&owner.', '&&username.')) owner FROM DUAL
/
--
COL table_name FOR A30;
COL num_rows FOR 999,999,999,990;
COL kievlive_y FOR 999,999,999,990;
COL kievlive_n FOR 999,999,999,990;
--
WITH
sqf1 AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       table_name,
       SUBSTR(UTL_RAW.CAST_TO_VARCHAR2(SUBSTR(LPAD(TO_CHAR(endpoint_value,'fmxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx'),30,'0'),1,12)), 1, 1) kievlive,
       endpoint_number - LAG(endpoint_number, 1, 0) OVER (PARTITION BY table_name ORDER BY endpoint_value) num_rows
  FROM dba_tab_histograms
 WHERE owner = '&&owner.'
   AND column_name = 'KIEVLIVE'
),
sqf2 AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       table_name,
       kievlive,
       MAX(num_rows) num_rows
  FROM sqf1
 WHERE kievlive IN ('Y', 'N')
 GROUP BY
       table_name,
       kievlive
)
SELECT b.name table_name,
       b.maxgarbageage,
       t.num_rows,
       CASE WHEN NVL(y.num_rows, 0) + NVL(n.num_rows, 0) > 0 THEN ROUND(y.num_rows * t.num_rows / (NVL(y.num_rows, 0) + NVL(n.num_rows, 0))) END kievlive_y,
       CASE WHEN NVL(y.num_rows, 0) + NVL(n.num_rows, 0) > 0 THEN ROUND(n.num_rows * t.num_rows / (NVL(y.num_rows, 0) + NVL(n.num_rows, 0))) END kievlive_n
  FROM &&owner..kievbuckets b,
       dba_tables t,
       sqf2 y,
       sqf2 n
 WHERE t.owner = '&&owner.'
   AND t.table_name = UPPER(b.name)
   AND y.table_name(+) = t.table_name
   AND y.kievlive(+) = 'Y'
   AND n.table_name(+) = t.table_name
   AND n.kievlive(+) = 'N'
 ORDER BY
       b.name
/
PRO
PRO 2. Enter Table Name
DEF table_name = '&2.';
UNDEF 2;
--
SELECT '&&cs_file_prefix._&&cs_script_name._&&owner..&&table_name.' cs_file_name FROM DUAL;
--
@@cs_internal/cs_spool_head.sql
PRO SQL> @&&cs_script_name..sql "&&owner." "&&table_name."
@@cs_internal/cs_spool_id.sql
--
PRO OWNER        : &&owner.
PRO TABLE_NAME   : &&table_name.
--
COL sql_text FOR A80 TRUNC;
PRO
PRO SQL
PRO ~~~
SELECT /*+ MATERIALIZE NO_MERGE */
       s.sql_id,
       CASE 
         WHEN MAX(s.sql_text) LIKE '/* SPM:CP %Value(%' THEN 'INSERT' 
         WHEN MAX(s.sql_text) LIKE '/* WriteBucketValues(%' THEN 'INSERT' 
         WHEN MAX(s.sql_text) LIKE '/* deleteBucketGarbage */%' THEN 'DELETE'
         WHEN MAX(s.sql_text) LIKE '/* SPM:CP addTransactionRow() */%' THEN 'KT_INS'
         WHEN MAX(s.sql_text) LIKE '/* batch commit */%' THEN 'KT_INS'
         WHEN MAX(s.sql_text) LIKE '/* Delete garbage for%transaction GC */%' THEN 'KT_DEL'
         ELSE 'ERROR' 
       END AS opname,
       MAX(s.sql_text) sql_text
  FROM v$sql s,
       audit_actions a
 WHERE (    s.sql_text LIKE '/* SPM:CP %Value(%' 
         OR s.sql_text LIKE '/* WriteBucketValues(%'
         OR s.sql_text LIKE '/* deleteBucketGarbage */%'
         OR s.sql_text LIKE '/* SPM:CP addTransactionRow() */%' 
         OR s.sql_text LIKE '/* batch commit */%' 
         OR s.sql_text LIKE '/* Delete garbage for%transaction GC */%'
       )
   AND (    UPPER(s.sql_text) LIKE '/* %('||UPPER('&&table_name.')||')%' 
         OR UPPER(s.sql_text) LIKE '/* % '||UPPER('&&table_name.')||' %'
         OR UPPER(s.sql_text) LIKE '/*%TRANSACTION%'
       )
   AND a.action = s.command_type
   AND a.name IN ('INSERT', 'DELETE')
 GROUP BY
       s.sql_id
/

--
COL end_time FOR A19;
COL inserted FOR 999,999,990;
COL deleted FOR 999,999,990;
COL growth FOR 999,999,990;
COL kt_inserted FOR 999,999,990;
COL kt_deleted FOR 999,999,990;
COL kt_growth FOR 999,999,990;
--
BREAK ON REPORT;
COMPUTE SUM LABEL 'TOTAL' OF inserted deleted growth kt_inserted kt_deleted kt_growth ON REPORT;
--
WITH 
insert_or_delete AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       s.sql_id,
       CASE 
         WHEN MAX(s.sql_text) LIKE '/* SPM:CP %Value(%' THEN 'INSERT' 
         WHEN MAX(s.sql_text) LIKE '/* WriteBucketValues(%' THEN 'INSERT' 
         WHEN MAX(s.sql_text) LIKE '/* deleteBucketGarbage */%' THEN 'DELETE'
         WHEN MAX(s.sql_text) LIKE '/* SPM:CP addTransactionRow() */%' THEN 'KT_INS'
         WHEN MAX(s.sql_text) LIKE '/* batch commit */%' THEN 'KT_INS'
         WHEN MAX(s.sql_text) LIKE '/* Delete garbage for%transaction GC */%' THEN 'KT_DEL'
         ELSE 'ERROR' 
       END AS opname,
       MAX(s.sql_text) sql_text
  FROM v$sql s,
       audit_actions a
 WHERE (    s.sql_text LIKE '/* SPM:CP %Value(%' 
         OR s.sql_text LIKE '/* WriteBucketValues(%'
         OR s.sql_text LIKE '/* deleteBucketGarbage */%'
         OR s.sql_text LIKE '/* SPM:CP addTransactionRow() */%' 
         OR s.sql_text LIKE '/* batch commit */%' 
         OR s.sql_text LIKE '/* Delete garbage for%transaction GC */%'
       )
   AND (    UPPER(s.sql_text) LIKE '/* %('||UPPER('&&table_name.')||')%' 
         OR UPPER(s.sql_text) LIKE '/* % '||UPPER('&&table_name.')||' %'
         OR UPPER(s.sql_text) LIKE '/*%TRANSACTION%'
       )
   AND a.action = s.command_type
   AND a.name IN ('INSERT', 'DELETE')
 GROUP BY
       s.sql_id
),
sqlstat AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       h.snap_id,
       o.opname,
       SUM(h.rows_processed_delta) rows_processed_delta
  FROM dba_hist_sqlstat h, /* sys.wrh$_sqlstat */
       insert_or_delete o
 WHERE h.dbid = &&cs_dbid.
   AND h.instance_number = &&cs_instance_number.
   AND h.sql_id = o.sql_id
   AND h.parsing_schema_name = UPPER('&&owner.')
   AND o.opname IN ('INSERT', 'DELETE', 'KT_INS', 'KT_DEL')
 GROUP BY
       h.snap_id,
       o.opname
),
sqlstat_denorm AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       snap_id,
       SUM(CASE opname WHEN 'INSERT' THEN rows_processed_delta ELSE 0 END) AS inserted,
       SUM(CASE opname WHEN 'DELETE' THEN rows_processed_delta ELSE 0 END) AS deleted,
       SUM(CASE opname WHEN 'KT_INS' THEN rows_processed_delta ELSE 0 END) AS kt_inserted,
       SUM(CASE opname WHEN 'KT_DEL' THEN rows_processed_delta ELSE 0 END) AS kt_deleted       
  FROM sqlstat
 GROUP BY
       snap_id
),
sqlstat_per_hour AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       TRUNC(s.end_interval_time, 'HH24') + (1/24) AS end_time,
       SUM(NVL(h.inserted, 0)) AS inserted,
       SUM(NVL(h.deleted, 0)) AS deleted,
       SUM(NVL(h.inserted, 0)) - SUM(NVL(h.deleted, 0)) AS growth,
       SUM(NVL(h.kt_inserted, 0)) AS kt_inserted,
       SUM(NVL(h.kt_deleted, 0)) AS kt_deleted,
       SUM(NVL(h.kt_inserted, 0)) - SUM(NVL(h.kt_deleted, 0)) AS kt_growth
  FROM sqlstat_denorm h,
       dba_hist_snapshot s /* sys.wrm$_snapshot */
 WHERE s.dbid = &&cs_dbid.
   AND s.instance_number = &&cs_instance_number.
   AND s.snap_id = h.snap_id
 GROUP BY
       TRUNC(s.end_interval_time, 'HH24')
)
SELECT end_time,
       inserted,
       deleted,
       growth,
       kt_inserted,
       kt_deleted,
       kt_growth 
  FROM sqlstat_per_hour
 ORDER BY
       end_time
/
-- for KT: /* SPM:CP addTransactionRow() */, /* Delete garbage for aborted transaction GC */, /* Delete garbage for transaction GC */
--
PRO
PRO SQL> @&&cs_script_name..sql "&&owner." "&&table_name."
--
@@cs_internal/cs_spool_tail.sql
@@cs_internal/cs_undef.sql
@@cs_internal/cs_reset.sql
--