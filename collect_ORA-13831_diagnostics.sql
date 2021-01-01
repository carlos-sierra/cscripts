-- collect_ORA-13831_diagnostics.sql (2020/03/10) 
-- Collects ORA-13831 diagnostics. inputs PDB and SQL_ID.
SPO collect_ORA-13831_diagnostics.log
SET HEA ON LIN 500 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF;
ALTER SESSION SET container = CDB$ROOT;
SELECT name pdb_name FROM v$containers WHERE open_mode = 'READ WRITE' ORDER BY 1;
PRO 1. Enter PDB_NAME failing with ORA-13831:
DEF pdb_name = '&1.';
UNDEF 1;
PRO 2. Enter SQL_ID failing with ORA-13831:
DEF sql_id = '&2.';
UNDEF 2;
SET FEED ON ECHO ON VER ON TI ON TIMI ON;
-- connect to pdb
ALTER SESSION SET container = &&pdb_name.;
-- prepares backup owner
DEF repo_owner = 'C##IOD';
COL default_tablespace NEW_V default_tablespace NOPRI;
SELECT default_tablespace FROM dba_users WHERE username = UPPER('&&repo_owner.');
ALTER USER &&repo_owner. QUOTA UNLIMITED ON &&default_tablespace.;
-- backup SPM metadata (for subsequent datapump)
COL backup_timestamp NEW_V backup_timestamp NOPRI;
SELECT TO_CHAR(SYSDATE, 'YYYYMMDD_HH24MISS') backup_timestamp FROM DUAL;
CREATE TABLE &&repo_owner..sqllog$_&&backup_timestamp. AS SELECT * FROM sys.sqllog$;
CREATE TABLE &&repo_owner..smb$config_&&backup_timestamp. AS SELECT * FROM sys.smb$config;
CREATE TABLE &&repo_owner..sql$_&&backup_timestamp. AS SELECT * FROM sys.sql$;
CREATE TABLE &&repo_owner..sql$text_&&backup_timestamp. AS SELECT * FROM sys.sql$text;
CREATE TABLE &&repo_owner..sqlobj$_&&backup_timestamp. AS SELECT * FROM sys.sqlobj$;
CREATE TABLE &&repo_owner..sqlobj$data_&&backup_timestamp. AS SELECT * FROM sys.sqlobj$data;
CREATE TABLE &&repo_owner..sqlobj$auxdata_&&backup_timestamp. AS SELECT * FROM sys.sqlobj$auxdata;
--CREATE TABLE &&repo_owner..sqlobj$plan_&&backup_timestamp. AS SELECT * FROM sys.sqlobj$plan;
-- needed to avoid ORA-00997: illegal use of LONG datatype on column "other"
CREATE TABLE &&repo_owner..sqlobj$plan_&&backup_timestamp. AS SELECT 
 signature
,category
,obj_type
,plan_id
,statement_id
,xpl_plan_id
,timestamp
,remarks
,operation
,options
,object_node
,object_owner
,object_name
,object_alias
,object_instance
,object_type
,optimizer
,search_columns
,id
,parent_id
,depth
,position
,cost
,cardinality
,bytes
,other_tag
,partition_start
,partition_stop
,partition_id
,TO_LOB(other) other -- TO_LOB() needed to avoid ORA-00997: illegal use of LONG datatype
,distribution
,cpu_cost
,io_cost
,temp_space
,access_predicates
,filter_predicates
,projection
,time
,qblock_name
,other_xml
FROM sys.sqlobj$plan;
-- not needed as long as event 13831 is already on. be aware this trace is verbose.
--ALTER SYSTEM SET events='13831 trace name errorstack level 3';
-- development asked for this SPM trace
ALTER SYSTEM SET EVENTS 'trace[SQL_Plan_Management][sql:&&sql_id.]';
-- sleeping few seconds is plenty to trap hard-parse of sql that executes often
EXEC DBMS_LOCK.sleep(10);
-- support asked for this CBO (10053) trace, in addition to SPM trace
ALTER SYSTEM SET EVENTS 'trace[SQL_Optimizer.*][sql:&&sql_id.]';
-- sleeping few seconds so we trap some sesisons with both SPM and CBO traces
EXEC DBMS_LOCK.sleep(10);
-- disable both traces
ALTER SYSTEM SET EVENTS 'trace[SQL_Optimizer.*][sql:&&sql_id.] off';
ALTER SYSTEM SET EVENTS 'trace[SQL_Plan_Management][sql:&&sql_id.] off';
-- gets signature so we can disable baselines for this sql
VAR signature NUMBER;
-- most times sql is in memory, so we get signature from v$sql
BEGIN
  SELECT exact_matching_signature INTO :signature FROM v$sql WHERE sql_id = '&&sql_id.' AND ROWNUM = 1;
END;
/
-- sometimes sql is not in memory but on awr, so we get sql_text from awr and we compute signature
DECLARE
  l_sql_text CLOB;
BEGIN
  IF :signature IS NULL THEN
    SELECT sql_text INTO l_sql_text FROM dba_hist_sqltext WHERE sql_id = '&&sql_id.' AND ROWNUM = 1;
    :signature := DBMS_SQLTUNE.SQLTEXT_TO_SIGNATURE(l_sql_text);
  END IF;
END;
/
-- disable all baselines for signature
DECLARE
  l_plans INTEGER;
BEGIN
  FOR i IN (SELECT sql_handle, plan_name 
              FROM dba_sql_plan_baselines 
             WHERE signature = :signature
               AND enabled = 'YES'
             ORDER BY signature, plan_name)
  LOOP
    l_plans := DBMS_SPM.alter_sql_plan_baseline(sql_handle => i.sql_handle, plan_name => i.plan_name, attribute_name => 'ENABLED', attribute_value => 'NO');
  END LOOP;
END;
/
-- end
COL trace_directory NEW_V trace_directory NOPRI;
SELECT value trace_directory FROM v$diag_info WHERE name = 'Diag Trace';
SET FEED OFF ECHO OFF VER OFF TI OFF TIMI OFF;
PRO 1. verify on alert log ORA-13831 is no longer raised
PRO 2. collect all traces updated after &&backup_timestamp on &&trace_directory.
PRO 3. datapump &&repo_owner..*_&&backup_timestamp. tables (8) from &&pdb_name.
SPO OFF;
QUIT;
