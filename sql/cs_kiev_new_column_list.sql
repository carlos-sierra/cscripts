----------------------------------------------------------------------------------------
--
-- File name:   cs_kiev_new_column_list.sql
--
-- Purpose:     Column List History for KIEV Scan and Gets
--
-- Author:      Carlos Sierra
--
-- Version:     2019/04/27
--
-- Usage:       Execute connected to PDB
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @cs_kiev_new_column_list.sql
--
-- Notes:       *** Requires Oracle Diagnostics Pack License ***
--
--              Developed and tested on 12.1.0.2.
--
---------------------------------------------------------------------------------------
--
@@cs_internal/cs_primary.sql
@@cs_internal/cs_cdb_warn.sql
@@cs_internal/cs_set.sql
@@cs_internal/cs_def.sql
@@cs_internal/cs_file_prefix.sql
--
DEF cs_script_name = 'cs_kiev_new_column_list';
DEF cs_days_threshold = '30';
--
SELECT '&&cs_file_prefix._&&cs_script_name.' cs_file_name FROM DUAL;
--
@@cs_internal/cs_spool_head.sql
PRO SQL> @&&cs_script_name..sql 
@@cs_internal/cs_spool_id.sql
--
COL owner FOR A30;
COL table_name FOR A30;
COL last_ddl_time FOR A19;
COL created FOR A19;
--
PRO
PRO Table with recent DDL
PRO ~~~~~~~~~~~~~~~~~~~~~
SELECT o.last_ddl_time,
       o.owner,
       o.object_name table_name
       --o.created
  FROM dba_objects o,
       dba_users u
 WHERE o.object_type = 'TABLE'
   AND o.last_ddl_time > SYSDATE - &&cs_days_threshold.
   AND o.object_name NOT LIKE 'KIEV%'
   AND u.username = o.owner
   AND u.oracle_maintained = 'N'
 ORDER BY
       1,2,3
/
--
COL owner FOR A30;
COL table_name FOR A30;
COL column_name FOR A30;
COL creation_date FOR A19;
BREAK ON table_name SKIP 1 DUPL;
--
PRO
PRO Columns (with stats) on recent tables
PRO ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--
SELECT c.owner,
       c.table_name,
       c.column_name, 
       CAST(MIN(h.savtime) AS DATE) creation_date
  FROM dba_objects o,
       dba_users u,
       dba_tab_cols c,
       sys.wri$_optstat_histhead_history h
 WHERE o.object_type = 'TABLE'
   AND o.last_ddl_time > SYSDATE - &&cs_days_threshold.
   AND o.object_name NOT LIKE 'KIEV%'
   AND u.username = o.owner
   AND u.oracle_maintained = 'N'
   AND c.owner = o.owner
   AND c.table_name = o.object_name
   AND h.obj# = o.object_id
   AND h.intcol# = c.column_id
 GROUP BY
       c.owner,
       c.table_name,
       c.column_name,
       o.last_ddl_time
HAVING CAST(MIN(h.savtime) AS DATE) > o.last_ddl_time
 ORDER BY
       c.owner,
       c.table_name,
       c.column_name
/       
--
CLEAR COL BREAK;
--
SET HEA OFF PAGES 0;
COL time FOR A19;
COL table_name FOR A30;
COL column_list FOR A2400;
COL source FOR A6;
BREAK ON table_name SKIP 1 DUPL;
--
PRO
PRO Tables with new columns
PRO ~~~~~~~~~~~~~~~~~~~~~~~
--
WITH
spm AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       DBMS_LOB.substr(sql_text, DBMS_LOB.instr(sql_text, '*/') + 1) decoration,
       DBMS_LOB.substr(sql_text, DBMS_LOB.instr(sql_text, ',') - DBMS_LOB.instr(sql_text, '(') - 1, DBMS_LOB.instr(sql_text, '(') + 1) table_name,
       TRIM(DBMS_LOB.substr(sql_text, DBMS_LOB.instr(sql_text, 'FROM') - DBMS_LOB.instr(sql_text, 'SELECT') - 8, DBMS_LOB.instr(sql_text, 'SELECT') + 7)) column_list,
       CAST(created AS DATE) time
  FROM dba_sql_plan_baselines
 WHERE DBMS_LOB.substr(sql_text, 1000) LIKE '/* %(%,%) */%'
   AND (UPPER(DBMS_LOB.substr(sql_text, 1000)) LIKE '/* %GET%(%,%) */%' OR UPPER(DBMS_LOB.substr(sql_text, 1000)) LIKE '/* %SCAN%(%,%) */%')
   AND REPLACE(DBMS_LOB.substr(sql_text, 1000), ' ') NOT LIKE '%SELECT*%'
   AND enabled = 'YES'
   AND accepted = 'YES'
),
mem AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       SUBSTR(sql_text, 1, INSTR(sql_text, '*/') + 1) decoration,
       SUBSTR(sql_text, INSTR(sql_text, '(') + 1, INSTR(sql_text, ',') - INSTR(sql_text, '(') - 1) table_name,
       TRIM(DBMS_LOB.substr(sql_fulltext, DBMS_LOB.instr(sql_fulltext, 'FROM') - DBMS_LOB.instr(sql_fulltext, 'SELECT') - 8, DBMS_LOB.instr(sql_fulltext, 'SELECT') + 7)) column_list,
       TO_DATE(first_load_time, 'YYYY-MM-DD/HH24:MI:SS') time
  FROM v$sql
 WHERE sql_text LIKE '/* %(%,%) */%'
   AND REPLACE(sql_text, ' ') NOT LIKE '%SELECT*%'
   AND (UPPER(sql_text) LIKE '/* %GET%(%,%) */%' OR UPPER(sql_text) LIKE '/* %SCAN%(%,%) */%')
   AND object_status = 'VALID'
   AND is_obsolete = 'N'
   AND is_shareable = 'Y'
),
grp AS (
SELECT 'SPM' source,
       MIN(time) time,
       table_name,
       column_list
  FROM spm
 GROUP BY
       table_name,
       column_list
 UNION ALL
SELECT 'MEM' source,
       MIN(time) time,
       table_name,
       column_list
  FROM mem
 GROUP BY
       table_name,
       column_list
),
ext AS (
SELECT source,
       time,
       table_name,
       column_list,
       COUNT(DISTINCT column_list) OVER(PARTITION BY table_name) cnt_distinct,
       SUM(CASE WHEN time > SYSDATE - &&cs_days_threshold. THEN 1 ELSE 0 END)  OVER(PARTITION BY table_name) cnt_recent
  FROM grp
)
SELECT table_name,
       time,
       source,
       column_list
  FROM ext
 WHERE cnt_distinct > 1
   AND cnt_recent > 0
 ORDER BY
       table_name,
       LENGTH(column_list),
       time
/
--
SET HEA ON PAGES 100;
--
COL kiev_owner NEW_V kiev_owner NOPRI;
SELECT owner kiev_owner FROM dba_tables WHERE table_name = 'KIEVBUCKETS' AND num_rows > 0 ORDER BY num_rows;
--
COL column_name FOR A30 TRUNC;
COL column_created FOR A19;
COL table_created FOR A19;
--
PRO
PRO New Columns by Table Name
PRO ~~~~~~~~~~~~~~~~~~~~~~~~~
SELECT b.name table_name,
       c.name column_name,
       CAST(c.whencreated AS DATE) column_created,
       CAST(b.whencreated AS DATE) table_created
  FROM &&kiev_owner..kievbuckets b,
       &&kiev_owner..kievbucketvalues c
 WHERE c.bucketid = b.bucketid
   AND c.whencreated > SYSDATE - &&cs_days_threshold.
   AND CAST(b.whencreated AS DATE) <> CAST(c.whencreated AS DATE) -- new table
ORDER BY 1,2
/
--
COL trunc_column_created NOPRI;
BREAK ON trunc_column_created SKIP 1 DUPL;
PRO
PRO New Columns by Date
PRO ~~~~~~~~~~~~~~~~~~~
SELECT TRUNC(CAST(c.whencreated AS DATE)) trunc_column_created,
       CAST(c.whencreated AS DATE) column_created,
       b.name table_name,
       c.name column_name,
       CAST(b.whencreated AS DATE) table_created
  FROM &&kiev_owner..kievbuckets b,
       &&kiev_owner..kievbucketvalues c
 WHERE c.bucketid = b.bucketid
   AND c.whencreated > SYSDATE - &&cs_days_threshold.
   AND CAST(b.whencreated AS DATE) <> CAST(c.whencreated AS DATE) -- new table
ORDER BY TRUNC(CAST(c.whencreated AS DATE)), b.name, c.name
/
--
CLEAR COL BREAK;
--
PRO
PRO SQL> @&&cs_script_name..sql 
--
@@cs_internal/cs_spool_tail.sql
@@cs_internal/cs_undef.sql
@@cs_internal/cs_reset.sql
--