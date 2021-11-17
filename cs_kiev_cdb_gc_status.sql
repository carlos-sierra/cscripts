----------------------------------------------------------------------------------------
--
-- File name:   cs_kiev_cdb_gc_status.sql
--
-- Purpose:     KIEV CDB Garbage Collection (GC) status
--
-- Author:      Carlos Sierra
--
-- Version:     2021/06/13
--
-- Usage:       Execute connected to CDB
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @cs_kiev_cdb_gc_status.sql
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
ALTER SESSION SET container = CDB$ROOT;
--
DEF cs_script_name = 'cs_kiev_cdb_gc_status';
SELECT '&&cs_file_prefix._&&cs_script_name.' cs_file_name FROM DUAL;
--
@@cs_internal/cs_spool_head.sql
PRO SQL> @&&cs_script_name..sql
@@cs_internal/cs_spool_id.sql
--
COL line FOR A300;
SET HEA OFF PAGES 0;
--
PRO
PRO CON PDB_NAME                       PDB_CREATION        LAST_GC_TIME          MINUTES  USED GBs
PRO ~~~ ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ~~~~~~~~~~~~~~~~~~~ ~~~~~~~~~~~~~~~~~~~ ~~~~~~~~~ ~~~~~~~~~
SPO OFF;
--
SET TERM OFF;
SPO &&cs_file_name._SCRIPT.sql;
WITH
kiev_gc_events AS (
SELECT /*+ OPT_PARAM('_px_cdb_view_enabled' 'FALSE') */ 
LPAD(c.con_id, 3, '0') AS con, c.name AS pdb_name, t.owner, t.table_name, h.op_timestamp, t.last_analyzed, ROUND(SUM(m.used_space) * 8192 / POWER(10,9), 1) AS gbs,
ROW_NUMBER() OVER (PARTITION BY c.con_id, c.name, t.owner, t.table_name, h.op_timestamp ORDER BY t.last_analyzed DESC NULLS LAST) AS rn
FROM cdb_tables t, v$containers c, cdb_pdb_history h, cdb_tablespace_usage_metrics m
WHERE t.table_name LIKE 'KIEVGCEVENTS_PART%'
AND c.con_id = t.con_id
AND h.con_id = c.con_id
AND h.operation LIKE '%CREATE%' -- had to use LIKE '%CREATE%' instead of = 'CREATE' due to IOD_META_AUX.do_dbc_pdbs ORA-00604: error occurred at recursive SQL level 1 ORA-00932: inconsistent datatypes: expected CHAR got C##IOD.SYS_PLSQL_25D5A17D_55_1
AND m.con_id = c.con_id
GROUP BY c.con_id, c.name, t.owner, t.table_name, h.op_timestamp, t.last_analyzed
)
SELECT DISTINCT
'/* '||k.con||' */'||CHR(10)||
'ALTER SESSION SET CONTAINER = '||k.pdb_name||';'||CHR(10)||
'COL con FOR A3;'||CHR(10)||
'COL pdb_name FOR A30 TRUNC;'||CHR(10)||
'COL last_gc_time FOR A19 TRUNC;'||CHR(10)||
'COL pdb_created FOR A19 TRUNC;'||CHR(10)||
'COL minutes FOR 99,990.0;'||CHR(10)||
'COL gbs FOR 99,990.0;'||CHR(10)||
'SPO &&cs_file_name..txt APP;'||CHR(10)||
'SELECT '''||k.con||''' AS con, '||CHR(10)||
''''||k.pdb_name||''' AS pdb_name, '||CHR(10)||
''''||k.op_timestamp||''' AS pdb_created, '||CHR(10)||
'CAST(MAX(e.eventtime) AS DATE) AS last_gc_time, '||CHR(10)||
'ROUND((SYSDATE - CAST(MAX(e.eventtime) AS DATE)) * 24 * 60, 1) AS minutes, '||CHR(10)||
'TO_NUMBER('''||k.gbs||''') AS gbs '||CHR(10)||
'FROM '||k.owner||'.'||k.table_name||' e '||CHR(10)||
'WHERE e.gctype = ''BUCKET'' '||CHR(10)||
'AND DBMS_LOB.instr(e.message, '' rows were deleted'') > 0 '||CHR(10)||
'; '||CHR(10)||
'SPO OFF;' AS line
FROM kiev_gc_events k
WHERE k.rn = 1
ORDER BY 1
/
SPO OFF;
SET TERM ON;
@&&cs_file_name._SCRIPT.sql
--HOS rm &cs_file_name._SCRIPT.sql
--
SPO &&cs_file_name..txt APP;
--
PRO
PRO SQL> @&&cs_script_name..sql
--
@@cs_internal/cs_spool_tail.sql
--
ALTER SESSION SET CONTAINER = &&cs_con_name.;
--
@@cs_internal/cs_undef.sql
@@cs_internal/cs_reset.sql
--