SPO sqlhc.log
SET DEF ^ TERM OFF ECHO ON AUTOP OFF VER OFF SERVEROUT ON SIZE 1000000;
REM
REM $Header: 1366133.1 sqlhc.sql 12.1.08 2014/04/18 carlos.sierra mauro.pagano $
REM
REM Copyright (c) 2000-2013, Oracle Corporation. All rights reserved.
REM
REM AUTHOR
REM   carlos.sierra@oracle.com
REM   mauro.pagano@oracle.com
REM
REM SCRIPT
REM   sqlhc.sql SQL Health-Check (extract mode)
REM
REM DESCRIPTION
REM   Produces an HTML report with a list of observations based on
REM   health-checks performed in and around a SQL statement that
REM   may be performing poorly.
REM
REM   Inputs a memory-resident SQL_ID.
REM
REM   In addition to the health_check report, it generates some
REM   additional diagnostics files regarding SQL performance.
REM
REM   This script does not install any objects in the database.
REM   It does not perform any DDL commands.
REM   It only performs DML commands against the PLAN_TABLE then it
REM   rolls back those temporary inserts.
REM   It can be used in Dataguard or any read-only database.
REM
REM PRE-REQUISITES
REM   1. Execute as SYS or user with DBA role or user with access
REM      to data dictionary views.
REM   2. The SQL for which this script is executed must be
REM      memory-resident.
REM
REM PARAMETERS
REM   1. Oracle Pack license (Tuning or Diagnostics or None) T|D|N
REM   2. SQL_ID of interest.
REM
REM EXECUTION
REM   1. Start SQL*Plus connecting as SYS or user with DBA role or
REM      user with access to data dictionary views.
REM   2. Execute script sqlhc.sql passing values for parameters.
REM
REM EXAMPLE
REM   # sqlplus / as sysdba
REM   SQL> START [path]sqlhc.sql [T|D|N] [SQL_ID]
REM   SQL> START sqlhc.sql T 51x6yr9ym5hdc
REM
REM NOTES
REM   1. For possible errors see sqlhc.log.
REM   2. If site has both Tuning and Diagnostics licenses then
REM      specified T (Oracle Tuning pack includes Oracle Diagnostics)
REM   3. On a read-only instance, the "Observations" section with the
REM      results of the health-checks will be missing.
REM
DEF health_checks = 'Y';
DEF shared_cursor = 'N';
DEF sql_monitor_reports = '12';
REM
DEF script = 'sqlhc';
DEF method = 'SQLHC';
DEF mos_doc = '1366133.1';
DEF doc_ver = '12.1.06';
DEF doc_date = '2014/01/30';
-- sqldx_output: HTML/CSV/BOTH/NONE
DEF sqldx_output = 'CSV';

/**************************************************************************************************/

EXEC DBMS_APPLICATION_INFO.SET_MODULE(module_name => '^^method. ^^doc_ver.', action_name => '^^script..sql');
EXEC DBMS_APPLICATION_INFO.SET_CLIENT_INFO(client_info => '^^method.');
VAR health_checks CHAR(1);
EXEC :health_checks := '^^health_checks.';
VAR shared_cursor CHAR(1);
EXEC :shared_cursor := '^^shared_cursor.';
SET TERM ON ECHO OFF;
PRO
PRO Parameter 1:
PRO Oracle Pack License (Tuning, Diagnostics or None) [T|D|N] (required)
PRO
DEF input_license = '^1';
PRO
SET TERM OFF;
COL license NEW_V license FOR A1;

SELECT UPPER(SUBSTR(TRIM('^^input_license.'), 1, 1)) license FROM DUAL;

VAR license CHAR(1);
EXEC :license := '^^license.';

COL unique_id NEW_V unique_id FOR A15;
SELECT TO_CHAR(SYSDATE, 'YYYYMMDD_HH24MISS') unique_id FROM DUAL;

SET TERM ON;
WHENEVER SQLERROR EXIT SQL.SQLCODE;

BEGIN
  IF '^^license.' IS NULL OR '^^license.' NOT IN ('T', 'D', 'N') THEN
    RAISE_APPLICATION_ERROR(-20100, 'Oracle Pack License (Tuning, Diagnostics or None) must be specified as "T" or "D" or "N".');
  END IF;
END;
/

WHENEVER SQLERROR CONTINUE;

PRO
PRO Parameter 2:
PRO SQL_ID of the SQL to be analyzed (required)
PRO
DEF input_sql_id = '^2';
DEF input_parameter = '^^input_sql_id.';
PRO

PRO Values passed:
PRO License: "^^input_license."
PRO SQL_ID : "^^input_sql_id."
PRO
--SET TERM OFF;

-- get dbid
COL dbid NEW_V dbid;
SELECT dbid FROM v$database;

COL sql_id NEW_V sql_id FOR A13;

SELECT sql_id
  FROM gv$sqlarea
 WHERE sql_id = TRIM('^^input_sql_id.')
 UNION
SELECT sql_id
  FROM dba_hist_sqltext
 WHERE :license IN ('T', 'D')
   AND dbid = ^^dbid.
   AND sql_id = TRIM('^^input_sql_id.');

VAR sql_id VARCHAR2(13);
EXEC :sql_id := '^^sql_id.';

SET TERM ON;
WHENEVER SQLERROR EXIT SQL.SQLCODE;

BEGIN
  IF '^^sql_id.' IS NULL THEN
    IF :license IN ('T', 'D') THEN
      RAISE_APPLICATION_ERROR(-20200, 'SQL_ID "^^input_sql_id." not found in memory nor in AWR.');
    ELSE
      RAISE_APPLICATION_ERROR(-20200, 'SQL_ID "^^input_sql_id." not found in memory.');
    END IF;
  END IF;
END;
/

WHENEVER SQLERROR CONTINUE;
SET ECHO ON TIMI ON;

/**************************************************************************************************
 *
 * begin_common: from begin_common to end_common sqlhc.sql and sqlhcxec.sql are identical
 *
 **************************************************************************************************/
SELECT 'BEGIN: '||TO_CHAR(SYSDATE, 'YYYY-MM-DD/HH24:MI:SS') FROM dual;

DEF doc_link = 'https://support.oracle.com/CSP/main/article?cmd=show&type=NOT&id=';
DEF bug_link = 'https://support.oracle.com/CSP/main/article?cmd=show&type=BUG&id=';

-- tracing script in case it takes long to execute so we can diagnose it
ALTER SESSION SET MAX_DUMP_FILE_SIZE = '1G';
ALTER SESSION SET TRACEFILE_IDENTIFIER = "^^script._^^unique_id.";
--ALTER SESSION SET STATISTICS_LEVEL = 'ALL';
ALTER SESSION SET EVENTS '10046 TRACE NAME CONTEXT FOREVER, LEVEL 12';

-- adding to prevent slow access to ASH with non default NLS settings
ALTER SESSION SET NLS_SORT = 'BINARY';
ALTER SESSION SET NLS_COMP = 'BINARY';

/**************************************************************************************************/

/* -------------------------
 *
 * get sql_text
 *
 * ------------------------- */

VAR sql_text CLOB;
EXEC :sql_text := NULL;

-- get sql_text from memory
DECLARE
  l_sql_text VARCHAR2(32767);
BEGIN -- 10g see bug 5017909
  DBMS_OUTPUT.PUT_LINE('getting sql_text from memory');
  FOR i IN (SELECT DISTINCT piece, sql_text
              FROM gv$sqltext_with_newlines
             WHERE sql_id = '^^sql_id.'
             ORDER BY 1, 2)
  LOOP
    IF :sql_text IS NULL THEN
      DBMS_LOB.CREATETEMPORARY(:sql_text, TRUE);
      DBMS_LOB.OPEN(:sql_text, DBMS_LOB.LOB_READWRITE);
    END IF;
    l_sql_text := REPLACE(i.sql_text, CHR(00), ' ');
    DBMS_LOB.WRITEAPPEND(:sql_text, LENGTH(l_sql_text), l_sql_text);
  END LOOP;
  IF :sql_text IS NOT NULL THEN
    DBMS_LOB.CLOSE(:sql_text);
  END IF;
EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('getting sql_text from memory: '||SQLERRM);
    :sql_text := NULL;
END;
/

-- get sql_text from awr
BEGIN
  IF :license IN ('T', 'D') AND (:sql_text IS NULL OR NVL(DBMS_LOB.GETLENGTH(:sql_text), 0) = 0) THEN
    DBMS_OUTPUT.PUT_LINE('getting sql_text from awr');
    SELECT REPLACE(sql_text, CHR(00), ' ')
      INTO :sql_text
      FROM dba_hist_sqltext
     WHERE :license IN ('T', 'D')
       AND dbid = ^^dbid.
       AND sql_id = '^^sql_id.'
       AND sql_text IS NOT NULL
       AND ROWNUM = 1;
  END IF;
EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('getting sql_text from awr: '||SQLERRM);
    :sql_text := NULL;
END;
/

SELECT :sql_text FROM DUAL;

/* -------------------------
 *
 * get several values
 *
 * ------------------------- */

-- signature (force=false)
VAR signature NUMBER;
BEGIN
  IF :license = 'T' THEN
    :signature := DBMS_SQLTUNE.SQLTEXT_TO_SIGNATURE(:sql_text, FALSE);
  ELSE
    :signature := -1;
  END IF;
END;
/
COL signature NEW_V signature FOR A20;
SELECT TO_CHAR(:signature) signature FROM DUAL;

-- signature (force=true)
VAR signaturef NUMBER;
BEGIN
  IF :license = 'T' THEN
    :signaturef := DBMS_SQLTUNE.SQLTEXT_TO_SIGNATURE(:sql_text, TRUE);
  ELSE
    :signaturef := -1;
  END IF;
END;
/
COL signaturef NEW_V signaturef FOR A20;
SELECT TO_CHAR(:signaturef) signaturef FROM DUAL;

-- get database name (up to 10, stop before first '.', no special characters)
COL database_name_short NEW_V database_name_short FOR A10;
SELECT SUBSTR(SYS_CONTEXT('USERENV', 'DB_NAME'), 1, 10) database_name_short FROM DUAL;
SELECT SUBSTR('^^database_name_short.', 1, INSTR('^^database_name_short..', '.') - 1) database_name_short FROM DUAL;
SELECT TRANSLATE('^^database_name_short.',
'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789 ''`~!@#$%^*()-_=+[]{}\|;:",.<>/?'||CHR(0)||CHR(9)||CHR(10)||CHR(13)||CHR(38),
'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789') database_name_short FROM DUAL;

-- get host name (up to 30, stop before first '.', no special characters)
COL host_name_short NEW_V host_name_short FOR A30;
SELECT SUBSTR(SYS_CONTEXT('USERENV', 'SERVER_HOST'), 1, 30) host_name_short FROM DUAL;
SELECT SUBSTR('^^host_name_short.', 1, INSTR('^^host_name_short..', '.') - 1) host_name_short FROM DUAL;
SELECT TRANSLATE('^^host_name_short.',
'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789 ''`~!@#$%^*()-_=+[]{}\|;:",.<>/?'||CHR(0)||CHR(9)||CHR(10)||CHR(13)||CHR(38),
'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789') host_name_short FROM DUAL;

-- get rdbms version
COL rdbms_version NEW_V rdbms_version FOR A17;
SELECT version rdbms_version FROM v$instance;

-- get platform
COL platform NEW_V platform FOR A80;
SELECT UPPER(TRIM(REPLACE(REPLACE(product, 'TNS for '), ':' ))) platform FROM product_component_version WHERE product LIKE 'TNS for%' AND ROWNUM = 1;

-- get instance
COL instance_number NEW_V instance_number FOR A10;
SELECT TO_CHAR(instance_number) instance_number FROM v$instance;

-- YYYYMMDD_HH24MISS
COL time_stamp NEW_V time_stamp FOR A15;
SELECT TO_CHAR(SYSDATE, 'YYYYMMDD_HH24MISS') time_stamp FROM DUAL;

-- YYYY-MM-DD/HH24:MI:SS
COL time_stamp2 NEW_V time_stamp2 FOR A20;
SELECT TO_CHAR(SYSDATE, 'YYYY-MM-DD/HH24:MI:SS') time_stamp2 FROM DUAL;

-- get db_block_size
COL sys_db_block_size NEW_V sys_db_block_size FOR A17;
SELECT value sys_db_block_size FROM v$system_parameter2 WHERE LOWER(name) = 'db_block_size';

-- get cpu_count
COL sys_cpu NEW_V sys_cpu FOR A17;
SELECT value sys_cpu FROM v$system_parameter2 WHERE LOWER(name) = 'cpu_count';

-- get ofe
COL sys_ofe NEW_V sys_ofe FOR A17;
SELECT value sys_ofe FROM v$system_parameter2 WHERE LOWER(name) = 'optimizer_features_enable';

-- get ds
COL sys_ds NEW_V sys_ds FOR A10;
SELECT value sys_ds FROM v$system_parameter2 WHERE LOWER(name) = 'optimizer_dynamic_sampling';

-- Exadata?
COL exadata NEW_V exadata FOR A1;
SELECT 'Y' exadata FROM v$cell_state WHERE ROWNUM = 1;

-- get user
COL sessionuser NEW_V sessionuser FOR A50;
SELECT TO_CHAR(SYS_CONTEXT('USERENV','SESSION_USER')) sessionuser FROM dual;

-- get num_cpu
COL num_cpus NEW_V num_cpus FOR A10
SELECT TO_CHAR(value) num_cpus FROM v$osstat WHERE stat_name = 'NUM_CPUS';

-- get num_cores
COL num_cores NEW_V num_cores FOR A10
SELECT TO_CHAR(value) num_cores FROM v$osstat WHERE stat_name = 'NUM_CPU_CORES';

-- get num_cpu
COL num_sockets NEW_V num_sockets FOR A10
SELECT TO_CHAR(value) num_sockets FROM v$osstat WHERE stat_name = 'NUM_CPU_SOCKETS';

/* -------------------------
 *
 * application vendor
 *
 * ------------------------- */

-- ebs
COL is_ebs NEW_V is_ebs FOR A1;
COL ebs_owner NEW_V ebs_owner FOR A30;
SELECT 'Y' is_ebs, owner ebs_owner
  FROM dba_tab_columns
 WHERE table_name = 'FND_PRODUCT_GROUPS'
   AND column_name = 'RELEASE_NAME'
   AND data_type = 'VARCHAR2'
   AND ROWNUM = 1;

-- siebel
COL is_siebel NEW_V is_siebel FOR A1;
COL siebel_owner NEW_V siebel_owner FOR A30;
SELECT 'Y' is_siebel, owner siebel_owner
  FROM dba_tab_columns
 WHERE '^^is_ebs.' IS NULL
   AND table_name = 'S_REPOSITORY'
   AND column_name = 'ROW_ID'
   AND data_type = 'VARCHAR2'
   AND ROWNUM = 1;

-- psft
COL is_psft NEW_V is_psft FOR A1;
COL psft_owner NEW_V psft_owner FOR A30;
SELECT 'Y' is_psft, owner psft_owner
  FROM dba_tab_columns
 WHERE '^^is_ebs.' IS NULL
   AND '^^is_siebel.' IS NULL
   AND table_name = 'PSSTATUS'
   AND column_name = 'TOOLSREL'
   AND data_type = 'VARCHAR2'
   AND ROWNUM = 1;

/* -------------------------
 *
 * find tables and indexes
 *
 * ------------------------- */

-- transaction begins here. it will be rolled back after generating spool file
SAVEPOINT save_point_1;

-- this script uses the gtt plan_table as a temporary staging place to store results of health-checks
DELETE plan_table;

-- record tables
INSERT INTO plan_table (object_type, object_owner, object_name)
WITH object AS (
SELECT /*+ MATERIALIZE */
       object_owner owner, object_name name
  FROM gv$sql_plan
 WHERE :health_checks = 'Y'
   AND inst_id IN (SELECT inst_id FROM gv$instance)
   AND sql_id = :sql_id
   AND object_owner IS NOT NULL
   AND object_name IS NOT NULL
 UNION
SELECT object_owner owner, object_name name
  FROM dba_hist_sql_plan
 WHERE :health_checks = 'Y'
   AND :license IN ('T', 'D')
   AND dbid = ^^dbid.
   AND sql_id = :sql_id
   AND object_owner IS NOT NULL
   AND object_name IS NOT NULL
)
SELECT 'TABLE', t.owner, t.table_name
  FROM dba_tab_statistics t, -- include fixed objects
       object o
 WHERE :health_checks = 'Y'
   AND t.owner = o.owner
   AND t.table_name = o.name
 UNION
SELECT 'TABLE', i.table_owner, i.table_name
  FROM dba_indexes i,
       object o
 WHERE :health_checks = 'Y'
   AND i.owner = o.owner
   AND i.index_name = o.name;

-- list tables
SELECT object_owner owner, object_name table_name
  FROM plan_table
 WHERE :health_checks = 'Y'
   AND object_type = 'TABLE'
 ORDER BY 1, 2;

-- record indexes from known plans
INSERT INTO plan_table (object_type, object_owner, object_name, other_tag)
SELECT 'INDEX', object_owner owner, object_name index_name, 'YES'
  FROM gv$sql_plan
 WHERE :health_checks = 'Y'
   AND inst_id IN (SELECT inst_id FROM gv$instance)
   AND sql_id = :sql_id
   AND object_owner IS NOT NULL
   AND object_name IS NOT NULL
   AND (object_type LIKE '%INDEX%' OR operation LIKE '%INDEX%')
 UNION
SELECT 'INDEX', object_owner owner, object_name index_name, 'YES'
  FROM dba_hist_sql_plan
 WHERE :health_checks = 'Y'
   AND :license IN ('T', 'D')
   AND dbid = ^^dbid.
   AND sql_id = :sql_id
   AND object_owner IS NOT NULL
   AND object_name IS NOT NULL
   AND (object_type LIKE '%INDEX%' OR operation LIKE '%INDEX%');

-- record indexes from tables in plan
INSERT INTO plan_table (object_type, object_owner, object_name, other_tag)
SELECT 'INDEX', owner, index_name, 'NO'
  FROM plan_table t,
       dba_indexes i
 WHERE :health_checks = 'Y'
   AND t.object_type = 'TABLE'
   AND t.object_owner = i.table_owner
   AND t.object_name = i.table_name
 MINUS
SELECT 'INDEX', object_owner, object_name, 'NO'
  FROM plan_table t
 WHERE :health_checks = 'Y'
   AND object_type = 'INDEX';

COL in_plan FOR A7;
-- list indexes
SELECT object_owner owner, object_name index_name, other_tag in_plan
  FROM plan_table
 WHERE :health_checks = 'Y'
   AND object_type = 'INDEX'
 ORDER BY 1, 2;

/* -------------------------
 *
 * record type enumerator
 *
 * ------------------------- */

-- constants
VAR E_GLOBAL     NUMBER;
VAR E_EBS        NUMBER;
VAR E_SIEBEL     NUMBER;
VAR E_PSFT       NUMBER;
VAR E_TABLE      NUMBER;
VAR E_INDEX      NUMBER;
VAR E_1COL_INDEX NUMBER;
VAR E_TABLE_PART NUMBER;
VAR E_INDEX_PART NUMBER;
VAR E_TABLE_COL  NUMBER;

EXEC :E_GLOBAL     := 01;
EXEC :E_EBS        := 02;
EXEC :E_SIEBEL     := 03;
EXEC :E_PSFT       := 04;
EXEC :E_TABLE      := 05;
EXEC :E_INDEX      := 06;
EXEC :E_1COL_INDEX := 07;
EXEC :E_TABLE_PART := 08;
EXEC :E_INDEX_PART := 09;
EXEC :E_TABLE_COL  := 10;

/**************************************************************************************************/

/* -------------------------
 *
 * global hc
 *
 * ------------------------- */
EXEC DBMS_APPLICATION_INFO.SET_CLIENT_INFO('^^method.: Global Health Check - ' || TO_CHAR(SYSDATE, 'YYYY-MM-DD/HH24:MI:SS'));

-- 5969780 STATISTICS_LEVEL = ALL on LINUX
INSERT INTO plan_table (id, operation, object_alias, other_tag, remarks, projection)
SELECT :E_GLOBAL, 'CBO PARAMETER', SYSTIMESTAMP, 'STATISTICS_LEVEL',
       'Parameter STATISTICS_LEVEL is set to ALL on ^^platform. platform.',
       'STATISTICS_LEVEL = ALL provides valuable metrics like A-Rows. Be aware of Bug <a target="MOS" href="^^bug_link.5969780">5969780</a> CPU overhead.<br>'||CHR(10)||
       'Use a value of ALL only at the session level. You could use CBO hint /*+ gather_plan_statistics */ to accomplish the same.'
  FROM v$system_parameter2
 WHERE :health_checks = 'Y'
   AND UPPER(name) = 'STATISTICS_LEVEL'
   AND UPPER(value) = 'ALL'
   AND '^^rdbms_version.' LIKE '10%'
   AND '^^platform.' LIKE '%LINUX%';

-- cbo parameters with non-default values at sql level
INSERT INTO plan_table (id, operation, object_alias, other_tag, remarks, projection)
SELECT :E_GLOBAL, 'CBO PARAMETER', SYSTIMESTAMP, UPPER(name),
       'CBO initialization parameter "'||name||'" with a non-default value of "'||value||'" as per V$SQL_OPTIMIZER_ENV.',
       'Review the correctness of this non-default value "'||value||'" for SQL_ID '||:sql_id||'.'
  FROM (
SELECT DISTINCT name, value
  FROM v$sql_optimizer_env
 WHERE :health_checks = 'Y'
   AND sql_id = :sql_id
   AND isdefault = 'NO' );

-- cbo parameters with non-default values at system level
INSERT INTO plan_table (id, operation, object_alias, other_tag, remarks, projection)
SELECT :E_GLOBAL, 'CBO PARAMETER', SYSTIMESTAMP, UPPER(g.name),
       'CBO initialization parameter "'||g.name||'" with a non-default value of "'||g.value||'" as per V$SYS_OPTIMIZER_ENV.',
       'Review the correctness of this non-default value "'||g.value||'".<br>'||CHR(10)||
       'Unset this parameter unless there is a strong reason for keeping its current value.<br>'||CHR(10)||
       'Default value is "'||g.default_value||'" as per V$SYS_OPTIMIZER_ENV.'
  FROM v$sys_optimizer_env g
 WHERE :health_checks = 'Y'
   AND g.isdefault = 'NO'
   AND NOT EXISTS (
SELECT NULL
  FROM v$sql_optimizer_env s
 WHERE :health_checks = 'Y'
   AND s.sql_id = :sql_id
   AND s.isdefault = 'NO'
   AND s.name = g.name
   AND s.value = g.value );

-- optimizer_features_enable <> rdbms_version at system level
INSERT INTO plan_table (id, operation, object_alias, other_tag, remarks, projection)
SELECT :E_GLOBAL, 'CBO PARAMETER', SYSTIMESTAMP, 'OPTIMIZER_FEATURES_ENABLE',
       'DB version ^^rdbms_version. and OPTIMIZER_FEATURES_ENABLE ^^sys_ofe. do not match as per V$SYSTEM_PARAMETER2.',
       'Be aware that you are using a prior version of the optimizer. New CBO features in your DB version may not be used.'
  FROM DUAL
 WHERE :health_checks = 'Y'
   AND SUBSTR('^^rdbms_version.', 1, LEAST(LENGTH('^^rdbms_version.'), LENGTH('^^sys_ofe.'))) <> SUBSTR('^^sys_ofe.', 1, LEAST(LENGTH('^^rdbms_version.'), LENGTH('^^sys_ofe.')));

-- optimizer_features_enable <> rdbms_version at sql level
INSERT INTO plan_table (id, operation, object_alias, other_tag, remarks, projection)
SELECT :E_GLOBAL, 'CBO PARAMETER', SYSTIMESTAMP, 'OPTIMIZER_FEATURES_ENABLE',
       'DB version ^^rdbms_version. and OPTIMIZER_FEATURES_ENABLE '||v.value||' do not match for SQL_ID '||:sql_id||' as per V$SQL_OPTIMIZER_ENV.',
       'Be aware that you are using a prior version of the optimizer. New CBO features in your DB version may not be used.'
  FROM (
SELECT DISTINCT value
  FROM v$sql_optimizer_env
 WHERE :health_checks = 'Y'
   AND sql_id = :sql_id
   AND LOWER(name) = 'optimizer_features_enable'
   AND SUBSTR('^^rdbms_version.', 1, LEAST(LENGTH('^^rdbms_version.'), LENGTH(value))) <> SUBSTR(value, 1, LEAST(LENGTH('^^rdbms_version.'), LENGTH(value))) ) v;

-- optimizer_dynamic_sampling between 1 and 3 at system level
INSERT INTO plan_table (id, operation, object_alias, other_tag, remarks, projection)
SELECT :E_GLOBAL, 'CBO PARAMETER', SYSTIMESTAMP, 'OPTIMIZER_DYNAMIC_SAMPLING',
       'Dynamic Sampling is set to small value of ^^sys_ds. as per V$SYSTEM_PARAMETER2.',
       'Be aware that using such a small value may produce statistics of poor quality.<br>'||CHR(10)||
       'If you rely on this functionality consider using a value no smaller than 4.'
  FROM plan_table pt,
       dba_tables t
 WHERE :health_checks = 'Y'
   AND TO_NUMBER('^^sys_ds.') BETWEEN 1 AND 3
   AND pt.object_type = 'TABLE'
   AND pt.object_owner = t.owner
   AND pt.object_name = t.table_name
   AND t.temporary = 'N'
   AND (t.last_analyzed IS NULL OR t.num_rows IS NULL)
   AND ROWNUM = 1;

-- db_file_multiblock_read_count should not be set
INSERT INTO plan_table (id, operation, object_alias, other_tag, remarks, projection)
SELECT :E_GLOBAL, 'CBO PARAMETER', SYSTIMESTAMP, 'DB_FILE_MULTIBLOCK_READ_COUNT',
       'MBRC Parameter is set to "'||value||'" overriding its default value.',
       'The default value of this parameter is a value that corresponds to the maximum I/O size that can be performed efficiently.<br>'||CHR(10)||
       'This value is platform-dependent and is 1MB for most platforms.<br>'||CHR(10)||
       'Because the parameter is expressed in blocks, it will be set to a value that is equal to the maximum I/O size that can be performed efficiently divided by the standard block size.'
  FROM v$system_parameter2
 WHERE :health_checks = 'Y'
   AND UPPER(name) = 'DB_FILE_MULTIBLOCK_READ_COUNT'
   AND (isdefault = 'FALSE' OR ismodified <> 'FALSE');

-- nls_sort is not binary (session)
INSERT INTO plan_table (id, operation, object_alias, other_tag, remarks, projection)
SELECT :E_GLOBAL, 'NLS PARAMETER', SYSTIMESTAMP, 'NLS_SORT',
       'NLS_SORT Session Parameter is set to "'||value||'" in V$NLS_PARAMETERS.',
       'Setting NLS_SORT to anything other than BINARY causes a sort to use a full table scan, regardless of the path chosen by the optimizer.'
  FROM v$nls_parameters
 WHERE :health_checks = 'Y'
   AND UPPER(parameter) = 'NLS_SORT'
   AND UPPER(value) <> 'BINARY';

-- nls_sort is not binary (instance)
INSERT INTO plan_table (id, operation, object_alias, other_tag, remarks, projection)
SELECT :E_GLOBAL, 'NLS PARAMETER', SYSTIMESTAMP, 'NLS_SORT',
       'NLS_SORT Instance Parameter is set to "'||value||'" in V$SYSTEM_PARAMETER.',
       'Setting NLS_SORT to anything other than BINARY causes a sort to use a full table scan, regardless of the path chosen by the optimizer.'
  FROM v$system_parameter
 WHERE :health_checks = 'Y'
   AND UPPER(name) = 'NLS_SORT'
   AND UPPER(value) <> 'BINARY';

-- nls_sort is not binary (global)
INSERT INTO plan_table (id, operation, object_alias, other_tag, remarks, projection)
SELECT :E_GLOBAL, 'NLS PARAMETER', SYSTIMESTAMP, 'NLS_SORT',
       'NLS_SORT Global Parameter is set to "'||value||'" in NLS_DATABASE_PARAMETERS.',
       'Setting NLS_SORT to anything other than BINARY causes a sort to use a full table scan, regardless of the path chosen by the optimizer.'
  FROM nls_database_parameters
 WHERE :health_checks = 'Y'
   AND UPPER(parameter) = 'NLS_SORT'
   AND UPPER(value) <> 'BINARY';

-- DBMS_STATS automatic gathering on 10g
INSERT INTO plan_table (id, operation, object_alias, other_tag, remarks, projection)
SELECT :E_GLOBAL, 'DBMS_STATS', SYSTIMESTAMP, 'DBA_SCHEDULER_JOBS',
       'Automatic gathering of CBO statistics is enabled.',
       CASE
         WHEN '^^is_ebs.' = 'Y' THEN
           'Disable this job immediately and re-gather statistics for all affected schemas using FND_STATS or coe_stats.sql.<br>'||CHR(10)||
           'See <a target="MOS" href="^^doc_link.156968.1">156968.1</a>.'
         WHEN '^^is_siebel.' = 'Y' THEN
           'Disable this job immediately and re-gather statistics for all affected schemas using coe_siebel_stats.sql.<br>'||CHR(10)||
           'See <a target="MOS" href="^^doc_link.781927.1">781927.1</a>.'
         WHEN '^^is_psft.' = 'Y' THEN
           'Disable this job immediately and re-gather statistics for all affected schemas using pscbo_stats.sql.<br>'||CHR(10)||
           'See <a target="MOS" href="^^doc_link.1322888.1">1322888.1</a>.'
         ELSE
           'Be aware that small sample sizes could produce poor quality histograms,<br>'||CHR(10)||
           'which combined with bind sensitive predicates could render suboptimal plans.<br>'||CHR(10)||
           'See <a target="MOS" href="^^doc_link.465787.1">465787.1</a>.'
         END
  FROM dba_scheduler_jobs
 WHERE :health_checks = 'Y'
   AND job_name = 'GATHER_STATS_JOB'
   AND enabled = 'TRUE';

-- DBMS_STATS automatic gathering on 11g
INSERT INTO plan_table (id, operation, object_alias, other_tag, remarks, projection)
SELECT :E_GLOBAL, 'DBMS_STATS', SYSTIMESTAMP, 'DBA_AUTOTASK_CLIENT',
       'Automatic gathering of CBO statistics is enabled.',
       CASE
         WHEN '^^is_ebs.' = 'Y' THEN
           'Disable this job immediately and re-gather statistics for all affected schemas using FND_STATS or coe_stats.sql.<br>'||CHR(10)||
           'See <a target="MOS" href="^^doc_link.156968.1">156968.1</a>.'
         WHEN '^^is_siebel.' = 'Y' THEN
           'Disable this job immediately and re-gather statistics for all affected schemas using coe_siebel_stats.sql.<br>'||CHR(10)||
           'See <a target="MOS" href="^^doc_link.781927.1">781927.1</a>.'
         WHEN '^^is_psft.' = 'Y' THEN
           'Disable this job immediately and re-gather statistics for all affected schemas using pscbo_stats.sql.<br>'||CHR(10)||
           'See <a target="MOS" href="^^doc_link.1322888.1">1322888.1</a>.'
         ELSE
           'Be aware that small sample sizes could produce poor quality histograms,<br>'||CHR(10)||
           'which combined with bind sensitive predicates could render suboptimal plans.<br>'||CHR(10)||
           'See <a target="MOS" href="^^doc_link.465787.1">465787.1</a>.'
         END
  FROM dba_autotask_client
 WHERE :health_checks = 'Y'
   AND client_name = 'auto optimizer stats collection'
   AND status = 'ENABLED';
   
-- DBMS_STATS automatic gathering on 11g but not running for a week   
INSERT INTO plan_table (id, operation, object_alias, other_tag, remarks, projection)
SELECT :E_GLOBAL, 'DBMS_STATS', SYSTIMESTAMP, 'DBA_AUTOTASK_CLIENT',
       'Automatic gathering of CBO statistics is enabled but no job was<br>executed in the last 8 days',
       'The job is enabled in the system but there is no evidence it was ever<br>executed in the last 8 days.'
  FROM dba_autotask_client
 WHERE :health_checks = 'Y'
   AND client_name = 'auto optimizer stats collection'
   AND status = 'ENABLED'
   AND 0 = (SELECT count(*)
		     FROM dba_autotask_client_history
            WHERE client_name = 'auto optimizer stats collection'
              AND window_start_time > (SYSDATE-8)); 

-- DBMS_STATS automatic gathering on 11g but some jobs not running for a week   
INSERT INTO plan_table (id, operation, object_alias, other_tag, remarks, projection)
SELECT :E_GLOBAL, 'DBMS_STATS', SYSTIMESTAMP, 'DBA_AUTOTASK_CLIENT',
       'Automatic gathering of CBO statistics is enabled but some job did<br>not complete in the last 8 days.',
       'The job is enabled in the system but there are some jobs in the<br>last 8 days that did not complete.'
  FROM dba_autotask_client
 WHERE :health_checks = 'Y'
   AND client_name = 'auto optimizer stats collection'
   AND status = 'ENABLED'
   AND 0 <> (SELECT count(*)
		       FROM dba_autotask_client_history
              WHERE client_name = 'auto optimizer stats collection'
                AND window_start_time > (SYSDATE-8)
			    AND (jobs_created-jobs_started > 0 OR jobs_started-jobs_completed > 0));		  

-- multiple CBO environments in SQL Area
INSERT INTO plan_table (id, operation, object_alias, other_tag, remarks, projection)
SELECT :E_GLOBAL, 'PLAN', SYSTIMESTAMP, 'OPTIMIZER_ENV',
       'SQL Area references '||COUNT(DISTINCT optimizer_env_hash_value)||' distinct CBO Environments for this one SQL.',
       'Distinct CBO Environments may produce different Plans.'
  FROM gv$sqlarea_plan_hash
 WHERE :health_checks = 'Y'
   AND sql_id = :sql_id
HAVING COUNT(*) > 1;

-- multiple CBO environments in GV$SQL
INSERT INTO plan_table (id, operation, object_alias, other_tag, remarks, projection)
SELECT :E_GLOBAL, 'PLAN', SYSTIMESTAMP, 'OPTIMIZER_ENV',
       'GV$SQL references '||COUNT(DISTINCT optimizer_env_hash_value)||' distinct CBO Environments for this one SQL.',
       'Distinct CBO Environments may produce different Plans.'
  FROM gv$sql
 WHERE :health_checks = 'Y'
   AND sql_id = :sql_id
HAVING COUNT(*) > 1;

-- multiple CBO environments in AWR
INSERT INTO plan_table (id, operation, object_alias, other_tag, remarks, projection)
SELECT :E_GLOBAL, 'PLAN', SYSTIMESTAMP, 'OPTIMIZER_ENV',
       'AWR references '||COUNT(DISTINCT optimizer_env_hash_value)||' distinct CBO Enviornments for this one SQL.',
       'Distinct CBO Environments may produce different Plans.'
  FROM dba_hist_sqlstat
 WHERE :health_checks = 'Y'
   AND :license IN ('T', 'D')
   AND dbid = ^^dbid.
   AND sql_id = :sql_id
HAVING COUNT(*) > 1;

-- multiple plans with same PHV but different predicate ordering
INSERT INTO plan_table (id, operation, object_alias, other_tag, remarks, projection)
SELECT :E_GLOBAL, 'PLAN', SYSTIMESTAMP, 'PREDICATES ORDERING',
       'There are plans with same PHV '||v.plan_hash_value||' but different predicate ordering.',
       'Different ordering in the predicates for '||v.plan_hash_value||' can affect the performance of this SQL,<br>'||CHR(10)||
       'focus on Step ID '||v.id||' predicates '||v.predicates||' .'
  FROM ( 
WITH d AS (
SELECT sql_id,
       plan_hash_value,
       id,
       COUNT(DISTINCT access_predicates) distinct_access_predicates,
       COUNT(DISTINCT filter_predicates) distinct_filter_predicates
  FROM gv$sql_plan_statistics_all
 WHERE sql_id = :sql_id
 GROUP BY
       sql_id,
       plan_hash_value,
       id
HAVING MIN(NVL(access_predicates, 'X')) != MAX(NVL(access_predicates, 'X'))
    OR MIN(NVL(filter_predicates, 'X')) != MAX(NVL(filter_predicates, 'X'))
)
SELECT v.plan_hash_value,
       v.id,
       'access' type,
       v.inst_id,
       v.child_number,
       v.access_predicates predicates
  FROM d,
       gv$sql_plan_statistics_all v
 WHERE v.sql_id = d.sql_id
   AND v.plan_hash_value = d.plan_hash_value
   AND v.id = d.id
   AND d.distinct_access_predicates > 1
 UNION ALL
SELECT v.plan_hash_value,
       v.id,
       'filter' type,
       v.inst_id,
       v.child_number,
       v.filter_predicates predicates
  FROM d,
       gv$sql_plan_statistics_all v
 WHERE v.sql_id = d.sql_id
   AND v.plan_hash_value = d.plan_hash_value
   AND v.id = d.id
   AND d.distinct_filter_predicates > 1
 ORDER BY
       1, 2, 3, 6, 4, 5) v
  WHERE :health_checks = 'Y' ; 

-- plans with implicit data_type conversion
INSERT INTO plan_table (id, operation, object_alias, other_tag, remarks, projection)
SELECT :E_GLOBAL, 'PLAN', SYSTIMESTAMP, 'PLAN_HASH_VALUE',
       'Plan '||v.plan_hash_value||' may have implicit data_type conversion functions in Filter Predicates.',
       'Review Execution Plans.<br>'||CHR(10)||
       'If Filter Predicates for '||v.plan_hash_value||' include unexpected INTERNAL_FUNCTION to perform an implicit data_type conversion,<br>'||CHR(10)||
       'be sure it is not preventing a column from being used as an Access Predicate.'
  FROM (
SELECT DISTINCT plan_hash_value
  FROM gv$sql_plan
 WHERE :health_checks = 'Y'
   AND inst_id IN (SELECT inst_id FROM gv$instance)
   AND sql_id = :sql_id
   AND filter_predicates LIKE '%INTERNAL_FUNCTION%'
 ORDER BY 1) v;

-- plan operations with cost 0 and card 1
INSERT INTO plan_table (id, operation, object_alias, other_tag, remarks, projection)
SELECT :E_GLOBAL, 'PLAN', SYSTIMESTAMP, 'PLAN_HASH_VALUE',
       'Plan '||v.plan_hash_value||' has operations with Cost 0 and Card 1. Possible incorrect Selectivity.',
       'Review Execution Plans.<br>'||CHR(10)||
       'Look for Plan operations in '||v.plan_hash_value||' where Cost is 0 and Estimated Cardinality is 1.<br>'||CHR(10)||
       'Suspect predicates out of range or incorrect statistics.'
  FROM (
SELECT plan_hash_value
  FROM gv$sql_plan
 WHERE :health_checks = 'Y'
   AND inst_id IN (SELECT inst_id FROM gv$instance)
   AND sql_id = :sql_id
   AND cost = 0
   AND cardinality = 1
 UNION
SELECT plan_hash_value
  FROM dba_hist_sql_plan
 WHERE :health_checks = 'Y'
   AND :license IN ('T', 'D')
   AND dbid = ^^dbid.
   AND sql_id = :sql_id
   AND cost = 0
   AND cardinality = 1) v;

-- high version count
INSERT INTO plan_table (id, operation, object_alias, other_tag, remarks, projection)
SELECT :E_GLOBAL, 'VERSION COUNT', SYSTIMESTAMP, 'VERSION COUNT',
       'This SQL shows evidence of high version count of '||MAX(v.version_count)||'.',
       'Review Execution Plans for details.'
  FROM (
SELECT MAX(version_count) version_count
  FROM gv$sqlarea_plan_hash
 WHERE :health_checks = 'Y'
   AND sql_id = :sql_id
 UNION
SELECT MAX(version_count) version_count
  FROM dba_hist_sqlstat
 WHERE :health_checks = 'Y'
   AND :license IN ('T', 'D')
   AND dbid = ^^dbid.
   AND sql_id = :sql_id ) v
HAVING MAX(v.version_count) > 20;

-- first rows
INSERT INTO plan_table (id, operation, object_alias, other_tag, remarks, projection)
SELECT :E_GLOBAL, 'OPTIMZER MODE', SYSTIMESTAMP, 'FIRST_ROWS',
       'OPTIMIZER_MODE was set to FIRST_ROWS in '||v.pln_count||' Plan(s).',
       'The optimizer uses a mix of cost and heuristics to find a best plan for fast delivery of the first few rows.<br>'||CHR(10)||
       'Using heuristics sometimes leads the query optimizer to generate a plan with a cost that is significantly larger than the cost of a plan without applying the heuristic.<br>'||CHR(10)||
       'FIRST_ROWS is available for backward compatibility and plan stability; use FIRST_ROWS_n instead.'
FROM (
SELECT COUNT(*) pln_count
  FROM (
SELECT plan_hash_value
  FROM gv$sql
 WHERE :health_checks = 'Y'
   AND sql_id = :sql_id
   AND optimizer_mode = 'FIRST_ROWS'
 UNION
SELECT plan_hash_value
  FROM dba_hist_sqlstat
 WHERE :health_checks = 'Y'
   AND :license IN ('T', 'D')
   AND dbid = ^^dbid.
   AND sql_id = :sql_id
   AND optimizer_mode = 'FIRST_ROWS') v) v
 WHERE :health_checks = 'Y'
   AND v.pln_count > 0;

-- fixed objects missing stats
INSERT INTO plan_table (id, operation, object_alias, other_tag, remarks, projection)
SELECT :E_GLOBAL, 'FIXED OBJECTS', SYSTIMESTAMP, 'DBA_TAB_COL_STATISTICS',
       'There exist(s) '||v.tbl_count||' Fixed Object(s) accessed by this SQL without CBO statistics.',
       'Consider gathering statistics for fixed objects using DBMS_STATS.GATHER_FIXED_OBJECTS_STATS.<br>'||CHR(10)||
       'See <a target="MOS" href="^^doc_link.465787.1">465787.1</a>.'
FROM (
SELECT COUNT(*) tbl_count
  FROM plan_table pt,
       dba_tab_statistics t
 WHERE :health_checks = 'Y'
   AND pt.object_type = 'TABLE'
   AND pt.object_owner = t.owner
   AND pt.object_name = t.table_name
   AND t.object_type = 'FIXED TABLE'
   AND NOT EXISTS (
SELECT NULL
  FROM dba_tab_cols c
 WHERE :health_checks = 'Y'
   AND t.owner = c.owner
   AND t.table_name = c.table_name )) v
 WHERE :health_checks = 'Y'
   AND v.tbl_count > 0;

-- system statistics not gathered
INSERT INTO plan_table (id, operation, object_alias, other_tag, remarks, projection)
SELECT :E_GLOBAL, 'DBMS_STATS', SYSTIMESTAMP, 'SYSTEM STATISTICS',
       'Workload CBO System Statistics are not gathered. CBO is using default values.',
       'Consider gathering workload system statistics using DBMS_STATS.GATHER_SYSTEM_STATS.<br>'||CHR(10)||
       'See also <a target="MOS" href="^^doc_link.465787.1">465787.1</a>.'
  FROM sys.aux_stats$
 WHERE :health_checks = 'Y'
   AND sname = 'SYSSTATS_MAIN'
   AND pname = 'CPUSPEED'
   AND pval1 IS NULL;

-- mreadtim < sreadtim
INSERT INTO plan_table (id, operation, object_alias, other_tag, remarks, projection)
SELECT :E_GLOBAL, 'DBMS_STATS', SYSTIMESTAMP, 'SYSTEM STATISTICS',
       'Multi-block read time of '||a1.pval1||'ms seems too small compared to single-block read time of '||a2.pval1||'ms.',
       'Consider gathering workload system statistics using DBMS_STATS.GATHER_SYSTEM_STATS or adjusting SREADTIM and MREADTIM using DBMS_STATS.SET_SYSTEM_STATS.<br>'||CHR(10)||
       'See also <a target="MOS" href="^^doc_link.465787.1">465787.1</a>.'
  FROM sys.aux_stats$ a1, sys.aux_stats$ a2
 WHERE :health_checks = 'Y'
   AND a1.sname = 'SYSSTATS_MAIN'
   AND a1.pname = 'MREADTIM'
   AND a2.sname = 'SYSSTATS_MAIN'
   AND a2.pname = 'SREADTIM'
   AND a1.pval1 < a2.pval1;

-- (1.2 * sreadtim) > mreadtim > sreadtim
INSERT INTO plan_table (id, operation, object_alias, other_tag, remarks, projection)
SELECT :E_GLOBAL, 'DBMS_STATS', SYSTIMESTAMP, 'SYSTEM STATISTICS',
       'Multi-block read time of '||a1.pval1||'ms seems too small compared to single-block read time of '||a2.pval1||'ms.',
       'Consider gathering workload system statistics using DBMS_STATS.GATHER_SYSTEM_STATS or adjusting SREADTIM and MREADTIM using DBMS_STATS.SET_SYSTEM_STATS.<br>'||CHR(10)||
       'See also <a target="MOS" href="^^doc_link.465787.1">465787.1</a>.'
  FROM sys.aux_stats$ a1, sys.aux_stats$ a2
 WHERE :health_checks = 'Y'
   AND a1.sname = 'SYSSTATS_MAIN'
   AND a1.pname = 'MREADTIM'
   AND a2.sname = 'SYSSTATS_MAIN'
   AND a2.pname = 'SREADTIM'
   AND (1.2 * a2.pval1) > a1.pval1
   AND a1.pval1 > a2.pval1;

-- sreadtim < 2
INSERT INTO plan_table (id, operation, object_alias, other_tag, remarks, projection)
SELECT :E_GLOBAL, 'DBMS_STATS', SYSTIMESTAMP, 'SYSTEM STATISTICS',
       'Single-block read time of '||pval1||' milliseconds seems too small.',
       'Consider gathering workload system statistics using DBMS_STATS.GATHER_SYSTEM_STATS or adjusting SREADTIM using DBMS_STATS.SET_SYSTEM_STATS.<br>'||CHR(10)||
       'See also <a target="MOS" href="^^doc_link.465787.1">465787.1</a>.'
  FROM sys.aux_stats$
 WHERE :health_checks = 'Y'
   AND sname = 'SYSSTATS_MAIN'
   AND pname = 'SREADTIM'
   AND pval1 < 2
   AND NVL('^^exadata.','N') = 'N'; 

-- mreadtim < 3
INSERT INTO plan_table (id, operation, object_alias, other_tag, remarks, projection)
SELECT :E_GLOBAL, 'DBMS_STATS', SYSTIMESTAMP, 'SYSTEM STATISTICS',
       'Multi-block read time of '||pval1||' milliseconds seems too small.',
       'Consider gathering workload system statistics using DBMS_STATS.GATHER_SYSTEM_STATS or adjusting MREADTIM using DBMS_STATS.SET_SYSTEM_STATS.<br>'||CHR(10)||
       'See also <a target="MOS" href="^^doc_link.465787.1">465787.1</a>.'
  FROM sys.aux_stats$
 WHERE :health_checks = 'Y'
   AND sname = 'SYSSTATS_MAIN'
   AND pname = 'MREADTIM'
   AND pval1 < 3
   AND NVL('^^exadata.','N') = 'N'; 

-- sreadtim > 18
INSERT INTO plan_table (id, operation, object_alias, other_tag, remarks, projection)
SELECT :E_GLOBAL, 'DBMS_STATS', SYSTIMESTAMP, 'SYSTEM STATISTICS',
       'Single-block read time of '||pval1||' milliseconds seems too large.',
       'Consider gathering workload system statistics using DBMS_STATS.GATHER_SYSTEM_STATS or adjusting SREADTIM using DBMS_STATS.SET_SYSTEM_STATS.<br>'||CHR(10)||
       'See also <a target="MOS" href="^^doc_link.465787.1">465787.1</a> and Bug <a target="MOS" href="^^bug_link.9842771">9842771</a>.'
  FROM sys.aux_stats$
 WHERE :health_checks = 'Y'
   AND sname = 'SYSSTATS_MAIN'
   AND pname = 'SREADTIM'
   AND pval1 > 18
   AND NVL('^^exadata.','N') = 'N'; 

-- mreadtim > 522
INSERT INTO plan_table (id, operation, object_alias, other_tag, remarks, projection)
SELECT :E_GLOBAL, 'DBMS_STATS', SYSTIMESTAMP, 'SYSTEM STATISTICS',
       'Multi-block read time of '||pval1||' milliseconds seems too large.',
       'Consider gathering workload system statistics using DBMS_STATS.GATHER_SYSTEM_STATS or adjusting MREADTIM using DBMS_STATS.SET_SYSTEM_STATS.<br>'||CHR(10)||
       'See also <a target="MOS" href="^^doc_link.465787.1">465787.1</a> and Bug <a target="MOS" href="^^bug_link.9842771">9842771</a>.'
  FROM sys.aux_stats$
 WHERE :health_checks = 'Y'
   AND sname = 'SYSSTATS_MAIN'
   AND pname = 'MREADTIM'
   AND pval1 > 522
   AND NVL('^^exadata.','N') = 'N'; 
   
-- sreadtim not between 0.5 and 10 in Exadata
INSERT INTO plan_table (id, operation, object_alias, other_tag, remarks, projection)
SELECT :E_GLOBAL, 'DBMS_STATS', SYSTIMESTAMP, 'SYSTEM STATISTICS',
       'Single-block read time of '||pval1||' milliseconds seems unlikely for an Exadata system.',
       'Consider gathering workload system statistics using DBMS_STATS.GATHER_SYSTEM_STATS or adjusting SREADTIM using DBMS_STATS.SET_SYSTEM_STATS.<br>'||CHR(10)||
       'See also <a target="MOS" href="^^doc_link.465787.1">465787.1</a> and Bug <a target="MOS" href="^^bug_link.9842771">9842771</a>.'
  FROM sys.aux_stats$
 WHERE :health_checks = 'Y'
   AND sname = 'SYSSTATS_MAIN'
   AND pname = 'SREADTIM'
   AND pval1 NOT BETWEEN 0.5 AND 10
   AND '^^exadata.' = 'Y';   
   
-- mreadtim not between 0.5 and 10 in Exadata
INSERT INTO plan_table (id, operation, object_alias, other_tag, remarks, projection)
SELECT :E_GLOBAL, 'DBMS_STATS', SYSTIMESTAMP, 'SYSTEM STATISTICS',
       'Multi-block read time of '||pval1||' milliseconds seems unlikely for  an Exadata system.',
       'Consider gathering workload system statistics using DBMS_STATS.GATHER_SYSTEM_STATS or adjusting MREADTIM using DBMS_STATS.SET_SYSTEM_STATS.<br>'||CHR(10)||
       'See also <a target="MOS" href="^^doc_link.465787.1">465787.1</a> and Bug <a target="MOS" href="^^bug_link.9842771">9842771</a>.'
  FROM sys.aux_stats$
 WHERE :health_checks = 'Y'
   AND sname = 'SYSSTATS_MAIN'
   AND pname = 'MREADTIM'
   AND pval1 NOT BETWEEN 0.5 AND 10
   AND '^^exadata.' = 'Y';    
   
-- exadata specific check, offload disabled because of bad timezone file to cells (bug 11836425)   
INSERT INTO plan_table (id, operation, object_alias, other_tag, remarks, projection)
SELECT :E_GLOBAL, 'OFFLOAD', SYSTIMESTAMP, 'OFFLOAD OFF',
       'Due to a timezone upgrade pending the offload might be disabled.',
       'Offload might get rejected if the cells don''t have the propert timezone file.'
  FROM database_properties
 WHERE :health_checks = 'Y'
   AND property_name = 'DST_UPGRADE_STATE' 
   AND property_value<>'NONE'
   AND ROWNUM = 1
   AND '^^exadata.' = 'Y'; 
   
-- Exadata specific check, offload disabled because tables with CACHE = YES
INSERT INTO plan_table (id, operation, object_alias, other_tag, remarks, projection)
SELECT :E_GLOBAL, 'OFFLOAD', SYSTIMESTAMP, 'OFFLOAD OFF',
       'There is/are tables(s) with property CACHE = ''Y'', this causes offload to be disabled on it/them.',
       'Offload is not used for tables that have property CACHE = ''Y''.'
  FROM plan_table pt,
       dba_tables t
 WHERE :health_checks = 'Y'
   AND pt.object_type = 'TABLE'
   AND pt.object_owner = t.owner
   AND pt.object_name = t.table_name
   AND t.object_type = 'TABLE'
   AND ROWNUM = 1
   AND t.cache = 'Y'
   AND '^^exadata.' = 'Y';    
   
-- Exadata specific check, offload disabled for SQL executed by shared servers
INSERT INTO plan_table (id, operation, object_alias, other_tag, remarks, projection)
SELECT :E_GLOBAL, 'OFFLOAD', SYSTIMESTAMP, 'OFFLOAD OFF',
       'Offload is not used for SQLs executed from Shared Server.',
       'SQLs executed by Shared Server cannot be offloaded since they don''t use direct path reads.'
  FROM v$system_parameter2 
 WHERE :health_checks = 'Y'
   AND UPPER(name) = 'SHARED_SERVERS'
   AND UPPER(value) > 0
   AND '^^exadata.' = 'Y';   

-- Exadata specific check, offload disabled for serial DML 
INSERT INTO plan_table (id, operation, object_alias, other_tag, remarks, projection)
SELECT :E_GLOBAL, 'OFFLOAD', SYSTIMESTAMP, 'OFFLOAD OFF',
       'Offload is not used for SQLs that don''t use direct path reads.',
       'Serial DMLs cannot be offloaded by default since they don''t use direct path reads<br>'||CHR(10)||
	   'If this execution is serial then make sure to use direct path reads or offload won'' be possible.'
  FROM v$sql 
 WHERE :health_checks = 'Y'
   AND TRIM(UPPER(SUBSTR(LTRIM(sql_text),1,6))) IN ('INSERT','UPDATE','DELETE','MERGE')
   AND sql_id = '^^sql_id.'
   AND ROWNUM = 1
   AND '^^exadata.' = 'Y';  

-- AutoDOP and no IO Calibration   
INSERT INTO plan_table (id, operation, object_alias, other_tag, remarks, projection)
SELECT :E_GLOBAL, 'PX', SYSTIMESTAMP, 'AUTODOP OFF',
       'AutoDOP is enable but there are no IO Calibration stats.',
       'AutoDOP requires IO Calibration stats, consider collecting them using DBMS_RESOURCE_MANAGER.CALIBRATE_IO.'
  FROM v$system_parameter2 
 WHERE :health_checks = 'Y'
   AND UPPER(name) = 'PARALLEL_DEGREE_POLICY'
   AND UPPER(value) IN ('AUTO','LIMITED')
   AND NOT EXISTS (SELECT 1 
                     FROM v$dba_rsrc_io_calibrate); 

-- Manuaul DOP and Tables with DEFAULT degree
INSERT INTO plan_table (id, operation, object_alias, other_tag, remarks, projection)
SELECT :E_GLOBAL, 'PX', SYSTIMESTAMP, 'MANUAL DOP WITH DEFAULT',
       'The DEGREE on some tables in set to DEFAULT and PARALLEL_DEGREE_POLICY is MANUAL',
       'DEFAULT degree combined with PARALLEL_DEGREE_POLICY = MANUAL might translate in a high degree of parallelism.'
  FROM v$system_parameter2 
 WHERE :health_checks = 'Y'
   AND UPPER(name) = 'PARALLEL_DEGREE_POLICY'
   AND UPPER(value) = 'MANUAL'
   AND EXISTS (SELECT 1 
                 FROM plan_table pt,
                      dba_tables t
                WHERE pt.object_type = 'TABLE'
                  AND pt.object_owner = t.owner
                  AND pt.object_name = t.table_name
                  AND t.object_type = 'TABLE'
                  AND t.degree = 'DEFAULT'); 					 
   
-- sql with policies as per v$vpd_policy
INSERT INTO plan_table (id, operation, object_alias, other_tag, remarks, projection)
SELECT :E_GLOBAL, 'VDP', SYSTIMESTAMP, 'V$VPD_POLICY',
       'Virtual Private Database. There is one or more policies affecting this SQL.',
       'Review Execution Plans and look for their injected predicates.'
  FROM v$vpd_policy
 WHERE :health_checks = 'Y'
   AND sql_id = :sql_id
HAVING COUNT(*) > 0;

-- materialized views with rewrite enabled
INSERT INTO plan_table (id, operation, object_alias, other_tag, remarks, projection)
SELECT :E_GLOBAL, 'MAT_VIEW', SYSTIMESTAMP, 'REWRITE_ENABLED',
       'There are '||COUNT(*)||' materialized views with rewrite enabled.',
       'A large number of materialized views could affect parsing time since CBO would have to evaluate each during a hard-parse.'
  FROM v$system_parameter2 p,
       dba_mviews m
 WHERE :health_checks = 'Y'
   AND UPPER(p.name) = 'QUERY_REWRITE_ENABLED'
   AND UPPER(p.value) = 'TRUE'
   AND m.rewrite_enabled = 'Y'
HAVING COUNT(*) > 1;

-- rewrite equivalences from DBMS_ADVANCED_REWRITE
INSERT INTO plan_table (id, operation, object_alias, other_tag, remarks, projection)
SELECT :E_GLOBAL, 'REWRITE_EQUIVALENCE', SYSTIMESTAMP, 'REWRITE_EQUIVALENCE',
       'There is/are '||COUNT(*)||' rewrite equivalence(s) defined by the owner(s) of the involved objects.',
       'A rewrite equivalence makes the CBO rewrite the original SQL to a different one so that needs to be considered when analyzing the case.'
  FROM dba_rewrite_equivalences m,
       (SELECT DISTINCT object_owner owner FROM plan_table) o
 WHERE :health_checks = 'Y'
   AND m.owner = o.owner
HAVING COUNT(*) > 0;

-- table with bitmap index(es)
INSERT INTO plan_table (id, operation, object_alias, other_tag, remarks, projection)
SELECT :E_GLOBAL, 'INDEX', SYSTIMESTAMP, 'BITMAP',
       'Your DML statement references '||COUNT(DISTINCT pt.object_name||pt.object_owner)||' Table(s) with at least one Bitmap index.',
       'Be aware that frequent DML operations operations in a Table with Bitmap indexes may produce contention where concurrent DML operations are common. If your SQL suffers of "TX-enqueue row lock contention" suspect this situation.'
  FROM plan_table pt,
       dba_indexes i
 WHERE :health_checks = 'Y'
   AND pt.object_type = 'TABLE'
   AND pt.object_owner = i.table_owner
   AND pt.object_name = i.table_name
   AND i.index_type = 'BITMAP'
   AND EXISTS (
SELECT NULL
  FROM gv$sqlarea s
 WHERE :health_checks = 'Y'
   AND s.sql_id = :sql_id
   AND s.command_type IN (2, 6, 7)) -- INSERT, UPDATE, DELETE
HAVING COUNT(*) > 0;

-- index in plan no longer exists
INSERT INTO plan_table (id, operation, object_alias, other_tag, remarks, projection)
SELECT DISTINCT :E_INDEX, 'INDEX', SYSTIMESTAMP, pt.object_owner||'.'||pt.object_name,
       'Index referenced by an Execution Plan no longer exists.',
       'If a Plan references a missing index then this Plan can no longer be generated by the CBO.'
  FROM plan_table pt
 WHERE :health_checks = 'Y'
   AND pt.object_type = 'INDEX'
   AND pt.other_tag = 'YES'
   AND NOT EXISTS (
SELECT NULL
  FROM dba_indexes i
 WHERE :health_checks = 'Y'
   AND pt.object_owner = i.owner
   AND pt.object_name = i.index_name );

-- index in plan is now unusable
INSERT INTO plan_table (id, operation, object_alias, other_tag, remarks, projection)
SELECT DISTINCT :E_INDEX, 'INDEX', SYSTIMESTAMP, pt.object_owner||'.'||pt.object_name,
       'Index referenced by an Execution Plan is now unusable.',
       'If a Plan references an unusable index then this Plan cannot be generated by the CBO.<br>'||CHR(10)||
       'If you need to enable tha Plan that references this index you need to rebuild it first.'
  FROM plan_table pt,
       dba_indexes i
 WHERE :health_checks = 'Y'
   AND pt.object_type = 'INDEX'
   AND pt.other_tag = 'YES'
   AND pt.object_owner = i.owner
   AND pt.object_name = i.index_name
   AND i.partitioned = 'NO'
   AND i.status = 'UNUSABLE';

-- index in plan has now unusable partitions
INSERT INTO plan_table (id, operation, object_alias, other_tag, remarks, projection)
SELECT DISTINCT :E_INDEX, 'INDEX', SYSTIMESTAMP, pt.object_owner||'.'||pt.object_name,
       'Index referenced by an Execution Plan has now unusable partitions.',
       'If a Plan references an index with unusable partitions then this Plan cannot be generated by the CBO.<br>'||CHR(10)||
       'If you need to enable tha Plan that references this index you need to rebuild the unusable partitions first.'
  FROM plan_table pt,
       dba_indexes i,
       dba_ind_partitions p
 WHERE :health_checks = 'Y'
   AND pt.object_type = 'INDEX'
   AND pt.other_tag = 'YES'
   AND pt.object_owner = i.owner
   AND pt.object_name = i.index_name
   AND i.partitioned = 'YES'
   AND pt.object_owner = p.index_owner
   AND pt.object_name = p.index_name
   AND p.status = 'UNUSABLE';

-- index in plan has now unusable subpartitions
INSERT INTO plan_table (id, operation, object_alias, other_tag, remarks, projection)
SELECT DISTINCT :E_INDEX, 'INDEX', SYSTIMESTAMP, pt.object_owner||'.'||pt.object_name,
       'Index referenced by an Execution Plan has now unusable subpartitions.',
       'If a Plan references an index with unusable subpartitions then this Plan cannot be generated by the CBO.<br>'||CHR(10)||
       'If you need to enable tha Plan that references this index you need to rebuild the unusable subpartitions first.'
  FROM plan_table pt,
       dba_indexes i,
       dba_ind_subpartitions p
 WHERE :health_checks = 'Y'
   AND pt.object_type = 'INDEX'
   AND pt.other_tag = 'YES'
   AND pt.object_owner = i.owner
   AND pt.object_name = i.index_name
   AND i.partitioned = 'YES'
   AND pt.object_owner = p.index_owner
   AND pt.object_name = p.index_name
   AND p.status = 'UNUSABLE';

-- index in plan is now invisible
INSERT INTO plan_table (id, operation, object_alias, other_tag, remarks, projection)
SELECT DISTINCT :E_INDEX, 'INDEX', SYSTIMESTAMP, pt.object_owner||'.'||pt.object_name,
       'Index referenced by an Execution Plan is now invisible.',
       'If a Plan references an invisible index then this Plan cannot be generated by the CBO.<br>'||CHR(10)||
       'If you need to enable tha Plan that references this index you need to make this index visible.'
  FROM plan_table pt,
       dba_indexes i
 WHERE :health_checks = 'Y'
   AND pt.object_type = 'INDEX'
   AND pt.other_tag = 'YES'
   AND pt.object_owner = i.owner
   AND pt.object_name = i.index_name
   AND i.partitioned = 'NO'
   AND i.visibility = 'INVISIBLE';

-- unusable indexes
INSERT INTO plan_table (id, operation, object_alias, other_tag, remarks, projection)
SELECT :E_GLOBAL, 'INDEX', SYSTIMESTAMP, 'UNUSABLE',
       'There are '||COUNT(*)||' unusable index(es) in tables being accessed by your SQL.',
       'Unusable indexes cannot be used by the CBO. This may cause Execution Plans to change.'
  FROM plan_table pt,
       dba_indexes i
 WHERE :health_checks = 'Y'
   AND pt.object_type = 'INDEX'
   AND pt.object_owner = i.owner
   AND pt.object_name = i.index_name
   AND i.partitioned = 'NO'
   AND i.status = 'UNUSABLE'
HAVING COUNT(*) > 0;

-- unusable index partitions
INSERT INTO plan_table (id, operation, object_alias, other_tag, remarks, projection)
SELECT :E_GLOBAL, 'INDEX PARTITION', SYSTIMESTAMP, 'UNUSABLE',
       'There are '||COUNT(*)||' unusable index partition(s) in tables being accessed by your SQL.',
       'Unusable index partitions cannot be used by the CBO. This may cause Execution Plans to change.'
  FROM plan_table pt,
       dba_indexes i,
       dba_ind_partitions p
 WHERE :health_checks = 'Y'
   AND pt.object_type = 'INDEX'
   AND pt.object_owner = i.owner
   AND pt.object_name = i.index_name
   AND i.partitioned = 'YES'
   AND pt.object_owner = p.index_owner
   AND pt.object_name = p.index_name
   AND p.status = 'UNUSABLE'
HAVING COUNT(*) > 0;

-- unusable index subpartitions
INSERT INTO plan_table (id, operation, object_alias, other_tag, remarks, projection)
SELECT :E_GLOBAL, 'INDEX SUBPARTITION', SYSTIMESTAMP, 'UNUSABLE',
       'There are '||COUNT(*)||' unusable index subpartition(s) in tables being accessed by your SQL.',
       'Unusable index subpartitions cannot be used by the CBO. This may cause Execution Plans to change.'
  FROM plan_table pt,
       dba_indexes i,
       dba_ind_subpartitions sp
 WHERE :health_checks = 'Y'
   AND pt.object_type = 'INDEX'
   AND pt.object_owner = i.owner
   AND pt.object_name = i.index_name
   AND i.partitioned = 'YES'
   AND pt.object_owner = sp.index_owner
   AND pt.object_name = sp.index_name
   AND sp.status = 'UNUSABLE'
HAVING COUNT(*) > 0;

-- invisible indexes
INSERT INTO plan_table (id, operation, object_alias, other_tag, remarks, projection)
SELECT :E_GLOBAL, 'INDEX', SYSTIMESTAMP, 'INVISIBLE',
       'There are '||COUNT(*)||' invisible index(es) in tables being accessed by your SQL.',
       'Invisible indexes cannot be used by the CBO. This may cause Execution Plans to change.'
  FROM plan_table pt,
       dba_indexes i
 WHERE :health_checks = 'Y'
   AND pt.object_type = 'INDEX'
   AND pt.object_owner = i.owner
   AND pt.object_name = i.index_name
   AND i.visibility = 'INVISIBLE'
HAVING COUNT(*) > 0;

/* -------------------------
 *
 * table hc
 *
 * ------------------------- */

-- empty_blocks > blocks
INSERT INTO plan_table (id, operation, object_alias, other_tag, remarks, projection)
SELECT :E_TABLE, 'TABLE', SYSTIMESTAMP, pt.object_owner||'.'||pt.object_name,
       'Table has more empty blocks ('||t.empty_blocks||') than actual blocks ('||t.blocks||') according to CBO statistics.',
       'Review Table statistics and consider re-organizing this Table.'
  FROM plan_table pt,
       dba_tables t
 WHERE :health_checks = 'Y'
   AND pt.object_type = 'TABLE'
   AND pt.object_owner = t.owner
   AND pt.object_name = t.table_name
   AND t.empty_blocks > t.blocks;

-- table dop is set
INSERT INTO plan_table (id, operation, object_alias, other_tag, remarks, projection)
SELECT :E_TABLE, 'TABLE', SYSTIMESTAMP, pt.object_owner||'.'||pt.object_name,
       'Table''s DOP is "'||TRIM(t.degree)||'".',
       'Degree of parallelism greater than 1 may cause parallel-execution PX plans.<br>'||CHR(10)||
       'Review table properties and execute "ALTER TABLE '||pt.object_owner||'.'||pt.object_name||' NOPARALLEL" to reset degree of parallelism to 1 if PX plans are not desired.'
  FROM plan_table pt,
       dba_tables t
 WHERE :health_checks = 'Y'
   AND pt.object_type = 'TABLE'
   AND pt.object_owner = t.owner
   AND pt.object_name = t.table_name
   AND TRIM(t.degree) NOT IN ('0', '1', 'DEFAULT');

-- table has indexes with dop set
INSERT INTO plan_table (id, operation, object_alias, other_tag, remarks, projection)
SELECT :E_TABLE, 'TABLE', SYSTIMESTAMP, pt.object_owner||'.'||pt.object_name,
       'Table has '||COUNT(*)||' index(es) with DOP greater than 1.',
       'Degree of parallelism greater than 1 may cause parallel-execution PX plans.<br>'||CHR(10)||
       'Review index properties and execute "ALTER INDEX index_name NOPARALLEL" to reset degree of parallelism to 1 if PX plans are not desired.'
  FROM plan_table pt,
       dba_indexes i
 WHERE :health_checks = 'Y'
   AND pt.object_type = 'TABLE'
   AND pt.object_owner = i.table_owner
   AND pt.object_name = i.table_name
   AND TRIM(i.degree) NOT IN ('0', '1', 'DEFAULT')
 GROUP BY
       pt.object_owner,
       pt.object_name;

-- index degree <> table degree
INSERT INTO plan_table (id, operation, object_alias, other_tag, remarks, projection)
SELECT :E_TABLE, 'TABLE', SYSTIMESTAMP, pt.object_owner||'.'||pt.object_name,
       'Table has '||COUNT(*)||' index(es) with DOP different than its table.',
       'Table has a degree of parallelism of "'||TRIM(t.degree)||'".<br>'||CHR(10)||
       'Review index properties and fix degree of parallelism of table and/or its index(es).'
  FROM plan_table pt,
       dba_tables t,
       dba_indexes i
 WHERE :health_checks = 'Y'
   AND pt.object_type = 'TABLE'
   AND pt.object_owner = t.owner
   AND pt.object_name = t.table_name
   AND pt.object_owner = i.table_owner
   AND pt.object_name = i.table_name
   AND TRIM(t.degree) <> TRIM(i.degree)
 GROUP BY
       pt.object_owner,
       pt.object_name,
       TRIM(t.degree);

-- no stats
INSERT INTO plan_table (id, operation, object_alias, other_tag, remarks, projection)
SELECT :E_TABLE, 'TABLE', SYSTIMESTAMP, pt.object_owner||'.'||pt.object_name,
       'Table lacks CBO Statistics.',
       CASE
         WHEN '^^is_ebs.' = 'Y' THEN
           'Consider gathering table statistics using FND_STATS.GATHER_TABLE_STATS or coe_stats.sql.<br>'||CHR(10)||
           'See <a target="MOS" href="^^doc_link.156968.1">156968.1</a>.'
         WHEN '^^is_siebel.' = 'Y' THEN
           'If table has more than 15 rows consider gathering table statistics using coe_siebel_stats.sql.<br>'||CHR(10)||
           'See <a target="MOS" href="^^doc_link.781927.1">781927.1</a>.'
         WHEN '^^is_psft.' = 'Y' THEN
           'Consider gathering table statistics using pscbo_stats.sql.<br>'||CHR(10)||
           'See <a target="MOS" href="^^doc_link.1322888.1">1322888.1</a>.'
         ELSE
           'Consider gathering table statistics using DBMS_STATS.GATHER_TABLE_STATS.'||CHR(10)||
           'See <a target="MOS" href="^^doc_link.465787.1">465787.1</a>.'
         END
  FROM plan_table pt,
       dba_tables t
 WHERE :health_checks = 'Y'
   AND pt.object_type = 'TABLE'
   AND pt.object_owner = t.owner
   AND pt.object_name = t.table_name
   AND t.temporary = 'N'
   AND (t.last_analyzed IS NULL OR t.num_rows IS NULL);

-- no rows
INSERT INTO plan_table (id, operation, object_alias, other_tag, remarks, projection)
SELECT :E_TABLE, 'TABLE', SYSTIMESTAMP, pt.object_owner||'.'||pt.object_name,
       'Number of rows equal to zero according to table''s CBO statistics.',
       CASE
         WHEN t.temporary = 'Y' THEN
           'Consider deleting table statistics on this GTT using DBMS_STATS.DELETE_TABLE_STATS.'
         WHEN '^^is_ebs.' = 'Y' THEN
           'If this table has rows consider gathering table statistics using FND_STATS.GATHER_TABLE_STATS or coe_stats.sql.<br>'||CHR(10)||
           'See <a target="MOS" href="^^doc_link.156968.1">156968.1</a>.'
         WHEN '^^is_siebel.' = 'Y' THEN
           'If table has less than 15 rows consider deleting table statistics using DBMS_STATS.DELETE_TABLE_STATS,<br>'||CHR(10)||
           'else gathering table statistics using coe_siebel_stats.sql.<br>'||CHR(10)||
           'See <a target="MOS" href="^^doc_link.781927.1">781927.1</a>.'
         WHEN '^^is_psft.' = 'Y' THEN
           'If this table has rows consider gathering table statistics using pscbo_stats.sql.<br>'||CHR(10)||
           'See <a target="MOS" href="^^doc_link.1322888.1">1322888.1</a>.'
         ELSE
           'Consider gathering table statistics using DBMS_STATS.GATHER_TABLE_STATS.'||CHR(10)||
           'See <a target="MOS" href="^^doc_link.465787.1">465787.1</a>.'
         END
  FROM plan_table pt,
       dba_tables t
 WHERE :health_checks = 'Y'
   AND pt.object_type = 'TABLE'
   AND pt.object_owner = t.owner
   AND pt.object_name = t.table_name
   AND t.num_rows = 0;

-- siebel small tables with CBO statistics
INSERT INTO plan_table (id, operation, object_alias, other_tag, remarks, projection)
SELECT :E_TABLE, 'TABLE', SYSTIMESTAMP, pt.object_owner||'.'||pt.object_name,
       'Small table with CBO statistics.',
       'Consider deleting table statistics on this small table using DBMS_STATS.DELETE_TABLE_STATS.<br>'||CHR(10)||
       'See <a target="MOS" href="^^doc_link.781927.1">781927.1</a>.'
  FROM plan_table pt,
       dba_tables t
 WHERE :health_checks = 'Y'
   AND '^^is_siebel.' = 'Y'
   AND pt.object_type = 'TABLE'
   AND pt.object_owner = t.owner
   AND pt.object_name = t.table_name
   AND t.num_rows < 15;

-- small sample size
INSERT INTO plan_table (id, operation, object_alias, other_tag, remarks, projection)
SELECT :E_TABLE, 'TABLE', SYSTIMESTAMP, v.object_owner||'.'||v.object_name,
       'Sample size of '||v.sample_size||' rows may be too small for table with '||v.num_rows||' rows.',
       'Sample percent used was:'||TRIM(TO_CHAR(ROUND(v.ratio * 100, 2), '99999990D00'))||'%.<br>'||CHR(10)||
       'Consider gathering better quality table statistics with DBMS_STATS.AUTO_SAMPLE_SIZE on 11g or with a sample size of '||ROUND(v.factor * 100)||'% on 10g.'
  FROM (
SELECT pt.object_owner,
       pt.object_name,
       t.num_rows,
       t.sample_size,
       (t.sample_size / t.num_rows) ratio,
       CASE
         WHEN t.num_rows < 1e6 THEN -- up to 1M then 100%
           1
         WHEN t.num_rows < 1e7 THEN -- up to 10M then 30%
           3/10
         WHEN t.num_rows < 1e8 THEN -- up to 100M then 10%
           1/10
         WHEN t.num_rows < 1e9 THEN -- up to 1B then 3%
           3/100
         ELSE -- more than 1B then 1%
           1/100
         END factor
  FROM plan_table pt,
       dba_tables t
 WHERE :health_checks = 'Y'
   AND pt.object_type = 'TABLE'
   AND pt.object_owner = t.owner
   AND pt.object_name = t.table_name
   AND t.num_rows > 0
   AND t.sample_size > 0
   AND t.last_analyzed IS NOT NULL ) v
 WHERE :health_checks = 'Y'
   AND v.ratio < (9/10) * v.factor;

-- old stats
INSERT INTO plan_table (id, operation, object_alias, other_tag, remarks, projection)
SELECT :E_TABLE, 'TABLE', SYSTIMESTAMP, v.object_owner||'.'||v.object_name,
       'Table CBO statistics are '||ROUND(SYSDATE - v.last_analyzed)||' days old: '||TO_CHAR(v.last_analyzed, 'YYYY-MM-DD/HH24:MI:SS')||'.',
       'Consider gathering better quality table statistics with DBMS_STATS.AUTO_SAMPLE_SIZE on 11g or with a sample size of '||ROUND(v.factor * 100)||'% on 10g.<br>'||CHR(10)||
       'Old statistics could contain low/high values for which a predicate may be out of range, producing then a poor plan.'
  FROM (
SELECT pt.object_owner,
       pt.object_name,
       t.last_analyzed,
       t.num_rows,
       t.sample_size,
       (t.sample_size / t.num_rows) ratio,
       CASE
         WHEN t.num_rows < 1e6 THEN -- up to 1M then 100%
           1
         WHEN t.num_rows < 1e7 THEN -- up to 10M then 30%
           3/10
         WHEN t.num_rows < 1e8 THEN -- up to 100M then 10%
           1/10
         WHEN t.num_rows < 1e9 THEN -- up to 1B then 3%
           3/100
         ELSE -- more than 1B then 1%
           1/100
         END factor
  FROM plan_table pt,
       dba_tables t
 WHERE :health_checks = 'Y'
   AND pt.object_type = 'TABLE'
   AND pt.object_owner = t.owner
   AND pt.object_name = t.table_name
   AND t.num_rows > 0
   AND t.sample_size > 0
   AND t.last_analyzed IS NOT NULL ) v
 WHERE :health_checks = 'Y'
   AND (v.last_analyzed < SYSDATE - 49
    OR (v.num_rows BETWEEN 0 AND 1e6 AND v.last_analyzed < SYSDATE - 21)
    OR (v.num_rows BETWEEN 1e6 AND 1e7 AND v.last_analyzed < SYSDATE - 28)
    OR (v.num_rows BETWEEN 1e7 AND 1e8 AND v.last_analyzed < SYSDATE - 35)
    OR (v.num_rows BETWEEN 1e8 AND 1e9 AND v.last_analyzed < SYSDATE - 42));


-- extended statistics
INSERT INTO plan_table (id, operation, object_alias, other_tag, remarks, projection)
SELECT :E_TABLE, 'TABLE', SYSTIMESTAMP, pt.object_owner||'.'||pt.object_name,
       'Table has '||COUNT(*)||' CBO statistics extension(s).',
       'Review table statistics extensions. Extensions can be used for expressions or column groups.<br>'||CHR(10)||
       'If your SQL contain matching predicates these extensions can influence the CBO.'
  FROM plan_table pt,
       dba_stat_extensions e
 WHERE :health_checks = 'Y'
   AND pt.object_type = 'TABLE'
   AND pt.object_owner = e.owner
   AND pt.object_name = e.table_name
 GROUP BY
       pt.object_owner,
       pt.object_name;

-- columns with no stats
INSERT INTO plan_table (id, operation, object_alias, other_tag, remarks, projection)
SELECT :E_TABLE, 'TABLE', SYSTIMESTAMP, pt.object_owner||'.'||pt.object_name,
       'Contains '||COUNT(*)||' column(s) with missing CBO statistics.',
       CASE
         WHEN '^^is_ebs.' = 'Y' THEN
           'Consider gathering table statistics using FND_STATS.GATHER_TABLE_STATS or coe_stats.sql.<br>'||CHR(10)||
           'See <a target="MOS" href="^^doc_link.156968.1">156968.1</a>.'
         WHEN '^^is_siebel.' = 'Y' THEN
           'If table has more than 15 rows consider gathering table statistics using coe_siebel_stats.sql.<br>'||CHR(10)||
           'See <a target="MOS" href="^^doc_link.781927.1">781927.1</a>.'
         WHEN '^^is_psft.' = 'Y' THEN
           'Consider gathering table statistics using pscbo_stats.sql.<br>'||CHR(10)||
           'See <a target="MOS" href="^^doc_link.1322888.1">1322888.1</a>.'
         ELSE
           'Consider gathering table statistics using DBMS_STATS.GATHER_TABLE_STATS.'||CHR(10)||
           'See <a target="MOS" href="^^doc_link.465787.1">465787.1</a>.'
         END
  FROM plan_table pt,
       dba_tables t,
       dba_tab_cols c
 WHERE :health_checks = 'Y'
   AND pt.object_type = 'TABLE'
   AND pt.object_owner = t.owner
   AND pt.object_name = t.table_name
   AND t.num_rows > 0
   AND t.last_analyzed IS NOT NULL
   AND pt.object_owner = c.owner
   AND pt.object_name = c.table_name
   AND c.last_analyzed IS NULL
 GROUP BY
       pt.object_owner,
       pt.object_name;

-- columns missing low/high values
INSERT INTO plan_table (id, operation, object_alias, other_tag, remarks, projection)
SELECT :E_TABLE, 'TABLE', SYSTIMESTAMP, pt.object_owner||'.'||pt.object_name,
       'Contains '||COUNT(*)||' column(s) with null low/high values.',
       'CBO cannot compute correct selectivity with these column statistics missing.<br>'||CHR(10)||
       'You may possibly have Bug <a target="MOS" href="^^bug_link.10248781">10248781</a><br>'||CHR(10)||
       'Consider gathering statistics for this table.'
  FROM plan_table pt,
       dba_tables t,
       dba_tab_cols c
 WHERE :health_checks = 'Y'
   AND pt.object_type = 'TABLE'
   AND pt.object_owner = t.owner
   AND pt.object_name = t.table_name
   AND t.num_rows > 0
   AND t.last_analyzed IS NOT NULL
   AND pt.object_owner = c.owner
   AND pt.object_name = c.table_name
   AND c.last_analyzed IS NOT NULL
   AND c.num_distinct > 0
   AND (c.low_value IS NULL OR c.high_value IS NULL)
 GROUP BY
       pt.object_owner,
       pt.object_name;

-- columns with old stats
INSERT INTO plan_table (id, operation, object_alias, other_tag, remarks, projection)
SELECT :E_TABLE, 'TABLE', SYSTIMESTAMP, v.object_owner||'.'||v.object_name,
       'Table contains column(s) with outdated CBO statistics for up to '||TRUNC(ABS(v.tbl_last_analyzed - v.col_last_analyzed))||' day(s).',
       'CBO table and column statistics are inconsistent. Consider gathering statistics for this table.<br>'||CHR(10)||
       'Old statistics could contain low/high values for which a predicate may be out of range, producing then a poor plan.'
  FROM (
SELECT pt.object_owner,
       pt.object_name,
       t.last_analyzed tbl_last_analyzed,
       MIN(c.last_analyzed) col_last_analyzed
  FROM plan_table pt,
       dba_tables t,
       dba_tab_cols c
 WHERE :health_checks = 'Y'
   AND pt.object_type = 'TABLE'
   AND pt.object_owner = t.owner
   AND pt.object_name = t.table_name
   AND t.num_rows > 0
   AND t.last_analyzed IS NOT NULL
   AND pt.object_owner = c.owner
   AND pt.object_name = c.table_name
   AND c.last_analyzed IS NOT NULL
 GROUP BY
       pt.object_owner,
       pt.object_name,
       t.last_analyzed ) v
 WHERE :health_checks = 'Y'
   AND ABS(v.tbl_last_analyzed - v.col_last_analyzed) > 1;

-- more nulls than rows
INSERT INTO plan_table (id, operation, object_alias, other_tag, remarks, projection)
SELECT :E_TABLE, 'TABLE', SYSTIMESTAMP, v.object_owner||'.'||v.object_name,
       'Number of nulls greater than number of rows by more than 10% in '||v.col_count||' column(s).',
       'There cannot be more rows with null value in a column than actual rows in the table.<br>'||CHR(10)||
       'Worst column shows '||v.num_nulls||' nulls while table has '||v.tbl_num_rows||' rows.<br>'||CHR(10)||
       'CBO table and column statistics are inconsistent. Consider gathering statistics for this table using a large sample size.'
  FROM (
SELECT pt.object_owner,
       pt.object_name,
       t.num_rows tbl_num_rows,
       COUNT(*) col_count,
       MAX(c.num_nulls) num_nulls
  FROM plan_table pt,
       dba_tables t,
       dba_tab_cols c
 WHERE :health_checks = 'Y'
   AND pt.object_type = 'TABLE'
   AND pt.object_owner = t.owner
   AND pt.object_name = t.table_name
   AND t.num_rows > 0
   AND t.last_analyzed IS NOT NULL
   AND pt.object_owner = c.owner
   AND pt.object_name = c.table_name
   AND c.num_nulls > t.num_rows
   AND (c.num_nulls - t.num_rows) > t.num_rows * 0.1
 GROUP BY
       pt.object_owner,
       pt.object_name,
       t.num_rows ) v
 WHERE :health_checks = 'Y'
   AND v.col_count > 0;

-- more distinct values than rows
INSERT INTO plan_table (id, operation, object_alias, other_tag, remarks, projection)
SELECT :E_TABLE, 'TABLE', SYSTIMESTAMP, v.object_owner||'.'||v.object_name,
       'Number of distinct values greater than number of rows by more than 10% in '||v.col_count||' column(s).',
       'There cannot be a larger number of distinct values in a column than actual rows in the table.<br>'||CHR(10)||
       'Worst column shows '||v.num_distinct||' distinct values while table has '||v.tbl_num_rows||' rows.<br>'||CHR(10)||
       'CBO table and column statistics are inconsistent. Consider gathering statistics for this table using a large sample size.'
  FROM (
SELECT pt.object_owner,
       pt.object_name,
       t.num_rows tbl_num_rows,
       COUNT(*) col_count,
       MAX(c.num_distinct) num_distinct
  FROM plan_table pt,
       dba_tables t,
       dba_tab_cols c
 WHERE :health_checks = 'Y'
   AND pt.object_type = 'TABLE'
   AND pt.object_owner = t.owner
   AND pt.object_name = t.table_name
   AND t.num_rows > 0
   AND t.last_analyzed IS NOT NULL
   AND pt.object_owner = c.owner
   AND pt.object_name = c.table_name
   AND c.num_distinct > t.num_rows
   AND (c.num_distinct - t.num_rows) > t.num_rows * 0.1
 GROUP BY
       pt.object_owner,
       pt.object_name,
       t.num_rows ) v
 WHERE :health_checks = 'Y'
   AND v.col_count > 0;

-- zero distinct values on columns with value
INSERT INTO plan_table (id, operation, object_alias, other_tag, remarks, projection)
SELECT :E_TABLE, 'TABLE', SYSTIMESTAMP, v.object_owner||'.'||v.object_name,
       'Number of distinct values is zero in at least '||v.col_count||' column(s) with value.',
       'There should not be columns with value ((num_rows - num_nulls) greater than 0) where the number of distinct values for the same column is zero.<br>'||CHR(10)||
       'Worst column shows '||(v.tbl_num_rows - v.num_nulls)||' rows with value while the number of distinct values for it is zero.<br>'||CHR(10)||
       'CBO table and column statistics are inconsistent. Consider gathering statistics for this table using a large sample size.'
  FROM (
SELECT pt.object_owner,
       pt.object_name,
       t.num_rows tbl_num_rows,
       COUNT(*) col_count,
       MIN(c.num_nulls) num_nulls
  FROM plan_table pt,
       dba_tables t,
       dba_tab_cols c
 WHERE :health_checks = 'Y'
   AND pt.object_type = 'TABLE'
   AND pt.object_owner = t.owner
   AND pt.object_name = t.table_name
   AND t.num_rows > 0
   AND t.last_analyzed IS NOT NULL
   AND pt.object_owner = c.owner
   AND pt.object_name = c.table_name
   AND t.num_rows > c.num_nulls
   AND c.num_distinct = 0
   AND (t.num_rows - c.num_nulls) > t.num_rows * 0.1
 GROUP BY
       pt.object_owner,
       pt.object_name,
       t.num_rows ) v
 WHERE :health_checks = 'Y'
   AND v.col_count > 0;

-- 9885553 incorrect NDV in long char column with histogram
INSERT INTO plan_table (id, operation, object_alias, other_tag, remarks, projection)
SELECT :E_TABLE, 'TABLE', SYSTIMESTAMP, v.object_owner||'.'||v.object_name,
       'Table contains '||v.col_count||' long CHAR column(s) with Histogram. Number of distinct values (NDV) could be incorrect.',
       'Possible Bug <a target="MOS" href="^^bug_link.9885553">9885553</a>.<br>'||CHR(10)||
       'When building histogram for a varchar column that is long, we only use its first 32 characters.<br>'||CHR(10)||
       'Two distinct values that share the same first 32 characters are deemed the same in the histogram.<br>'||CHR(10)||
       'Therefore the NDV derived from the histogram is inaccurate.'||CHR(10)||
       'If NDV is wrong then drop the Histogram.'
  FROM (
SELECT pt.object_owner,
       pt.object_name,
       COUNT(*) col_count
  FROM plan_table pt,
       dba_tab_cols c
 WHERE :health_checks = 'Y'
   AND pt.object_type = 'TABLE'
   AND pt.object_owner = c.owner
   AND pt.object_name = c.table_name
   AND c.num_distinct > 0
   AND c.data_type LIKE '%CHAR%'
   AND c.avg_col_len > 32
   AND c.histogram IN ('FREQUENCY', 'HEIGHT BALANCED')
   AND '^^rdbms_version.' < '11.2.0.3'
 GROUP BY
       pt.object_owner,
       pt.object_name ) v
 WHERE :health_checks = 'Y'
   AND v.col_count > 0;

-- 10174050 frequency histograms with less buckets than NDV
INSERT INTO plan_table (id, operation, object_alias, other_tag, remarks, projection)
SELECT :E_TABLE, 'TABLE', SYSTIMESTAMP, v.object_owner||'.'||v.object_name,
       'Table contains '||v.col_count||' column(s) where the number of distinct values does not match the number of buckets.',
       'Review column statistics for this table and look for "Num Distinct" and "Num Buckets". If there are values missing from the frequency histogram you may have Bug <a target="MOS" href="^^bug_link.10174050">10174050</a>.<br>'||CHR(10)||
       'If you are referencing in your predicates one of the missing values the CBO can over estimate table cardinality, and this may produce a sub-optimal plan.<br>'||CHR(10)||
       'You can either gather statistics with 100% or as a workaround: ALTER system/session "_fix_control"=''5483301:OFF'';'
  FROM (
SELECT pt.object_owner,
       pt.object_name,
       COUNT(*) col_count
  FROM plan_table pt,
       dba_tab_cols c
 WHERE :health_checks = 'Y'
   AND pt.object_type = 'TABLE'
   AND pt.object_owner = c.owner
   AND pt.object_name = c.table_name
   AND c.histogram = 'FREQUENCY'
   AND c.num_distinct <> c.num_buckets
 GROUP BY
       pt.object_owner,
       pt.object_name ) v
 WHERE :health_checks = 'Y'
   AND v.col_count > 0;

-- frequency histogram with 1 bucket
INSERT INTO plan_table (id, operation, object_alias, other_tag, remarks, projection)
SELECT :E_TABLE, 'TABLE', SYSTIMESTAMP, v.object_owner||'.'||v.object_name,
       'Table contains '||v.col_count||' column(s) where the number of buckets is 1 for a "FREQUENCY" histogram.',
       'Review column statistics for this table and look for "Num Buckets" and "Histogram". Possible Bugs '||
       '<a target="MOS" href="^^bug_link.1386119">1386119</a>, '||
       '<a target="MOS" href="^^bug_link.4406309">4406309</a>, '||
       '<a target="MOS" href="^^bug_link.4495422">4495422</a>, '||
       '<a target="MOS" href="^^bug_link.4567767">4567767</a>, '||
       '<a target="MOS" href="^^bug_link.5483301">5483301</a> or '||
       '<a target="MOS" href="^^bug_link.6082745">6082745</a>.<br>'||CHR(10)||
       'If you are referencing in your predicates one of the missing values the CBO can over estimate table cardinality, and this may produce a sub-optimal plan.<br>'||CHR(10)||
       'You can either gather statistics with 100% or as a workaround: ALTER system/session "_fix_control"=''5483301:OFF'';'
  FROM (
SELECT pt.object_owner,
       pt.object_name,
       COUNT(*) col_count
  FROM plan_table pt,
       dba_tab_cols c
 WHERE :health_checks = 'Y'
   AND pt.object_type = 'TABLE'
   AND pt.object_owner = c.owner
   AND pt.object_name = c.table_name
   AND c.histogram = 'FREQUENCY'
   AND c.num_buckets = 1
 GROUP BY
       pt.object_owner,
       pt.object_name ) v
 WHERE :health_checks = 'Y'
   AND v.col_count > 0;

-- height balanced histogram with no popular values
INSERT INTO plan_table (id, operation, object_alias, other_tag, remarks, projection)
SELECT :E_TABLE, 'TABLE', SYSTIMESTAMP, v.object_owner||'.'||v.object_name,
       'Table contains '||v.col_count||' column(s) with no popular values on a "HEIGHT BALANCED" histogram.',
       'A Height-balanced histogram with no popular values is not helpful nor desired. Consider dropping this histogram by collecting new CBO statistics while using METHOD_OPT with SIZE 1.'
  FROM (
SELECT pt.object_owner,
       pt.object_name,
       COUNT(*) col_count
  FROM plan_table pt,
       dba_tab_cols c
 WHERE :health_checks = 'Y'
   AND pt.object_type = 'TABLE'
   AND pt.object_owner = c.owner
   AND pt.object_name = c.table_name
   AND c.histogram = 'HEIGHT BALANCED'
   AND c.num_buckets > 253
   AND (SELECT COUNT(*)
          FROM dba_tab_histograms h
         WHERE :health_checks = 'Y'
           AND h.owner = c.owner
           AND h.table_name = c.table_name
           AND h.column_name = c.column_name) > 253
 GROUP BY
       pt.object_owner,
       pt.object_name ) v
 WHERE :health_checks = 'Y'
   AND v.col_count > 0;

-- 8543770 corrupted histogram
INSERT INTO plan_table (id, operation, object_alias, other_tag, remarks, projection)
SELECT :E_TABLE, 'TABLE', SYSTIMESTAMP, v.object_owner||'.'||v.object_name,
       'Table contains '||v.col_count||' column(s) with corrupted histogram.',
       'These columns have buckets with values out of order. Consider dropping those histogram by collecting new CBO statistics while using METHOD_OPT with SIZE 1. Possible Bugs '||
       '<a target="MOS" href="^^bug_link.8543770">8543770</a>, '||
       '<a target="MOS" href="^^bug_link.10267075">10267075</a>, '||
       '<a target="MOS" href="^^bug_link.12819221">12819221</a> or '||
       '<a target="MOS" href="^^bug_link.12876988">12876988</a>.'
  FROM (
SELECT pt.object_owner,
       pt.object_name,
       COUNT(*) col_count
  FROM plan_table pt,
       dba_tab_cols c
 WHERE :health_checks = 'Y'
   AND pt.object_type = 'TABLE'
   AND pt.object_owner = c.owner
   AND pt.object_name = c.table_name
   AND c.num_distinct > 0
   AND c.num_buckets > 1
   AND (SELECT COUNT(*) 
          FROM (SELECT CASE WHEN LAG(endpoint_value) OVER (ORDER BY endpoint_number) > c1.endpoint_value THEN 1 else 0 END mycol
                  FROM dba_tab_histograms c1
                 WHERE :health_checks = 'Y'
                   AND c1.owner = c.owner
                   AND c1.table_name = c.table_name
                   AND c1.column_name = c.column_name)
         WHERE mycol = 1) > 0
 GROUP BY
       pt.object_owner,
       pt.object_name ) v
 WHERE :health_checks = 'Y'
   AND v.col_count > 0;

-- analyze 236935.1
INSERT INTO plan_table (id, operation, object_alias, other_tag, remarks, projection)
SELECT :E_TABLE, 'TABLE', SYSTIMESTAMP, pt.object_owner||'.'||pt.object_name,
       'CBO statistics were gathered using deprecated ANALYZE command.',
       CASE
         WHEN '^^is_ebs.' = 'Y' THEN
           'When ANALYZE is used on a non-partitioned table, the global_stats column of the table statistics receives a value of ''NO''.<br>'||CHR(10)||
           'Consider gathering statistics using FND_STATS instead.<br>'||CHR(10)||
           'See also <a target="MOS" href="^^doc_link.156968.1">156968.1</a>.'
         WHEN '^^is_siebel.' = 'Y' THEN
           'When ANALYZE is used on a non-partitioned table, the global_stats column of the table statistics receives a value of ''NO''.<br>'||CHR(10)||
           'Consider gathering statistics using coe_siebel_stats.sql instead.<br>'||CHR(10)||
           'See <a target="MOS" href="^^doc_link.781927.1">781927.1</a>.'
         WHEN '^^is_psft.' = 'Y' THEN
           'When ANALYZE is used on a non-partitioned table, the global_stats column of the table statistics receives a value of ''NO''.<br>'||CHR(10)||
           'Consider gathering statistics using pscbo_stats.sql instead.<br>'||CHR(10)||
           'See <a target="MOS" href="^^doc_link.1322888.1">1322888.1</a>.'
         ELSE
           'When ANALYZE is used on a non-partitioned table, the global_stats column of the table statistics receives a value of ''NO''.<br>'||CHR(10)||
           'Consider gathering statistics using DBMS_STATS instead.<br>'||CHR(10)||
           'See <a target="MOS" href="^^doc_link.465787.1">465787.1</a>.'
         END
  FROM plan_table pt,
       dba_tables t
 WHERE :health_checks = 'Y'
   AND pt.object_type = 'TABLE'
   AND pt.object_owner = t.owner
   AND pt.object_name = t.table_name
   AND t.num_rows > 0
   AND t.last_analyzed IS NOT NULL
   AND t.partitioned = 'NO'
   AND t.global_stats = 'NO';

-- derived stats
INSERT INTO plan_table (id, operation, object_alias, other_tag, remarks, projection)
SELECT :E_TABLE, 'TABLE', SYSTIMESTAMP, pt.object_owner||'.'||pt.object_name,
       'CBO statistics are being derived by aggregation from lower level objects.',
       CASE
         WHEN '^^is_ebs.' = 'Y' THEN
           'When statistics are derived by aggregation from lower level objects, the global_stats column of the table statistics receives a value of ''NO''.<br>'||CHR(10)||
           'Consider gathering statistics using FND_STATS instead.<br>'||CHR(10)||
           'See also <a target="MOS" href="^^doc_link.156968.1">156968.1</a>.'
         WHEN '^^is_siebel.' = 'Y' THEN
           'When statistics are derived by aggregation from lower level objects, the global_stats column of the table statistics receives a value of ''NO''.<br>'||CHR(10)||
           'Consider gathering statistics using coe_siebel_stats.sql instead.<br>'||CHR(10)||
           'See <a target="MOS" href="^^doc_link.781927.1">781927.1</a>.'
         WHEN '^^is_psft.' = 'Y' THEN
           'When statistics are derived by aggregation from lower level objects, the global_stats column of the table statistics receives a value of ''NO''.<br>'||CHR(10)||
           'Consider gathering statistics using pscbo_stats.sql instead.<br>'||CHR(10)||
           'See <a target="MOS" href="^^doc_link.1322888.1">1322888.1</a>.'
         ELSE
           'When statistics are derived by aggregation from lower level objects, the global_stats column of the table statistics receives a value of ''NO''.<br>'||CHR(10)||
           'Consider gathering statistics using DBMS_STATS instead.<br>'||CHR(10)||
           'See <a target="MOS" href="^^doc_link.465787.1">465787.1</a>.'
         END
  FROM plan_table pt,
       dba_tables t
 WHERE :health_checks = 'Y'
   AND pt.object_type = 'TABLE'
   AND pt.object_owner = t.owner
   AND pt.object_name = t.table_name
   AND t.num_rows > 0
   AND t.last_analyzed IS NOT NULL
   AND t.partitioned = 'YES'
   AND t.global_stats = 'NO';

-- tables with stale statistics
INSERT INTO plan_table (id, operation, object_alias, other_tag, remarks, projection)
SELECT :E_TABLE, 'TABLE', SYSTIMESTAMP, pt.object_owner||'.'||pt.object_name,
       'Table has stale statistics.',
       CASE
         WHEN '^^is_ebs.' = 'Y' THEN
           'Consider gathering table statistics using FND_STATS.GATHER_TABLE_STATS or coe_stats.sql.<br>'||CHR(10)||
           'See <a target="MOS" href="^^doc_link.156968.1">156968.1</a>.'
         WHEN '^^is_siebel.' = 'Y' THEN
           'If table has more than 15 rows consider gathering table statistics using coe_siebel_stats.sql.<br>'||CHR(10)||
           'See <a target="MOS" href="^^doc_link.781927.1">781927.1</a>.'
         WHEN '^^is_psft.' = 'Y' THEN
           'Consider gathering table statistics using pscbo_stats.sql.<br>'||CHR(10)||
           'See <a target="MOS" href="^^doc_link.1322888.1">1322888.1</a>.'
         ELSE
           'Consider gathering table statistics using DBMS_STATS.GATHER_TABLE_STATS.'||CHR(10)||
           'See <a target="MOS" href="^^doc_link.465787.1">465787.1</a>.'
         END
  FROM plan_table pt,
       dba_tab_statistics t
 WHERE :health_checks = 'Y'
   AND pt.object_type = 'TABLE'
   AND pt.object_owner = t.owner
   AND pt.object_name = t.table_name
   AND t.object_type = 'TABLE'
   AND t.stale_stats = 'YES';

-- tables with locked statistics
INSERT INTO plan_table (id, operation, object_alias, other_tag, remarks, projection)
SELECT :E_TABLE, 'TABLE', SYSTIMESTAMP, pt.object_owner||'.'||pt.object_name,
       'Table has locked statistics.',
       'Review table statistics.'
  FROM plan_table pt,
       dba_tab_statistics t
 WHERE :health_checks = 'Y'
   AND pt.object_type = 'TABLE'
   AND pt.object_owner = t.owner
   AND pt.object_name = t.table_name
   AND t.object_type = 'TABLE'
   AND t.stattype_locked IN ('ALL', 'DATA');

-- sql with policies as per dba_policies
INSERT INTO plan_table (id, operation, object_alias, other_tag, remarks, projection)
SELECT :E_TABLE, 'DBA_POLICIES', SYSTIMESTAMP, pt.object_owner||'.'||pt.object_name,
       'Virtual Private Database. There is one or more policies affecting this table.',
       'Review Execution Plans and look for their injected predicates.'
  FROM plan_table pt,
       dba_policies p
 WHERE :health_checks = 'Y'
   AND pt.object_type = 'TABLE'
   AND pt.object_owner = p.object_owner
   AND pt.object_name = p.object_name
 GROUP BY
       pt.object_owner,
       pt.object_name
HAVING COUNT(*) > 0
 ORDER BY
       pt.object_owner,
       pt.object_name;

-- sql with policies as per dba_audit_policies
INSERT INTO plan_table (id, operation, object_alias, other_tag, remarks, projection)
SELECT :E_TABLE, 'DBA_AUDIT_POLICIES', SYSTIMESTAMP, pt.object_owner||'.'||pt.object_name,
       'Fine-Grained Auditing. There is one or more audit policies affecting this table.',
       'Review Execution Plans and look for their injected predicates.'
  FROM plan_table pt,
       dba_audit_policies p
 WHERE :health_checks = 'Y'
   AND pt.object_type = 'TABLE'
   AND pt.object_owner = p.object_schema
   AND pt.object_name = p.object_name
 GROUP BY
       pt.object_owner,
       pt.object_name
HAVING COUNT(*) > 0
 ORDER BY
       pt.object_owner,
       pt.object_name;

-- table partitions with no stats
INSERT INTO plan_table (id, operation, object_alias, other_tag, remarks, projection)
SELECT :E_TABLE_PART, 'TABLE PARTITION', SYSTIMESTAMP, v.object_owner||'.'||v.object_name,
       v.no_stats||' out of '||v.par_count||' partition(s) lack(s) CBO statistics.',
       CASE
         WHEN '^^is_ebs.' = 'Y' THEN
           'Consider gathering statistics using FND_STATS.GATHER_TABLE_STATISTICS.<br>'||CHR(10)||
           'See also <a target="MOS" href="^^doc_link.156968.1">156968.1</a>.'
         WHEN '^^is_siebel.' = 'Y' THEN
           'Consider gathering statistics using coe_siebel_stats.sql.<br>'||CHR(10)||
           'See <a target="MOS" href="^^doc_link.781927.1">781927.1</a>.'
         WHEN '^^is_psft.' = 'Y' THEN
           'Consider gathering statistics using pscbo_stats.sql.<br>'||CHR(10)||
           'See <a target="MOS" href="^^doc_link.1322888.1">1322888.1</a>.'
         ELSE
           'Consider gathering statistics using DBMS_STATS.GATHER_TABLE_STATISTICS.<br>'||CHR(10)||
           'See <a target="MOS" href="^^doc_link.465787.1">465787.1</a>.'
         END
  FROM (
SELECT pt.object_owner,
       pt.object_name,
       COUNT(*) par_count,
       SUM(CASE WHEN p.last_analyzed IS NULL OR p.num_rows IS NULL THEN 1 ELSE 0 END) no_stats
  FROM plan_table pt,
       dba_tables t,
       dba_tab_partitions p
 WHERE :health_checks = 'Y'
   AND pt.object_type = 'TABLE'
   AND pt.object_owner = t.owner
   AND pt.object_name = t.table_name
   AND t.partitioned = 'YES'
   AND t.num_rows > 0
   AND t.last_analyzed IS NOT NULL
   AND pt.object_owner = p.table_owner
   AND pt.object_name = p.table_name
 GROUP BY
       pt.object_owner,
       pt.object_name ) v
 WHERE :health_checks = 'Y'
   AND v.no_stats > 0;

-- table partitions where num rows = 0
INSERT INTO plan_table (id, operation, object_alias, other_tag, remarks, projection)
SELECT :E_TABLE_PART, 'TABLE PARTITION', SYSTIMESTAMP, v.object_owner||'.'||v.object_name,
       v.num_rows_zero||' out of '||v.par_count||' partition(s) with number of rows equal to zero according to partition''s CBO statistics.',
       'If these table partitions are not empty, consider gathering table statistics using GRANULARITY=>GLOBAL AND PARTITION.'
  FROM (
SELECT pt.object_owner,
       pt.object_name,
       COUNT(*) par_count,
       SUM(CASE WHEN p.num_rows = 0 THEN 1 ELSE 0 END) num_rows_zero
  FROM plan_table pt,
       dba_tables t,
       dba_tab_partitions p
 WHERE :health_checks = 'Y'
   AND pt.object_type = 'TABLE'
   AND pt.object_owner = t.owner
   AND pt.object_name = t.table_name
   AND t.partitioned = 'YES'
   AND t.num_rows > 0
   AND t.last_analyzed IS NOT NULL
   AND pt.object_owner = p.table_owner
   AND pt.object_name = p.table_name
 GROUP BY
       pt.object_owner,
       pt.object_name ) v
 WHERE :health_checks = 'Y'
   AND v.num_rows_zero > 0;

-- table partitions with outdated stats
INSERT INTO plan_table (id, operation, object_alias, other_tag, remarks, projection)
SELECT :E_TABLE_PART, 'TABLE PARTITION', SYSTIMESTAMP, v.object_owner||'.'||v.object_name,
       'Table contains partition(s) with table/partition CBO statistics out of sync for up to '||TRUNC(ABS(v.tbl_last_analyzed - v.par_last_analyzed))||' day(s).',
       'Table and partition statistics were gathered up to '||TRUNC(ABS(v.tbl_last_analyzed - v.par_last_analyzed))||' day(s) appart, so they do not offer a consistent view to the CBO.<br>'||CHR(10)||
       'Consider re-gathering table statistics using GRANULARITY=>GLOBAL AND PARTITION.'
  FROM (
SELECT pt.object_owner,
       pt.object_name,
       t.last_analyzed tbl_last_analyzed,
       COUNT(*) par_count,
       MIN(p.last_analyzed) par_last_analyzed
  FROM plan_table pt,
       dba_tables t,
       dba_tab_partitions p
 WHERE :health_checks = 'Y'
   AND pt.object_type = 'TABLE'
   AND pt.object_owner = t.owner
   AND pt.object_name = t.table_name
   AND t.partitioned = 'YES'
   AND t.num_rows > 0
   AND t.last_analyzed IS NOT NULL
   AND pt.object_owner = p.table_owner
   AND pt.object_name = p.table_name
 GROUP BY
       pt.object_owner,
       pt.object_name,
       t.last_analyzed ) v
 WHERE :health_checks = 'Y'
   AND ABS(v.tbl_last_analyzed - v.par_last_analyzed) > 1;

-- partitions with no column stats
INSERT INTO plan_table (id, operation, object_alias, other_tag, remarks, projection)
SELECT :E_TABLE_PART, 'TABLE PARTITION', SYSTIMESTAMP, v.object_owner||'.'||v.object_name,
       v.no_stats||' column(s) lack(s) partition level CBO statistics.',
       CASE
         WHEN '^^is_ebs.' = 'Y' THEN
           'Consider gathering statistics using FND_STATS.GATHER_TABLE_STATISTICS.<br>'||CHR(10)||
           'See also <a target="MOS" href="^^doc_link.156968.1">156968.1</a>.'
         WHEN '^^is_siebel.' = 'Y' THEN
           'Consider gathering statistics using coe_siebel_stats.sql.<br>'||CHR(10)||
           'See <a target="MOS" href="^^doc_link.781927.1">781927.1</a>.'
         WHEN '^^is_psft.' = 'Y' THEN
           'Consider gathering statistics using pscbo_stats.sql.<br>'||CHR(10)||
           'See <a target="MOS" href="^^doc_link.1322888.1">1322888.1</a>.'
         ELSE
           'Consider gathering statistics using DBMS_STATS.GATHER_TABLE_STATISTICS.<br>'||CHR(10)||
           'See <a target="MOS" href="^^doc_link.465787.1">465787.1</a>.'
         END
  FROM (
SELECT pt.object_owner,
       pt.object_name,
       (SELECT COUNT(DISTINCT c.column_name)
          FROM dba_part_col_statistics c
         WHERE :health_checks = 'Y'
           AND c.owner = pt.object_owner
           AND c.table_name = pt.object_name
           AND c.last_analyzed IS NULL) no_stats
  FROM plan_table pt,
       dba_tables t
 WHERE :health_checks = 'Y'
   AND pt.object_type = 'TABLE'
   AND pt.object_owner = t.owner
   AND pt.object_name = t.table_name
   AND t.partitioned = 'YES'
   AND t.num_rows > 0
   AND t.last_analyzed IS NOT NULL
 GROUP BY
       pt.object_owner,
       pt.object_name ) v
 WHERE :health_checks = 'Y'
   AND v.no_stats > 0;

-- partition columns with outdated stats
INSERT INTO plan_table (id, operation, object_alias, other_tag, remarks, projection)
SELECT :E_TABLE_PART, 'TABLE PARTITION', SYSTIMESTAMP, v.object_owner||'.'||v.object_name,
       'Table contains column(s) with table/partition CBO statistics out of sync for up to '||TRUNC(ABS(v.tbl_last_analyzed - v.col_last_analyzed))||' day(s).',
       'Table and partition statistics were gathered up to '||TRUNC(ABS(v.tbl_last_analyzed - v.col_last_analyzed))||' day(s) appart, so they do not offer a consistent view to the CBO.<br>'||CHR(10)||
       'Consider re-gathering table statistics using GRANULARITY=>GLOBAL AND PARTITION.'
  FROM (
SELECT pt.object_owner,
       pt.object_name,
       t.last_analyzed tbl_last_analyzed,
       (SELECT MIN(c.last_analyzed)
          FROM dba_part_col_statistics c
         WHERE :health_checks = 'Y'
           AND c.owner = pt.object_owner
           AND c.table_name = pt.object_name
           AND c.last_analyzed IS NOT NULL) col_last_analyzed
  FROM plan_table pt,
       dba_tables t
 WHERE :health_checks = 'Y'
   AND pt.object_type = 'TABLE'
   AND pt.object_owner = t.owner
   AND pt.object_name = t.table_name
   AND t.partitioned = 'YES'
   AND t.num_rows > 0
   AND t.last_analyzed IS NOT NULL
 GROUP BY
       pt.object_owner,
       pt.object_name,
       t.last_analyzed ) v
 WHERE :health_checks = 'Y'
   AND ABS(v.tbl_last_analyzed - v.col_last_analyzed) > 1;

/* -------------------------
 *
 * index hc
 *
 * ------------------------- */

-- no stats
INSERT INTO plan_table (id, operation, object_alias, other_tag, remarks, projection)
SELECT :E_INDEX, 'INDEX', SYSTIMESTAMP, i.owner||'.'||i.index_name,
       'Index lacks CBO Statistics.',
       CASE
         WHEN '^^is_ebs.' = 'Y' THEN
           'Consider gathering table and index statistics using FND_STATS.GATHER_TABLE_STATS or coe_stats.sql.<br>'||CHR(10)||
           'See <a target="MOS" href="^^doc_link.156968.1">156968.1</a>.'
         WHEN '^^is_siebel.' = 'Y' THEN
           'If table has more than 15 rows consider gathering table and index statistics using coe_siebel_stats.sql.<br>'||CHR(10)||
           'See <a target="MOS" href="^^doc_link.781927.1">781927.1</a>.'
         WHEN '^^is_psft.' = 'Y' THEN
           'Consider gathering table and index statistics using pscbo_stats.sql.<br>'||CHR(10)||
           'See <a target="MOS" href="^^doc_link.1322888.1">1322888.1</a>.'
         ELSE
           'Consider gathering table and index statistics using DBMS_STATS.GATHER_TABLE_STATS.'||CHR(10)||
           'See <a target="MOS" href="^^doc_link.465787.1">465787.1</a>.'
         END
  FROM plan_table pt,
       dba_tables t,
       dba_indexes i
 WHERE :health_checks = 'Y'
   AND pt.object_type = 'TABLE'
   AND pt.object_owner = t.owner
   AND pt.object_name = t.table_name
   AND t.last_analyzed IS NOT NULL
   AND t.num_rows > 0
   AND t.temporary = 'N'
   AND pt.object_owner = i.table_owner
   AND pt.object_name = i.table_name
   AND i.index_type NOT IN ('DOMAIN', 'LOB', 'FUNCTION-BASED DOMAIN')
   AND (i.last_analyzed IS NULL OR i.num_rows IS NULL);

-- more rows in index than its table
INSERT INTO plan_table (id, operation, object_alias, other_tag, remarks, projection)
SELECT :E_INDEX, 'INDEX', SYSTIMESTAMP, i.owner||'.'||i.index_name,
       'Index appears to have more rows ('||i.num_rows||') than its table ('||t.num_rows||') by '||ROUND(100 * (i.num_rows - t.num_rows) / t.num_rows)||'%.',
       CASE
         WHEN '^^is_ebs.' = 'Y' THEN
           'Consider gathering table and index statistics using FND_STATS.GATHER_TABLE_STATS or coe_stats.sql.<br>'||CHR(10)||
           'See <a target="MOS" href="^^doc_link.156968.1">156968.1</a>.'
         WHEN '^^is_siebel.' = 'Y' THEN
           'If table has more than 15 rows consider gathering table and index statistics using coe_siebel_stats.sql.<br>'||CHR(10)||
           'See <a target="MOS" href="^^doc_link.781927.1">781927.1</a>.'
         WHEN '^^is_psft.' = 'Y' THEN
           'Consider gathering table and index statistics using pscbo_stats.sql.<br>'||CHR(10)||
           'See <a target="MOS" href="^^doc_link.1322888.1">1322888.1</a>.'
         ELSE
           'Consider gathering table and index statistics using DBMS_STATS.GATHER_TABLE_STATS.'||CHR(10)||
           'See <a target="MOS" href="^^doc_link.465787.1">465787.1</a>.'
         END
  FROM plan_table pt,
       dba_tables t,
       dba_indexes i
 WHERE :health_checks = 'Y'
   AND pt.object_type = 'TABLE'
   AND pt.object_owner = t.owner
   AND pt.object_name = t.table_name
   AND t.last_analyzed IS NOT NULL
   AND t.num_rows > 0
   AND t.temporary = 'N'
   AND pt.object_owner = i.table_owner
   AND pt.object_name = i.table_name
   AND i.num_rows > t.num_rows
   AND (i.num_rows - t.num_rows) > t.num_rows * 0.1;

-- clustering factor > rows in table
INSERT INTO plan_table (id, operation, object_alias, other_tag, remarks, projection)
SELECT :E_INDEX, 'INDEX', SYSTIMESTAMP, i.owner||'.'||i.index_name,
       'Clustering factor of '||i.clustering_factor||' is larger than number of rows in its table ('||t.num_rows||') by more than '||ROUND(100 * (i.clustering_factor - t.num_rows) / t.num_rows)||'%.',
       CASE
         WHEN '^^is_ebs.' = 'Y' THEN
           'Consider gathering table and index statistics using FND_STATS.GATHER_TABLE_STATS or coe_stats.sql.<br>'||CHR(10)||
           'See <a target="MOS" href="^^doc_link.156968.1">156968.1</a>.'
         WHEN '^^is_siebel.' = 'Y' THEN
           'If table has more than 15 rows consider gathering table and index statistics using coe_siebel_stats.sql.<br>'||CHR(10)||
           'See <a target="MOS" href="^^doc_link.781927.1">781927.1</a>.'
         WHEN '^^is_psft.' = 'Y' THEN
           'Consider gathering table and index statistics using pscbo_stats.sql.<br>'||CHR(10)||
           'See <a target="MOS" href="^^doc_link.1322888.1">1322888.1</a>.'
         ELSE
           'Consider gathering table and index statistics using DBMS_STATS.GATHER_TABLE_STATS.'||CHR(10)||
           'See <a target="MOS" href="^^doc_link.465787.1">465787.1</a>.'
         END
  FROM plan_table pt,
       dba_tables t,
       dba_indexes i
 WHERE :health_checks = 'Y'
   AND pt.object_type = 'TABLE'
   AND pt.object_owner = t.owner
   AND pt.object_name = t.table_name
   AND t.last_analyzed IS NOT NULL
   AND t.temporary = 'N'
   AND pt.object_owner = i.table_owner
   AND pt.object_name = i.table_name
   AND i.clustering_factor > t.num_rows
   AND (i.clustering_factor - t.num_rows) > t.num_rows * 0.1;

-- stats on zero while columns have value
INSERT INTO plan_table (id, operation, object_alias, other_tag, remarks, projection)
SELECT :E_INDEX, 'INDEX', SYSTIMESTAMP, i.owner||'.'||i.index_name,
       'Index CBO statistics on 0 with indexed columns with value.',
       'This index with zeroes in CBO index statistics contains columns for which there are values, so the index should not have statistics in zeroes.<br>'||CHR(10)||
       'Possible Bug <a target="MOS" href="^^bug_link.4055596">4055596</a>. Consider gathering table statistics, or DROP and RE-CREATE index.'
  FROM plan_table pt,
       dba_tables t,
       dba_indexes i
 WHERE :health_checks = 'Y'
   AND pt.object_type = 'TABLE'
   AND pt.object_owner = t.owner
   AND pt.object_name = t.table_name
   AND t.last_analyzed IS NOT NULL
   AND t.num_rows > 0
   AND t.temporary = 'N'
   AND pt.object_owner = i.table_owner
   AND pt.object_name = i.table_name
   AND i.index_type NOT IN ('DOMAIN', 'LOB', 'FUNCTION-BASED DOMAIN')
   AND i.num_rows = 0
   AND i.distinct_keys = 0
   AND i.leaf_blocks = 0
   AND i.blevel = 0
   AND EXISTS (
SELECT NULL
  FROM dba_ind_columns ic,
       dba_tab_cols tc
 WHERE :health_checks = 'Y'
   AND ic.index_owner = i.owner
   AND ic.index_name = i.index_name
   AND ic.table_owner = tc.owner
   AND ic.table_name = tc.table_name
   AND ic.column_name = tc.column_name
   AND t.num_rows > tc.num_nulls
   AND (t.num_rows - tc.num_nulls) > t.num_rows * 0.1);

-- table/index stats out of sync
INSERT INTO plan_table (id, operation, object_alias, other_tag, remarks, projection)
SELECT :E_INDEX, 'INDEX', SYSTIMESTAMP, i.owner||'.'||i.index_name,
       'Table/Index CBO statistics out of sync.',
       CASE
         WHEN '^^is_ebs.' = 'Y' THEN
           'Table and index statistics were gathered '||TRUNC(ABS(t.last_analyzed - i.last_analyzed))||' day(s) appart,<br>'||CHR(10)||
           'so they do not offer a consistent view to the CBO.<br>'||CHR(10)||
           'Consider gathering table and index statistics using FND_STATS.GATHER_TABLE_STATS or coe_stats.sql.<br>'||CHR(10)||
           'See <a target="MOS" href="^^doc_link.156968.1">156968.1</a>.'
         WHEN '^^is_siebel.' = 'Y' THEN
           'Table and index statistics were gathered '||TRUNC(ABS(t.last_analyzed - i.last_analyzed))||' day(s) appart,<br>'||CHR(10)||
           'so they do not offer a consistent view to the CBO.<br>'||CHR(10)||
           'If table has more than 15 rows consider gathering table and index statistics using coe_siebel_stats.sql.<br>'||CHR(10)||
           'See <a target="MOS" href="^^doc_link.781927.1">781927.1</a>.'
         WHEN '^^is_psft.' = 'Y' THEN
           'Table and index statistics were gathered '||TRUNC(ABS(t.last_analyzed - i.last_analyzed))||' day(s) appart,<br>'||CHR(10)||
           'so they do not offer a consistent view to the CBO.<br>'||CHR(10)||
           'Consider gathering table and index statistics using pscbo_stats.sql.<br>'||CHR(10)||
           'See <a target="MOS" href="^^doc_link.1322888.1">1322888.1</a>.'
         ELSE
           'Table and index statistics were gathered '||TRUNC(ABS(t.last_analyzed - i.last_analyzed))||' day(s) appart,<br>'||CHR(10)||
           'so they do not offer a consistent view to the CBO.<br>'||CHR(10)||
           'Consider gathering table and index statistics using DBMS_STATS.GATHER_TABLE_STATS using CASCADE=>TRUE.'||CHR(10)||
           'See also <a target="MOS" href="^^doc_link.465787.1">465787.1</a>.'
         END
  FROM plan_table pt,
       dba_tables t,
       dba_indexes i
 WHERE :health_checks = 'Y'
   AND pt.object_type = 'TABLE'
   AND pt.object_owner = t.owner
   AND pt.object_name = t.table_name
   AND t.last_analyzed IS NOT NULL
   AND t.num_rows > 0
   AND t.temporary = 'N'
   AND pt.object_owner = i.table_owner
   AND pt.object_name = i.table_name
   AND i.index_type NOT IN ('DOMAIN', 'LOB', 'FUNCTION-BASED DOMAIN')
   AND i.last_analyzed IS NOT NULL
   AND ABS(t.last_analyzed - i.last_analyzed) > 1;

-- analyze 236935.1
INSERT INTO plan_table (id, operation, object_alias, other_tag, remarks, projection)
SELECT :E_INDEX, 'INDEX', SYSTIMESTAMP, i.owner||'.'||i.index_name,
       'CBO statistics were either gathered using deprecated ANALYZE command or derived by aggregation from lower level objects.',
       CASE
         WHEN '^^is_ebs.' = 'Y' THEN
           'When ANALYZE is used on a non-partitioned index, the global_stats column of the index statistics receives a value of ''NO''.<br>'||CHR(10)||
           'Consider gathering statistics using FND_STATS instead.<br>'||CHR(10)||
           'See also <a target="MOS" href="^^doc_link.156968.1">156968.1</a>.'
         WHEN '^^is_siebel.' = 'Y' THEN
           'When ANALYZE is used on a non-partitioned index, the global_stats column of the index statistics receives a value of ''NO''.<br>'||CHR(10)||
           'Consider gathering statistics using coe_siebel_stats.sql instead.<br>'||CHR(10)||
           'See <a target="MOS" href="^^doc_link.781927.1">781927.1</a>.'
         WHEN '^^is_psft.' = 'Y' THEN
           'When ANALYZE is used on a non-partitioned index, the global_stats column of the index statistics receives a value of ''NO''.<br>'||CHR(10)||
           'Consider gathering statistics using pscbo_stats.sql instead.<br>'||CHR(10)||
           'See <a target="MOS" href="^^doc_link.1322888.1">1322888.1</a>.'
         ELSE
           'When ANALYZE is used on a non-partitioned index, the global_stats column of the index statistics receives a value of ''NO''.<br>'||CHR(10)||
           'Consider gathering statistics using DBMS_STATS instead.<br>'||CHR(10)||
           'See <a target="MOS" href="^^doc_link.465787.1">465787.1</a>.'
         END
  FROM plan_table pt,
       dba_indexes i
 WHERE :health_checks = 'Y'
   AND pt.object_type = 'TABLE'
   AND pt.object_owner = i.table_owner
   AND pt.object_name = i.table_name
   AND i.index_type = 'NORMAL'
   AND i.last_analyzed IS NOT NULL
   AND i.partitioned = 'NO'
   AND i.global_stats = 'NO';

-- derived stats
INSERT INTO plan_table (id, operation, object_alias, other_tag, remarks, projection)
SELECT :E_INDEX, 'INDEX', SYSTIMESTAMP, i.owner||'.'||i.index_name,
       'CBO statistics were either gathered using deprecated ANALYZE command or derived by aggregation from lower level objects.',
       CASE
         WHEN '^^is_ebs.' = 'Y' THEN
           'When statistics are derived by aggregation from lower level objects, the global_stats column of the index statistics receives a value of ''NO''.<br>'||CHR(10)||
           'Consider gathering statistics using FND_STATS instead.<br>'||CHR(10)||
           'See also <a target="MOS" href="^^doc_link.156968.1">156968.1</a>.'
         WHEN '^^is_siebel.' = 'Y' THEN
           'When statistics are derived by aggregation from lower level objects, the global_stats column of the index statistics receives a value of ''NO''.<br>'||CHR(10)||
           'Consider gathering statistics using coe_siebel_stats.sql instead.<br>'||CHR(10)||
           'See <a target="MOS" href="^^doc_link.781927.1">781927.1</a>.'
         WHEN '^^is_psft.' = 'Y' THEN
           'When statistics are derived by aggregation from lower level objects, the global_stats column of the index statistics receives a value of ''NO''.<br>'||CHR(10)||
           'Consider gathering statistics using pscbo_stats.sql instead.<br>'||CHR(10)||
           'See <a target="MOS" href="^^doc_link.1322888.1">1322888.1</a>.'
         ELSE
           'When statistics are derived by aggregation from lower level objects, the global_stats column of the index statistics receives a value of ''NO''.<br>'||CHR(10)||
           'Consider gathering statistics using DBMS_STATS instead.<br>'||CHR(10)||
           'See <a target="MOS" href="^^doc_link.465787.1">465787.1</a>.'
         END
  FROM plan_table pt,
       dba_indexes i
 WHERE :health_checks = 'Y'
   AND pt.object_type = 'TABLE'
   AND pt.object_owner = i.table_owner
   AND pt.object_name = i.table_name
   AND i.index_type = 'NORMAL'
   AND i.last_analyzed IS NOT NULL
   AND i.partitioned = 'YES'
   AND i.global_stats = 'NO';

-- unusable indexes
INSERT INTO plan_table (id, operation, object_alias, other_tag, remarks, projection)
SELECT :E_INDEX, 'INDEX', SYSTIMESTAMP, i.owner||'.'||i.index_name,
       'Unusable index.',
       'Unusable indexes cannot be used by the CBO. This may cause Execution Plans to change.'
  FROM plan_table pt,
       dba_indexes i
 WHERE :health_checks = 'Y'
   AND pt.object_type = 'TABLE'
   AND pt.object_owner = i.table_owner
   AND pt.object_name = i.table_name
   AND i.partitioned = 'NO'
   AND i.status = 'UNUSABLE';

-- unusable index partitions
INSERT INTO plan_table (id, operation, object_alias, other_tag, remarks, projection)
SELECT :E_INDEX_PART, 'INDEX PARTITION', SYSTIMESTAMP, v.object_owner||'.'||v.object_name,
       'Index with '||v.par_count||' unusable partition(s).',
       'Unusable index partitions cannot be used by the CBO. This may cause Execution Plans to change.'
  FROM (
SELECT pt.object_owner,
       pt.object_name,
       COUNT(*) par_count
  FROM plan_table pt,
       dba_indexes i,
       dba_ind_partitions p
 WHERE :health_checks = 'Y'
   AND pt.object_type = 'INDEX'
   AND pt.object_owner = i.owner
   AND pt.object_name = i.index_name
   AND i.partitioned = 'YES'
   AND pt.object_owner = p.index_owner
   AND pt.object_name = p.index_name
   AND p.status = 'UNUSABLE'
 GROUP BY
       pt.object_owner,
       pt.object_name ) v
 WHERE :health_checks = 'Y'
   AND v.par_count > 0;

-- unusable index subpartitions
INSERT INTO plan_table (id, operation, object_alias, other_tag, remarks, projection)
SELECT :E_INDEX_PART, 'INDEX SUBPARTITION', SYSTIMESTAMP, v.object_owner||'.'||v.object_name,
       'Index with '||v.par_count||' unusable subpartition(s).',
       'Unusable index subpartitions cannot be used by the CBO. This may cause Execution Plans to change.'
  FROM (
SELECT pt.object_owner,
       pt.object_name,
       COUNT(*) par_count
  FROM plan_table pt,
       dba_indexes i,
       dba_ind_subpartitions sp
 WHERE :health_checks = 'Y'
   AND pt.object_type = 'INDEX'
   AND pt.object_owner = i.owner
   AND pt.object_name = i.index_name
   AND i.partitioned = 'YES'
   AND pt.object_owner = sp.index_owner
   AND pt.object_name = sp.index_name
   AND sp.status = 'UNUSABLE'
 GROUP BY
       pt.object_owner,
       pt.object_name ) v
 WHERE :health_checks = 'Y'
   AND v.par_count > 0;

-- invisible indexes
INSERT INTO plan_table (id, operation, object_alias, other_tag, remarks, projection)
SELECT :E_INDEX, 'INDEX', SYSTIMESTAMP, i.owner||'.'||i.index_name,
       'Invisible index.',
       'Invisible indexes cannot be used by the CBO. This may cause Execution Plans to change.'
  FROM plan_table pt,
       dba_indexes i
 WHERE :health_checks = 'Y'
   AND pt.object_type = 'TABLE'
   AND pt.object_owner = i.table_owner
   AND pt.object_name = i.table_name
   AND i.visibility = 'INVISIBLE';

-- no column stats in single-column index
INSERT INTO plan_table (id, operation, object_alias, other_tag, remarks, projection)
SELECT :E_1COL_INDEX, '1-COL INDEX', SYSTIMESTAMP, i.index_name||'('||ic.column_name||')',
       'Lack of CBO statistics in column of this single-column index.',
       'To avoid CBO guessed statistics on this indexed column, gather table statistics and include this column in METHOD_OPT used.'
  FROM plan_table pt,
       dba_indexes i,
       dba_ind_columns ic,
       dba_tab_cols tc
 WHERE :health_checks = 'Y'
   AND pt.object_type = 'TABLE'
   AND pt.object_owner = i.table_owner
   AND pt.object_name = i.table_name
   AND i.index_type NOT IN ('DOMAIN', 'LOB', 'FUNCTION-BASED DOMAIN')
   AND i.last_analyzed IS NOT NULL
   AND i.num_rows > 0
   AND i.owner = ic.index_owner
   AND i.index_name = ic.index_name
   AND ic.column_position = 1
   AND ic.table_owner = tc.owner
   AND ic.table_name = tc.table_name
   AND ic.column_name = tc.column_name
   AND (tc.last_analyzed IS NULL OR tc.num_distinct IS NULL OR tc.num_nulls IS NULL)
   AND NOT EXISTS (
SELECT NULL
  FROM dba_ind_columns ic2
 WHERE :health_checks = 'Y'
   AND ic2.index_owner = i.owner
   AND ic2.index_name = i.index_name
   AND ic2.column_position = 2 );

-- NDV on column > num_rows in single-column index
INSERT INTO plan_table (id, operation, object_alias, other_tag, remarks, projection)
SELECT :E_1COL_INDEX, '1-COL INDEX', SYSTIMESTAMP, i.index_name||'('||ic.column_name||')',
       'Single-column index with number of distinct values greater than number of rows by '||ROUND(100 * (tc.num_distinct - i.num_rows) / i.num_rows)||'%.',
       'There cannot be a larger number of distinct values ('||tc.num_distinct||') in a column than actual rows ('||i.num_rows||') in the index.<br>'||CHR(10)||
       'This is an inconsistency on this indexed column. Consider gathering table statistics using a large sample size.'
  FROM plan_table pt,
       dba_indexes i,
       dba_ind_columns ic,
       dba_tab_cols tc
 WHERE :health_checks = 'Y'
   AND pt.object_type = 'TABLE'
   AND pt.object_owner = i.table_owner
   AND pt.object_name = i.table_name
   AND i.index_type NOT IN ('DOMAIN', 'LOB', 'FUNCTION-BASED DOMAIN')
   AND i.last_analyzed IS NOT NULL
   AND i.num_rows > 0
   AND i.owner = ic.index_owner
   AND i.index_name = ic.index_name
   AND ic.column_position = 1
   AND ic.table_owner = tc.owner
   AND ic.table_name = tc.table_name
   AND ic.column_name = tc.column_name
   AND tc.num_distinct > i.num_rows
   AND (tc.num_distinct - i.num_rows) > i.num_rows * 0.1
   AND NOT EXISTS (
SELECT NULL
  FROM dba_ind_columns ic2
 WHERE :health_checks = 'Y'
   AND ic2.index_owner = i.owner
   AND ic2.index_name = i.index_name
   AND ic2.column_position = 2 );

-- NDV is zero but column has values in single-column index
INSERT INTO plan_table (id, operation, object_alias, other_tag, remarks, projection)
SELECT :E_1COL_INDEX, '1-COL INDEX', SYSTIMESTAMP, i.index_name||'('||ic.column_name||')',
       'Single-column index with number of distinct value equal to zero in column with value.',
       'There should not be columns with value where the number of distinct values for the same column is zero.<br>'||CHR(10)||
       'Column has '||(i.num_rows - tc.num_nulls)||' rows with value while the number of distinct values for it is zero.<br>'||CHR(10)||
       'This is an inconsistency on this indexed column. Consider gathering table statistics using a large sample size.'
  FROM plan_table pt,
       dba_indexes i,
       dba_ind_columns ic,
       dba_tab_cols tc
 WHERE :health_checks = 'Y'
   AND pt.object_type = 'TABLE'
   AND pt.object_owner = i.table_owner
   AND pt.object_name = i.table_name
   AND i.index_type NOT IN ('DOMAIN', 'LOB', 'FUNCTION-BASED DOMAIN')
   AND i.last_analyzed IS NOT NULL
   AND i.num_rows > 0
   AND i.owner = ic.index_owner
   AND i.index_name = ic.index_name
   AND ic.column_position = 1
   AND ic.table_owner = tc.owner
   AND ic.table_name = tc.table_name
   AND ic.column_name = tc.column_name
   AND tc.num_distinct = 0
   AND i.num_rows > tc.num_nulls
   AND (i.num_rows - tc.num_nulls) > i.num_rows * 0.1
   AND NOT EXISTS (
SELECT NULL
  FROM dba_ind_columns ic2
 WHERE :health_checks = 'Y'
   AND ic2.index_owner = i.owner
   AND ic2.index_name = i.index_name
   AND ic2.column_position = 2 );

-- Bugs 4495422 or 9885553 NDV <> NDK in single-column index
INSERT INTO plan_table (id, operation, object_alias, other_tag, remarks, projection)
SELECT :E_1COL_INDEX, '1-COL INDEX', SYSTIMESTAMP, i.index_name||'('||ic.column_name||')',
       'Number of distinct values ('||tc.num_distinct||') does not match number of distinct keys ('||i.distinct_keys||') by '||ROUND(100 * (i.distinct_keys - tc.num_distinct) / tc.num_distinct)||'%.',
       CASE
         WHEN tc.data_type LIKE '%CHAR%' AND tc.num_buckets > 1 THEN
           'Possible Bug <a target="MOS" href="^^bug_link.4495422">4495422</a> or <a target="MOS" href="^^bug_link.9885553">9885553</a>.<br>'||CHR(10)||
           'This is an inconsistency on this indexed column. Gather fresh statistics with no histograms or adjusting DISTCNT and DENSITY using SET_COLUMN_statistics APIs.'
         ELSE
           'This is an inconsistency on this indexed column. Gather fresh statistics or adjusting DISTCNT and DENSITY using SET_COLUMN_statistics APIs.'
         END
  FROM plan_table pt,
       dba_indexes i,
       dba_ind_columns ic,
       dba_tab_cols tc
 WHERE :health_checks = 'Y'
   AND pt.object_type = 'TABLE'
   AND pt.object_owner = i.table_owner
   AND pt.object_name = i.table_name
   AND i.index_type NOT IN ('DOMAIN', 'LOB', 'FUNCTION-BASED DOMAIN')
   AND i.last_analyzed IS NOT NULL
   AND i.num_rows > 0
   AND i.owner = ic.index_owner
   AND i.index_name = ic.index_name
   AND ic.column_position = 1
   AND ic.table_owner = tc.owner
   AND ic.table_name = tc.table_name
   AND ic.column_name = tc.column_name
   AND tc.num_distinct > 0
   AND i.distinct_keys > 0
   AND i.distinct_keys > tc.num_distinct
   AND (i.distinct_keys - tc.num_distinct) > tc.num_distinct * 0.1
   AND NOT EXISTS (
SELECT NULL
  FROM dba_ind_columns ic2
 WHERE :health_checks = 'Y'
   AND ic2.index_owner = i.owner
   AND ic2.index_name = i.index_name
   AND ic2.column_position = 2 );

-- index partitions with no stats
INSERT INTO plan_table (id, operation, object_alias, other_tag, remarks, projection)
SELECT :E_INDEX_PART, 'INDEX PARTITION', SYSTIMESTAMP, v.object_owner||'.'||v.object_name,
       v.no_stats||' out of '||v.par_count||' partition(s) lack(s) CBO statistics.',
       CASE
         WHEN '^^is_ebs.' = 'Y' THEN
           'Consider gathering statistics using FND_STATS.GATHER_TABLE_STATISTICS.<br>'||CHR(10)||
           'See also <a target="MOS" href="^^doc_link.156968.1">156968.1</a>.'
         WHEN '^^is_siebel.' = 'Y' THEN
           'Consider gathering statistics using coe_siebel_stats.sql.<br>'||CHR(10)||
           'See <a target="MOS" href="^^doc_link.781927.1">781927.1</a>.'
         WHEN '^^is_psft.' = 'Y' THEN
           'Consider gathering statistics using pscbo_stats.sql.<br>'||CHR(10)||
           'See <a target="MOS" href="^^doc_link.1322888.1">1322888.1</a>.'
         ELSE
           'Consider gathering statistics using DBMS_STATS.GATHER_TABLE_STATISTICS.<br>'||CHR(10)||
           'See <a target="MOS" href="^^doc_link.465787.1">465787.1</a>.'
         END
  FROM (
SELECT pt.object_owner,
       pt.object_name,
       COUNT(*) par_count,
       SUM(CASE WHEN p.last_analyzed IS NULL OR p.num_rows IS NULL THEN 1 ELSE 0 END) no_stats
  FROM plan_table pt,
       dba_indexes i,
       dba_ind_partitions p
 WHERE :health_checks = 'Y'
   AND pt.object_type = 'INDEX'
   AND pt.object_owner = i.owner
   AND pt.object_name = i.index_name
   AND i.partitioned = 'YES'
   AND i.num_rows > 0
   AND i.last_analyzed IS NOT NULL
   AND pt.object_owner = p.index_owner
   AND pt.object_name = p.index_name
 GROUP BY
       pt.object_owner,
       pt.object_name ) v
 WHERE :health_checks = 'Y'
   AND v.no_stats > 0;

-- index partitions where num rows = 0
INSERT INTO plan_table (id, operation, object_alias, other_tag, remarks, projection)
SELECT :E_INDEX_PART, 'INDEX PARTITION', SYSTIMESTAMP, v.object_owner||'.'||v.object_name,
       v.num_rows_zero||' out of '||v.par_count||' partition(s) with number of rows equal to zero according to partition''s CBO statistics.',
       'If these index partitions are not empty, consider gathering table statistics using GRANULARITY=>GLOBAL AND PARTITION.'
  FROM (
SELECT pt.object_owner,
       pt.object_name,
       COUNT(*) par_count,
       SUM(CASE WHEN p.num_rows = 0 THEN 1 ELSE 0 END) num_rows_zero
  FROM plan_table pt,
       dba_indexes i,
       dba_ind_partitions p
 WHERE :health_checks = 'Y'
   AND pt.object_type = 'INDEX'
   AND pt.object_owner = i.owner
   AND pt.object_name = i.index_name
   AND i.partitioned = 'YES'
   AND i.num_rows > 0
   AND i.last_analyzed IS NOT NULL
   AND pt.object_owner = p.index_owner
   AND pt.object_name = p.index_name
 GROUP BY
       pt.object_owner,
       pt.object_name ) v
 WHERE :health_checks = 'Y'
   AND v.num_rows_zero > 0;

-- index partitions with outdated stats
INSERT INTO plan_table (id, operation, object_alias, other_tag, remarks, projection)
SELECT :E_INDEX_PART, 'INDEX PARTITION', SYSTIMESTAMP, v.object_owner||'.'||v.object_name,
       'Index contains partition(s) with index/partition CBO statistics out of sync for up to '||TRUNC(ABS(v.idx_last_analyzed - v.par_last_analyzed))||' day(s).',
       'Index and partition statistics were gathered up to '||TRUNC(ABS(v.idx_last_analyzed - v.par_last_analyzed))||' day(s) appart, so they do not offer a consistent view to the CBO.<br>'||CHR(10)||
       'Consider re-gathering table statistics using GRANULARITY=>GLOBAL AND PARTITION.'
  FROM (
SELECT pt.object_owner,
       pt.object_name,
       i.last_analyzed idx_last_analyzed,
       COUNT(*) par_count,
       MIN(p.last_analyzed) par_last_analyzed
  FROM plan_table pt,
       dba_indexes i,
       dba_ind_partitions p
 WHERE :health_checks = 'Y'
   AND pt.object_type = 'INDEX'
   AND pt.object_owner = i.owner
   AND pt.object_name = i.index_name
   AND i.partitioned = 'YES'
   AND i.num_rows > 0
   AND i.last_analyzed IS NOT NULL
   AND pt.object_owner = p.index_owner
   AND pt.object_name = p.index_name
 GROUP BY
       pt.object_owner,
       pt.object_name,
       i.last_analyzed ) v
 WHERE :health_checks = 'Y'
   AND ABS(v.idx_last_analyzed - v.par_last_analyzed) > 1;

-- table and index partitions do not match 14013094
INSERT INTO plan_table (id, operation, object_alias, other_tag, remarks, projection)
WITH idx AS (
SELECT /*+ MATERIALIZE */
       i.owner index_owner, i.index_name, i.table_owner, i.table_name, COUNT(*) index_partitions
  FROM plan_table pt,
       dba_indexes i,
       dba_ind_partitions ip
 WHERE :health_checks = 'Y'
   AND pt.object_type = 'INDEX'
   AND pt.object_owner = i.owner
   AND pt.object_name = i.index_name
   AND i.partitioned = 'YES'
   AND pt.object_owner = ip.index_owner
   AND pt.object_name = ip.index_name
 GROUP BY
       i.owner, i.index_name, i.table_owner, i.table_name
), tbl AS (
SELECT /*+ MATERIALIZE */
       t.owner table_owner, t.table_name, COUNT(*) table_partitions
  FROM plan_table pt,
       dba_tables t,
       dba_tab_partitions tp
 WHERE :health_checks = 'Y'
   AND pt.object_type = 'TABLE'
   AND pt.object_owner = t.owner
   AND pt.object_name = t.table_name
   AND t.partitioned = 'YES'
   AND pt.object_owner = tp.table_owner
   AND pt.object_name = tp.table_name
 GROUP BY
       t.owner, t.table_name
), idx_tbl AS (
SELECT /*+ MATERIALIZE */
       idx.index_owner, idx.index_name, idx.table_owner, idx.table_name, idx.index_partitions partitions
  FROM idx, tbl
 WHERE idx.table_owner = tbl.table_owner
   AND idx.table_name = tbl.table_name
   AND idx.index_partitions = tbl.table_partitions
)
--SELECT idx_tbl.index_owner, idx_tbl.index_name, idx_tbl.table_owner, idx_tbl.table_name, COUNT(*)
SELECT :E_INDEX_PART, 'INDEX PARTITION', SYSTIMESTAMP, idx_tbl.index_owner||'.'||idx_tbl.index_name,
       'Index contains '||COUNT(*)||' partition(s) where the partition name does not match to corresponding Table partition(s) name.',
       'Review Table and Index partition names and positions, then try to rule out Bug <a target="MOS" href="^^bug_link.14013094">14013094</a>.'
  FROM idx_tbl,
       dba_tab_statistics tps,
       dba_ind_statistics ips
 WHERE tps.owner = idx_tbl.table_owner
   AND tps.table_name = idx_tbl.table_name
   AND tps.object_type = 'PARTITION'
   AND ips.owner = idx_tbl.index_owner
   AND ips.index_name = idx_tbl.index_name
   AND ips.object_type = 'PARTITION'
   AND tps.partition_position = ips.partition_position
   AND tps.partition_name != ips.partition_name
 GROUP BY
       idx_tbl.index_owner, idx_tbl.index_name, idx_tbl.table_owner, idx_tbl.table_name;

-- setup to produce reports
SET ECHO OFF FEED OFF VER OFF SHOW OFF HEA OFF LIN 2000 NEWP NONE PAGES 0 LONG 2000000 LONGC 2000 SQLC MIX TAB ON TRIMS ON TI OFF TIMI OFF ARRAY 100 NUMF "" SQLP SQL> SUF sql BLO . RECSEP OFF APPI OFF AUTOT OFF;

/**************************************************************************************************/

COL files_prefix NEW_V files_prefix FOR A40;
--SELECT '^^script._^^database_name_short._^^host_name_short._^^rdbms_version._^^sql_id._^^time_stamp.' files_prefix FROM DUAL;
SELECT '^^script._^^time_stamp._^^sql_id.' files_prefix FROM DUAL;
COL sqldx_prefix NEW_V sqldx_prefix FOR A40;
SELECT '^^files_prefix._8_sqldx' sqldx_prefix FROM DUAL;

/**************************************************************************************************
 *
 * health-check report
 *
 **************************************************************************************************/

/* -------------------------
 *
 * heading
 *
 * ------------------------- */
SPO ^^files_prefix._1_health_check.html;

PRO <html>
PRO <!-- $Header: ^^mos_doc. ^^script..sql ^^doc_ver. ^^doc_date. carlos.sierra $ -->
PRO <!-- Copyright (c) 2000-2012, Oracle Corporation. All rights reserved. -->
PRO <!-- Author: carlos.sierra@oracle.com -->
PRO
PRO <head>
PRO <title>^^files_prefix._1_health_check.html</title>
PRO

PRO <style type="text/css">
PRO body {font:10pt Arial,Helvetica,Verdana,Geneva,sans-serif; color:black; background:white;}
PRO a {font-weight:bold; color:#663300;}
PRO pre {font:8pt Monaco,"Courier New",Courier,monospace;} /* for code */
PRO h1 {font-size:16pt; font-weight:bold; color:#336699;}
PRO h2 {font-size:14pt; font-weight:bold; color:#336699;}
PRO h3 {font-size:12pt; font-weight:bold; color:#336699;}
PRO li {font-size:10pt; font-weight:bold; color:#336699; padding:0.1em 0 0 0;}
PRO table {font-size:8pt; color:black; background:white;}
PRO th {font-weight:bold; background:#cccc99; color:#336699; vertical-align:bottom; padding-left:3pt; padding-right:3pt; padding-top:1pt; padding-bottom:1pt;}
PRO td {text-align:left; background:#fcfcf0; vertical-align:top; padding-left:3pt; padding-right:3pt; padding-top:1pt; padding-bottom:1pt;}
PRO td.c {text-align:center;} /* center */
PRO td.l {text-align:left;} /* left (default) */
PRO td.r {text-align:right;} /* right */
PRO font.n {font-size:8pt; font-style:italic; color:#336699;} /* table footnote in blue */
PRO font.f {font-size:8pt; color:#999999;} /* footnote in gray */
PRO </style>
PRO

PRO </head>
PRO <body>
PRO <h1><a target="MOS" href="^^doc_link.^^mos_doc.">^^mos_doc.</a> ^^method.
PRO ^^doc_ver. Report: ^^files_prefix._1_health_check.html</h1>
PRO

PRO <pre>
PRO License    : ^^input_license.
PRO Input      : ^^input_parameter.
PRO SIGNATURE  : ^^signature.
PRO SIGNATUREF : ^^signaturef.
PRO RDBMS      : ^^rdbms_version.
PRO Platform   : ^^platform.
PRO Database   : ^^database_name_short.
PRO DBID       : ^^dbid.
PRO Host       : ^^host_name_short.
PRO Instance   : ^^instance_number.
PRO CPU_Count  : ^^sys_cpu.
PRO Num CPUs   : ^^num_cpus.
PRO Num Cores  : ^^num_cores.
PRO Num Sockets: ^^num_sockets.
PRO Block Size : ^^sys_db_block_size.
PRO OFE        : ^^sys_ofe.
PRO DYN_SAMP   : ^^sys_ds.
PRO EBS        : "^^is_ebs."
PRO SIEBEL     : "^^is_siebel."
PRO PSFT       : "^^is_psft."
PRO Date       : ^^time_stamp2.
PRO User       : ^^sessionuser.
PRO </pre>

PRO <ul>
PRO <li><a href="#obs">Observations</a></li>
PRO <li><a href="#text">SQL Text</a></li>
PRO <li><a href="#tbl_sum">Tables Summary</a></li>
PRO <li><a href="#idx_sum">Indexes Summary</a></li>
PRO </ul>

/* -------------------------
 *
 * observations
 *
 * ------------------------- */
PRO <a name="obs"></a><h2>Observations</h2>
PRO
PRO Observations below are the outcome of several heath-checks on the schema objects accessed by your SQL and its environment.
PRO Review them carefully and take action when appropriate. Then re-execute your SQL and generate this report again.
PRO
PRO <table>
PRO
PRO <tr>
PRO <th>#</th>
PRO <th>Type</th>
PRO <th>Name</th>
PRO <th>Observation</th>
PRO <th>Details</th>
PRO </tr>
PRO
SELECT '<!-- '||TO_CHAR(SYSDATE, 'YYYY-MM-DD/HH24:MI:SS')||' -->' FROM dual;
PRO <!-- Please Wait -->

SELECT CHR(10)||'<tr>'||CHR(10)||
       '<td class="r">'||ROWNUM||'</td>'||CHR(10)||
       '<td>'||v.object_type||'</td>'||CHR(10)||
       '<td>'||v.object_name||'</td>'||CHR(10)||
       '<td>'||v.observation||'</td>'||CHR(10)||
       '<td>'||v.more||'</td>'||CHR(10)||
       '</tr>'
  FROM (
SELECT /*+ NO_MERGE */
       operation object_type,
       other_tag object_name,
       remarks observation,
       projection more
  FROM plan_table
 WHERE :health_checks = 'Y'
   AND id IS NOT NULL
   AND operation IS NOT NULL
   AND object_alias IS NOT NULL
   AND other_tag IS NOT NULL
   AND remarks IS NOT NULL
 ORDER BY
       id,
       operation,
       other_tag,
       object_alias ) v;

PRO
PRO <tr>
PRO <th>#</th>
PRO <th>Type</th>
PRO <th>Name</th>
PRO <th>Observation</th>
PRO <th>Details</th>
PRO </tr>
PRO
PRO </table>
PRO

-- nothing is updated to the db. transaction ends here
ROLLBACK TO save_point_1;

/* -------------------------
 *
 * sql_text
 *
 * ------------------------- */
PRO <a name="text"></a><h2>SQL Text</h2>
PRO
PRO <pre>

DECLARE
  l_sql_text CLOB := :sql_text;
  l_pos NUMBER;
BEGIN
  WHILE NVL(LENGTH(l_sql_text), 0) > 0
  LOOP
    l_pos := INSTR(l_sql_text, CHR(10));
    IF l_pos > 0 THEN
      DBMS_OUTPUT.PUT_LINE(SUBSTR(l_sql_text, 1, l_pos - 1));
      l_sql_text := SUBSTR(l_sql_text, l_pos + 1);
    ELSE
      DBMS_OUTPUT.PUT_LINE(l_sql_text);
      l_sql_text := NULL;
    END IF;
  END LOOP;
END;
/

PRO </pre>

/* -------------------------
 *
 * tables summary
 *
 * ------------------------- */
EXEC DBMS_APPLICATION_INFO.SET_CLIENT_INFO('^^method.: tables summary - ' || TO_CHAR(SYSDATE, 'YYYY-MM-DD/HH24:MI:SS'));
PRO <a name="tbl_sum"></a><h2>Tables Summary</h2>
PRO
PRO Values below have two purposes:<br>
PRO 1. Provide a quick view of the state of Table level CBO statistics, as well as their indexes and columns.<br>
PRO 2. More easily allow the comparison of two systems that are believed to be similar.
PRO
PRO <table>
PRO
PRO <tr>
PRO <th>#</th>
PRO <th>Table Name</th>
PRO <th>Owner</th>
PRO <th>Num Rows</th>
PRO <th>Table<br>Sample Size</th>
PRO <th>Last Analyzed</th>
PRO <th>Indexes</th>
PRO <th>Avg Index<br>Sample Size</th>
PRO <th>Table<br>Columns</th>
PRO <th>Columns with<br>Histogram</th>
PRO <th>Avg Column<br>Sample Size</th>
PRO </tr>
PRO
SELECT '<!-- '||TO_CHAR(SYSDATE, 'YYYY-MM-DD/HH24:MI:SS')||' -->' FROM dual;
PRO <!-- Please Wait -->

SELECT CHR(10)||'<tr>'||CHR(10)||
       '<td class="r">'||ROWNUM||'</td>'||CHR(10)||
       '<td>'||v.table_name||'</td>'||CHR(10)||
       '<td>'||v.owner||'</td>'||CHR(10)||
       '<td class="r">'||v.num_rows||'</td>'||CHR(10)||
       '<td class="r">'||v.table_sample_size||'</td>'||CHR(10)||
       '<td nowrap>'||v.last_analyzed||'</td>'||CHR(10)||
       '<td class="r">'||v.indexes||'</td>'||CHR(10)||
       '<td class="r">'||v.avg_index_sample_size||'</td>'||CHR(10)||
       '<td class="r">'||v.columns||'</td>'||CHR(10)||
       '<td class="r">'||v.columns_with_histograms||'</td>'||CHR(10)||
       '<td class="r">'||v.avg_column_sample_size||'</td>'||CHR(10)||
       '</tr>'
  FROM (
WITH object AS (
SELECT /*+ MATERIALIZE */
       object_owner owner, object_name name
  FROM gv$sql_plan
 WHERE inst_id IN (SELECT inst_id FROM gv$instance)
   AND sql_id = :sql_id
   AND object_owner IS NOT NULL
   AND object_name IS NOT NULL
 UNION
SELECT object_owner owner, object_name name
  FROM dba_hist_sql_plan
 WHERE :license IN ('T', 'D')
   AND dbid = ^^dbid.
   AND sql_id = :sql_id
   AND object_owner IS NOT NULL
   AND object_name IS NOT NULL
 ), plan_tables AS (
 SELECT /*+ MATERIALIZE */
        'TABLE' object_type, t.owner object_owner, t.table_name object_name
   FROM dba_tab_statistics t, -- include fixed objects
        object o
  WHERE t.owner = o.owner
    AND t.table_name = o.name
  UNION
 SELECT 'TABLE' object_type, i.table_owner object_owner, i.table_name object_name
   FROM dba_indexes i,
        object o
  WHERE i.owner = o.owner
    AND i.index_name = o.name
), t AS (
SELECT /*+ MATERIALIZE */
       pt.object_owner owner,
       pt.object_name table_name,
       t.num_rows,
       t.sample_size table_sample_size,
       TO_CHAR(t.last_analyzed, 'DD-MON-YY HH24:MI:SS') last_analyzed,
       COUNT(*) indexes,
       ROUND(AVG(i.sample_size)) avg_index_sample_size
  FROM plan_tables pt,
       dba_tables t,
       dba_indexes i
 WHERE pt.object_type = 'TABLE'
   AND pt.object_owner = t.owner
   AND pt.object_name = t.table_name
   AND pt.object_owner = i.table_owner(+)
   AND pt.object_name = i.table_name(+)
 GROUP BY
       pt.object_owner,
       pt.object_name,
       t.num_rows,
       t.sample_size,
       t.last_analyzed ),
c AS (
SELECT /*+ MATERIALIZE */
       pt.object_owner owner,
       pt.object_name table_name,
       COUNT(*) columns,
       SUM(CASE WHEN NVL(c.histogram, 'NONE') = 'NONE' THEN 0 ELSE 1 END) columns_with_histograms,
       ROUND(AVG(c.sample_size)) avg_column_sample_size
  FROM plan_tables pt,
       dba_tab_cols c
 WHERE pt.object_type = 'TABLE'
   AND pt.object_owner = c.owner
   AND pt.object_name = c.table_name
 GROUP BY
       pt.object_owner,
       pt.object_name )
SELECT /*+ NO_MERGE */
       t.table_name,
       t.owner,
       t.num_rows,
       t.table_sample_size,
       t.last_analyzed,
       t.indexes,
       t.avg_index_sample_size,
       c.columns,
       c.columns_with_histograms,
       c.avg_column_sample_size
  FROM t, c
 WHERE t.table_name = c.table_name
   AND t.owner = c.owner
 ORDER BY
       t.table_name,
       t.owner ) v;

PRO
PRO <tr>
PRO <th>#</th>
PRO <th>Table Name</th>
PRO <th>Owner</th>
PRO <th>Num Rows</th>
PRO <th>Table<br>Sample Size</th>
PRO <th>Last Analyzed</th>
PRO <th>Indexes</th>
PRO <th>Avg Index<br>Sample Size</th>
PRO <th>Table<br>Columns</th>
PRO <th>Columns with<br>Histogram</th>
PRO <th>Avg Column<br>Sample Size</th>
PRO </tr>
PRO
PRO </table>
PRO

/* -------------------------
 *
 * indexes summary
 *
 * ------------------------- */
EXEC DBMS_APPLICATION_INFO.SET_CLIENT_INFO('^^method.: indexes summary - ' || TO_CHAR(SYSDATE, 'YYYY-MM-DD/HH24:MI:SS'));
PRO <a name="idx_sum"></a><h2>Indexes Summary</h2>
PRO
PRO Values below have two purposes:<br>
PRO 1. Provide a quick view of the state of Index level CBO statistics, as well as their columns.<br>
PRO 2. More easily allow the comparison of two systems that are believed to be similar.<br>
PRO This section includes data captured by AWR. If this is a stand-by read-only database then the AWR information below is from the Primary database.
PRO
PRO <table>
PRO
PRO <tr>
PRO <th>#</th>
PRO <th>Table Name</th>
PRO <th>Table<br>Owner</th>
PRO <th>Index Name</th>
PRO <th>Index<br>Owner</th>
PRO <th>In MEM<br>Plan</th>
PRO <th>In AWR<br>Plan</th>
PRO <th>Num Rows</th>
PRO <th>Index<br>Sample Size</th>
PRO <th>Last Analyzed</th>
PRO <th>Index<br>Columns</th>
PRO <th>Columns with<br>Histogram</th>
PRO <th>Avg Column<br>Sample Size</th>
PRO </tr>
PRO
SELECT '<!-- '||TO_CHAR(SYSDATE, 'YYYY-MM-DD/HH24:MI:SS')||' -->' FROM dual;
PRO <!-- Please Wait -->

SELECT CHR(10)||'<tr>'||CHR(10)||
       '<td class="r">'||ROWNUM||'</td>'||CHR(10)||
       '<td>'||v.table_name||'</td>'||CHR(10)||
       '<td>'||v.table_owner||'</td>'||CHR(10)||
       '<td>'||v.index_name||'</td>'||CHR(10)||
       '<td>'||v.index_owner||'</td>'||CHR(10)||
       '<td class="c">'||v.in_mem_plan||'</td>'||CHR(10)||
       '<td class="c">'||v.in_awr_plan||'</td>'||CHR(10)||
       '<td class="r">'||v.num_rows||'</td>'||CHR(10)||
       '<td class="r">'||v.table_sample_size||'</td>'||CHR(10)||
       '<td nowrap>'||v.last_analyzed||'</td>'||CHR(10)||
       '<td class="r">'||v.columns||'</td>'||CHR(10)||
       '<td class="r">'||v.columns_with_histograms||'</td>'||CHR(10)||
       '<td class="r">'||v.avg_column_sample_size||'</td>'||CHR(10)||
       '</tr>'
  FROM (
WITH object AS (
SELECT /*+ MATERIALIZE */
       object_owner owner, object_name name
  FROM gv$sql_plan
 WHERE inst_id IN (SELECT inst_id FROM gv$instance)
   AND sql_id = :sql_id
   AND object_owner IS NOT NULL
   AND object_name IS NOT NULL
 UNION
SELECT object_owner owner, object_name name
  FROM dba_hist_sql_plan
 WHERE :license IN ('T', 'D')
   AND dbid = ^^dbid.
   AND sql_id = :sql_id
   AND object_owner IS NOT NULL
   AND object_name IS NOT NULL
 ), plan_tables AS (
 SELECT /*+ MATERIALIZE */
        'TABLE' object_type, t.owner object_owner, t.table_name object_name
   FROM dba_tab_statistics t, -- include fixed objects
        object o
  WHERE t.owner = o.owner
    AND t.table_name = o.name
  UNION
 SELECT 'TABLE' object_type, i.table_owner object_owner, i.table_name object_name
   FROM dba_indexes i,
        object o
  WHERE i.owner = o.owner
    AND i.index_name = o.name
), i AS (
SELECT /*+ MATERIALIZE */
       pt.object_owner table_owner,
       pt.object_name table_name,
       i.owner index_owner,
       i.index_name,
       i.num_rows,
       i.sample_size table_sample_size,
       TO_CHAR(i.last_analyzed, 'DD-MON-YY HH24:MI:SS') last_analyzed,
       (SELECT 'YES'
          FROM gv$sql_plan p1
         WHERE p1.inst_id IN (SELECT inst_id FROM gv$instance)
           AND p1.sql_id = :sql_id
           AND (p1.object_type LIKE '%INDEX%' OR p1.operation LIKE '%INDEX%')
           AND i.owner = p1.object_owner
           AND i.index_name = p1.object_name
           AND ROWNUM = 1) in_mem_plan,
       (SELECT 'YES'
          FROM dba_hist_sql_plan p2
         WHERE :license IN ('T', 'D')
           AND p2.dbid = ^^dbid.
           AND p2.sql_id = :sql_id
           AND (p2.object_type LIKE '%INDEX%' OR p2.operation LIKE '%INDEX%')
           AND i.owner = p2.object_owner
           AND i.index_name = p2.object_name
           AND ROWNUM = 1) in_awr_plan
  FROM plan_tables pt,
       dba_indexes i
 WHERE pt.object_type = 'TABLE'
   AND pt.object_owner = i.table_owner
   AND pt.object_name = i.table_name ),
c AS (
SELECT /*+ MATERIALIZE */
       ic.index_owner,
       ic.index_name,
       COUNT(*) columns,
       SUM(CASE WHEN NVL(c.histogram, 'NONE') = 'NONE' THEN 0 ELSE 1 END) columns_with_histograms,
       ROUND(AVG(c.sample_size)) avg_column_sample_size
  FROM plan_tables pt,
       dba_ind_columns ic,
       dba_tab_cols c
 WHERE pt.object_type = 'TABLE'
   AND pt.object_owner = ic.table_owner
   AND pt.object_name = ic.table_name
   AND ic.table_owner = c.owner
   AND ic.table_name = c.table_name
   AND ic.column_name = c.column_name
 GROUP BY
       ic.index_owner,
       ic.index_name )
SELECT /*+ NO_MERGE */
       i.table_name,
       i.table_owner,
       i.index_name,
       i.index_owner,
       i.num_rows,
       i.table_sample_size,
       i.last_analyzed,
       i.in_mem_plan,
       i.in_awr_plan,
       c.columns,
       c.columns_with_histograms,
       c.avg_column_sample_size
  FROM i, c
 WHERE i.index_name = c.index_name
   AND i.index_owner = c.index_owner
 ORDER BY
       i.table_name,
       i.table_owner,
       i.index_name,
       i.index_owner ) v;

PRO
PRO <tr>
PRO <th>#</th>
PRO <th>Table Name</th>
PRO <th>Table<br>Owner</th>
PRO <th>Index Name</th>
PRO <th>Index<br>Owner</th>
PRO <th>In MEM<br>Plan</th>
PRO <th>In AWR<br>Plan</th>
PRO <th>Num Rows</th>
PRO <th>Index<br>Sample Size</th>
PRO <th>Last Analyzed</th>
PRO <th>Index<br>Columns</th>
PRO <th>Columns with<br>Histogram</th>
PRO <th>Avg Column<br>Sample Size</th>
PRO </tr>
PRO
PRO </table>
PRO

/* -------------------------
 *
 * footer
 *
 * ------------------------- */
PRO
SELECT '<!-- '||TO_CHAR(SYSDATE, 'YYYY-MM-DD/HH24:MI:SS')||' -->' FROM dual;
PRO <hr size="3">
PRO <font class="f">^^mos_doc. ^^method. ^^doc_ver. ^^time_stamp2. tool_date: ^^doc_date. executed by: ^^sessionuser. </font>
PRO </body>
PRO </html>

SPO OFF;

/**************************************************************************************************/

/* -------------------------
 *
 * gv$sql_shared_cursor cursor_sum
 *
 * ------------------------- */
SPO sql_shared_cursor_sum_^^sql_id..sql;
PRO SELECT /* ^^script..sql Cursor Sharing as per Reason */
PRO        CHR(10)||'<tr>'||CHR(10)||
PRO        '<td class="r">'||ROWNUM||'</td>'||CHR(10)||
PRO        '<td>'||v2.reason||'</td>'||CHR(10)||
PRO        '<td class="c">'||v2.inst_id||'</td>'||CHR(10)||
PRO        '<td class="r">'||v2.cursors||'</td>'||CHR(10)||
PRO        '</tr>'
PRO   FROM (
SELECT (CASE WHEN ROWNUM = 1 THEN 'WITH sc AS (SELECT /*+ MATERIALIZE */ /* gv$sql_shared_cursor cursor_sum */ * FROM gv$sql_shared_cursor WHERE :shared_cursor = ''Y'' AND sql_id = ''^^sql_id.'')' ELSE 'UNION ALL' END)||CHR(10)||
       'SELECT '''||v.column_name||''' reason, inst_id, COUNT(*) cursors FROM sc WHERE '||v.column_name||' = ''Y'' GROUP BY inst_id' line
  FROM (
SELECT /*+ NO_MERGE */
       column_name
  FROM dba_tab_cols
 WHERE :shared_cursor = 'Y'
   AND owner = 'SYS'
   AND table_name = 'GV_$SQL_SHARED_CURSOR'
   AND data_type = 'VARCHAR2'
   AND data_length = 1
 ORDER BY
       column_name ) v;
SELECT 'SELECT ''reason'' reason, 0 inst_id, 0 cursors FROM DUAL WHERE 1 = 0' FROM dual WHERE :shared_cursor <> 'Y';
PRO ORDER BY reason, inst_id ) v2;;
SPO OFF;

/* -------------------------
 *
 * gv$sql_shared_cursor cursor_col
 *
 * ------------------------- */
SPO sql_shared_cursor_col_^^sql_id..sql
SELECT (CASE WHEN ROWNUM = 1 THEN 'WITH sc AS (SELECT /*+ MATERIALIZE */ /* gv$sql_shared_cursor cursor_col */ * FROM gv$sql_shared_cursor WHERE :shared_cursor = ''Y'' AND sql_id = ''^^sql_id.'')' ELSE 'UNION ALL' END)||CHR(10)||
       'SELECT '', RPAD('||LOWER(v.column_name)||', 30) "'||v.column_name||'"'' column_name FROM sc WHERE '||v.column_name||' = ''Y'' AND ROWNUM = 1' line
  FROM (
SELECT /*+ NO_MERGE */
       column_name
  FROM dba_tab_cols
 WHERE :shared_cursor = 'Y'
   AND owner = 'SYS'
   AND table_name = 'GV_$SQL_SHARED_CURSOR'
   AND data_type = 'VARCHAR2'
   AND data_length = 1
 ORDER BY
       column_name ) v;
SELECT 'SELECT * FROM DUAL WHERE 1 = 0' FROM dual WHERE :shared_cursor <> 'Y';
PRO ;;
SPO OFF;

/* -------------------------
 *
 * gv$sql_shared_cursor cursor_cur
 *
 * ------------------------- */
SPO sql_shared_cursor_cur_^^sql_id..sql
PRO SELECT /* ^^script..sql Cursor Sharing List */
PRO ROWNUM "#", v.* FROM (
PRO SELECT /*+ NO_MERGE */
PRO inst_id
PRO , child_number
@sql_shared_cursor_col_^^sql_id..sql
SELECT ', reason' FROM DUAL WHERE '^^rdbms_version.' >= '11.2%';
PRO FROM gv$sql_shared_cursor
PRO WHERE :shared_cursor = 'Y'
PRO AND sql_id = '^^sql_id.'
PRO ORDER BY 1, 2) v;;
SPO OFF;

/**************************************************************************************************/

/**************************************************************************************************
 *
 * diagnostics report
 *
 **************************************************************************************************/

/* -------------------------
 *
 * heading
 *
 * ------------------------- */
SPO ^^files_prefix._2_diagnostics.html;

PRO <html>
PRO <!-- $Header: ^^mos_doc. ^^script..sql ^^doc_ver. ^^doc_date. carlos.sierra $ -->
PRO <!-- Copyright (c) 2000-2012, Oracle Corporation. All rights reserved. -->
PRO <!-- Author: carlos.sierra@oracle.com -->
PRO
PRO <head>
PRO <title>^^files_prefix._2_diagnostics.html</title>
PRO

PRO <style type="text/css">
PRO body {font:10pt Arial,Helvetica,Verdana,Geneva,sans-serif; color:black; background:white;}
PRO a {font-weight:bold; color:#663300;}
PRO pre {font:8pt Monaco,"Courier New",Courier,monospace;} /* for code */
PRO h1 {font-size:16pt; font-weight:bold; color:#336699;}
PRO h2 {font-size:14pt; font-weight:bold; color:#336699;}
PRO h3 {font-size:12pt; font-weight:bold; color:#336699;}
PRO li {font-size:10pt; font-weight:bold; color:#336699; padding:0.1em 0 0 0;}
PRO table {font-size:8pt; color:black; background:white;}
PRO th {font-weight:bold; background:#cccc99; color:#336699; vertical-align:bottom; padding-left:3pt; padding-right:3pt; padding-top:1pt; padding-bottom:1pt;}
PRO td {text-align:left; background:#fcfcf0; vertical-align:top; padding-left:3pt; padding-right:3pt; padding-top:1pt; padding-bottom:1pt;}
PRO td.c {text-align:center;} /* center */
PRO td.l {text-align:left;} /* left (default) */
PRO td.r {text-align:right;} /* right */
PRO font.n {font-size:8pt; font-style:italic; color:#336699;} /* table footnote in blue */
PRO font.f {font-size:8pt; color:#999999;} /* footnote in gray */
PRO </style>
PRO

PRO </head>
PRO <body>
PRO <h1><a target="MOS" href="^^doc_link.^^mos_doc.">^^mos_doc.</a> ^^method.
PRO ^^doc_ver. Report: ^^files_prefix._2_diagnostics.html</h1>
PRO

PRO <pre>
PRO License    : ^^input_license.
PRO Input      : ^^input_parameter.
PRO SIGNATURE  : ^^signature.
PRO SIGNATUREF : ^^signaturef.
PRO RDBMS      : ^^rdbms_version.
PRO Platform   : ^^platform.
PRO Database   : ^^database_name_short.
PRO DBID       : ^^dbid.
PRO Host       : ^^host_name_short.
PRO Instance   : ^^instance_number.
PRO CPU_Count  : ^^sys_cpu.
PRO Num CPUs   : ^^num_cpus.
PRO Num Cores  : ^^num_cores.
PRO Num Sockets: ^^num_sockets.
PRO Block Size : ^^sys_db_block_size.
PRO OFE        : ^^sys_ofe.
PRO DYN_SAMP   : ^^sys_ds.
PRO EBS        : "^^is_ebs."
PRO SIEBEL     : "^^is_siebel."
PRO PSFT       : "^^is_psft."
PRO Date       : ^^time_stamp2.
PRO User       : ^^sessionuser.
PRO </pre>

PRO <ul>
PRO <li><a href="#text">SQL Text</a></li>
PRO <li><a href="#spm">SQL Plan Baselines (DBA_SQL_PLAN_BASELINES)</a></li>
PRO <li><a href="#prof">SQL Profiles (DBA_SQL_PROFILES)</a></li>
PRO <li><a href="#patch">SQL Patches (DBA_SQL_PATCHES)</a></li>
PRO <li><a href="#share_r">Cursor Sharing and Reason</a></li>
PRO <li><a href="#share_l">Cursor Sharing List</a></li>
PRO <li><a href="#mem_plans_sum">Current Plans Summary (GV$SQL)</a></li>
PRO <li><a href="#mem_stats">Current SQL Statistics (GV$SQL)</a></li>
PRO <li><a href="#awr_plans_sum">Historical Plans Summary (DBA_HIST_SQLSTAT)</a></li>
PRO <li><a href="#awr_stats_d">Historical SQL Statistics - Delta (DBA_HIST_SQLSTAT)</a></li>
PRO <li><a href="#awr_stats_t">Historical SQL Statistics - Total (DBA_HIST_SQLSTAT)</a></li>
PRO <li><a href="#ash_plan">Active Session History by Plan (GV$ACTIVE_SESSION_HISTORY)</a></li>
PRO <li><a href="#ash_line">Active Session History by Plan Line (GV$ACTIVE_SESSION_HISTORY)</a></li>
PRO <li><a href="#awr_plan">AWR Active Session History by Plan (DBA_HIST_ACTIVE_SESS_HISTORY)</a></li>
PRO <li><a href="#awr_line">AWR Active Session History by Plan Line (DBA_HIST_ACTIVE_SESS_HISTORY)</a></li>
PRO <li><a href="#dbms_stats_sys_prefs">DBMS_STATS System Preferences</a></li>
PRO <li><a href="#tables">Tables</a></li>
PRO <li><a href="#dbms_stats_tab_prefs">DBMS_STATS Table Preferences</a></li>
PRO <li><a href="#tbl_cols">Table Columns</a></li>
PRO <li><a href="#tbl_parts">Table Partitions</a></li>
PRO <li><a href="#tbl_constr">Table Constraints</a></li>
PRO <li><a href="#tbl_stat_ver">Tables Statistics Versions</a></li>
PRO <li><a href="#indexes">Indexes</a></li>
PRO <li><a href="#idx_cols">Index Columns</a></li>
PRO <li><a href="#ind_parts">Index Partitions</a></li>
PRO <li><a href="#idx_stat_ver">Indexes Statistics Versions</a></li>
PRO <li><a href="#sys_params">System Parameters with Non-Default or Modified Values</a></li>
PRO <li><a href="#inst_params">Instance Parameters</a></li>
PRO <li><a href="#metadata">Metadata</a></li>
PRO </ul>

/* -------------------------
 *
 * sql_text
 *
 * ------------------------- */
PRO <a name="text"></a><h2>SQL Text</h2>
PRO
PRO <pre>

DECLARE
  l_sql_text CLOB := :sql_text;
  l_pos NUMBER;
BEGIN
  WHILE NVL(LENGTH(l_sql_text), 0) > 0
  LOOP
    l_pos := INSTR(l_sql_text, CHR(10));
    IF l_pos > 0 THEN
      DBMS_OUTPUT.PUT_LINE(SUBSTR(l_sql_text, 1, l_pos - 1));
      l_sql_text := SUBSTR(l_sql_text, l_pos + 1);
    ELSE
      DBMS_OUTPUT.PUT_LINE(l_sql_text);
      l_sql_text := NULL;
    END IF;
  END LOOP;
END;
/

PRO </pre>

/* -------------------------
 *
 * dba_sql_plan_baselines
 *
 * ------------------------- */
PRO <a name="spm"></a><h2>SQL Plan Baselines (DBA_SQL_PLAN_BASELINES)</h2>
PRO
PRO Available on 11g or higher. If this section is empty that means there are no plans in plan history for this SQL.
PRO
SELECT '<!-- '||TO_CHAR(SYSDATE, 'YYYY-MM-DD/HH24:MI:SS')||' -->' FROM dual;
PRO <!-- Please Wait -->

SET HEA ON PAGES 50 MARK HTML ON TABLE "" SPOOL OFF;
COL signature FOR 99999999999999999999;
SELECT ROWNUM "#", v.* FROM (SELECT /*+ NO_MERGE */ * FROM dba_sql_plan_baselines WHERE signature IN (^^signature., ^^signaturef.) ORDER BY created, plan_name) v;
SET HEA OFF PAGES 0 MARK HTML OFF;

/* -------------------------
 *
 * dba_sql_profiles
 *
 * ------------------------- */
PRO <a name="prof"></a><h2>SQL Profiles (DBA_SQL_PROFILES)</h2>
PRO
PRO Available on 10g or higher. If this section is empty that means there are no profiles for this SQL.
PRO
SELECT '<!-- '||TO_CHAR(SYSDATE, 'YYYY-MM-DD/HH24:MI:SS')||' -->' FROM dual;
PRO <!-- Please Wait -->

SET HEA ON PAGES 50 MARK HTML ON TABLE "" SPOOL OFF;
COL signature FOR 99999999999999999999;
SELECT ROWNUM "#", v.* FROM (SELECT /*+ NO_MERGE */ * FROM dba_sql_profiles WHERE signature IN (^^signature., ^^signaturef.) ORDER BY created, name) v;
SET HEA OFF PAGES 0 MARK HTML OFF;

/* -------------------------
 *
 * dba_sql_patches
 *
 * ------------------------- */
PRO <a name="patch"></a><h2>SQL Patches (DBA_SQL_PATCHES)</h2>
PRO
PRO Available on 11g or higher. If this section is empty that means there are no patches for this SQL.
PRO
SELECT '<!-- '||TO_CHAR(SYSDATE, 'YYYY-MM-DD/HH24:MI:SS')||' -->' FROM dual;
PRO <!-- Please Wait -->

SET HEA ON PAGES 50 MARK HTML ON TABLE "" SPOOL OFF;
COL signature FOR 99999999999999999999;
SELECT ROWNUM "#", v.* FROM (SELECT /*+ NO_MERGE */ * FROM dba_sql_patches WHERE signature IN (^^signature., ^^signaturef.) ORDER BY created, name) v;
SET HEA OFF PAGES 0 MARK HTML OFF;

/* -------------------------
 *
 * cursor sharing reason
 *
 * ------------------------- */
PRO <a name="share_r"></a><h2>Cursor Sharing and Reason</h2>
PRO
PRO Collected from GV$SQL_SHARED_CURSOR.
PRO
PRO <table>
PRO
PRO <tr>
PRO <th>#</th>
PRO <th>Reason</th>
PRO <th>Inst</th>
PRO <th>Cursors</th>
PRO </tr>
PRO
SELECT '<!-- '||TO_CHAR(SYSDATE, 'YYYY-MM-DD/HH24:MI:SS')||' -->' FROM dual;
PRO <!-- Please Wait -->

@sql_shared_cursor_sum_^^sql_id..sql;

PRO
PRO <tr>
PRO <th>#</th>
PRO <th>Reason</th>
PRO <th>Inst</th>
PRO <th>Cursors</th>
PRO </tr>
PRO
PRO </table>
PRO

/* -------------------------
 *
 * cursor sharing list
 *
 * ------------------------- */
PRO <a name="share_l"></a><h2>Cursor Sharing List</h2>
PRO
PRO Collected from GV$SQL_SHARED_CURSOR.
PRO
SELECT '<!-- '||TO_CHAR(SYSDATE, 'YYYY-MM-DD/HH24:MI:SS')||' -->' FROM dual;
PRO <!-- Please Wait -->

SET HEA ON PAGES 50 MARK HTML ON TABLE "" SPOOL OFF;

@sql_shared_cursor_cur_^^sql_id..sql;

SET HEA OFF PAGES 0 MARK HTML OFF;

/* -------------------------
 *
 * gv$sql plans summary
 *
 * ------------------------- */
EXEC DBMS_APPLICATION_INFO.SET_CLIENT_INFO('^^method.: Plans Summary and Plan Statistics - ' || TO_CHAR(SYSDATE, 'YYYY-MM-DD/HH24:MI:SS'));
PRO <a name="mem_plans_sum"></a><h2>Current Plans Summary (GV$SQL)</h2>
PRO
PRO Execution Plans performance metrics for ^^sql_id. while still in memory. Plans ordered by average elapsed time.
PRO
PRO <table>
PRO
PRO <tr>
PRO <th>#</th>
PRO <th>Plan HV</th>
PRO <th>Avg<br>Elapsed<br>Time<br>(secs)</th>
PRO <th>Avg<br>CPU<br>Time<br>(secs)</th>
PRO <th>Avg<br>IO<br>Time<br>(secs)</th>
PRO <th>Avg<br>Conc<br>Time<br>(secs)</th>
PRO <th>Avg<br>Appl<br>Time<br>(secs)</th>
PRO <th>Avg<br>Clus<br>Time<br>(secs)</th>
PRO <th>Avg<br>PLSQL<br>Time<br>(secs)</th>
PRO <th>Avg<br>Java<br>Time<br>(secs)</th>
PRO <th>Avg<br>Buffer<br>Gets</th>
PRO <th>Avg<br>Disk<br>Reads</th>
PRO <th>Avg<br>Direct<br>Writes</th>
PRO <th>Avg<br>Rows<br>Proc</th>
PRO <th>Total<br>Execs</th>
PRO <th>Total<br>Fetch</th>
PRO <th>Total<br>Loads</th>
PRO <th>Total<br>Inval</th>
PRO <th>Total<br>Parse<br>Calls</th>
PRO <th>Total<br>Child<br>Cursors</th>
PRO <th>Min<br>Cost</th>
PRO <th>Max<br>Cost</th>
PRO <th>Min<br>Opt Env HV</th>
PRO <th>Max<br>Opt Env HV</th>
PRO <th>First Load</th>
PRO <th>Last Load</th>
PRO <th>Last Active</th>
PRO </tr>
PRO
SELECT '<!-- '||TO_CHAR(SYSDATE, 'YYYY-MM-DD/HH24:MI:SS')||' -->' FROM dual;
PRO <!-- Please Wait -->

SELECT CHR(10)||'<tr>'||CHR(10)||
       '<td class="r">'||ROWNUM||'</td>'||CHR(10)||
       '<td class="r">'||v.plan_hash_value||'</td>'||CHR(10)||
       '<td class="r">'||TO_CHAR(v.avg_elapsed_time_secs, '99999999999990D990')||'</td>'||CHR(10)||
       '<td class="r">'||TO_CHAR(v.avg_cpu_time_secs, '99999999999990D990')||'</td>'||CHR(10)||
       '<td class="r">'||TO_CHAR(v.avg_user_io_wait_time_secs, '99999999999990D990')||'</td>'||CHR(10)||
       '<td class="r">'||TO_CHAR(v.avg_concurrency_wait_time_secs, '99999999999990D990')||'</td>'||CHR(10)||
       '<td class="r">'||TO_CHAR(v.avg_application_wait_time_secs, '99999999999990D990')||'</td>'||CHR(10)||
       '<td class="r">'||TO_CHAR(v.avg_cluster_wait_time_secs, '99999999999990D990')||'</td>'||CHR(10)||
       '<td class="r">'||TO_CHAR(v.avg_plsql_exec_time_secs, '99999999999990D990')||'</td>'||CHR(10)||
       '<td class="r">'||TO_CHAR(v.avg_java_exec_time_secs, '99999999999990D990')||'</td>'||CHR(10)||
       '<td class="r">'||v.avg_buffer_gets||'</td>'||CHR(10)||
       '<td class="r">'||v.avg_disk_reads||'</td>'||CHR(10)||
       '<td class="r">'||v.avg_direct_writes||'</td>'||CHR(10)||
       '<td class="r">'||v.avg_rows_processed||'</td>'||CHR(10)||
       '<td class="r">'||v.total_executions||'</td>'||CHR(10)||
       '<td class="r">'||v.total_fetches||'</td>'||CHR(10)||
       '<td class="r">'||v.total_loads||'</td>'||CHR(10)||
       '<td class="r">'||v.total_invalidations||'</td>'||CHR(10)||
       '<td class="r">'||v.total_parse_calls||'</td>'||CHR(10)||
       '<td class="r">'||v.child_cursors||'</td>'||CHR(10)||
       '<td class="r">'||v.min_optimizer_cost||'</td>'||CHR(10)||
       '<td class="r">'||DECODE(v.min_optimizer_cost, v.max_optimizer_cost, NULL, v.max_optimizer_cost)||'</td>'||CHR(10)||
       '<td class="r">'||v.min_optimizer_env_hash_value||'</td>'||CHR(10)||
       '<td class="r">'||DECODE(v.min_optimizer_env_hash_value, v.max_optimizer_env_hash_value, NULL, v.max_optimizer_env_hash_value)||'</td>'||CHR(10)||
       '<td nowrap>'||v.first_load_time||'</td>'||CHR(10)||
       '<td nowrap>'||v.last_load_time||'</td>'||CHR(10)||
       '<td nowrap>'||TO_CHAR(v.last_active_time, 'YYYY-MM-DD/HH24:MI:SS')||'</td>'||CHR(10)||
       '</tr>'
  FROM (
SELECT /*+ NO_MERGE */
       plan_hash_value,
       ROUND((SUM(elapsed_time)/SUM(GREATEST(executions, 1))) / 1e6, 3) avg_elapsed_time_secs,
       ROUND((SUM(cpu_time)/SUM(GREATEST(executions, 1))) / 1e6, 3) avg_cpu_time_secs,
       ROUND((SUM(user_io_wait_time)/SUM(GREATEST(executions, 1))) / 1e6, 3) avg_user_io_wait_time_secs,
       ROUND((SUM(concurrency_wait_time)/SUM(GREATEST(executions, 1))) / 1e6, 3) avg_concurrency_wait_time_secs,
       ROUND((SUM(application_wait_time)/SUM(GREATEST(executions, 1))) / 1e6, 3) avg_application_wait_time_secs,
       ROUND((SUM(cluster_wait_time)/SUM(GREATEST(executions, 1))) / 1e6, 3) avg_cluster_wait_time_secs,
       ROUND((SUM(plsql_exec_time)/SUM(GREATEST(executions, 1))) / 1e6, 3) avg_plsql_exec_time_secs,
       ROUND((SUM(java_exec_time)/SUM(GREATEST(executions, 1))) / 1e6, 3) avg_java_exec_time_secs,
       ROUND(SUM(buffer_gets)/SUM(GREATEST(executions, 1))) avg_buffer_gets,
       ROUND(SUM(disk_reads)/SUM(GREATEST(executions, 1))) avg_disk_reads,
       ROUND(SUM(direct_writes)/SUM(GREATEST(executions, 1))) avg_direct_writes,
       ROUND(SUM(rows_processed)/SUM(GREATEST(executions, 1))) avg_rows_processed,
       SUM(GREATEST(executions, 1)) total_executions,
       SUM(fetches) total_fetches,
       SUM(loads) total_loads,
       SUM(invalidations) total_invalidations,
       SUM(parse_calls) total_parse_calls,
       COUNT(*) child_cursors,
       MIN(optimizer_cost) min_optimizer_cost,
       MAX(optimizer_cost) max_optimizer_cost,
       MIN(optimizer_env_hash_value) min_optimizer_env_hash_value,
       MAX(optimizer_env_hash_value) max_optimizer_env_hash_value,
       MIN(first_load_time) first_load_time,
       MAX(last_load_time) last_load_time,
       MAX(last_active_time) last_active_time
  FROM gv$sql
 WHERE sql_id = :sql_id
 GROUP BY
       plan_hash_value
 ORDER BY
       2) v;

PRO
PRO <tr>
PRO <th>#</th>
PRO <th>Plan HV</th>
PRO <th>Avg<br>Elapsed<br>Time<br>(secs)</th>
PRO <th>Avg<br>CPU<br>Time<br>(secs)</th>
PRO <th>Avg<br>IO<br>Time<br>(secs)</th>
PRO <th>Avg<br>Conc<br>Time<br>(secs)</th>
PRO <th>Avg<br>Appl<br>Time<br>(secs)</th>
PRO <th>Avg<br>Clus<br>Time<br>(secs)</th>
PRO <th>Avg<br>PLSQL<br>Time<br>(secs)</th>
PRO <th>Avg<br>Java<br>Time<br>(secs)</th>
PRO <th>Avg<br>Buffer<br>Gets</th>
PRO <th>Avg<br>Disk<br>Reads</th>
PRO <th>Avg<br>Direct<br>Writes</th>
PRO <th>Avg<br>Rows<br>Proc</th>
PRO <th>Total<br>Execs</th>
PRO <th>Total<br>Fetch</th>
PRO <th>Total<br>Loads</th>
PRO <th>Total<br>Inval</th>
PRO <th>Total<br>Parse<br>Calls</th>
PRO <th>Total<br>Child<br>Cursors</th>
PRO <th>Min<br>Cost</th>
PRO <th>Max<br>Cost</th>
PRO <th>Min<br>Opt Env HV</th>
PRO <th>Max<br>Opt Env HV</th>
PRO <th>First Load</th>
PRO <th>Last Load</th>
PRO <th>Last Active</th>
PRO </tr>
PRO
PRO </table>
PRO

/* -------------------------
 *
 * gv$sql sql statistics
 *
 * ------------------------- */
PRO <a name="mem_stats"></a><h2>Current SQL Statistics (GV$SQL)</h2>
PRO
PRO Performance metrics of child cursors of ^^sql_id. while still in memory.
PRO
PRO <table>
PRO
PRO <tr>
PRO <th>#</th>
PRO <th>Inst<br>ID</th>
PRO <th>Child<br>Num</th>
PRO <th>Plan HV</th>
PRO <th>Execs</th>
PRO <th>Fetch</th>
PRO <th>Loads</th>
PRO <th>Inval</th>
PRO <th>Parse<br>Calls</th>
PRO <th>Buffer<br>Gets</th>
PRO <th>Disk<br>Reads</th>
PRO <th>Direct<br>Writes</th>
PRO <th>Rows<br>Proc</th>
PRO <th>Elapsed<br>Time<br>(secs)</th>
PRO <th>CPU<br>Time<br>(secs)</th>
PRO <th>IO<br>Time<br>(secs)</th>
PRO <th>Conc<br>Time<br>(secs)</th>
PRO <th>Appl<br>Time<br>(secs)</th>
PRO <th>Clus<br>Time<br>(secs)</th>
PRO <th>PLSQL<br>Time<br>(secs)</th>
PRO <th>Java<br>Time<br>(secs)</th>
PRO <th>Optimizer<br>Mode</th>
PRO <th>Cost</th>
PRO <th>Opt Env HV</th>
PRO <th>Parsing<br>Schema<br>Name</th>
PRO <th>Module</th>
PRO <th>Action</th>
PRO <th>Outline</th>
PRO <th>Profile</th>
PRO <th>First Load</th>
PRO <th>Last Load</th>
PRO <th>Last Active</th>
PRO </tr>
PRO
SELECT '<!-- '||TO_CHAR(SYSDATE, 'YYYY-MM-DD/HH24:MI:SS')||' -->' FROM dual;
PRO <!-- Please Wait -->

SELECT CHR(10)||'<tr>'||CHR(10)||
       '<td class="r">'||ROWNUM||'</td>'||CHR(10)||
       '<td class="r">'||inst_id||'</td>'||CHR(10)||
       '<td class="r">'||child_number||'</td>'||CHR(10)||
       '<td class="r">'||plan_hash_value||'</td>'||CHR(10)||
       '<td class="r">'||executions||'</td>'||CHR(10)||
       '<td class="r">'||fetches||'</td>'||CHR(10)||
       '<td class="r">'||loads||'</td>'||CHR(10)||
       '<td class="r">'||invalidations||'</td>'||CHR(10)||
       '<td class="r">'||parse_calls||'</td>'||CHR(10)||
       '<td class="r">'||buffer_gets||'</td>'||CHR(10)||
       '<td class="r">'||disk_reads||'</td>'||CHR(10)||
       '<td class="r">'||direct_writes||'</td>'||CHR(10)||
       '<td class="r">'||rows_processed||'</td>'||CHR(10)||
       '<td class="r">'||TO_CHAR(ROUND(elapsed_time / 1e6, 3), '99999999999990D990')||'</td>'||CHR(10)||
       '<td class="r">'||TO_CHAR(ROUND(cpu_time / 1e6, 3), '99999999999990D990')||'</td>'||CHR(10)||
       '<td class="r">'||TO_CHAR(ROUND(user_io_wait_time / 1e6, 3), '99999999999990D990')||'</td>'||CHR(10)||
       '<td class="r">'||TO_CHAR(ROUND(concurrency_wait_time / 1e6, 3), '99999999999990D990')||'</td>'||CHR(10)||
       '<td class="r">'||TO_CHAR(ROUND(application_wait_time / 1e6, 3), '99999999999990D990')||'</td>'||CHR(10)||
       '<td class="r">'||TO_CHAR(ROUND(cluster_wait_time / 1e6, 3), '99999999999990D990')||'</td>'||CHR(10)||
       '<td class="r">'||TO_CHAR(ROUND(plsql_exec_time / 1e6, 3), '99999999999990D990')||'</td>'||CHR(10)||
       '<td class="r">'||TO_CHAR(ROUND(java_exec_time / 1e6, 3), '99999999999990D990')||'</td>'||CHR(10)||
       '<td>'||optimizer_mode||'</td>'||CHR(10)||
       '<td class="r">'||optimizer_cost||'</td>'||CHR(10)||
       '<td class="r">'||optimizer_env_hash_value||'</td>'||CHR(10)||
       '<td>'||parsing_schema_name||'</td>'||CHR(10)||
       '<td>'||module||'</td>'||CHR(10)||
       '<td>'||action||'</td>'||CHR(10)||
       '<td>'||outline_category||'</td>'||CHR(10)||
       '<td>'||sql_profile||'</td>'||CHR(10)||
       '<td nowrap>'||first_load_time||'</td>'||CHR(10)||
       '<td nowrap>'||last_load_time||'</td>'||CHR(10)||
       '<td nowrap>'||TO_CHAR(last_active_time, 'YYYY-MM-DD/HH24:MI:SS')||'</td>'||CHR(10)||
       '</tr>'
  FROM gv$sql
 WHERE sql_id = :sql_id
 ORDER BY
       inst_id,
       child_number;

PRO
PRO <tr>
PRO <th>#</th>
PRO <th>Inst<br>ID</th>
PRO <th>Child<br>Num</th>
PRO <th>Plan HV</th>
PRO <th>Execs</th>
PRO <th>Fetch</th>
PRO <th>Loads</th>
PRO <th>Inval</th>
PRO <th>Parse<br>Calls</th>
PRO <th>Buffer<br>Gets</th>
PRO <th>Disk<br>Reads</th>
PRO <th>Direct<br>Writes</th>
PRO <th>Rows<br>Proc</th>
PRO <th>Elapsed<br>Time<br>(secs)</th>
PRO <th>CPU<br>Time<br>(secs)</th>
PRO <th>IO<br>Time<br>(secs)</th>
PRO <th>Conc<br>Time<br>(secs)</th>
PRO <th>Appl<br>Time<br>(secs)</th>
PRO <th>Clus<br>Time<br>(secs)</th>
PRO <th>PLSQL<br>Time<br>(secs)</th>
PRO <th>Java<br>Time<br>(secs)</th>
PRO <th>Optimizer<br>Mode</th>
PRO <th>Cost</th>
PRO <th>Opt Env HV</th>
PRO <th>Parsing<br>Schema<br>Name</th>
PRO <th>Module</th>
PRO <th>Action</th>
PRO <th>Outline</th>
PRO <th>Profile</th>
PRO <th>First Load</th>
PRO <th>Last Load</th>
PRO <th>Last Active</th>
PRO </tr>
PRO
PRO </table>
PRO

/* -------------------------
 *
 * dba_hist_sqlstat plans summary
 *
 * ------------------------- */
PRO <a name="awr_plans_sum"></a><h2>Historical Plans Summary (DBA_HIST_SQLSTAT)</h2>
PRO
PRO Performance metrics of Execution Plans of ^^sql_id.. Plans ordered by average elapsed time.<br>
PRO This section includes data captured by AWR. If this is a stand-by read-only database then the AWR information below is from the Primary database.
PRO
PRO <table>
PRO
PRO <tr>
PRO <th>#</th>
PRO <th>Plan HV</th>
PRO <th>Avg<br>Elapsed<br>Time<br>(secs)</th>
PRO <th>Avg<br>CPU<br>Time<br>(secs)</th>
PRO <th>Avg<br>IO<br>Time<br>(secs)</th>
PRO <th>Avg<br>Conc<br>Time<br>(secs)</th>
PRO <th>Avg<br>Appl<br>Time<br>(secs)</th>
PRO <th>Avg<br>Clus<br>Time<br>(secs)</th>
PRO <th>Avg<br>PLSQL<br>Time<br>(secs)</th>
PRO <th>Avg<br>Java<br>Time<br>(secs)</th>
PRO <th>Avg<br>Buffer<br>Gets</th>
PRO <th>Avg<br>Disk<br>Reads</th>
PRO <th>Avg<br>Direct<br>Writes</th>
PRO <th>Avg<br>Rows<br>Proc</th>
PRO <th>Total<br>Execs</th>
--PRO <th>Total<br>Fetch</th>
--PRO <th>Total<br>Loads</th>
--PRO <th>Total<br>Inval</th>
--PRO <th>Total<br>Parse<br>Calls</th>
PRO <th>Min<br>Cost</th>
PRO <th>Max<br>Cost</th>
PRO <th>Min<br>Opt Env HV</th>
PRO <th>Max<br>Opt Env HV</th>
PRO <th>First Snapshot</th>
PRO <th>Last Snapshot</th>
PRO </tr>
PRO
SELECT '<!-- '||TO_CHAR(SYSDATE, 'YYYY-MM-DD/HH24:MI:SS')||' -->' FROM dual;
PRO <!-- Please Wait -->

SELECT CHR(10)||'<tr>'||CHR(10)||
       '<td class="r">'||ROWNUM||'</td>'||CHR(10)||
       '<td class="r">'||v.plan_hash_value||'</td>'||CHR(10)||
       '<td class="r">'||TO_CHAR(v.avg_elapsed_time_secs, '99999999999990D990')||'</td>'||CHR(10)||
       '<td class="r">'||TO_CHAR(v.avg_cpu_time_secs, '99999999999990D990')||'</td>'||CHR(10)||
       '<td class="r">'||TO_CHAR(v.avg_user_io_wait_time_secs, '99999999999990D990')||'</td>'||CHR(10)||
       '<td class="r">'||TO_CHAR(v.avg_concurrency_wait_time_secs, '99999999999990D990')||'</td>'||CHR(10)||
       '<td class="r">'||TO_CHAR(v.avg_application_wait_time_secs, '99999999999990D990')||'</td>'||CHR(10)||
       '<td class="r">'||TO_CHAR(v.avg_cluster_wait_time_secs, '99999999999990D990')||'</td>'||CHR(10)||
       '<td class="r">'||TO_CHAR(v.avg_plsql_exec_time_secs, '99999999999990D990')||'</td>'||CHR(10)||
       '<td class="r">'||TO_CHAR(v.avg_java_exec_time_secs, '99999999999990D990')||'</td>'||CHR(10)||
       '<td class="r">'||v.avg_buffer_gets||'</td>'||CHR(10)||
       '<td class="r">'||v.avg_disk_reads||'</td>'||CHR(10)||
       '<td class="r">'||v.avg_direct_writes||'</td>'||CHR(10)||
       '<td class="r">'||v.avg_rows_processed||'</td>'||CHR(10)||
       '<td class="r">'||v.delta_executions||'</td>'||CHR(10)||
       --'<td class="r">'||v.delta_fetches||'</td>'||CHR(10)||
       --'<td class="r">'||v.delta_loads||'</td>'||CHR(10)||
       --'<td class="r">'||v.delta_invalidations||'</td>'||CHR(10)||
       --'<td class="r">'||v.delta_parse_calls||'</td>'||CHR(10)||
       '<td class="r">'||v.min_optimizer_cost||'</td>'||CHR(10)||
       '<td class="r">'||DECODE(v.min_optimizer_cost, v.max_optimizer_cost, NULL, v.max_optimizer_cost)||'</td>'||CHR(10)||
       '<td class="r">'||v.min_optimizer_env_hash_value||'</td>'||CHR(10)||
       '<td class="r">'||DECODE(v.min_optimizer_env_hash_value, v.max_optimizer_env_hash_value, NULL, v.max_optimizer_env_hash_value)||'</td>'||CHR(10)||
       '<td nowrap>'||TO_CHAR(v.first_snap_time, 'YYYY-MM-DD/HH24:MI:SS')||'</td>'||CHR(10)||
       '<td nowrap>'||TO_CHAR(v.last_snap_time, 'YYYY-MM-DD/HH24:MI:SS')||'</td>'||CHR(10)||
       '</tr>'
  FROM (
SELECT /*+ NO_MERGE */
       h.plan_hash_value,
       ROUND((SUM(h.elapsed_time_delta)/SUM(GREATEST(h.executions_delta, 1))) / 1e6, 3) avg_elapsed_time_secs,
       ROUND((SUM(h.cpu_time_delta)/SUM(GREATEST(h.executions_delta, 1))) / 1e6, 3) avg_cpu_time_secs,
       ROUND((SUM(h.iowait_delta)/SUM(GREATEST(h.executions_delta, 1))) / 1e6, 3) avg_user_io_wait_time_secs,
       ROUND((SUM(h.ccwait_delta)/SUM(GREATEST(h.executions_delta, 1))) / 1e6, 3) avg_concurrency_wait_time_secs,
       ROUND((SUM(h.apwait_delta)/SUM(GREATEST(h.executions_delta, 1))) / 1e6, 3) avg_application_wait_time_secs,
       ROUND((SUM(h.clwait_delta)/SUM(GREATEST(h.executions_delta, 1))) / 1e6, 3) avg_cluster_wait_time_secs,
       ROUND((SUM(h.plsexec_time_delta)/SUM(GREATEST(h.executions_delta, 1))) / 1e6, 3) avg_plsql_exec_time_secs,
       ROUND((SUM(h.javexec_time_delta)/SUM(GREATEST(h.executions_delta, 1))) / 1e6, 3) avg_java_exec_time_secs,
       ROUND(SUM(h.buffer_gets_delta)/SUM(GREATEST(h.executions_delta, 1))) avg_buffer_gets,
       ROUND(SUM(h.disk_reads_delta)/SUM(GREATEST(h.executions_delta, 1))) avg_disk_reads,
       ROUND(SUM(h.direct_writes_delta)/SUM(GREATEST(h.executions_delta, 1))) avg_direct_writes,
       ROUND(SUM(h.rows_processed_delta)/SUM(GREATEST(h.executions_delta, 1))) avg_rows_processed,
       SUM(GREATEST(h.executions_delta, 1)) delta_executions,
       --SUM(h.fetches_delta) delta_fetches,
       --SUM(h.loads_delta) delta_loads,
       --SUM(h.invalidations_delta) delta_invalidations,
       --SUM(h.parse_calls_delta) delta_parse_calls,
       MIN(h.optimizer_cost) min_optimizer_cost,
       MAX(h.optimizer_cost) max_optimizer_cost,
       MIN(h.optimizer_env_hash_value) min_optimizer_env_hash_value,
       MAX(h.optimizer_env_hash_value) max_optimizer_env_hash_value,
       MIN(s.end_interval_time) first_snap_time,
       MAX(s.end_interval_time) last_snap_time
  FROM dba_hist_sqlstat h,
       dba_hist_snapshot s
 WHERE :license IN ('T', 'D')
   AND h.dbid = ^^dbid.
   AND h.sql_id = :sql_id
   AND h.snap_id = s.snap_id
   AND h.dbid = s.dbid
   AND h.instance_number = s.instance_number
 GROUP BY
       h.plan_hash_value
 ORDER BY
       2) v;

PRO
PRO <tr>
PRO <th>#</th>
PRO <th>Plan HV</th>
PRO <th>Avg<br>Elapsed<br>Time<br>(secs)</th>
PRO <th>Avg<br>CPU<br>Time<br>(secs)</th>
PRO <th>Avg<br>IO<br>Time<br>(secs)</th>
PRO <th>Avg<br>Conc<br>Time<br>(secs)</th>
PRO <th>Avg<br>Appl<br>Time<br>(secs)</th>
PRO <th>Avg<br>Clus<br>Time<br>(secs)</th>
PRO <th>Avg<br>PLSQL<br>Time<br>(secs)</th>
PRO <th>Avg<br>Java<br>Time<br>(secs)</th>
PRO <th>Avg<br>Buffer<br>Gets</th>
PRO <th>Avg<br>Disk<br>Reads</th>
PRO <th>Avg<br>Direct<br>Writes</th>
PRO <th>Avg<br>Rows<br>Proc</th>
PRO <th>Total<br>Execs</th>
--PRO <th>Total<br>Fetch</th>
--PRO <th>Total<br>Loads</th>
--PRO <th>Total<br>Inval</th>
--PRO <th>Total<br>Parse<br>Calls</th>
PRO <th>Min<br>Cost</th>
PRO <th>Max<br>Cost</th>
PRO <th>Min<br>Opt Env HV</th>
PRO <th>Max<br>Opt Env HV</th>
PRO <th>First Snapshot</th>
PRO <th>Last Snapshot</th>
PRO </tr>
PRO
PRO </table>
PRO

/* -------------------------
 *
 * dba_hist_sqlstat sql statistics
 *
 * ------------------------- */
PRO <a name="awr_stats_d"></a><h2>Historical SQL Statistics - Delta (DBA_HIST_SQLSTAT)</h2>
PRO
PRO Performance metrics of Execution Plans of ^^sql_id..<br>
PRO This section includes data captured by AWR. If this is a stand-by read-only database then the AWR information below is from the Primary database.
PRO
PRO <table>
PRO
PRO <tr>
PRO <th>#</th>
PRO <th>Snap<br>ID</th>
PRO <th>Snaphot</th>
PRO <th>Inst<br>ID</th>
PRO <th>Plan HV</th>
PRO <th>Vers<br>Cnt</th>
PRO <th>Execs</th>
PRO <th>Fetch</th>
PRO <th>Loads</th>
PRO <th>Inval</th>
PRO <th>Parse<br>Calls</th>
PRO <th>Buffer<br>Gets</th>
PRO <th>Disk<br>Reads</th>
PRO <th>Direct<br>Writes</th>
PRO <th>Rows<br>Proc</th>
PRO <th>Elapsed<br>Time<br>(secs)</th>
PRO <th>CPU<br>Time<br>(secs)</th>
PRO <th>IO<br>Time<br>(secs)</th>
PRO <th>Conc<br>Time<br>(secs)</th>
PRO <th>Appl<br>Time<br>(secs)</th>
PRO <th>Clus<br>Time<br>(secs)</th>
PRO <th>PLSQL<br>Time<br>(secs)</th>
PRO <th>Java<br>Time<br>(secs)</th>
PRO <th>Optimizer<br>Mode</th>
PRO <th>Cost</th>
PRO <th>Opt Env HV</th>
PRO <th>Parsing<br>Schema<br>Name</th>
PRO <th>Module</th>
PRO <th>Action</th>
PRO <th>Profile</th>
PRO </tr>
PRO
SELECT '<!-- '||TO_CHAR(SYSDATE, 'YYYY-MM-DD/HH24:MI:SS')||' -->' FROM dual;
PRO <!-- Please Wait -->

SELECT CHR(10)||'<tr>'||CHR(10)||
       '<td class="r">'||ROWNUM||'</td>'||CHR(10)||
       '<td class="r">'||v.snap_id||'</td>'||CHR(10)||
       '<td nowrap>'||TO_CHAR(v.end_interval_time, 'YYYY-MM-DD/HH24:MI:SS')||'</td>'||CHR(10)||
       '<td class="r">'||v.instance_number||'</td>'||CHR(10)||
       '<td class="r">'||v.plan_hash_value||'</td>'||CHR(10)||
       '<td class="r">'||v.version_count||'</td>'||CHR(10)||
       '<td class="r">'||v.executions_delta||'</td>'||CHR(10)||
       '<td class="r">'||v.fetches_delta||'</td>'||CHR(10)||
       '<td class="r">'||v.loads_delta||'</td>'||CHR(10)||
       '<td class="r">'||v.invalidations_delta||'</td>'||CHR(10)||
       '<td class="r">'||v.parse_calls_delta||'</td>'||CHR(10)||
       '<td class="r">'||v.buffer_gets_delta||'</td>'||CHR(10)||
       '<td class="r">'||v.disk_reads_delta||'</td>'||CHR(10)||
       '<td class="r">'||v.direct_writes_delta||'</td>'||CHR(10)||
       '<td class="r">'||v.rows_processed_delta||'</td>'||CHR(10)||
       '<td class="r">'||TO_CHAR(ROUND(v.elapsed_time_delta / 1e6, 3), '99999999999990D990')||'</td>'||CHR(10)||
       '<td class="r">'||TO_CHAR(ROUND(v.cpu_time_delta / 1e6, 3), '99999999999990D990')||'</td>'||CHR(10)||
       '<td class="r">'||TO_CHAR(ROUND(v.iowait_delta / 1e6, 3), '99999999999990D990')||'</td>'||CHR(10)||
       '<td class="r">'||TO_CHAR(ROUND(v.ccwait_delta / 1e6, 3), '99999999999990D990')||'</td>'||CHR(10)||
       '<td class="r">'||TO_CHAR(ROUND(v.apwait_delta / 1e6, 3), '99999999999990D990')||'</td>'||CHR(10)||
       '<td class="r">'||TO_CHAR(ROUND(v.clwait_delta / 1e6, 3), '99999999999990D990')||'</td>'||CHR(10)||
       '<td class="r">'||TO_CHAR(ROUND(v.plsexec_time_delta / 1e6, 3), '99999999999990D990')||'</td>'||CHR(10)||
       '<td class="r">'||TO_CHAR(ROUND(v.javexec_time_delta / 1e6, 3), '99999999999990D990')||'</td>'||CHR(10)||
       '<td>'||v.optimizer_mode||'</td>'||CHR(10)||
       '<td class="r">'||v.optimizer_cost||'</td>'||CHR(10)||
       '<td class="r">'||v.optimizer_env_hash_value||'</td>'||CHR(10)||
       '<td>'||v.parsing_schema_name||'</td>'||CHR(10)||
       '<td>'||v.module||'</td>'||CHR(10)||
       '<td>'||v.action||'</td>'||CHR(10)||
       '<td>'||v.sql_profile||'</td>'||CHR(10)||
       '</tr>'
  FROM (
SELECT /*+ NO_MERGE */
       h.snap_id,
       s.end_interval_time,
       h.instance_number,
       h.plan_hash_value,
       h.optimizer_cost,
       h.optimizer_mode,
       h.optimizer_env_hash_value,
       h.version_count,
       h.module,
       h.action,
       h.sql_profile,
       h.parsing_schema_name,
       h.fetches_delta,
       h.executions_delta,
       h.loads_delta,
       h.invalidations_delta,
       h.parse_calls_delta,
       h.disk_reads_delta,
       h.buffer_gets_delta,
       h.rows_processed_delta,
       h.cpu_time_delta,
       h.elapsed_time_delta,
       h.iowait_delta,
       h.clwait_delta,
       h.apwait_delta,
       h.ccwait_delta,
       h.direct_writes_delta,
       h.plsexec_time_delta,
       h.javexec_time_delta
  FROM dba_hist_sqlstat h,
       dba_hist_snapshot s
 WHERE :license IN ('T', 'D')
   AND h.dbid = ^^dbid.
   AND h.sql_id = :sql_id
   AND h.snap_id = s.snap_id
   AND h.dbid = s.dbid
   AND h.instance_number = s.instance_number
 ORDER BY
       s.end_interval_time,
       h.instance_number,
       h.plan_hash_value ) v;

PRO
PRO <tr>
PRO <th>#</th>
PRO <th>Snap<br>ID</th>
PRO <th>Snaphot</th>
PRO <th>Inst<br>ID</th>
PRO <th>Plan HV</th>
PRO <th>Vers<br>Cnt</th>
PRO <th>Execs</th>
PRO <th>Fetch</th>
PRO <th>Loads</th>
PRO <th>Inval</th>
PRO <th>Parse<br>Calls</th>
PRO <th>Buffer<br>Gets</th>
PRO <th>Disk<br>Reads</th>
PRO <th>Direct<br>Writes</th>
PRO <th>Rows<br>Proc</th>
PRO <th>Elapsed<br>Time<br>(secs)</th>
PRO <th>CPU<br>Time<br>(secs)</th>
PRO <th>IO<br>Time<br>(secs)</th>
PRO <th>Conc<br>Time<br>(secs)</th>
PRO <th>Appl<br>Time<br>(secs)</th>
PRO <th>Clus<br>Time<br>(secs)</th>
PRO <th>PLSQL<br>Time<br>(secs)</th>
PRO <th>Java<br>Time<br>(secs)</th>
PRO <th>Optimizer<br>Mode</th>
PRO <th>Cost</th>
PRO <th>Opt Env HV</th>
PRO <th>Parsing<br>Schema<br>Name</th>
PRO <th>Module</th>
PRO <th>Action</th>
PRO <th>Profile</th>
PRO </tr>
PRO
PRO </table>
PRO

/* -------------------------
 *
 * dba_hist_sqlstat sql statistics
 *
 * ------------------------- */
PRO <a name="awr_stats_t"></a><h2>Historical SQL Statistics - Total (DBA_HIST_SQLSTAT)</h2>
PRO
PRO Performance metrics of Execution Plans of ^^sql_id..<br>
PRO This section includes data captured by AWR. If this is a stand-by read-only database then the AWR information below is from the Primary database.
PRO
PRO <table>
PRO
PRO <tr>
PRO <th>#</th>
PRO <th>Snap<br>ID</th>
PRO <th>Snaphot</th>
PRO <th>Inst<br>ID</th>
PRO <th>Plan HV</th>
PRO <th>Vers<br>Cnt</th>
PRO <th>Execs</th>
PRO <th>Fetch</th>
PRO <th>Loads</th>
PRO <th>Inval</th>
PRO <th>Parse<br>Calls</th>
PRO <th>Buffer<br>Gets</th>
PRO <th>Disk<br>Reads</th>
PRO <th>Direct<br>Writes</th>
PRO <th>Rows<br>Proc</th>
PRO <th>Elapsed<br>Time<br>(secs)</th>
PRO <th>CPU<br>Time<br>(secs)</th>
PRO <th>IO<br>Time<br>(secs)</th>
PRO <th>Conc<br>Time<br>(secs)</th>
PRO <th>Appl<br>Time<br>(secs)</th>
PRO <th>Clus<br>Time<br>(secs)</th>
PRO <th>PLSQL<br>Time<br>(secs)</th>
PRO <th>Java<br>Time<br>(secs)</th>
PRO <th>Optimizer<br>Mode</th>
PRO <th>Cost</th>
PRO <th>Opt Env HV</th>
PRO <th>Parsing<br>Schema<br>Name</th>
PRO <th>Module</th>
PRO <th>Action</th>
PRO <th>Profile</th>
PRO </tr>
PRO
SELECT '<!-- '||TO_CHAR(SYSDATE, 'YYYY-MM-DD/HH24:MI:SS')||' -->' FROM dual;
PRO <!-- Please Wait -->

SELECT CHR(10)||'<tr>'||CHR(10)||
       '<td class="r">'||ROWNUM||'</td>'||CHR(10)||
       '<td class="r">'||v.snap_id||'</td>'||CHR(10)||
       '<td nowrap>'||TO_CHAR(v.end_interval_time, 'YYYY-MM-DD/HH24:MI:SS')||'</td>'||CHR(10)||
       '<td class="r">'||v.instance_number||'</td>'||CHR(10)||
       '<td class="r">'||v.plan_hash_value||'</td>'||CHR(10)||
       '<td class="r">'||v.version_count||'</td>'||CHR(10)||
       '<td class="r">'||v.executions_total||'</td>'||CHR(10)||
       '<td class="r">'||v.fetches_total||'</td>'||CHR(10)||
       '<td class="r">'||v.loads_total||'</td>'||CHR(10)||
       '<td class="r">'||v.invalidations_total||'</td>'||CHR(10)||
       '<td class="r">'||v.parse_calls_total||'</td>'||CHR(10)||
       '<td class="r">'||v.buffer_gets_total||'</td>'||CHR(10)||
       '<td class="r">'||v.disk_reads_total||'</td>'||CHR(10)||
       '<td class="r">'||v.direct_writes_total||'</td>'||CHR(10)||
       '<td class="r">'||v.rows_processed_total||'</td>'||CHR(10)||
       '<td class="r">'||TO_CHAR(ROUND(v.elapsed_time_total / 1e6, 3), '99999999999990D990')||'</td>'||CHR(10)||
       '<td class="r">'||TO_CHAR(ROUND(v.cpu_time_total / 1e6, 3), '99999999999990D990')||'</td>'||CHR(10)||
       '<td class="r">'||TO_CHAR(ROUND(v.iowait_total / 1e6, 3), '99999999999990D990')||'</td>'||CHR(10)||
       '<td class="r">'||TO_CHAR(ROUND(v.ccwait_total / 1e6, 3), '99999999999990D990')||'</td>'||CHR(10)||
       '<td class="r">'||TO_CHAR(ROUND(v.apwait_total / 1e6, 3), '99999999999990D990')||'</td>'||CHR(10)||
       '<td class="r">'||TO_CHAR(ROUND(v.clwait_total / 1e6, 3), '99999999999990D990')||'</td>'||CHR(10)||
       '<td class="r">'||TO_CHAR(ROUND(v.plsexec_time_total / 1e6, 3), '99999999999990D990')||'</td>'||CHR(10)||
       '<td class="r">'||TO_CHAR(ROUND(v.javexec_time_total / 1e6, 3), '99999999999990D990')||'</td>'||CHR(10)||
       '<td>'||v.optimizer_mode||'</td>'||CHR(10)||
       '<td class="r">'||v.optimizer_cost||'</td>'||CHR(10)||
       '<td class="r">'||v.optimizer_env_hash_value||'</td>'||CHR(10)||
       '<td>'||v.parsing_schema_name||'</td>'||CHR(10)||
       '<td>'||v.module||'</td>'||CHR(10)||
       '<td>'||v.action||'</td>'||CHR(10)||
       '<td>'||v.sql_profile||'</td>'||CHR(10)||
       '</tr>'
  FROM (
SELECT /*+ NO_MERGE */
       h.snap_id,
       s.end_interval_time,
       h.instance_number,
       h.plan_hash_value,
       h.optimizer_cost,
       h.optimizer_mode,
       h.optimizer_env_hash_value,
       h.version_count,
       h.module,
       h.action,
       h.sql_profile,
       h.parsing_schema_name,
       h.fetches_total,
       h.executions_total,
       h.loads_total,
       h.invalidations_total,
       h.parse_calls_total,
       h.disk_reads_total,
       h.buffer_gets_total,
       h.rows_processed_total,
       h.cpu_time_total,
       h.elapsed_time_total,
       h.iowait_total,
       h.clwait_total,
       h.apwait_total,
       h.ccwait_total,
       h.direct_writes_total,
       h.plsexec_time_total,
       h.javexec_time_total
  FROM dba_hist_sqlstat h,
       dba_hist_snapshot s
 WHERE :license IN ('T', 'D')
   AND h.dbid = ^^dbid.
   AND h.sql_id = :sql_id
   AND h.snap_id = s.snap_id
   AND h.dbid = s.dbid
   AND h.instance_number = s.instance_number
 ORDER BY
       s.end_interval_time,
       h.instance_number,
       h.plan_hash_value ) v;

PRO
PRO <tr>
PRO <th>#</th>
PRO <th>Snap<br>ID</th>
PRO <th>Snaphot</th>
PRO <th>Inst<br>ID</th>
PRO <th>Plan HV</th>
PRO <th>Vers<br>Cnt</th>
PRO <th>Execs</th>
PRO <th>Fetch</th>
PRO <th>Loads</th>
PRO <th>Inval</th>
PRO <th>Parse<br>Calls</th>
PRO <th>Buffer<br>Gets</th>
PRO <th>Disk<br>Reads</th>
PRO <th>Direct<br>Writes</th>
PRO <th>Rows<br>Proc</th>
PRO <th>Elapsed<br>Time<br>(secs)</th>
PRO <th>CPU<br>Time<br>(secs)</th>
PRO <th>IO<br>Time<br>(secs)</th>
PRO <th>Conc<br>Time<br>(secs)</th>
PRO <th>Appl<br>Time<br>(secs)</th>
PRO <th>Clus<br>Time<br>(secs)</th>
PRO <th>PLSQL<br>Time<br>(secs)</th>
PRO <th>Java<br>Time<br>(secs)</th>
PRO <th>Optimizer<br>Mode</th>
PRO <th>Cost</th>
PRO <th>Opt Env HV</th>
PRO <th>Parsing<br>Schema<br>Name</th>
PRO <th>Module</th>
PRO <th>Action</th>
PRO <th>Profile</th>
PRO </tr>
PRO
PRO </table>
PRO

/* -------------------------
 *
 * gv$active_session_history by plan
 *
 * ------------------------- */
EXEC DBMS_APPLICATION_INFO.SET_CLIENT_INFO('^^method.: GV$ASH by Plan - ' || TO_CHAR(SYSDATE, 'YYYY-MM-DD/HH24:MI:SS'));
PRO <a name="ash_plan"></a><h2>Active Session History by Plan (GV$ACTIVE_SESSION_HISTORY)</h2>
PRO
PRO Snapshots counts per Plan and Wait Event for ^^sql_id..<br>
PRO This section includes data captured by AWR.
PRO
PRO <table>
PRO
PRO <tr>
PRO <th>#</th>
PRO <th>Plan<br>Hash<br>Value</th>
PRO <th>Session<br>State</th>
PRO <th>Wait<br>Class</th>
PRO <th>Event</th>
PRO <th>Snaps<br>Count</th>
PRO </tr>
PRO
SELECT '<!-- '||TO_CHAR(SYSDATE, 'YYYY-MM-DD/HH24:MI:SS')||' -->' FROM dual;
PRO <!-- Please Wait -->

SELECT CHR(10)||'<tr>'||CHR(10)||
       '<td class="r">'||ROWNUM||'</td>'||CHR(10)||
       '<td class="r">'||v.sql_plan_hash_value||'</td>'||CHR(10)||
       '<td>'||v.session_state||'</td>'||CHR(10)||
       '<td>'||v.wait_class||'</td>'||CHR(10)||
       '<td>'||v.event||'</td>'||CHR(10)||
       '<td class="r">'||v.snaps_count||'</td>'||CHR(10)||
       '</tr>'
  FROM (
SELECT /*+ NO_MERGE */
       ash.sql_plan_hash_value,
       ash.session_state,
       ash.wait_class,
       ash.event,
       COUNT(*) snaps_count
  FROM gv$active_session_history ash
 WHERE :license IN ('T', 'D')
   AND ash.sql_id = :sql_id
 GROUP BY
       ash.sql_plan_hash_value,
       ash.session_state,
       ash.wait_class,
       ash.event
 ORDER BY
       ash.sql_plan_hash_value,
       5 DESC,
       ash.session_state,
       ash.wait_class,
       ash.event ) v;

PRO
PRO <tr>
PRO <th>#</th>
PRO <th>Plan<br>Hash<br>Value</th>
PRO <th>Session<br>State</th>
PRO <th>Wait<br>Class</th>
PRO <th>Event</th>
PRO <th>Snaps<br>Count</th>
PRO </tr>
PRO
PRO </table>
PRO

/* -------------------------
 *
 * gv$active_session_history by plan line
 *
 * ------------------------- */
EXEC DBMS_APPLICATION_INFO.SET_CLIENT_INFO('^^method.: GV$ASH by Plan Line - ' || TO_CHAR(SYSDATE, 'YYYY-MM-DD/HH24:MI:SS'));
PRO <a name="ash_line"></a><h2>Active Session History by Plan Line (GV$ACTIVE_SESSION_HISTORY)</h2>
PRO
PRO Snapshots counts per Plan Line and Wait Event for ^^sql_id..<br>
PRO This section includes data captured by AWR.<br>
PRO Available on 11g or higher..
PRO
PRO <table>
PRO
PRO <tr>
PRO <th>#</th>
PRO <th>Plan<br>Hash<br>Value</th>
PRO <th>Plan<br>Line<br>ID</th>
PRO <th>Plan<br>Operation</th>
PRO <th>Plan<br>Options</th>
PRO <th>Plan<br>Object<br>Owner</th>
PRO <th>Plan<br>Object<br>Name</th>
PRO <th>Session<br>State</th>
PRO <th>Wait<br>Class</th>
PRO <th>Event</th>
PRO <th>Curr<br>Obj<br>ID</th>
PRO <th>Curr<br>Object<br>Name</th>
PRO <th>Snaps<br>Count</th>
PRO </tr>
PRO
SELECT '<!-- '||TO_CHAR(SYSDATE, 'YYYY-MM-DD/HH24:MI:SS')||' -->' FROM dual;
PRO <!-- Please Wait -->

SELECT CHR(10)||'<tr>'||CHR(10)||
       '<td class="r">'||ROWNUM||'</td>'||CHR(10)||
       '<td class="r">'||v.sql_plan_hash_value||'</td>'||CHR(10)||
       '<td class="r">'||v.sql_plan_line_id||'</td>'||CHR(10)||
       '<td>'||v.sql_plan_operation||'</td>'||CHR(10)||
       '<td>'||v.sql_plan_options||'</td>'||CHR(10)||
       '<td>'||v.object_owner||'</td>'||CHR(10)||
       '<td>'||v.object_name||'</td>'||CHR(10)||
       '<td>'||v.session_state||'</td>'||CHR(10)||
       '<td>'||v.wait_class||'</td>'||CHR(10)||
       '<td>'||v.event||'</td>'||CHR(10)||
       '<td class="r">'||v.current_obj#||'</td>'||CHR(10)||
       '<td>'||v.current_obj_name||'</td>'||CHR(10)||
       '<td class="r">'||v.snaps_count||'</td>'||CHR(10)||
       '</tr>'
  FROM (
SELECT /*+ NO_MERGE */
       ash.sql_plan_hash_value,
       ash.sql_plan_line_id,
       ash.sql_plan_operation,
       ash.sql_plan_options,
       ash.object_owner,
       ash.object_name,
       ash.current_obj#,
       CASE
         WHEN ash.current_obj# IS NOT NULL THEN
           (SELECT obj.owner||'.'||obj.object_name||NVL2(obj.subobject_name, '.'||obj.subobject_name, NULL)
              FROM dba_objects obj
             WHERE obj.object_id = ash.current_obj#)
       END current_obj_name,
       ash.session_state,
       ash.wait_class,
       ash.event,
       COUNT(*) snaps_count
  FROM (
SELECT /*+ NO_MERGE */
       sh.sql_plan_hash_value,
       sh.sql_plan_line_id,
       sh.sql_plan_operation,
       sh.sql_plan_options,
       CASE
         WHEN sh.wait_class IN ('Application', 'Cluster', 'Concurrency', 'User I/O') THEN
           sh.current_obj#
       END current_obj#,
       sh.session_state,
       sh.wait_class,
       sh.event,
       sp.object_owner,
       sp.object_name
  FROM gv$active_session_history sh,
       gv$sql_plan sp
 WHERE :license IN ('T', 'D')
   AND sh.sql_id = :sql_id
   AND sh.sql_plan_line_id > 0
   AND sp.inst_id(+) = sh.inst_id
   AND sp.sql_id(+) = sh.sql_id
   AND sp.child_number(+) = sh.sql_child_number
   AND sp.plan_hash_value(+) = sh.sql_plan_hash_value
   AND sp.id(+) = sh.sql_plan_line_id ) ash
 GROUP BY
       ash.sql_plan_hash_value,
       ash.sql_plan_line_id,
       ash.sql_plan_operation,
       ash.sql_plan_options,
       ash.object_owner,
       ash.object_name,
       ash.session_state,
       ash.wait_class,
       ash.current_obj#,
       ash.event
 ORDER BY
       ash.sql_plan_hash_value,
       ash.sql_plan_line_id,
       12 DESC,
       ash.sql_plan_operation,
       ash.sql_plan_options,
       ash.object_owner,
       ash.object_name,
       ash.session_state,
       ash.wait_class,
       ash.current_obj#,
       ash.event ) v;

PRO
PRO <tr>
PRO <th>#</th>
PRO <th>Plan<br>Hash<br>Value</th>
PRO <th>Plan<br>Line<br>ID</th>
PRO <th>Plan<br>Operation</th>
PRO <th>Plan<br>Options</th>
PRO <th>Plan<br>Object<br>Owner</th>
PRO <th>Plan<br>Object<br>Name</th>
PRO <th>Session<br>State</th>
PRO <th>Wait<br>Class</th>
PRO <th>Event</th>
PRO <th>Curr<br>Obj<br>ID</th>
PRO <th>Curr<br>Object<br>Name</th>
PRO <th>Snaps<br>Count</th>
PRO </tr>
PRO
PRO </table>
PRO

/* -------------------------
 *
 * dba_hist_active_sess_history by plan
 *
 * ------------------------- */
EXEC DBMS_APPLICATION_INFO.SET_CLIENT_INFO('^^method.: DBA_HIST_ASH by Plan - ' || TO_CHAR(SYSDATE, 'YYYY-MM-DD/HH24:MI:SS'));
PRO <a name="awr_plan"></a><h2>AWR Active Session History by Plan (DBA_HIST_ACTIVE_SESS_HISTORY)</h2>
PRO
PRO Snapshots counts per Plan and Wait Event for ^^sql_id..<br>
PRO This section includes data captured by AWR. If this is a stand-by read-only database then the AWR information below is from the Primary database.
PRO
PRO <table>
PRO
PRO <tr>
PRO <th>#</th>
PRO <th>Plan<br>Hash<br>Value</th>
PRO <th>Session<br>State</th>
PRO <th>Wait<br>Class</th>
PRO <th>Event</th>
PRO <th>Snaps<br>Count</th>
PRO </tr>
PRO
SELECT '<!-- '||TO_CHAR(SYSDATE, 'YYYY-MM-DD/HH24:MI:SS')||' -->' FROM dual;
PRO <!-- Please Wait -->

SELECT CHR(10)||'<tr>'||CHR(10)||
       '<td class="r">'||ROWNUM||'</td>'||CHR(10)||
       '<td class="r">'||v.sql_plan_hash_value||'</td>'||CHR(10)||
       '<td>'||v.session_state||'</td>'||CHR(10)||
       '<td>'||v.wait_class||'</td>'||CHR(10)||
       '<td>'||v.event||'</td>'||CHR(10)||
       '<td class="r">'||v.snaps_count||'</td>'||CHR(10)||
       '</tr>'
  FROM (
SELECT /*+ NO_MERGE */
       ash.sql_plan_hash_value,
       ash.session_state,
       ash.wait_class,
       ash.event,
       COUNT(*) snaps_count
  FROM dba_hist_active_sess_history ash
 WHERE :license IN ('T', 'D')
   AND ash.dbid = ^^dbid.
   AND ash.sql_id = :sql_id
   --AND ash.sql_plan_line_id > 0
 GROUP BY
       ash.sql_plan_hash_value,
       ash.session_state,
       ash.wait_class,
       ash.event
 ORDER BY
       ash.sql_plan_hash_value,
       5 DESC,
       ash.session_state,
       ash.wait_class,
       ash.event ) v;

PRO
PRO <tr>
PRO <th>#</th>
PRO <th>Plan<br>Hash<br>Value</th>
PRO <th>Session<br>State</th>
PRO <th>Wait<br>Class</th>
PRO <th>Event</th>
PRO <th>Snaps<br>Count</th>
PRO </tr>
PRO
PRO </table>
PRO

/* -------------------------
 *
 * dba_hist_active_sess_history by plan line
 *
 * ------------------------- */
EXEC DBMS_APPLICATION_INFO.SET_CLIENT_INFO('^^method.: DBA_HIST_ASH by Plan Line - ' || TO_CHAR(SYSDATE, 'YYYY-MM-DD/HH24:MI:SS'));
PRO <a name="awr_line"></a><h2>AWR Active Session History by Plan Line (DBA_HIST_ACTIVE_SESS_HISTORY)</h2>
PRO
PRO Snapshots counts per Plan Line and Wait Event for ^^sql_id..<br>
PRO This section includes data captured by AWR. If this is a stand-by read-only database then the AWR information below is from the Primary database.<br>
PRO Available on 11g or higher..
PRO
PRO <table>
PRO
PRO <tr>
PRO <th>#</th>
PRO <th>Plan<br>Hash<br>Value</th>
PRO <th>Plan<br>Line<br>ID</th>
PRO <th>Plan<br>Operation</th>
PRO <th>Plan<br>Options</th>
PRO <th>Plan<br>Object<br>Owner</th>
PRO <th>Plan<br>Object<br>Name</th>
PRO <th>Session<br>State</th>
PRO <th>Wait<br>Class</th>
PRO <th>Event</th>
PRO <th>Curr<br>Obj<br>ID</th>
PRO <th>Curr<br>Object<br>Name</th>
PRO <th>Snaps<br>Count</th>
PRO </tr>
PRO
SELECT '<!-- '||TO_CHAR(SYSDATE, 'YYYY-MM-DD/HH24:MI:SS')||' -->' FROM dual;
PRO <!-- Please Wait -->

SELECT CHR(10)||'<tr>'||CHR(10)||
       '<td class="r">'||ROWNUM||'</td>'||CHR(10)||
       '<td class="r">'||v.sql_plan_hash_value||'</td>'||CHR(10)||
       '<td class="r">'||v.sql_plan_line_id||'</td>'||CHR(10)||
       '<td>'||v.sql_plan_operation||'</td>'||CHR(10)||
       '<td>'||v.sql_plan_options||'</td>'||CHR(10)||
       '<td>'||v.object_owner||'</td>'||CHR(10)||
       '<td>'||v.object_name||'</td>'||CHR(10)||
       '<td>'||v.session_state||'</td>'||CHR(10)||
       '<td>'||v.wait_class||'</td>'||CHR(10)||
       '<td>'||v.event||'</td>'||CHR(10)||
       '<td class="r">'||v.current_obj#||'</td>'||CHR(10)||
       '<td>'||v.current_obj_name||'</td>'||CHR(10)||
       '<td class="r">'||v.snaps_count||'</td>'||CHR(10)||
       '</tr>'
  FROM (
SELECT /*+ NO_MERGE */
       ash.sql_plan_hash_value,
       ash.sql_plan_line_id,
       ash.sql_plan_operation,
       ash.sql_plan_options,
       ash.object_owner,
       ash.object_name,
       ash.current_obj#,
       CASE
         WHEN ash.current_obj# IS NOT NULL THEN
           (SELECT obj.owner||'.'||obj.object_name||NVL2(obj.subobject_name, '.'||obj.subobject_name, NULL)
              FROM dba_hist_seg_stat_obj obj
             WHERE obj.obj# = ash.current_obj#
               AND obj.dbid = ^^dbid.
               AND ROWNUM = 1)
       END current_obj_name,
       ash.session_state,
       ash.wait_class,
       ash.event,
       COUNT(*) snaps_count
  FROM (
SELECT /*+ NO_MERGE */
       sh.sql_plan_hash_value,
       sh.sql_plan_line_id,
       sh.sql_plan_operation,
       sh.sql_plan_options,
       CASE
         WHEN sh.wait_class IN ('Application', 'Cluster', 'Concurrency', 'User I/O') THEN
           sh.current_obj#
       END current_obj#,
       sh.session_state,
       sh.wait_class,
       sh.event,
       sp.object_owner,
       sp.object_name
  FROM dba_hist_active_sess_history sh,
       dba_hist_sql_plan sp
 WHERE :license IN ('T', 'D')
   AND sh.dbid = ^^dbid.
   AND sh.sql_id = :sql_id
   AND sh.sql_plan_line_id > 0
   AND sp.dbid(+) = sh.dbid
   AND sp.sql_id(+) = sh.sql_id
   AND sp.plan_hash_value(+) = sh.sql_plan_hash_value
   AND sp.id(+) = sh.sql_plan_line_id ) ash
 GROUP BY
       ash.sql_plan_hash_value,
       ash.sql_plan_line_id,
       ash.sql_plan_operation,
       ash.sql_plan_options,
       ash.object_owner,
       ash.object_name,
       ash.session_state,
       ash.wait_class,
       ash.current_obj#,
       ash.event
 ORDER BY
       ash.sql_plan_hash_value,
       ash.sql_plan_line_id,
       12 DESC,
       ash.sql_plan_operation,
       ash.sql_plan_options,
       ash.object_owner,
       ash.object_name,
       ash.session_state,
       ash.wait_class,
       ash.current_obj#,
       ash.event ) v;

PRO
PRO <tr>
PRO <th>#</th>
PRO <th>Plan<br>Hash<br>Value</th>
PRO <th>Plan<br>Line<br>ID</th>
PRO <th>Plan<br>Operation</th>
PRO <th>Plan<br>Options</th>
PRO <th>Plan<br>Object<br>Owner</th>
PRO <th>Plan<br>Object<br>Name</th>
PRO <th>Session<br>State</th>
PRO <th>Wait<br>Class</th>
PRO <th>Event</th>
PRO <th>Curr<br>Obj<br>ID</th>
PRO <th>Curr<br>Object<br>Name</th>
PRO <th>Snaps<br>Count</th>
PRO </tr>
PRO
PRO </table>
PRO

/* -------------------------
 *
 * DBMS_STATS System Preferences
 *
 * ------------------------- */
EXEC DBMS_APPLICATION_INFO.SET_CLIENT_INFO('^^method.: DBMS_STATS System Preferences - ' || TO_CHAR(SYSDATE, 'YYYY-MM-DD/HH24:MI:SS'));
PRO <a name="dbms_stats_sys_prefs"></a><h2>DBMS_STATS System Preferences</h2>
PRO
PRO DBMS_STATS System Preferences.
PRO
PRO <table>
PRO
PRO <tr>
PRO <th>#</th>
PRO <th>Parameter Name</th>
PRO <th>Parameter Value</th>
PRO </tr>
PRO
SELECT '<!-- '||TO_CHAR(SYSDATE, 'YYYY-MM-DD/HH24:MI:SS')||' -->' FROM dual;
PRO <!-- Please Wait --> 

SELECT /* ^^script..sql DBMS_STATS System Preferences */
       CHR(10)||'<tr>'||CHR(10)||
       '<td class="r">'||ROWNUM||'</td>'||CHR(10)||
       '<td>'||v.sname||'</td>'||CHR(10)||
       '<td>'||v.spare4||'</td>'||CHR(10)||
	   '</tr>'
  FROM sys.optstat_hist_control$ v
 WHERE v.sname IN ('AUTOSTATS_TARGET', 
                   'ESTIMATE_PERCENT',
                   'DEGREE',
                   'CASCADE',
                   'NO_INVALIDATE',
                   'METHOD_OPT',
                   'GRANULARITY',
                   'STATS_RETENTION',
                   'PUBLISH',
                   'INCREMENTAL',
                   'STALE_PERCENT',
                   'APPROXIMATE_NDV',
                   'INCREMENTAL_INTERNAL_CONTROL',
                   'CONCURRENT')
ORDER BY v.sname;

PRO
PRO <tr>
PRO <th>#</th>
PRO <th>Preference Name</th>
PRO <th>Preference Value</th>
PRO </tr>
PRO
PRO <table>
/* -------------------------
 *
 * tables
 *
 * ------------------------- */
EXEC DBMS_APPLICATION_INFO.SET_CLIENT_INFO('^^method.: Tables Stats and Attributes - ' || TO_CHAR(SYSDATE, 'YYYY-MM-DD/HH24:MI:SS'));
PRO <a name="tables"></a><h2>Tables</h2>
PRO
PRO CBO Statistics and relevant attributes.
PRO
PRO <table>
PRO
PRO <tr>
PRO <th>#</th>
PRO <th>Table Name</th>
PRO <th>Owner</th>
PRO <th>Part</th>
PRO <th>DoP</th>
PRO <th>Temp</th>
PRO <th>Num Rows</th>
PRO <th>Sample<br>Size</th>
PRO <th>Perc</th>
PRO <th>Last Analyzed</th>
PRO <th>Blocks</th>
PRO <th>Avg<br>Row<br>Len</th>
PRO <th>Global<br>Stats</th>
PRO <th>User<br>Stats</th>
PRO <th>Stat<br>Type<br>Locked</th>
PRO <th>Stale<br>Stats</th>
PRO <th>Perc</th>
PRO <th>Table<br>Cols</th>
PRO <th>Indexes</th>
PRO <th>Index<br>Cols</th>
PRO <th>Stat<br>Versions</th>
PRO </tr>
PRO
SELECT '<!-- '||TO_CHAR(SYSDATE, 'YYYY-MM-DD/HH24:MI:SS')||' -->' FROM dual;
PRO <!-- Please Wait -->

SELECT /* ^^script..sql Tables */
       CHR(10)||'<tr>'||CHR(10)||
       '<td class="r">'||ROWNUM||'</td>'||CHR(10)||
       '<td>'||v.table_name||'</td>'||CHR(10)||
       '<td>'||v.owner||'</td>'||CHR(10)||
       CASE WHEN v.partitioned = 'YES' 
	     THEN '<td class="c"><a href="#tp_'||LOWER(v.table_name||'_'||v.owner)||'">'||v.partitioned||'</a></td>'
		 ELSE '<td class="c">'||v.partitioned||'</td>'
	   END||CHR(10)||
       '<td class="c">'||v.degree||'</td>'||CHR(10)||
       '<td class="c">'||v.temporary||'</td>'||CHR(10)||
       '<td class="r">'||v.num_rows||'</td>'||CHR(10)||
       '<td class="r">'||v.sample_size||'</td>'||CHR(10)||
       '<td class="r">'||v.sample_size_perc||'</td>'||CHR(10)||
       '<td nowrap>'||v.last_analyzed||'</td>'||CHR(10)||
       '<td class="r">'||v.blocks||'</td>'||CHR(10)||
       '<td class="r">'||v.avg_row_len||'</td>'||CHR(10)||
       '<td class="c">'||v.global_stats||'</td>'||CHR(10)||
       '<td class="c">'||v.user_stats||'</td>'||CHR(10)||
       '<td class="c">'||v.stattype_locked||'</td>'||CHR(10)||
       '<td class="c">'||v.stale_stats||'</td>'||CHR(10)||
       '<td class="r">'||v.stale_stats_perc||'</td>'||CHR(10)||
       '<td class="c"><a href="#c_'||LOWER(v.table_name||'_'||v.owner)||'">'||v.columns||'</a></td>'||CHR(10)||
       '<td class="c"><a href="#i_'||LOWER(v.table_name||'_'||v.owner)||'">'||v.indexes||'</a></td>'||CHR(10)||
       '<td class="c"><a href="#ic_'||LOWER(v.table_name||'_'||v.owner)||'">'||v.index_columns||'</a></td>'||CHR(10)||
	   '<td class="c"><a href="#tbl_stat_ver">Versions</a></td>'||CHR(10)||
       '</tr>'
  FROM (
WITH object AS (
SELECT /*+ MATERIALIZE */
       object_owner owner, object_name name
  FROM gv$sql_plan
 WHERE inst_id IN (SELECT inst_id FROM gv$instance)
   AND sql_id = :sql_id
   AND object_owner IS NOT NULL
   AND object_name IS NOT NULL
 UNION
SELECT object_owner owner, object_name name
  FROM dba_hist_sql_plan
 WHERE :license IN ('T', 'D')
   AND dbid = ^^dbid.
   AND sql_id = :sql_id
   AND object_owner IS NOT NULL
   AND object_name IS NOT NULL
 ), plan_tables AS (
 SELECT /*+ MATERIALIZE */
        'TABLE' object_type, t.owner object_owner, t.table_name object_name
   FROM dba_tab_statistics t, -- include fixed objects
        object o
  WHERE t.owner = o.owner
    AND t.table_name = o.name
  UNION
 SELECT 'TABLE' object_type, i.table_owner object_owner, i.table_name object_name
   FROM dba_indexes i,
        object o
  WHERE i.owner = o.owner
    AND i.index_name = o.name
)
SELECT /*+ NO_MERGE LEADING(pt s t m) */
       s.table_name,
       s.owner,
       t.partitioned,
       t.degree,
       t.temporary,
       s.num_rows,
       s.sample_size,
       CASE WHEN s.num_rows > 0 THEN TO_CHAR(ROUND(s.sample_size * 100 / s.num_rows, 1), '99999990D0') END sample_size_perc,
       TO_CHAR(s.last_analyzed, 'YYYY-MM-DD/HH24:MI:SS') last_analyzed,
       s.blocks,
       s.avg_row_len,
       s.global_stats,
       s.user_stats,
       s.stattype_locked,
       s.stale_stats,
       CASE WHEN s.num_rows > 0 THEN TO_CHAR(ROUND((m.inserts + m.updates + m.deletes) * 100 / s.num_rows, 1), '99999990D0') END stale_stats_perc,
       (SELECT COUNT(*)
          FROM dba_tab_cols c
         WHERE c.owner = s.owner
           AND c.table_name = s.table_name) columns,
       (SELECT COUNT(*)
          FROM dba_indexes i
         WHERE i.table_owner = s.owner
           AND i.table_name = s.table_name) indexes,
       (SELECT COUNT(*)
          FROM dba_ind_columns ic
         WHERE ic.table_owner = s.owner
           AND ic.table_name = s.table_name) index_columns
  FROM plan_tables pt,
       dba_tab_statistics s,
       dba_tables t,
       sys.dba_tab_modifications m -- requires sys on 10g
 WHERE pt.object_type = 'TABLE'
   AND pt.object_owner = s.owner
   AND pt.object_name = s.table_name
   AND pt.object_type = s.object_type
   AND s.owner = t.owner
   AND s.table_name = t.table_name
   AND t.owner = m.table_owner(+)
   AND t.table_name = m.table_name(+)
   AND m.partition_name IS NULL
 ORDER BY
       s.table_name,
       s.owner) v;

PRO
PRO <tr>
PRO <th>#</th>
PRO <th>Table Name</th>
PRO <th>Owner</th>
PRO <th>Part</th>
PRO <th>DoP</th>
PRO <th>Temp</th>
PRO <th>Num Rows</th>
PRO <th>Sample<br>Size</th>
PRO <th>Perc</th>
PRO <th>Last Analyzed</th>
PRO <th>Blocks</th>
PRO <th>Avg<br>Row<br>Len</th>
PRO <th>Global<br>Stats</th>
PRO <th>User<br>Stats</th>
PRO <th>Stat<br>Type<br>Locked</th>
PRO <th>Stale<br>Stats</th>
PRO <th>Perc</th>
PRO <th>Table<br>Cols</th>
PRO <th>Indexes</th>
PRO <th>Index<br>Cols</th>
PRO <th>Stat<br>Versions</th>
PRO </tr>
PRO
PRO </table>
PRO

/* -------------------------
 *
 * DBMS_STATS Table Preferences
 *
 * ------------------------- */
EXEC DBMS_APPLICATION_INFO.SET_CLIENT_INFO('^^method.: DBMS_STATS Table Preferences - ' || TO_CHAR(SYSDATE, 'YYYY-MM-DD/HH24:MI:SS'));
PRO <a name="dbms_stats_tab_prefs"></a><h2>DBMS_STATS Table Preferences</h2>
PRO
PRO DBMS_STATS Table Preferences.
PRO
PRO <table>
PRO
PRO <tr>
PRO <th>#</th>
PRO <th>Owner</th>
PRO <th>Table Name</th>
PRO <th>Obj#</th>
PRO <th>Parameter Name</th>
PRO <th>Parameter Value</th>
PRO <th>Change Time</th>
PRO </tr>
PRO
SELECT '<!-- '||TO_CHAR(SYSDATE, 'YYYY-MM-DD/HH24:MI:SS')||' -->' FROM dual;
PRO <!-- Please Wait --> 

SELECT /* ^^script..sql DBMS_STATS Table Preferences */
       CHR(10)||'<tr>'||CHR(10)||
	   '<td class="r">'||ROWNUM||'</td>'||CHR(10)||
       '<td>'||o.object_owner||'</td>'||CHR(10)||
	   '<td>'||o.object_name||'</td>'||CHR(10)||
	   '<td>'||v.obj#||'</td>'||CHR(10)||
       '<td>'||v.pname||'</td>'||CHR(10)||
       '<td>'||v.valchar||'</td>'||CHR(10)||
	   '<td>'||v.chgtime||'</td>'||CHR(10)||
	   '</tr>'
  FROM sys.optstat_user_prefs$ v,
       (WITH object AS (
          SELECT /*+ MATERIALIZE */
                 object_owner owner, object_name name, object# obj#
            FROM gv$sql_plan
           WHERE inst_id IN (SELECT inst_id FROM gv$instance)
             AND sql_id = :sql_id
             AND object_owner IS NOT NULL
             AND object_name IS NOT NULL
           UNION
          SELECT object_owner owner, object_name name, object# obj#
            FROM dba_hist_sql_plan
           WHERE :license IN ('T', 'D')
             AND dbid = ^^dbid.
             AND sql_id = :sql_id
             AND object_owner IS NOT NULL
             AND object_name IS NOT NULL
           ), plan_tables AS (
           SELECT /*+ MATERIALIZE */
                  'TABLE' object_type, t.owner object_owner, t.table_name object_name, o.obj#
             FROM dba_tables t, -- include fixed objects
                  object o
            WHERE t.owner = o.owner
              AND t.table_name = o.name
            UNION
           SELECT 'TABLE' object_type, i.table_owner object_owner, i.table_name object_name, 
		          (SELECT object_id
					 FROM dba_objects io
					WHERE io.owner = i.table_owner
					  AND io.object_name = i.table_name
					  AND io.object_type = 'TABLE') obj#
             FROM dba_indexes i,
                  object o
            WHERE i.owner = o.owner
              AND i.index_name = o.name
          ) 
		  SELECT object_owner, object_name, obj#
		    FROM plan_tables
          )	o	  
 WHERE v.obj# = o.obj#
ORDER BY o.obj#, v.pname;

PRO
PRO <tr>
PRO <th>#</th>
PRO <th>Owner</th>
PRO <th>Table Name</th>
PRO <th>Obj#</th>
PRO <th>Parameter Name</th>
PRO <th>Parameter Value</th>
PRO <th>Change Time</th>
PRO </tr>
PRO
PRO <table>


/* -------------------------
 *
 * table columns
 *
 * ------------------------- */
EXEC DBMS_APPLICATION_INFO.SET_CLIENT_INFO('^^method.: Table Columns - ' || TO_CHAR(SYSDATE, 'YYYY-MM-DD/HH24:MI:SS'));
PRO <a name="tbl_cols"></a><h2>Table Columns</h2>
PRO
SELECT '<!-- '||TO_CHAR(SYSDATE, 'YYYY-MM-DD/HH24:MI:SS')||' -->' FROM dual;
PRO <!-- Please Wait -->

SELECT /* ^^script..sql Table Columns */
       v2.line_text
  FROM (
WITH object AS (
SELECT /*+ MATERIALIZE */
       object_owner owner, object_name name
  FROM gv$sql_plan
 WHERE inst_id IN (SELECT inst_id FROM gv$instance)
   AND sql_id = :sql_id
   AND object_owner IS NOT NULL
   AND object_name IS NOT NULL
 UNION
SELECT object_owner owner, object_name name
  FROM dba_hist_sql_plan
 WHERE :license IN ('T', 'D')
   AND dbid = ^^dbid.
   AND sql_id = :sql_id
   AND object_owner IS NOT NULL
   AND object_name IS NOT NULL
 ), plan_tables AS (
 SELECT /*+ MATERIALIZE */
        'TABLE' object_type, t.owner object_owner, t.table_name object_name
   FROM dba_tab_statistics t, -- include fixed objects
        object o
  WHERE t.owner = o.owner
    AND t.table_name = o.name
  UNION
 SELECT 'TABLE' object_type, i.table_owner object_owner, i.table_name object_name
   FROM dba_indexes i,
        object o
  WHERE i.owner = o.owner
    AND i.index_name = o.name
)
SELECT object_name table_name,
       object_owner owner,
       1 line_type,
       1 row_num,
       '<a name="c_'||LOWER(object_name||'_'||object_owner)||'"></a><h3>Table Columns: '||object_name||' ('||object_owner||')</h3>'||CHR(10)||CHR(10)||
       'CBO Statistics and relevant attributes.'||CHR(10)||CHR(10)||
       '<table>'||CHR(10)||CHR(10)||
       '<tr>'||CHR(10)||
       '<th>#</th>'||CHR(10)||
       --'<th>Table Name</th>'||CHR(10)||
       --'<th>Owner</th>'||CHR(10)||
       '<th>Indexes</th>'||CHR(10)||
       '<th>Col<br>ID</th>'||CHR(10)||
       '<th>Column Name</th>'||CHR(10)||
       '<th>Data<br>Type</th>'||CHR(10)||
       '<th>Num<br>Rows</th>'||CHR(10)||
       '<th>Num<br>Nulls</th>'||CHR(10)||
       '<th>Sample<br>Size</th>'||CHR(10)||
       '<th>Perc</th>'||CHR(10)||
       '<th>Num<br>Distinct</th>'||CHR(10)||
       '<th>Low Value</th>'||CHR(10)||
       '<th>High Value</th>'||CHR(10)||
       '<th>Last Analyzed</th>'||CHR(10)||
       '<th>Avg<br>Col<br>Len</th>'||CHR(10)||
       '<th>Density</th>'||CHR(10)||
       '<th>Num<br>Buckets</th>'||CHR(10)||
       '<th>Histogram</th>'||CHR(10)||
       '<th>Global<br>Stats</th>'||CHR(10)||
       '<th>User<br>Stats</th>'||CHR(10)||
       '</tr>'||CHR(10) line_text
  FROM plan_tables
 WHERE object_type = 'TABLE'
 UNION ALL
SELECT v.table_name,
       v.owner,
       2 line_type,
       ROWNUM row_num,
       CHR(10)||'<tr>'||CHR(10)||
       '<td class="r">'||ROWNUM||'</td>'||CHR(10)||
       --'<td>'||v.table_name||'</td>'||CHR(10)||
       --'<td>'||v.owner||'</td>'||CHR(10)||
       '<td class="c">'||v.indexes||'</td>'||CHR(10)||
       '<td class="c">'||v.column_id||'</td>'||CHR(10)||
       '<td>'||v.column_name||'</td>'||CHR(10)||
       '<td>'||v.data_type||'</td>'||CHR(10)||
       '<td class="r">'||v.num_rows||'</td>'||CHR(10)||
       '<td class="r">'||v.num_nulls||'</td>'||CHR(10)||
       '<td class="r">'||v.sample_size||'</td>'||CHR(10)||
       '<td class="r">'||v.sample_size_perc||'</td>'||CHR(10)||
       '<td class="r">'||v.num_distinct||'</td>'||CHR(10)||
       '<td nowrap>'||v.low_value||'</td>'||CHR(10)||
       '<td nowrap>'||v.high_value||'</td>'||CHR(10)||
       '<td nowrap>'||v.last_analyzed||'</td>'||CHR(10)||
       '<td class="r">'||v.avg_col_len||'</td>'||CHR(10)||
       '<td class="r">'||v.density||'</td>'||CHR(10)||
       '<td class="r">'||v.num_buckets||'</td>'||CHR(10)||
       '<td>'||v.histogram||'</td>'||CHR(10)||
       '<td class="c">'||v.global_stats||'</td>'||CHR(10)||
       '<td class="c">'||v.user_stats||'</td>'||CHR(10)||
       '</tr>'||CHR(10) line_text
  FROM (
SELECT /*+ NO_MERGE LEADING(pt t c) */
       t.table_name,
       t.owner,
       NVL(ic.index_count,0) indexes,
       c.column_id,
       c.column_name,
       c.data_type,
       c.data_default,
       t.num_rows,
       c.num_nulls,
       c.sample_size,
       CASE
       WHEN t.num_rows > c.num_nulls THEN TO_CHAR(LEAST(100, ROUND(c.sample_size * 100 / (t.num_rows - c.num_nulls), 1)), '99999990D0')
       WHEN t.num_rows = c.num_nulls THEN TO_CHAR(100, '99999990D0')
       END sample_size_perc,
       c.num_distinct,
       c.low_value,
       c.high_value high_value,
       TO_CHAR(c.last_analyzed, 'YYYY-MM-DD/HH24:MI:SS') last_analyzed,
       c.avg_col_len,
       LOWER(TO_CHAR(c.density, '0D000000EEEE')) density,
       c.num_buckets,
       c.histogram,
       c.global_stats,
       c.user_stats
  FROM plan_tables pt,
       dba_tables t,
       dba_tab_cols c,
       (SELECT i.table_owner,
               i.table_name,
               i.column_name,
               COUNT(*) index_count
          FROM dba_ind_columns i
         GROUP BY
               i.table_owner,
               i.table_name,
               i.column_name ) ic
 WHERE pt.object_type = 'TABLE'
   AND pt.object_owner = t.owner
   AND pt.object_name = t.table_name
   AND t.owner = c.owner
   AND t.table_name = c.table_name
   AND ic.table_owner (+) = c.owner
   AND ic.table_name (+) = c.table_name
   AND ic.column_name (+) = c.column_name
 ORDER BY
       t.table_name,
       t.owner,
       NVL(ic.index_count,0) DESC,
       c.column_id NULLS LAST,
       c.column_name) v
 UNION ALL
SELECT object_name table_name,
       object_owner owner,
       3 line_type,
       1 row_num,
       '<tr>'||CHR(10)||
       '<th>#</th>'||CHR(10)||
       --'<th>Table Name</th>'||CHR(10)||
       --'<th>Owner</th>'||CHR(10)||
       '<th>Indexes</th>'||CHR(10)||
       '<th>Col<br>ID</th>'||CHR(10)||
       '<th>Column Name</th>'||CHR(10)||
       '<th>Data<br>Type</th>'||CHR(10)||
       '<th>Num<br>Rows</th>'||CHR(10)||
       '<th>Num<br>Nulls</th>'||CHR(10)||
       '<th>Sample<br>Size</th>'||CHR(10)||
       '<th>Perc</th>'||CHR(10)||
       '<th>Num<br>Distinct</th>'||CHR(10)||
       '<th>Low Value</th>'||CHR(10)||
       '<th>High Value</th>'||CHR(10)||
       '<th>Last Analyzed</th>'||CHR(10)||
       '<th>Avg<br>Col<br>Len</th>'||CHR(10)||
       '<th>Density</th>'||CHR(10)||
       '<th>Num<br>Buckets</th>'||CHR(10)||
       '<th>Histogram</th>'||CHR(10)||
       '<th>Global<br>Stats</th>'||CHR(10)||
       '<th>User<br>Stats</th>'||CHR(10)||
       '</tr>'||CHR(10) line_text
  FROM plan_tables
 WHERE object_type = 'TABLE'
 UNION ALL
SELECT object_name table_name,
       object_owner owner,
       4 line_type,
       1 row_num,
       CHR(10)||'</table>'||CHR(10)||CHR(10) line_text
  FROM plan_tables
 WHERE object_type = 'TABLE') v2
 ORDER BY
       v2.table_name,
       v2.owner,
       v2.line_type,
       v2.row_num;

	   
/* -------------------------
 *
 * table partitions
 *
 * ------------------------- */
EXEC DBMS_APPLICATION_INFO.SET_CLIENT_INFO('^^method.: Table Partitions - ' || TO_CHAR(SYSDATE, 'YYYY-MM-DD/HH24:MI:SS'));
PRO <a name="tbl_parts"></a><h2>Table Partitions</h2>
PRO
SELECT '<!-- '||TO_CHAR(SYSDATE, 'YYYY-MM-DD/HH24:MI:SS')||' -->' FROM dual;
PRO <!-- Please Wait -->	

SELECT /* ^^script..sql Table Partitions */
       v2.line_text
  FROM (
WITH object AS (
SELECT /*+ MATERIALIZE */
       object_owner owner, object_name name
  FROM gv$sql_plan
 WHERE inst_id IN (SELECT inst_id FROM gv$instance)
   AND sql_id = :sql_id
   AND object_owner IS NOT NULL
   AND object_name IS NOT NULL
 UNION
SELECT object_owner owner, object_name name
  FROM dba_hist_sql_plan
 WHERE :license IN ('T', 'D')
   AND dbid = ^^dbid.
   AND sql_id = :sql_id
   AND object_owner IS NOT NULL
   AND object_name IS NOT NULL
 ), plan_tables AS (
 SELECT /*+ MATERIALIZE */
        'TABLE' object_type, p.table_owner object_owner, p.table_name object_name
   FROM dba_tab_partitions p, -- include fixed objects
        object o
  WHERE p.table_owner = o.owner
    AND p.table_name = o.name
  UNION
 SELECT 'TABLE' object_type, i.table_owner object_owner, i.table_name object_name
   FROM dba_indexes i,
        dba_ind_partitions p,
        object o
  WHERE i.owner = o.owner
    AND i.index_name = o.name
	AND i.owner = p.index_owner(+)  -- partitioned table but not part index in the plan
	AND i.index_name = p.index_name(+)  -- same as above
)
SELECT object_name table_name,
       object_owner owner,
       1 line_type,
       1 row_num,
       '<a name="tp_'||LOWER(object_name||'_'||object_owner)||'"></a><h3>Table Partitions: '||object_name||' ('||object_owner||')</h3>'||CHR(10)||CHR(10)||
       'Table partitions and relevant attributes (only the first and last 100).'||CHR(10)||CHR(10)||
       '<table>'||CHR(10)||CHR(10)||
       '<tr>'||CHR(10)||
       '<th>#</th>'||CHR(10)||
       '<th>Partition<br>Position</th>'||CHR(10)||
       '<th>Partition<br>Name</th>'||CHR(10)||
       '<th>Composite</th>'||CHR(10)||
       '<th>Subpartition<br>Count</th>'||CHR(10)||
       '<th>Num<br>Rows</th>'||CHR(10)||
       '<th>Sample<br>Size</th>'||CHR(10)||
       '<th>Perc</th>'||CHR(10)||
       '<th>Last Analyzed</th>'||CHR(10)||
       '<th>Blocks</th>'||CHR(10)||    
       '<th>Avg<br>Row<br>Len</th>'||CHR(10)||
       '<th>Global<br>Stats</th>'||CHR(10)||
       '<th>User<br>Stats</th>'||CHR(10)||
       '<th>Staleness<br>Perc</th>'||CHR(10)||
       '</tr>'||CHR(10) line_text
  FROM plan_tables
 WHERE object_type = 'TABLE'
 UNION ALL
SELECT v.table_name,
       v.table_owner,
       2 line_type,
       ROWNUM row_num,
       CHR(10)||'<tr>'||CHR(10)||
       '<td class="r">'||ROWNUM||'</td>'||CHR(10)||
	   '<td class="c">'||v.partition_position||'</td>'||CHR(10)||
       '<td class="c">'||v.partition_name||'</td>'||CHR(10)||
       '<td class="c">'||v.composite||'</td>'||CHR(10)||
       '<td class="r">'||v.subpartition_count||'</td>'||CHR(10)||
       '<td class="r">'||v.num_rows||'</td>'||CHR(10)||
       '<td class="r">'||v.sample_size||'</td>'||CHR(10)||
       '<td class="r">'||v.sample_size_perc||'</td>'||CHR(10)||
       '<td nowrap>'||v.last_analyzed||'</td>'||CHR(10)||
       '<td class="r">'||v.blocks||'</td>'||CHR(10)||
       '<td class="r">'||v.avg_row_len||'</td>'||CHR(10)||
       '<td class="c">'||v.global_stats||'</td>'||CHR(10)||
       '<td class="c">'||v.user_stats||'</td>'||CHR(10)||
       '<td class="r">'||v.staleness_perc||'</td>'||CHR(10)||
       '</tr>'
  FROM (
SELECT DISTINCT v.table_name,
       v.table_owner,
	   v.partition_name,
	   v.partition_position,
	   v.subpartition_count,
	   v.composite,
       v.num_rows,
       v.sample_size,
       v.sample_size_perc,
       v.last_analyzed,
       v.blocks,
       v.avg_row_len,
       v.global_stats,
       v.user_stats,
       v.staleness_perc
  FROM (  
SELECT /*+ NO_MERGE LEADING(pt s m) */
       s.table_name,
       s.table_owner,
	   s.partition_name,
	   s.partition_position,
	   s.subpartition_count,
	   s.composite,
       s.num_rows,
       s.sample_size,
       CASE WHEN s.num_rows > 0 THEN TO_CHAR(ROUND(s.sample_size * 100 / s.num_rows, 1), '99999990D0') END sample_size_perc,
       TO_CHAR(s.last_analyzed, 'YYYY-MM-DD/HH24:MI:SS') last_analyzed,
       s.blocks,
       s.avg_row_len,
       s.global_stats,
       s.user_stats,
       CASE WHEN s.num_rows > 0 THEN TO_CHAR(ROUND((m.inserts + m.updates + m.deletes) * 100 / s.num_rows, 1), '99999990D0') END staleness_perc,
	   ROW_NUMBER() OVER (PARTITION BY s.table_owner, s.table_name ORDER BY s.partition_position DESC) row_num 
  FROM plan_tables pt,
       dba_tab_partitions s,
       sys.dba_tab_modifications m -- requires sys on 10g
 WHERE pt.object_type = 'TABLE'
   AND pt.object_owner = s.table_owner
   AND pt.object_name = s.table_name
   AND s.table_owner = m.table_owner(+)
   AND s.table_name = m.table_name(+)
   AND s.partition_name = m.partition_name(+)
UNION 
SELECT /*+ NO_MERGE LEADING(pt s m) */
       s.table_name,
       s.table_owner,
	   s.partition_name,
	   s.partition_position,
	   s.subpartition_count,
	   s.composite,
       s.num_rows,
       s.sample_size,
       CASE WHEN s.num_rows > 0 THEN TO_CHAR(ROUND(s.sample_size * 100 / s.num_rows, 1), '99999990D0') END sample_size_perc,
       TO_CHAR(s.last_analyzed, 'YYYY-MM-DD/HH24:MI:SS') last_analyzed,
       s.blocks,
       s.avg_row_len,
       s.global_stats,
       s.user_stats,
       CASE WHEN s.num_rows > 0 THEN TO_CHAR(ROUND((m.inserts + m.updates + m.deletes) * 100 / s.num_rows, 1), '99999990D0') END staleness_perc,
	   ROW_NUMBER() OVER (PARTITION BY s.table_owner, s.table_name ORDER BY s.partition_position ASC) row_num 
  FROM plan_tables pt,
       dba_tab_partitions s,
       sys.dba_tab_modifications m -- requires sys on 10g
 WHERE pt.object_type = 'TABLE'
   AND pt.object_owner = s.table_owner
   AND pt.object_name = s.table_name
   AND s.table_owner = m.table_owner(+)
   AND s.table_name = m.table_name(+)
   AND s.partition_name = m.partition_name(+)   
   ) v
 WHERE v.row_num BETWEEN 1 AND 100
 ORDER BY
       v.table_name,
       v.table_owner,
	   v.partition_position DESC) v
 UNION ALL
SELECT object_name table_name,
       object_owner owner,
       3 line_type,
       1 row_num,
       '<tr>'||CHR(10)||
       '<th>#</th>'||CHR(10)||
       '<th>Partition<br>Position</th>'||CHR(10)||
       '<th>Partition<br>Name</th>'||CHR(10)||
       '<th>Composite</th>'||CHR(10)||
       '<th>Subpartition<br>Count</th>'||CHR(10)||
       '<th>Num<br>Rows</th>'||CHR(10)||
       '<th>Sample<br>Size</th>'||CHR(10)||
       '<th>Perc</th>'||CHR(10)||
       '<th>Last Analyzed</th>'||CHR(10)||
       '<th>Blocks</th>'||CHR(10)||    
       '<th>Avg<br>Row<br>Len</th>'||CHR(10)||
       '<th>Global<br>Stats</th>'||CHR(10)||
       '<th>User<br>Stats</th>'||CHR(10)||
       '<th>Staleness<br>Perc</th>'||CHR(10)||
       '</tr>'||CHR(10) line_text
  FROM plan_tables
 WHERE object_type = 'TABLE'
 UNION ALL
SELECT object_name table_name,
       object_owner owner,
       4 line_type,
       1 row_num,
       CHR(10)||'</table>'||CHR(10)||CHR(10) line_text
  FROM plan_tables
 WHERE object_type = 'TABLE') v2
 ORDER BY
       v2.table_name,
       v2.owner,
       v2.line_type,
       v2.row_num;	      
	   
/* -------------------------
 *
 * table constraints
 *
 * ------------------------- */
EXEC DBMS_APPLICATION_INFO.SET_CLIENT_INFO('^^method.: Table Constraints - ' || TO_CHAR(SYSDATE, 'YYYY-MM-DD/HH24:MI:SS'));
PRO <a name="tbl_constr"></a><h2>Table Constraints</h2>
PRO
SELECT '<!-- '||TO_CHAR(SYSDATE, 'YYYY-MM-DD/HH24:MI:SS')||' -->' FROM dual;
PRO <!-- Please Wait -->	

SELECT /* ^^script..sql Table Constraints */
       v2.line_text
  FROM (
WITH object AS (
SELECT /*+ MATERIALIZE */
       object_owner owner, object_name name
  FROM gv$sql_plan
 WHERE inst_id IN (SELECT inst_id FROM gv$instance)
   AND sql_id = :sql_id
   AND object_owner IS NOT NULL
   AND object_name IS NOT NULL
 UNION
SELECT object_owner owner, object_name name
  FROM dba_hist_sql_plan
 WHERE dbid = ^^dbid.
   AND sql_id = :sql_id
   AND object_owner IS NOT NULL
   AND object_name IS NOT NULL
 ), plan_tables AS (
 SELECT /*+ MATERIALIZE */
        'TABLE' object_type, p.owner object_owner, p.table_name object_name
   FROM dba_tables p, -- include fixed objects
        object o
  WHERE p.owner = o.owner
    AND p.table_name = o.name
  UNION
 SELECT 'TABLE' object_type, i.table_owner object_owner, i.table_name object_name
   FROM dba_indexes i,
        object o
  WHERE i.owner = o.owner
    AND i.index_name = o.name
)
SELECT object_name table_name,
       object_owner owner,
       1 line_type,
       1 row_num,
       '<a name="tc_'||LOWER(object_name||'_'||object_owner)||'"></a><h3>Table Constraints: '||object_name||' ('||object_owner||')</h3>'||CHR(10)||CHR(10)||
       'Table constraints and relevant attributes.'||CHR(10)||CHR(10)||
       '<table>'||CHR(10)||CHR(10)||
       '<tr>'||CHR(10)||
       '<th>#</th>'||CHR(10)||
       '<th>Constraint<br>Name</th>'||CHR(10)||
       '<th>Constraint<br>Type</th>'||CHR(10)||
    --  '<th>Search<br>Condition</th>'||CHR(10)||
       '<th>R Owner</th>'||CHR(10)||
       '<th>R Constraint<br>Name</th>'||CHR(10)||
       '<th>Delete<br>Rule</th>'||CHR(10)||
       '<th>Status</th>'||CHR(10)||
       '<th>Defferable</th>'||CHR(10)||    
       '<th>Deferred</th>'||CHR(10)||
       '<th>Validated</th>'||CHR(10)||
       '<th>Generated</th>'||CHR(10)||
       '<th>Rely</th>'||CHR(10)||
	   '<th>Last<br>Change</th>'||CHR(10)||
	   '<th>Index<br>Owner</th>'||CHR(10)||
	   '<th>Index<br>Name</th>'||CHR(10)||
	   '<th>Invalid</th>'||CHR(10)||
	   '<th>View<br>Related</th>'||CHR(10)||
       '</tr>'||CHR(10) line_text
  FROM plan_tables
 WHERE object_type = 'TABLE'
 UNION ALL
SELECT v.table_name,
       v.owner,
       2 line_type,
       ROWNUM row_num,
       CHR(10)||'<tr>'||CHR(10)||
       '<td class="r">'||ROWNUM||'</td>'||CHR(10)||
	   '<td class="c">'||v.constraint_name||'</td>'||CHR(10)||
       '<td class="c">'||v.constraint_type||'</td>'||CHR(10)||
     --  '<td class="c">'||v.search_condition||'</td>'||CHR(10)||
       '<td class="r">'||v.r_owner||'</td>'||CHR(10)||
       '<td class="r">'||v.r_constraint_name||'</td>'||CHR(10)||
       '<td class="r">'||v.delete_rule||'</td>'||CHR(10)||
       '<td class="r">'||v.status||'</td>'||CHR(10)||
       '<td class="r">'||v.deferrable||'</td>'||CHR(10)||
       '<td class="r">'||v.deferred||'</td>'||CHR(10)||
       '<td class="r">'||v.validated||'</td>'||CHR(10)||
       '<td class="c">'||v.generated||'</td>'||CHR(10)||
       '<td class="c">'||v.rely||'</td>'||CHR(10)||
       '<td class="r">'||v.last_change||'</td>'||CHR(10)||
	   '<td class="r">'||v.index_owner||'</td>'||CHR(10)||
	   '<td class="r">'||v.index_name||'</td>'||CHR(10)||
	   '<td class="r">'||v.invalid||'</td>'||CHR(10)||
	   '<td class="r">'||v.view_related||'</td>'||CHR(10)||
       '</tr>'
  FROM (  
SELECT /*+ NO_MERGE LEADING(pt s) */
       s.table_name,
       s.owner,
       s.constraint_name,
	   s.constraint_type,
	  -- dbms_lob.substr(s.search_condition,1,100) search_condition,
	   s.r_owner,
	   s.r_constraint_name,
       s.delete_rule,
       s.status,
       s.deferrable,
       s.deferred,
       s.validated,
       s.generated,
       s.rely,
       s.last_change,
       s.index_owner,
	   s.index_name,
	   s.invalid,
	   s.view_related
  FROM plan_tables pt,
       dba_constraints s
 WHERE pt.object_type = 'TABLE'
   AND pt.object_owner = s.owner
   AND pt.object_name = s.table_name) v
 UNION ALL
SELECT object_name table_name,
       object_owner owner,
       3 line_type,
       1 row_num,
       '<tr>'||CHR(10)||
       '<th>#</th>'||CHR(10)||
       '<th>Constraint<br>Name</th>'||CHR(10)||
       '<th>Constraint<br>Type</th>'||CHR(10)||
     --  '<th>Search<br>Condition</th>'||CHR(10)||
       '<th>R Owner</th>'||CHR(10)||
       '<th>R Constraint<br>Name</th>'||CHR(10)||
       '<th>Delete<br>Rule</th>'||CHR(10)||
       '<th>Status</th>'||CHR(10)||
       '<th>Defferable</th>'||CHR(10)||    
       '<th>Deferred</th>'||CHR(10)||
       '<th>Validated</th>'||CHR(10)||
       '<th>Generated</th>'||CHR(10)||
       '<th>Rely</th>'||CHR(10)||
	   '<th>Last<br>Change</th>'||CHR(10)||
	   '<th>Index<br>Owner</th>'||CHR(10)||
	   '<th>Index<br>Name</th>'||CHR(10)||
	   '<th>Invalid</th>'||CHR(10)||
	   '<th>View<br>Related</th>'||CHR(10)||
       '</tr>'||CHR(10) line_text
  FROM plan_tables
 WHERE object_type = 'TABLE'
 UNION ALL
SELECT object_name table_name,
       object_owner owner,
       4 line_type,
       1 row_num,
       CHR(10)||'</table>'||CHR(10)||CHR(10) line_text
  FROM plan_tables
 WHERE object_type = 'TABLE') v2
 ORDER BY
       v2.table_name,
       v2.owner,
       v2.line_type,
       v2.row_num;		 
	   
/* -------------------------
 *
 * tables statistics version
 *
 * ------------------------- */
EXEC DBMS_APPLICATION_INFO.SET_CLIENT_INFO('^^method.: Tables Statistics versions - ' || TO_CHAR(SYSDATE, 'YYYY-MM-DD/HH24:MI:SS'));
PRO <a name="tbl_stat_ver"></a><h2>Tables Statistics Versions</h2>
PRO
PRO CBO Statistics and relevant attributes.
PRO
PRO <table>
PRO
PRO <tr>
PRO <th>#</th>
PRO <th>Table Name</th>
PRO <th>Owner</th>
PRO <th>Version Type</th>
PRO <th>Save Time</th>
PRO <th>Last Analyzed</th>
PRO <th>Num Rows</th>
PRO <th>Sample<br>Size</th>
PRO <th>Perc</th>
PRO <th>Blocks</th>
PRO <th>Avg<br>Row<br>Len</th>
PRO </tr>
PRO
SELECT '<!-- '||TO_CHAR(SYSDATE, 'YYYY-MM-DD/HH24:MI:SS')||' -->' FROM dual;
PRO <!-- Please Wait -->
	   
SELECT /* ^^script..sql Tables Statistics Versions */
       CHR(10)||'<tr>'||CHR(10)||
       '<td class="r">'||ROWNUM||'</td>'||CHR(10)||
       '<td>'||v.object_name||'</td>'||CHR(10)||
       '<td>'||v.owner||'</td>'||CHR(10)||
       '<td>'||v.version_type||'</td>'||CHR(10)||	   
       '<td nowrap>'||v.savtime||'</td>'||CHR(10)||
	   '<td nowrap>'||v.analyzetime||'</td>'||CHR(10)||
       '<td class="r">'||v.rowcnt||'</td>'||CHR(10)||
       '<td class="r">'||v.samplesize||'</td>'||CHR(10)||
       '<td class="c">'||v.perc||'</td>'||CHR(10)||
       '<td class="c">'||v.blkcnt||'</td>'||CHR(10)||
       '<td class="c">'||v.avgrln||'</td>'||CHR(10)||
       '</tr>'
  FROM (
WITH object AS (
SELECT /*+ MATERIALIZE */
       object_owner owner, object_name name
  FROM gv$sql_plan
 WHERE inst_id IN (SELECT inst_id FROM gv$instance)
   AND sql_id = :sql_id
   AND object_owner IS NOT NULL
   AND object_name IS NOT NULL
 UNION
SELECT object_owner owner, object_name name
  FROM dba_hist_sql_plan
 WHERE :license IN ('T', 'D')
   AND dbid = ^^dbid.
   AND sql_id = :sql_id
   AND object_owner IS NOT NULL
   AND object_name IS NOT NULL
 ), plan_tables AS (
 SELECT /*+ MATERIALIZE */
        'TABLE' object_type, t.owner object_owner, t.table_name object_name
   FROM dba_tab_statistics t, -- include fixed objects
        object o
  WHERE t.owner = o.owner
    AND t.table_name = o.name
  UNION
 SELECT 'TABLE' object_type, i.table_owner object_owner, i.table_name object_name
   FROM dba_indexes i,
        object o
  WHERE i.owner = o.owner
    AND i.index_name = o.name
)
SELECT *
  FROM (
SELECT /*+ NO_MERGE LEADING(pt s t m) */
       t.table_name object_name,
       t.owner,
	   'CURRENT' version_type,
       NULL savtime, 
	   t.last_analyzed analyzetime, 
	   t.num_rows rowcnt, 
	   t.sample_size samplesize, 
	   CASE WHEN t.num_rows > 0 THEN TO_CHAR(ROUND(t.sample_size * 100 / t.num_rows, 1), '99999990D0') END perc, 
	   t.blocks blkcnt, 
	   t.avg_row_len avgrln
  FROM plan_tables pt,
       dba_tables t
 WHERE pt.object_type = 'TABLE'
   AND pt.object_owner = t.owner
   AND pt.object_name = t.table_name
UNION ALL
SELECT /*+ NO_MERGE LEADING(pt s t m) */
       t.object_name,
       t.owner,
	   'HISTORY' version_type,
       h.savtime, 
	   h.analyzetime, 
	   h.rowcnt, 
	   h.samplesize, 
	   CASE WHEN h.rowcnt > 0 THEN TO_CHAR(ROUND(h.samplesize * 100 / h.rowcnt, 1), '99999990D0') END perc, 
	   h.blkcnt, 
	   h.avgrln
  FROM plan_tables pt,
       dba_objects t,
	   sys.WRI$_OPTSTAT_TAB_HISTORY h
 WHERE pt.object_type = 'TABLE'
   AND pt.object_owner = t.owner
   AND pt.object_name = t.object_name
   AND t.object_id = h.obj#
   AND t.object_type = 'TABLE')
 ORDER BY
       object_name,
       owner,
	   savtime DESC NULLS FIRST) v;	   

PRO
PRO <tr>
PRO <th>#</th>
PRO <th>Table Name</th>
PRO <th>Owner</th>
PRO <th>Version Type</th>
PRO <th>Save Time</th>
PRO <th>Last Analyzed</th>
PRO <th>Num Rows</th>
PRO <th>Sample<br>Size</th>
PRO <th>Perc</th>
PRO <th>Blocks</th>
PRO <th>Avg<br>Row<br>Len</th>
PRO </tr>
PRO
PRO </table>
PRO
	   
/* -------------------------
 *
 * indexes
 *
 * ------------------------- */
EXEC DBMS_APPLICATION_INFO.SET_CLIENT_INFO('^^method.: Indexes details - ' || TO_CHAR(SYSDATE, 'YYYY-MM-DD/HH24:MI:SS'));
PRO <a name="indexes"></a><h2>Indexes</h2>
PRO
SELECT '<!-- '||TO_CHAR(SYSDATE, 'YYYY-MM-DD/HH24:MI:SS')||' -->' FROM dual;
PRO <!-- Please Wait -->

SELECT /* ^^script..sql Indexes */
       v2.line_text
  FROM (
WITH object AS (
SELECT /*+ MATERIALIZE */
       object_owner owner, object_name name
  FROM gv$sql_plan
 WHERE inst_id IN (SELECT inst_id FROM gv$instance)
   AND sql_id = :sql_id
   AND object_owner IS NOT NULL
   AND object_name IS NOT NULL
 UNION
SELECT object_owner owner, object_name name
  FROM dba_hist_sql_plan
 WHERE :license IN ('T', 'D')
   AND dbid = ^^dbid.
   AND sql_id = :sql_id
   AND object_owner IS NOT NULL
   AND object_name IS NOT NULL
 ), plan_tables AS (
 SELECT /*+ MATERIALIZE */
        'TABLE' object_type, t.owner object_owner, t.table_name object_name
   FROM dba_tab_statistics t, -- include fixed objects
        object o
  WHERE t.owner = o.owner
    AND t.table_name = o.name
  UNION
 SELECT 'TABLE' object_type, i.table_owner object_owner, i.table_name object_name
   FROM dba_indexes i,
        object o
  WHERE i.owner = o.owner
    AND i.index_name = o.name
)
SELECT object_name table_name,
       object_owner owner,
       1 line_type,
       1 row_num,
       '<a name="i_'||LOWER(object_name||'_'||object_owner)||'"></a><h3>Indexes: '||object_name||' ('||object_owner||')</h3>'||CHR(10)||CHR(10)||
       'CBO Statistics and relevant attributes.'||CHR(10)||CHR(10)||
       '<table>'||CHR(10)||CHR(10)||
       '<tr>'||CHR(10)||
       '<th>#</th>'||CHR(10)||
       --'<th>Table Name</th>'||CHR(10)||
       --'<th>Owner</th>'||CHR(10)||
       '<th>Index Name</th>'||CHR(10)||
       '<th>Owner</th>'||CHR(10)||
       '<th>Index Type</th>'||CHR(10)||
       '<th>Part</th>'||CHR(10)||
       '<th>DoP</th>'||CHR(10)||
       '<th>Temp</th>'||CHR(10)||
       '<th>Uniqueness</th>'||CHR(10)||
       '<th>Cols</th>'||CHR(10)||
       '<th>Num<br>Rows</th>'||CHR(10)||
       '<th>Sample<br>Size</th>'||CHR(10)||
       '<th>Perc</th>'||CHR(10)||
       '<th>Last Analyzed</th>'||CHR(10)||
       '<th>Distinct<br>Keys</th>'||CHR(10)||
       '<th>Blevel</th>'||CHR(10)||
       '<th>Leaf<br>Blocks</th>'||CHR(10)||
       '<th>Avg<br>Leaf<br>Blocks<br>per Key</th>'||CHR(10)||
       '<th>Avg<br>Data<br>Blocks<br>per Key</th>'||CHR(10)||
       '<th>Clustering<br>Factor</th>'||CHR(10)||
       '<th>Global<br>Stats</th>'||CHR(10)||
       '<th>User<br>Stats</th>'||CHR(10)||
       '<th>Stat<br>Type<br>Locked</th>'||CHR(10)||
       '<th>Stale<br>Stats</th>'||CHR(10)||
	   '<th>Stats<br>Versions</th>'||CHR(10)||
       '</tr>'||CHR(10) line_text
  FROM plan_tables
 WHERE object_type = 'TABLE'
 UNION ALL
SELECT v.table_name,
       v.table_owner owner,
       2 line_type,
       ROWNUM row_num,
       CHR(10)||'<tr>'||CHR(10)||
       '<td class="r">'||ROWNUM||'</td>'||CHR(10)||
       --'<td>'||v.table_name||'</td>'||CHR(10)||
       --'<td>'||v.table_owner||'</td>'||CHR(10)||
       '<td>'||v.index_name||'</td>'||CHR(10)||
       '<td>'||v.owner||'</td>'||CHR(10)||
       '<td>'||v.index_type||'</td>'||CHR(10)||
	   CASE WHEN v.partitioned = 'YES' 
	     THEN '<td class="c"><a href="#ip_'||LOWER(v.table_name||'_'||v.table_owner)||'">'||v.partitioned||'</a></td>'
		 ELSE '<td class="c">'||v.partitioned||'</td>'
	   END||CHR(10)||
       '<td class="c">'||v.degree||'</td>'||CHR(10)||
       '<td class="c">'||v.temporary||'</td>'||CHR(10)||
       '<td>'||v.uniqueness||'</td>'||CHR(10)||
       '<td class="c"><a href="#ic_'||LOWER(v.index_name||'_'||v.owner)||'">'||v.columns||'</a></td>'||CHR(10)||
       '<td class="r">'||v.num_rows||'</td>'||CHR(10)||
       '<td class="r">'||v.sample_size||'</td>'||CHR(10)||
       '<td class="r">'||v.sample_size_perc||'</td>'||CHR(10)||
       '<td nowrap>'||v.last_analyzed||'</td>'||CHR(10)||
       '<td class="r">'||v.distinct_keys||'</td>'||CHR(10)||
       '<td class="r">'||v.blevel||'</td>'||CHR(10)||
       '<td class="r">'||v.leaf_blocks||'</td>'||CHR(10)||
       '<td class="r">'||v.avg_leaf_blocks_per_key||'</td>'||CHR(10)||
       '<td class="r">'||v.avg_data_blocks_per_key||'</td>'||CHR(10)||
       '<td class="r">'||v.clustering_factor||'</td>'||CHR(10)||
       '<td class="c">'||v.global_stats||'</td>'||CHR(10)||
       '<td class="c">'||v.user_stats||'</td>'||CHR(10)||
       '<td class="c">'||v.stattype_locked||'</td>'||CHR(10)||
       '<td class="c">'||v.stale_stats||'</td>'||CHR(10)||
	   '<td class="c"><a href="#i_stat_ver_'||LOWER(v.table_name||'_'||v.table_owner)||'">Versions</a></td>'||CHR(10)||
       '</tr>'||CHR(10) line_text
  FROM (
SELECT /*+ NO_MERGE LEADING(pt s i) */
       s.table_name,
       s.table_owner,
       s.index_name,
       s.owner,
       i.index_type,
       i.partitioned,
       i.degree,
       i.temporary,
       i.uniqueness,
       (SELECT COUNT(*)
          FROM dba_ind_columns c
         WHERE c.index_owner = s.owner
           AND c.index_name = s.index_name
           AND c.table_owner = s.table_owner
           AND c.table_name = s.table_name) columns,
       s.num_rows,
       s.sample_size,
       CASE WHEN s.num_rows > 0 THEN TO_CHAR(ROUND(s.sample_size * 100 / s.num_rows, 1), '99999990D0') END sample_size_perc,
       TO_CHAR(s.last_analyzed, 'YYYY-MM-DD/HH24:MI:SS') last_analyzed,
       s.distinct_keys,
       s.blevel,
       s.leaf_blocks,
       s.avg_leaf_blocks_per_key,
       s.avg_data_blocks_per_key,
       s.clustering_factor,
       s.global_stats,
       s.user_stats,
       s.stattype_locked,
       s.stale_stats
  FROM plan_tables pt,
       dba_ind_statistics s,
       dba_indexes i
 WHERE pt.object_type = 'TABLE'
   AND pt.object_owner = s.table_owner
   AND pt.object_name = s.table_name
   AND s.object_type = 'INDEX'
   AND s.owner = i.owner
   AND s.index_name = i.index_name
   AND s.table_owner = i.table_owner
   AND s.table_name = i.table_name
 ORDER BY
       s.table_name,
       s.table_owner,
       s.index_name,
       s.owner) v
 UNION ALL
SELECT object_name table_name,
       object_owner owner,
       3 line_type,
       1 row_num,
       '<tr>'||CHR(10)||
       '<th>#</th>'||CHR(10)||
       --'<th>Table Name</th>'||CHR(10)||
       --'<th>Owner</th>'||CHR(10)||
       '<th>Index Name</th>'||CHR(10)||
       '<th>Owner</th>'||CHR(10)||
       '<th>Index Type</th>'||CHR(10)||
       '<th>Part</th>'||CHR(10)||
       '<th>DoP</th>'||CHR(10)||
       '<th>Temp</th>'||CHR(10)||
       '<th>Uniqueness</th>'||CHR(10)||
       '<th>Cols</th>'||CHR(10)||
       '<th>Num<br>Rows</th>'||CHR(10)||
       '<th>Sample<br>Size</th>'||CHR(10)||
       '<th>Perc</th>'||CHR(10)||
       '<th>Last Analyzed</th>'||CHR(10)||
       '<th>Distinct<br>Keys</th>'||CHR(10)||
       '<th>Blevel</th>'||CHR(10)||
       '<th>Leaf<br>Blocks</th>'||CHR(10)||
       '<th>Avg<br>Leaf<br>Blocks<br>per Key</th>'||CHR(10)||
       '<th>Avg<br>Data<br>Blocks<br>per Key</th>'||CHR(10)||
       '<th>Clustering<br>Factor</th>'||CHR(10)||
       '<th>Global<br>Stats</th>'||CHR(10)||
       '<th>User<br>Stats</th>'||CHR(10)||
       '<th>Stat<br>Type<br>Locked</th>'||CHR(10)||
       '<th>Stale<br>Stats</th>'||CHR(10)||
	   '<th>Stats<br>Versions</th>'||CHR(10)||
       '</tr>'||CHR(10) line_text
  FROM plan_tables
 WHERE object_type = 'TABLE'
 UNION ALL
SELECT object_name table_name,
       object_owner owner,
       4 line_type,
       1 row_num,
       CHR(10)||'</table>'||CHR(10)||CHR(10) line_text
  FROM plan_tables
 WHERE object_type = 'TABLE') v2
 ORDER BY
       v2.table_name,
       v2.owner,
       v2.line_type,
       v2.row_num;	   
	   
/* -------------------------
 *
 * index columns
 *
 * ------------------------- */
EXEC DBMS_APPLICATION_INFO.SET_CLIENT_INFO('^^method.: Index Columns - ' || TO_CHAR(SYSDATE, 'YYYY-MM-DD/HH24:MI:SS'));
PRO <a name="idx_cols"></a><h2>Index Columns</h2>
PRO
SELECT '<!-- '||TO_CHAR(SYSDATE, 'YYYY-MM-DD/HH24:MI:SS')||' -->' FROM dual;
PRO <!-- Please Wait -->

SELECT /* ^^script..sql Index Columns */
       v2.line_text
  FROM (
WITH object AS (
SELECT /*+ MATERIALIZE */
       object_owner owner, object_name name
  FROM gv$sql_plan
 WHERE inst_id IN (SELECT inst_id FROM gv$instance)
   AND sql_id = :sql_id
   AND object_owner IS NOT NULL
   AND object_name IS NOT NULL
 UNION
SELECT object_owner owner, object_name name
  FROM dba_hist_sql_plan
 WHERE :license IN ('T', 'D')
   AND dbid = ^^dbid.
   AND sql_id = :sql_id
   AND object_owner IS NOT NULL
   AND object_name IS NOT NULL
 ), plan_tables AS (
 SELECT /*+ MATERIALIZE */
        'TABLE' object_type, t.owner object_owner, t.table_name object_name
   FROM dba_tab_statistics t, -- include fixed objects
        object o
  WHERE t.owner = o.owner
    AND t.table_name = o.name
  UNION
 SELECT 'TABLE' object_type, i.table_owner object_owner, i.table_name object_name
   FROM dba_indexes i,
        object o
  WHERE i.owner = o.owner
    AND i.index_name = o.name
)
SELECT object_name table_name,
       object_owner owner,
       1 line_type,
       1 row_num,
       '<a name="ic_'||LOWER(object_name||'_'||object_owner)||'"></a><h3>Index Columns: '||object_name||' ('||object_owner||')</h3>'||CHR(10)||CHR(10)||
       'CBO Statistics and relevant attributes.'||CHR(10)||CHR(10)||
       '<table>'||CHR(10)||CHR(10)||
       '<tr>'||CHR(10)||
       '<th>#</th>'||CHR(10)||
       --'<th>Table Name</th>'||CHR(10)||
       --'<th>Owner</th>'||CHR(10)||
       '<th>Index Name</th>'||CHR(10)||
       --'<th>Index Owner</th>'||CHR(10)||
       '<th>Col<br>Pos</th>'||CHR(10)||
       '<th>Col<br>ID</th>'||CHR(10)||
       '<th>Column Name</th>'||CHR(10)||
       '<th>Descend</th>'||CHR(10)||
       '<th>Num<br>Rows</th>'||CHR(10)||
       '<th>Num<br>Nulls</th>'||CHR(10)||
       '<th>Sample<br>Size</th>'||CHR(10)||
       '<th>Perc</th>'||CHR(10)||
       '<th>Num<br>Distinct</th>'||CHR(10)||
       '<th>Low Value</th>'||CHR(10)||
       '<th>High Value</th>'||CHR(10)||
       '<th>Last Analyzed</th>'||CHR(10)||
       '<th>Avg<br>Col<br>Len</th>'||CHR(10)||
       '<th>Density</th>'||CHR(10)||
       '<th>Num<br>Buckets</th>'||CHR(10)||
       '<th>Histogram</th>'||CHR(10)||
       '<th>Global<br>Stats</th>'||CHR(10)||
       '<th>User<br>Stats</th>'||CHR(10)||
       '</tr>'||CHR(10) line_text
  FROM plan_tables
 WHERE object_type = 'TABLE'
 UNION ALL
SELECT v.table_name,
       v.table_owner,
       2 line_type,
       ROWNUM row_num,
       CHR(10)||'<tr>'||CHR(10)||
       '<td class="r">'||ROWNUM||'</td>'||CHR(10)||
       --'<td>'||v.table_name||'</td>'||CHR(10)||
       --'<td>'||v.table_owner||'</td>'||CHR(10)||
       '<td>'||
       (CASE WHEN v.column_position = 1 THEN '<a name="ic_'||LOWER(v.index_name||'_'||v.index_owner)||'"></a>' END)||
       v.index_name||'</td>'||CHR(10)||
       --'<td>'||v.index_owner||'</td>'||CHR(10)||
       '<td class="r">'||v.column_position||'</td>'||CHR(10)||
       '<td class="c">'||v.column_id||'</td>'||CHR(10)||
       '<td>'||v.column_name||'</td>'||CHR(10)||
       '<td>'||v.descend||'</td>'||CHR(10)||
       '<td class="r">'||v.num_rows||'</td>'||CHR(10)||
       '<td class="r">'||v.num_nulls||'</td>'||CHR(10)||
       '<td class="r">'||v.sample_size||'</td>'||CHR(10)||
       '<td class="r">'||v.sample_size_perc||'</td>'||CHR(10)||
       '<td class="r">'||v.num_distinct||'</td>'||CHR(10)||
       '<td nowrap>'||v.low_value||'</td>'||CHR(10)||
       '<td nowrap>'||v.high_value||'</td>'||CHR(10)||
       '<td nowrap>'||v.last_analyzed||'</td>'||CHR(10)||
       '<td class="r">'||v.avg_col_len||'</td>'||CHR(10)||
       '<td class="r">'||v.density||'</td>'||CHR(10)||
       '<td class="r">'||v.num_buckets||'</td>'||CHR(10)||
       '<td>'||v.histogram||'</td>'||CHR(10)||
       '<td class="c">'||v.global_stats||'</td>'||CHR(10)||
       '<td class="c">'||v.user_stats||'</td>'||CHR(10)||
       '</tr>'||CHR(10) line_text
  FROM (
SELECT /*+ NO_MERGE LEADING(pt t i c c2) */
       i.table_name,
       i.table_owner,
       i.index_name,
       i.index_owner,
       i.column_position,
       c.column_id,
       i.column_name,
       i.descend,
       t.num_rows,
       c.num_nulls,
       c.sample_size,
       CASE
       WHEN t.num_rows > c.num_nulls THEN TO_CHAR(LEAST(100, ROUND(c.sample_size * 100 / (t.num_rows - c.num_nulls), 1)), '99999990D0')
       WHEN t.num_rows = c.num_nulls THEN TO_CHAR(100, '99999990D0')
       END sample_size_perc,
       c.num_distinct,
       c.low_value,
       c.high_value,
       TO_CHAR(c.last_analyzed, 'YYYY-MM-DD/HH24:MI:SS') last_analyzed,
       c.avg_col_len,
       LOWER(TO_CHAR(c.density, '0D000000EEEE')) density,
       c.num_buckets,
       c.histogram,
       c.global_stats,
       c.user_stats
  FROM plan_tables pt,
       dba_tables t,
       dba_ind_columns i,
       dba_tab_cols c
 WHERE pt.object_type = 'TABLE'
   AND pt.object_owner = t.owner
   AND pt.object_name = t.table_name
   AND t.owner = i.table_owner
   AND t.table_name = i.table_name
   AND i.table_owner = c.owner
   AND i.table_name = c.table_name
   AND i.column_name = c.column_name
 ORDER BY
       i.table_name,
       i.table_owner,
       i.index_name,
       i.index_owner,
       i.column_position) v
 UNION ALL
SELECT object_name table_name,
       object_owner owner,
       3 line_type,
       1 row_num,
       '<tr>'||CHR(10)||
       '<th>#</th>'||CHR(10)||
       --'<th>Table Name</th>'||CHR(10)||
       --'<th>Owner</th>'||CHR(10)||
       '<th>Index Name</th>'||CHR(10)||
       --'<th>Index Owner</th>'||CHR(10)||
       '<th>Col<br>Pos</th>'||CHR(10)||
       '<th>Col<br>ID</th>'||CHR(10)||
       '<th>Column Name</th>'||CHR(10)||
       '<th>Descend</th>'||CHR(10)||
       '<th>Num<br>Rows</th>'||CHR(10)||
       '<th>Num<br>Nulls</th>'||CHR(10)||
       '<th>Sample<br>Size</th>'||CHR(10)||
       '<th>Perc</th>'||CHR(10)||
       '<th>Num<br>Distinct</th>'||CHR(10)||
       '<th>Low Value</th>'||CHR(10)||
       '<th>High Value</th>'||CHR(10)||
       '<th>Last Analyzed</th>'||CHR(10)||
       '<th>Avg<br>Col<br>Len</th>'||CHR(10)||
       '<th>Density</th>'||CHR(10)||
       '<th>Num<br>Buckets</th>'||CHR(10)||
       '<th>Histogram</th>'||CHR(10)||
       '<th>Global<br>Stats</th>'||CHR(10)||
       '<th>User<br>Stats</th>'||CHR(10)||
       '</tr>'||CHR(10) line_text
  FROM plan_tables
 WHERE object_type = 'TABLE'
 UNION ALL
SELECT object_name table_name,
       object_owner owner,
       4 line_type,
       1 row_num,
       CHR(10)||'</table>'||CHR(10)||CHR(10) line_text
  FROM plan_tables
 WHERE object_type = 'TABLE') v2
 ORDER BY
       v2.table_name,
       v2.owner,
       v2.line_type,
       v2.row_num;
	   
/* -------------------------
 *
 * index partitions
 *
 * ------------------------- */
EXEC DBMS_APPLICATION_INFO.SET_CLIENT_INFO('^^method.: Index Partitions - ' || TO_CHAR(SYSDATE, 'YYYY-MM-DD/HH24:MI:SS'));
PRO <a name="ind_parts"></a><h2>Index Partitions</h2>
PRO
SELECT '<!-- '||TO_CHAR(SYSDATE, 'YYYY-MM-DD/HH24:MI:SS')||' -->' FROM dual;
PRO <!-- Please Wait -->		

SELECT /* ^^script..sql Index Partitions */
       v2.line_text
  FROM (
WITH object AS (
SELECT /*+ MATERIALIZE */
       object_owner owner, object_name name
  FROM gv$sql_plan
 WHERE inst_id IN (SELECT inst_id FROM gv$instance)
   AND sql_id = :sql_id
   AND object_owner IS NOT NULL
   AND object_name IS NOT NULL
 UNION
SELECT object_owner owner, object_name name
  FROM dba_hist_sql_plan
 WHERE :license IN ('T', 'D')
   AND dbid = ^^dbid.
   AND sql_id = :sql_id
   AND object_owner IS NOT NULL
   AND object_name IS NOT NULL
 ), plan_tables AS (
 SELECT /*+ MATERIALIZE */
        'TABLE' object_type, p.table_owner object_owner, p.table_name object_name
   FROM dba_tab_partitions p, -- include fixed objects
        object o
  WHERE p.table_owner = o.owner
    AND p.table_name = o.name
  UNION
 SELECT 'TABLE' object_type, i.table_owner object_owner, i.table_name object_name
   FROM dba_indexes i,
        dba_ind_partitions p,
        object o
  WHERE i.owner = o.owner
    AND i.index_name = o.name
	AND i.owner = p.index_owner(+)  -- partitioned table but not part index in the plan
	AND i.index_name = p.index_name(+)  -- same as above
)
SELECT object_name table_name,
       object_owner owner,
       1 line_type,
       1 row_num,
       '<a name="ip_'||LOWER(object_name||'_'||object_owner)||'"></a><h3>Index Partitions: '||object_name||' ('||object_owner||')</h3>'||CHR(10)||CHR(10)||
       'CBO Statistics and relevant attributes.'||CHR(10)||CHR(10)||
       '<table>'||CHR(10)||CHR(10)||
       '<tr>'||CHR(10)||
       '<th>#</th>'||CHR(10)||
       '<th>Index Name</th>'||CHR(10)||
       '<th>Owner</th>'||CHR(10)||
       '<th>Partition<br>Position</th>'||CHR(10)||
       '<th>Partition<br>Name</th>'||CHR(10)||
       '<th>Subpartition<br>Count</th>'||CHR(10)||	   
       '<th>Num<br>Rows</th>'||CHR(10)||
       '<th>Sample<br>Size</th>'||CHR(10)||
       '<th>Perc</th>'||CHR(10)||
       '<th>Last Analyzed</th>'||CHR(10)||
       '<th>Distinct<br>Keys</th>'||CHR(10)||
       '<th>Blevel</th>'||CHR(10)||
       '<th>Leaf<br>Blocks</th>'||CHR(10)||
       '<th>Avg<br>Leaf<br>Blocks<br>per Key</th>'||CHR(10)||
       '<th>Avg<br>Data<br>Blocks<br>per Key</th>'||CHR(10)||
       '<th>Clustering<br>Factor</th>'||CHR(10)||
       '</tr>'||CHR(10) line_text
  FROM plan_tables
 WHERE object_type = 'TABLE'
 UNION ALL
SELECT v.table_name,
       v.table_owner owner,
       2 line_type,
       ROWNUM row_num,
       CHR(10)||'<tr>'||CHR(10)||
       '<td class="r">'||ROWNUM||'</td>'||CHR(10)||
       '<td>'||v.index_name||'</td>'||CHR(10)||
       '<td>'||v.owner||'</td>'||CHR(10)||
	   '<td class="c">'||v.partition_position||'</td>'||CHR(10)||
       '<td class="c">'||v.partition_name||'</td>'||CHR(10)||
       '<td class="r">'||v.subpartition_count||'</td>'||CHR(10)||	   
       '<td class="r">'||v.num_rows||'</td>'||CHR(10)||
       '<td class="r">'||v.sample_size||'</td>'||CHR(10)||
       '<td class="r">'||v.sample_size_perc||'</td>'||CHR(10)||
       '<td nowrap>'||v.last_analyzed||'</td>'||CHR(10)||
       '<td class="r">'||v.distinct_keys||'</td>'||CHR(10)||
       '<td class="r">'||v.blevel||'</td>'||CHR(10)||
       '<td class="r">'||v.leaf_blocks||'</td>'||CHR(10)||
       '<td class="r">'||v.avg_leaf_blocks_per_key||'</td>'||CHR(10)||
       '<td class="r">'||v.avg_data_blocks_per_key||'</td>'||CHR(10)||
       '<td class="r">'||v.clustering_factor||'</td>'||CHR(10)||
       '</tr>'||CHR(10) line_text
  FROM (
SELECT DISTINCT v.table_name,
       v.table_owner,
       v.index_name,
       v.owner,
	   v.subpartition_count,
	   v.partition_name,
	   v.partition_position,
       v.num_rows,
       v.sample_size,
       v.sample_size_perc,
       v.last_analyzed,
       v.distinct_keys,
       v.blevel,
       v.leaf_blocks,
       v.avg_leaf_blocks_per_key,
       v.avg_data_blocks_per_key,
       v.clustering_factor
  FROM (  
SELECT /*+ NO_MERGE LEADING(pt s i) */
       s.table_name,
       s.table_owner,
       s.index_name,
       s.owner,
	   i.subpartition_count,
	   i.partition_name,
	   i.partition_position,
       i.num_rows,
       i.sample_size,
       CASE WHEN s.num_rows > 0 THEN TO_CHAR(ROUND(i.sample_size * 100 / i.num_rows, 1), '99999990D0') END sample_size_perc,
       TO_CHAR(i.last_analyzed, 'YYYY-MM-DD/HH24:MI:SS') last_analyzed,
       i.distinct_keys,
       i.blevel,
       i.leaf_blocks,
       i.avg_leaf_blocks_per_key,
       i.avg_data_blocks_per_key,
       i.clustering_factor,
	   ROW_NUMBER() OVER (PARTITION BY s.owner, s.index_name ORDER BY i.partition_position DESC) row_num
  FROM plan_tables pt,
       dba_indexes s,
       dba_ind_partitions i
 WHERE pt.object_type = 'TABLE'
   AND pt.object_owner = s.table_owner
   AND pt.object_name = s.table_name
   AND s.index_name = i.index_name
   AND s.owner = i.index_owner
UNION
SELECT /*+ NO_MERGE LEADING(pt s i) */
       s.table_name,
       s.table_owner,
       s.index_name,
       s.owner,
	   i.subpartition_count,
	   i.partition_name,
	   i.partition_position,
       i.num_rows,
       i.sample_size,
       CASE WHEN s.num_rows > 0 THEN TO_CHAR(ROUND(i.sample_size * 100 / i.num_rows, 1), '99999990D0') END sample_size_perc,
       TO_CHAR(i.last_analyzed, 'YYYY-MM-DD/HH24:MI:SS') last_analyzed,
       i.distinct_keys,
       i.blevel,
       i.leaf_blocks,
       i.avg_leaf_blocks_per_key,
       i.avg_data_blocks_per_key,
       i.clustering_factor,
	   ROW_NUMBER() OVER (PARTITION BY s.owner, s.index_name ORDER BY i.partition_position ASC) row_num
  FROM plan_tables pt,
       dba_indexes s,
       dba_ind_partitions i
 WHERE pt.object_type = 'TABLE'
   AND pt.object_owner = s.table_owner
   AND pt.object_name = s.table_name
   AND s.index_name = i.index_name
   AND s.owner = i.index_owner 
	  ) v 
 WHERE v.row_num BETWEEN 1 AND 100
 ORDER BY
       v.index_name,
       v.owner,
	   v.partition_position DESC	  
	  ) v
 UNION ALL
SELECT object_name table_name,
       object_owner owner,
       3 line_type,
       1 row_num,
       '<tr>'||CHR(10)||
       '<th>#</th>'||CHR(10)||
       '<th>Index Name</th>'||CHR(10)||
       '<th>Owner</th>'||CHR(10)||
       '<th>Partition<br>Position</th>'||CHR(10)||
       '<th>Partition<br>Name</th>'||CHR(10)||
       '<th>Subpartition<br>Count</th>'||CHR(10)||	   
       '<th>Num<br>Rows</th>'||CHR(10)||
       '<th>Sample<br>Size</th>'||CHR(10)||
       '<th>Perc</th>'||CHR(10)||
       '<th>Last Analyzed</th>'||CHR(10)||
       '<th>Distinct<br>Keys</th>'||CHR(10)||
       '<th>Blevel</th>'||CHR(10)||
       '<th>Leaf<br>Blocks</th>'||CHR(10)||
       '<th>Avg<br>Leaf<br>Blocks<br>per Key</th>'||CHR(10)||
       '<th>Avg<br>Data<br>Blocks<br>per Key</th>'||CHR(10)||
       '<th>Clustering<br>Factor</th>'||CHR(10)||
       '</tr>'||CHR(10) line_text
  FROM plan_tables
 WHERE object_type = 'TABLE'
 UNION ALL
SELECT object_name table_name,
       object_owner owner,
       4 line_type,
       1 row_num,
       CHR(10)||'</table>'||CHR(10)||CHR(10) line_text
  FROM plan_tables
 WHERE object_type = 'TABLE') v2
 ORDER BY
       v2.table_name,
       v2.owner,
       v2.line_type,
       v2.row_num;   

/* -------------------------
 *
 * index statistics versions
 *
 * ------------------------- */
EXEC DBMS_APPLICATION_INFO.SET_CLIENT_INFO('^^method.: Indexes Statistics Versions - ' || TO_CHAR(SYSDATE, 'YYYY-MM-DD/HH24:MI:SS'));
PRO <a name="idx_stat_ver"></a><h2>Indexes Statistics Versions</h2>
PRO
SELECT '<!-- '||TO_CHAR(SYSDATE, 'YYYY-MM-DD/HH24:MI:SS')||' -->' FROM dual;
PRO <!-- Please Wait -->

SELECT /* ^^script..sql Indexes Statistics Versions */
       v2.line_text
  FROM (
WITH object AS (
SELECT /*+ MATERIALIZE */
       object_owner owner, object_name name
  FROM gv$sql_plan
 WHERE inst_id IN (SELECT inst_id FROM gv$instance)
   AND sql_id = :sql_id
   AND object_owner IS NOT NULL
   AND object_name IS NOT NULL
 UNION
SELECT object_owner owner, object_name name
  FROM dba_hist_sql_plan
 WHERE :license IN ('T', 'D')
   AND dbid = ^^dbid.
   AND sql_id = :sql_id
   AND object_owner IS NOT NULL
   AND object_name IS NOT NULL
 ) , plan_tables AS (
 SELECT /*+ MATERIALIZE */
        'TABLE' object_type, t.owner object_owner, t.table_name object_name
   FROM dba_tab_statistics t, -- include fixed objects
        object o
  WHERE t.owner = o.owner
    AND t.table_name = o.name
  UNION
 SELECT 'TABLE' object_type, i.table_owner object_owner, i.table_name object_name
   FROM dba_indexes i,
        object o
  WHERE i.owner = o.owner
    AND i.index_name = o.name
)
SELECT object_name table_name,
       object_owner owner,
       1 line_type,
       1 row_num,
       '<a name="i_stat_ver_'||LOWER(object_name||'_'||object_owner)||'"></a><h3>Indexes Statistics Versions: '||object_name||' ('||object_owner||')</h3>'||CHR(10)||CHR(10)||
       'CBO Statistics and relevant attributes.'||CHR(10)||CHR(10)||
       '<table>'||CHR(10)||CHR(10)||
       '<tr>'||CHR(10)||
       '<th>#</th>'||CHR(10)||
       '<th>Index Name</th>'||CHR(10)||
       '<th>Owner</th>'||CHR(10)||
	   '<th>Version Type</th>'||CHR(10)||
	   '<th>Save Time</th>'||CHR(10)||
	   '<th>Last Analyzed</th>'||CHR(10)||	   
       '<th>Num<br>Rows</th>'||CHR(10)||
       '<th>Sample<br>Size</th>'||CHR(10)||
       '<th>Perc</th>'||CHR(10)||
       '<th>Distinct<br>Keys</th>'||CHR(10)||
       '<th>Blevel</th>'||CHR(10)||
       '<th>Leaf<br>Blocks</th>'||CHR(10)||
       '<th>Avg<br>Leaf<br>Blocks<br>per Key</th>'||CHR(10)||
       '<th>Avg<br>Data<br>Blocks<br>per Key</th>'||CHR(10)||
       '<th>Clustering<br>Factor</th>'||CHR(10)||
       '</tr>'||CHR(10) line_text
  FROM plan_tables
 WHERE object_type = 'TABLE'
 UNION ALL 
SELECT v.object_name,
       v.object_owner owner,
       2 line_type,
       ROWNUM row_num,
       CHR(10)||'<tr>'||CHR(10)||
       '<td class="r">'||ROWNUM||'</td>'||CHR(10)||
       '<td>'||v.index_name||'</td>'||CHR(10)||
       '<td>'||v.owner||'</td>'||CHR(10)||
	   '<td>'||v.version_type||'</td>'||CHR(10)||
	   '<td nowrap>'||v.save_time||'</td>'||CHR(10)||
       '<td nowrap>'||v.last_analyzed||'</td>'||CHR(10)||	   
       '<td class="r">'||v.num_rows||'</td>'||CHR(10)||
       '<td class="r">'||v.sample_size||'</td>'||CHR(10)||
       '<td class="r">'||v.sample_size_perc||'</td>'||CHR(10)||
       '<td class="r">'||v.distinct_keys||'</td>'||CHR(10)||
       '<td class="r">'||v.blevel||'</td>'||CHR(10)||
       '<td class="r">'||v.leaf_blocks||'</td>'||CHR(10)||
       '<td class="r">'||v.avg_leaf_blocks_per_key||'</td>'||CHR(10)||
       '<td class="r">'||v.avg_data_blocks_per_key||'</td>'||CHR(10)||
       '<td class="r">'||v.clustering_factor||'</td>'||CHR(10)||
       '</tr>'||CHR(10) line_text
  FROM (
SELECT * 
  FROM (  
SELECT /*+ NO_MERGE LEADING(pt s i) */
       i.table_name object_name,
       i.table_owner object_owner,
       i.index_name,
       i.owner,
	   'HISTORY' version_type,
	   s.savtime save_time,
       TO_CHAR(s.analyzetime, 'YYYY-MM-DD/HH24:MI:SS') last_analyzed,	   
       s.rowcnt num_rows,
       s.samplesize sample_size,
       CASE WHEN s.rowcnt > 0 THEN TO_CHAR(ROUND(s.samplesize * 100 / s.rowcnt, 1), '99999990D0') END sample_size_perc,
       s.distkey distinct_keys,
       s.blevel,
       s.leafcnt leaf_blocks,
       s.lblkkey avg_leaf_blocks_per_key,
       s.dblkkey avg_data_blocks_per_key,
       s.clufac clustering_factor
  FROM plan_tables pt,
       sys.wri$_optstat_ind_history s,
       dba_indexes i,
	   dba_objects o
 WHERE pt.object_type = 'TABLE'
   AND pt.object_owner = i.table_owner
   AND pt.object_name = i.table_name
   AND o.object_type = 'INDEX'
   AND o.owner = i.owner
   AND o.object_name = i.index_name 
   AND s.obj# = o.object_id
UNION ALL  
SELECT /*+ NO_MERGE LEADING(pt s i) */
       s.table_name,
       s.table_owner,
       s.index_name,
       s.owner,
	   'CURRENT' version_type,
	   NULL save_time,
       TO_CHAR(s.last_analyzed, 'YYYY-MM-DD/HH24:MI:SS') last_analyzed,	   
       s.num_rows,
       s.sample_size,
       CASE WHEN s.num_rows > 0 THEN TO_CHAR(ROUND(s.sample_size * 100 / s.num_rows, 1), '99999990D0') END sample_size_perc,      
       s.distinct_keys,
       s.blevel,
       s.leaf_blocks,
       s.avg_leaf_blocks_per_key,
       s.avg_data_blocks_per_key,
       s.clustering_factor
  FROM plan_tables pt,
       dba_ind_statistics s,
       dba_indexes i
 WHERE pt.object_type = 'TABLE'
   AND pt.object_owner = s.table_owner
   AND pt.object_name = s.table_name
   AND s.object_type = 'INDEX'
   AND s.owner = i.owner
   AND s.index_name = i.index_name
   AND s.table_owner = i.table_owner
   AND s.table_name = i.table_name) 
 ORDER BY
       index_name,
       owner,
	   save_time DESC NULLS FIRST) v
UNION ALL
SELECT object_name table_name,
       object_owner owner,
       3 line_type,
       1 row_num,
       '<tr>'||CHR(10)||
       '<th>#</th>'||CHR(10)||
       '<th>Index Name</th>'||CHR(10)||
       '<th>Owner</th>'||CHR(10)||
	   '<th>Version Type</th>'||CHR(10)||
	   '<th>Save Time</th>'||CHR(10)||
	   '<th>Last Analyzed</th>'||CHR(10)||	   
       '<th>Num<br>Rows</th>'||CHR(10)||
       '<th>Sample<br>Size</th>'||CHR(10)||
       '<th>Perc</th>'||CHR(10)||
       '<th>Distinct<br>Keys</th>'||CHR(10)||
       '<th>Blevel</th>'||CHR(10)||
       '<th>Leaf<br>Blocks</th>'||CHR(10)||
       '<th>Avg<br>Leaf<br>Blocks<br>per Key</th>'||CHR(10)||
       '<th>Avg<br>Data<br>Blocks<br>per Key</th>'||CHR(10)||
       '<th>Clustering<br>Factor</th>'||CHR(10)||
       '</tr>'||CHR(10) line_text
  FROM plan_tables
 WHERE object_type = 'TABLE'
 UNION ALL
SELECT object_name table_name,
       object_owner owner,
       4 line_type,
       1 row_num,
       CHR(10)||'</table>'||CHR(10)||CHR(10) line_text
  FROM plan_tables
 WHERE object_type = 'TABLE')  v2
 ORDER BY
       v2.table_name,
       v2.owner,
       v2.line_type,
       v2.row_num;	   
	   
/* -------------------------
 *
 * system parameters
 *
 * ------------------------- */
EXEC DBMS_APPLICATION_INFO.SET_CLIENT_INFO('^^method.: System Parameters - ' || TO_CHAR(SYSDATE, 'YYYY-MM-DD/HH24:MI:SS'));
PRO <a name="sys_params"></a><h2>System Parameters with Non-Default or Modified Values</h2>
PRO
PRO Collected from GV$SYSTEM_PARAMETER2 where isdefault = 'FALSE' OR ismodified != 'FALSE'.
PRO "Is Default" = FALSE means the parameter was set in the spfile.
PRO
PRO <table>
PRO
PRO <tr>
PRO <th>#</th>
PRO <th>Name</th>
PRO <th>Inst</th>
PRO <th>Ord</th>
PRO <th>Is<br>Default</th>
PRO <th>Is<br>Modified</th>
PRO <th>Value</th>
PRO <th>Display<br>Value</th>
PRO <th>Description</th>
PRO </tr>
PRO
SELECT '<!-- '||TO_CHAR(SYSDATE, 'YYYY-MM-DD/HH24:MI:SS')||' -->' FROM dual;
PRO <!-- Please Wait -->

SELECT /* ^^script..sql System Parameters */
       CHR(10)||'<tr>'||CHR(10)||
       '<td class="r">'||ROWNUM||'</td>'||CHR(10)||
       '<td>'||v.name||'</td>'||CHR(10)||
       '<td class="c">'||v.inst_id||'</td>'||CHR(10)||
       '<td class="r">'||v.ordinal||'</td>'||CHR(10)||
       '<td>'||v.isdefault||'</td>'||CHR(10)||
       '<td>'||v.ismodified||'</td>'||CHR(10)||
       '<td>'||v.value||'</td>'||CHR(10)||
       '<td>'||DECODE(v.display_value, v.value, NULL, v.display_value)||'</td>'||CHR(10)||
       '<td>'||v.description||'</td>'||CHR(10)||
       '</tr>'
  FROM (
SELECT /*+ NO_MERGE */ *
  FROM gv$system_parameter2
 WHERE (isdefault = 'FALSE' OR ismodified <> 'FALSE')
 ORDER BY
       name,
       inst_id,
       ordinal ) v;

PRO
PRO <tr>
PRO <th>#</th>
PRO <th>Name</th>
PRO <th>Inst</th>
PRO <th>Ord</th>
PRO <th>Is<br>Default</th>
PRO <th>Is<br>Modified</th>
PRO <th>Value</th>
PRO <th>Display<br>Value</th>
PRO <th>Description</th>
PRO </tr>
PRO
PRO </table>
PRO

/* -------------------------
 *
 * instance parameters
 *
 * ------------------------- */
PRO <a name="inst_params"></a><h2>Instance Parameters</h2>
PRO
PRO System Parameters collected from V$SYSTEM_PARAMETER2 for Instance number ^^instance_number..
PRO
PRO <table>
PRO
PRO <tr>
PRO <th>#</th>
PRO <th>Name</th>
PRO <th>Ord</th>
PRO <th>Is<br>Default</th>
PRO <th>Is<br>Modified</th>
PRO <th>Value</th>
PRO <th>Display<br>Value</th>
PRO <th>Description</th>
PRO </tr>
PRO
SELECT '<!-- '||TO_CHAR(SYSDATE, 'YYYY-MM-DD/HH24:MI:SS')||' -->' FROM dual;
PRO <!-- Please Wait -->

SELECT /* ^^script..sql System Parameters */
       CHR(10)||'<tr>'||CHR(10)||
       '<td class="r">'||ROWNUM||'</td>'||CHR(10)||
       '<td>'||v.name||'</td>'||CHR(10)||
       '<td class="r">'||v.ordinal||'</td>'||CHR(10)||
       '<td>'||v.isdefault||'</td>'||CHR(10)||
       '<td>'||v.ismodified||'</td>'||CHR(10)||
       '<td>'||v.value||'</td>'||CHR(10)||
       '<td>'||DECODE(v.display_value, v.value, NULL, v.display_value)||'</td>'||CHR(10)||
       '<td>'||v.description||'</td>'||CHR(10)||
       '</tr>'
  FROM (
SELECT /*+ NO_MERGE */ *
  FROM v$system_parameter2
 ORDER BY
       name,
       ordinal ) v;

PRO
PRO <tr>
PRO <th>#</th>
PRO <th>Name</th>
PRO <th>Ord</th>
PRO <th>Is<br>Default</th>
PRO <th>Is<br>Modified</th>
PRO <th>Value</th>
PRO <th>Display<br>Value</th>
PRO <th>Description</th>
PRO </tr>
PRO
PRO </table>
PRO

/* -------------------------
 *
 * Metadata
 *
 * ------------------------- */
PRO <a name="metadata"></a><h2>Metadata</h2>
PRO
PRO Table and Index Metadata of the objects involved in the plan and their dependent objects
PRO
SET LONG 1000000 LONGCHUNKSIZE 1000000
WITH object AS (
SELECT /*+ MATERIALIZE */
       object_owner owner, object_name name
  FROM gv$sql_plan
 WHERE inst_id IN (SELECT inst_id FROM gv$instance)
   AND sql_id = :sql_id
   AND object_owner IS NOT NULL
   AND object_name IS NOT NULL
 UNION
SELECT object_owner owner, object_name name
  FROM dba_hist_sql_plan
 WHERE :license IN ('T', 'D')
   AND dbid = ^^dbid.
   AND sql_id = :sql_id
   AND object_owner IS NOT NULL
   AND object_name IS NOT NULL
 )
 SELECT '<h3>Table: '||t.object_owner||'.'||t.object_name||'</h3>'||REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(DBMS_METADATA.GET_DDL('TABLE',t.object_name,t.object_owner), '<', CHR(38)||'lt;'), '>', CHR(38)||'gt;'), '''', CHR(38)||'#39;'), '"', CHR(38)||'quot;'), CHR(10), '<br>'||CHR(10))
   FROM (SELECT t.owner object_owner, t.table_name object_name
           FROM dba_tables t, -- include fixed objects
                object o
          WHERE t.owner = o.owner
            AND t.table_name = o.name
          UNION
         SELECT i.table_owner object_owner, i.table_name object_name
           FROM dba_indexes i,
                object o
          WHERE i.owner = o.owner
            AND i.index_name = o.name) t;
			
WITH object AS (
SELECT /*+ MATERIALIZE */
       object_owner owner, object_name name
  FROM gv$sql_plan
 WHERE inst_id IN (SELECT inst_id FROM gv$instance)
   AND sql_id = :sql_id
   AND object_owner IS NOT NULL
   AND object_name IS NOT NULL
 UNION
SELECT object_owner owner, object_name name
  FROM dba_hist_sql_plan
 WHERE :license IN ('T', 'D')
   AND dbid = ^^dbid.
   AND sql_id = :sql_id
   AND object_owner IS NOT NULL
   AND object_name IS NOT NULL
 ), plan_tables AS (
 SELECT /*+ MATERIALIZE */
        'TABLE' object_type, t.owner object_owner, t.table_name object_name
   FROM dba_tables t, -- include fixed objects
        object o
  WHERE t.owner = o.owner
    AND t.table_name = o.name
  UNION
 SELECT 'TABLE' object_type, i.table_owner object_owner, i.table_name object_name
   FROM dba_indexes i,
        object o
  WHERE i.owner = o.owner
    AND i.index_name = o.name
)
SELECT '<h3>Index: '||s.owner||'.'||s.index_name||'</h3>'||REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(DBMS_METADATA.GET_DDL('INDEX',s.index_name,s.owner), '<', CHR(38)||'lt;'), '>', CHR(38)||'gt;'), '''', CHR(38)||'#39;'), '"', CHR(38)||'quot;'), CHR(10), '<br>'||CHR(10))
  FROM plan_tables pt,
       dba_indexes s
 WHERE pt.object_type = 'TABLE'
   AND pt.object_owner = s.table_owner
   AND pt.object_name = s.table_name
 ORDER BY
       s.table_name,
       s.table_owner,
       s.index_name,
       s.owner;
			

/* -------------------------
 *
 * footer
 *
 * ------------------------- */
PRO
SELECT '<!-- '||TO_CHAR(SYSDATE, 'YYYY-MM-DD/HH24:MI:SS')||' -->' FROM dual;
PRO <hr size="3">
PRO <font class="f">^^mos_doc. ^^method. ^^doc_ver. ^^time_stamp2.</font>
PRO </body>
PRO </html>

SPO OFF;

/**************************************************************************************************/

/**************************************************************************************************
 *
 * execution_plans report
 *
 **************************************************************************************************/

EXEC DBMS_APPLICATION_INFO.SET_CLIENT_INFO('^^method.: Execution Plans - ' || TO_CHAR(SYSDATE, 'YYYY-MM-DD/HH24:MI:SS'));

/* -------------------------
 *
 * heading
 *
 * ------------------------- */
SPO ^^files_prefix._3_execution_plans.html;

PRO <html>
PRO <!-- $Header: ^^mos_doc. ^^script..sql ^^doc_ver. ^^doc_date. carlos.sierra $ -->
PRO <!-- Copyright (c) 2000-2012, Oracle Corporation. All rights reserved. -->
PRO <!-- Author: carlos.sierra@oracle.com -->
PRO
PRO <head>
PRO <title>^^files_prefix._3_execution_plans.html</title>
PRO

PRO <style type="text/css">
PRO body {font:10pt Arial,Helvetica,Verdana,Geneva,sans-serif; color:black; background:white;}
PRO a {font-weight:bold; color:#663300;}
PRO pre {font:8pt Monaco,"Courier New",Courier,monospace;} /* for code */
PRO h1 {font-size:16pt; font-weight:bold; color:#336699;}
PRO h2 {font-size:14pt; font-weight:bold; color:#336699;}
PRO h3 {font-size:12pt; font-weight:bold; color:#336699;}
PRO li {font-size:10pt; font-weight:bold; color:#336699; padding:0.1em 0 0 0;}
PRO table {font-size:8pt; color:black; background:white;}
PRO th {font-weight:bold; background:#cccc99; color:#336699; vertical-align:bottom; padding-left:3pt; padding-right:3pt; padding-top:1pt; padding-bottom:1pt;}
PRO td {text-align:left; background:#fcfcf0; vertical-align:top; padding-left:3pt; padding-right:3pt; padding-top:1pt; padding-bottom:1pt;}
PRO td.c {text-align:center;} /* center */
PRO td.l {text-align:left;} /* left (default) */
PRO td.r {text-align:right;} /* right */
PRO font.n {font-size:8pt; font-style:italic; color:#336699;} /* table footnote in blue */
PRO font.f {font-size:8pt; color:#999999;} /* footnote in gray */
PRO </style>
PRO

PRO </head>
PRO <body>
PRO <h1><a target="MOS" href="^^doc_link.^^mos_doc.">^^mos_doc.</a> ^^method.
PRO ^^doc_ver. Report: ^^files_prefix._3_execution_plans.html</h1>
PRO

PRO <pre>
PRO License    : ^^input_license.
PRO Input      : ^^input_parameter.
PRO SIGNATURE  : ^^signature.
PRO SIGNATUREF : ^^signaturef.
PRO RDBMS      : ^^rdbms_version.
PRO Platform   : ^^platform.
PRO Database   : ^^database_name_short.
PRO DBID       : ^^dbid.
PRO Host       : ^^host_name_short.
PRO Instance   : ^^instance_number.
PRO CPU_Count  : ^^sys_cpu.
PRO Num CPUs   : ^^num_cpus.
PRO Num Cores  : ^^num_cores.
PRO Num Sockets: ^^num_sockets.
PRO Block Size : ^^sys_db_block_size.
PRO OFE        : ^^sys_ofe.
PRO DYN_SAMP   : ^^sys_ds.
PRO EBS        : "^^is_ebs."
PRO SIEBEL     : "^^is_siebel."
PRO PSFT       : "^^is_psft."
PRO Date       : ^^time_stamp2.
PRO User       : ^^sessionuser.
PRO </pre>

PRO <ul>
PRO <li><a href="#text">SQL Text</a></li>
PRO <li><a href="#mem_plans_last">Current Execution Plans (last execution)</a></li>
PRO <li><a href="#mem_plans_all">Current Execution Plans (all executions)</a></li>
PRO <li><a href="#awr_plans">Historical Execution Plans</a></li>
PRO </ul>

/* -------------------------
 *
 * sql_text
 *
 * ------------------------- */
PRO <a name="text"></a><h2>SQL Text</h2>
PRO
PRO <pre>

DECLARE
  l_sql_text CLOB := :sql_text;
  l_pos NUMBER;
BEGIN
  WHILE NVL(LENGTH(l_sql_text), 0) > 0
  LOOP
    l_pos := INSTR(l_sql_text, CHR(10));
    IF l_pos > 0 THEN
      DBMS_OUTPUT.PUT_LINE(SUBSTR(l_sql_text, 1, l_pos - 1));
      l_sql_text := SUBSTR(l_sql_text, l_pos + 1);
    ELSE
      DBMS_OUTPUT.PUT_LINE(l_sql_text);
      l_sql_text := NULL;
    END IF;
  END LOOP;
END;
/

PRO </pre>

/* -------------------------
 *
 * DBMS_XPLAN.DISPLAY_CURSOR OUTLINE ALLSTATS LAST
 *
 * ------------------------- */
COL inst_child FOR A21;
BREAK ON inst_child SKIP 2;

PRO <a name="mem_plans_last"></a><h2>Current Execution Plans (last execution)</h2>
PRO
PRO Captured while still in memory. Metrics below are for the last execution of each child cursor.<br>
PRO If STATISTICS_LEVEL was set to ALL at the time of the hard-parse then A-Rows column is populated.
PRO
SELECT '<!-- '||TO_CHAR(SYSDATE, 'YYYY-MM-DD/HH24:MI:SS')||' -->' FROM dual;
PRO <!-- Please Wait -->
PRO <pre>

SELECT RPAD('Inst: '||v.inst_id, 9)||' '||RPAD('Child: '||v.child_number, 11) inst_child, t.plan_table_output
  FROM gv$sql v,
       TABLE(DBMS_XPLAN.DISPLAY('gv$sql_plan_statistics_all', NULL, 'ADVANCED ALLSTATS LAST', 'inst_id = '||v.inst_id||' AND sql_id = '''||v.sql_id||''' AND child_number = '||v.child_number)) t
 WHERE v.sql_id = :sql_id
   AND v.loaded_versions > 0;

PRO </pre>

/* -------------------------
 *
 * DBMS_XPLAN.DISPLAY_CURSOR OUTLINE ALLSTATS
 *
 * ------------------------- */
PRO <a name="mem_plans_all"></a><h2>Current Execution Plans (all executions)</h2>
PRO
PRO Captured while still in memory. Metrics below are an aggregate for all the execution of each child cursor.<br>
PRO If STATISTICS_LEVEL was set to ALL at the time of the hard-parse then A-Rows column is populated.
PRO
SELECT '<!-- '||TO_CHAR(SYSDATE, 'YYYY-MM-DD/HH24:MI:SS')||' -->' FROM dual;
PRO <!-- Please Wait -->
PRO <pre>

SELECT RPAD('Inst: '||v.inst_id, 9)||' '||RPAD('Child: '||v.child_number, 11) inst_child, t.plan_table_output
  FROM gv$sql v,
       TABLE(DBMS_XPLAN.DISPLAY('gv$sql_plan_statistics_all', NULL, 'ADVANCED ALLSTATS', 'inst_id = '||v.inst_id||' AND sql_id = '''||v.sql_id||''' AND child_number = '||v.child_number)) t
 WHERE v.sql_id = :sql_id
   AND v.loaded_versions > 0
   AND v.executions > 1;

PRO </pre>

/* -------------------------
 *
 * DBMS_XPLAN.DISPLAY_AWR OUTLINE
 *
 * ------------------------- */
PRO <a name="awr_plans"></a><h2>Historical Execution Plans</h2>
PRO
PRO This section includes data captured by AWR. If this is a stand-by read-only database then the AWR information below is from the Primary database.
PRO
SELECT '<!-- '||TO_CHAR(SYSDATE, 'YYYY-MM-DD/HH24:MI:SS')||' -->' FROM dual;
PRO <!-- Please Wait -->
PRO <pre>

SELECT t.plan_table_output
  FROM (SELECT DISTINCT sql_id, plan_hash_value, dbid
          FROM dba_hist_sql_plan WHERE :license IN ('T', 'D') AND dbid = ^^dbid. AND sql_id = :sql_id) v,
       TABLE(DBMS_XPLAN.DISPLAY_AWR(v.sql_id, v.plan_hash_value, v.dbid, 'ADVANCED')) t;

PRO </pre>

/* -------------------------
 *
 * footer
 *
 * ------------------------- */
PRO
SELECT '<!-- '||TO_CHAR(SYSDATE, 'YYYY-MM-DD/HH24:MI:SS')||' -->' FROM dual;
PRO <hr size="3">
PRO <font class="f">^^mos_doc. ^^method. ^^doc_ver. ^^time_stamp2.</font>
PRO </body>
PRO </html>

SPO OFF;

/**************************************************************************************************/

/**************************************************************************************************
 *
 * 11g sql detail report
 *
 **************************************************************************************************/

EXEC DBMS_APPLICATION_INFO.SET_CLIENT_INFO('^^method.: SQL Detail Report - ' || TO_CHAR(SYSDATE, 'YYYY-MM-DD/HH24:MI:SS'));
PRO 11g SQL Detail Report
PRO
SELECT TO_CHAR(SYSDATE, 'YYYY-MM-DD/HH24:MI:SS') FROM dual;
PRO Please Wait

VAR det CLOB;
EXEC :det := 'SQL Detail Report is available on 11.2 and higher';

SPO ^^files_prefix._4_sql_detail.html;
SELECT '<!-- '||TO_CHAR(SYSDATE, 'YYYY-MM-DD/HH24:MI:SS')||' -->' FROM dual;
PRO <!-- begin DBMS_SQLTUNE.REPORT_SQL_DETAIL
DECLARE
  l_start_time DATE := NULL;
  l_duration NUMBER := NULL;
BEGIN
  IF :license = 'T' AND '^^rdbms_version.' >= '11.2%' THEN
    SELECT CAST(MIN(sample_time) AS DATE),
           ((CAST(MAX(sample_time) AS DATE) - CAST(MIN(sample_time) AS DATE)) * 24 * 3600)
      INTO l_start_time, l_duration
      FROM gv$active_session_history
     WHERE sql_id = :sql_id;

    l_start_time := LEAST(NVL(l_start_time, SYSDATE), SYSDATE - 1); -- at least 1 day
    l_duration := GREATEST(NVL(l_duration, 0), 24 * 3600); -- at least 1 day

    :det := DBMS_SQLTUNE.REPORT_SQL_DETAIL(
       sql_id       => :sql_id,
       start_time   => l_start_time,
       duration     => l_duration,
       report_level => 'ALL',
       type         => 'ACTIVE' );
  END IF;
END;
/
PRO end -->
SELECT '<!-- '||TO_CHAR(SYSDATE, 'YYYY-MM-DD/HH24:MI:SS')||' -->' FROM dual;
SELECT :det FROM DUAL;
SELECT '<!-- '||TO_CHAR(SYSDATE, 'YYYY-MM-DD/HH24:MI:SS')||' -->' FROM dual;
SPO OFF;

/**************************************************************************************************/

/**************************************************************************************************
 *
 * 11g sql monitor report
 *
 **************************************************************************************************/

EXEC DBMS_APPLICATION_INFO.SET_CLIENT_INFO('^^method.: SQL Monitor Report - ' || TO_CHAR(SYSDATE, 'YYYY-MM-DD/HH24:MI:SS'));
PRO SQL Monitor Report
PRO
SELECT TO_CHAR(SYSDATE, 'YYYY-MM-DD/HH24:MI:SS') FROM dual;
PRO Please Wait

SPO ^^files_prefix._5_sql_monitor.sql;
PRO -- SQL Monitor Report for ^^sql_id.

DECLARE
  l_count NUMBER := 0;
  TYPE mon_rt IS RECORD (
    sql_exec_start DATE,
    sql_exec_id NUMBER,
    sql_plan_hash_value NUMBER,
    inst_id NUMBER );
  mon_rec mon_rt;
  mon_cv SYS_REFCURSOR;
BEGIN
  IF :license = 'T' AND '^^rdbms_version.' >= '11' THEN
    DBMS_OUTPUT.PUT_LINE('VAR mon_exec_start VARCHAR2(14);');
    DBMS_OUTPUT.PUT_LINE('VAR mon_exec_id NUMBER;');
    DBMS_OUTPUT.PUT_LINE('VAR mon_sql_plan_hash_value NUMBER;');
    DBMS_OUTPUT.PUT_LINE('VAR mon_inst_id NUMBER;');
    DBMS_OUTPUT.PUT_LINE('VAR mon_report CLOB;');
    DBMS_OUTPUT.PUT_LINE('VAR mon_sql_id VARCHAR2(13);');
    DBMS_OUTPUT.PUT_LINE('EXEC :mon_sql_id := ''^^sql_id.'';');
    DBMS_OUTPUT.PUT_LINE('SET ECHO OFF FEED OFF VER OFF SHOW OFF HEA OFF LIN 2000 NEWP NONE PAGES 0 LONG 2000000 LONGC 2000 SQLC MIX TAB ON TRIMS ON TI OFF TIMI OFF ARRAY 100 NUMF "" SQLP SQL> SUF sql BLO . RECSEP OFF APPI OFF AUTOT OFF;');

    -- cursor variable to avoid error on 10g since v$sql_monitor didn't exist then
    OPEN mon_cv FOR
      'SELECT DISTINCT '||
      '       sql_exec_start, '||
      '       sql_exec_id, '||
      '       sql_plan_hash_value, '||
      '       inst_id '||
      '  FROM gv$sql_monitor /* 11g */ '||
      ' WHERE process_name = ''ora'' '||
      '   AND sql_id = ''^^sql_id.'' '||
      ' ORDER BY '||
      '       1, '||
      '       2';
    LOOP
      FETCH mon_cv INTO mon_rec;
      EXIT WHEN mon_cv%NOTFOUND;

      l_count := l_count + 1;
      IF l_count > ^^sql_monitor_reports. THEN
        EXIT; -- exits loop
      END IF;

      DBMS_OUTPUT.PUT_LINE('EXEC :mon_exec_start := '''||TO_CHAR(mon_rec.sql_exec_start, 'YYYYMMDDHH24MISS')||''';');
      DBMS_OUTPUT.PUT_LINE('EXEC :mon_exec_id := '||TO_CHAR(mon_rec.sql_exec_id)||';');
      DBMS_OUTPUT.PUT_LINE('EXEC :mon_sql_plan_hash_value := '||TO_CHAR(mon_rec.sql_plan_hash_value)||';');
      DBMS_OUTPUT.PUT_LINE('EXEC :mon_inst_id := '||TO_CHAR(mon_rec.inst_id)||';');
      DBMS_OUTPUT.PUT_LINE('SPO ^^files_prefix._'||TO_CHAR(mon_rec.sql_exec_id)||'_'||TO_CHAR(mon_rec.sql_plan_hash_value)||'_'||TO_CHAR(mon_rec.inst_id)||'_5_sql_monitor.html;');
      DBMS_OUTPUT.PUT_LINE('SELECT ''<!-- ''||TO_CHAR(SYSDATE, ''YYYY-MM-DD/HH24:MI:SS'')||'' -->'' FROM dual;');
      DBMS_OUTPUT.PUT_LINE('PRO <!-- begin DBMS_SQLTUNE.REPORT_SQL_MONITOR');
      DBMS_OUTPUT.PUT_LINE('BEGIN');
      DBMS_OUTPUT.PUT_LINE('  :mon_report := DBMS_SQLTUNE.REPORT_SQL_MONITOR (');
      DBMS_OUTPUT.PUT_LINE('    sql_id         => :mon_sql_id,');
      DBMS_OUTPUT.PUT_LINE('    sql_exec_start => TO_DATE(:mon_exec_start, ''YYYYMMDDHH24MISS''),');
      DBMS_OUTPUT.PUT_LINE('    sql_exec_id    => :mon_exec_id,');
      DBMS_OUTPUT.PUT_LINE('    report_level   => ''ALL'',');
      DBMS_OUTPUT.PUT_LINE('    type           => ''ACTIVE'' );');
      DBMS_OUTPUT.PUT_LINE('END;');
      DBMS_OUTPUT.PUT_LINE('/');
      DBMS_OUTPUT.PUT_LINE('PRO end -->');
      DBMS_OUTPUT.PUT_LINE('SELECT ''<!-- ''||TO_CHAR(SYSDATE, ''YYYY-MM-DD/HH24:MI:SS'')||'' -->'' FROM dual;');

      IF '^^rdbms_version.' LIKE '11.1%' THEN
        DBMS_OUTPUT.PUT_LINE('PRO <html>');
        DBMS_OUTPUT.PUT_LINE('PRO <head>');
        DBMS_OUTPUT.PUT_LINE('PRO  <meta http-equiv="Content-Type" content="text/html; charset=utf-8"/>');
        DBMS_OUTPUT.PUT_LINE('PRO  <base href="http://download.oracle.com/otn_software/"/>');
        DBMS_OUTPUT.PUT_LINE('PRO  <script language="javascript" type="text/javascript" src="emviewers/scripts/flashver.js">');
        DBMS_OUTPUT.PUT_LINE('PRO   <!--Test flash version-->');
        DBMS_OUTPUT.PUT_LINE('PRO  </script>');
        DBMS_OUTPUT.PUT_LINE('PRO  <style>');
        DBMS_OUTPUT.PUT_LINE('PRO      body { margin: 0px; overflow:hidden }');
        DBMS_OUTPUT.PUT_LINE('PRO    </style>');
        DBMS_OUTPUT.PUT_LINE('PRO </head>');
        DBMS_OUTPUT.PUT_LINE('PRO <body scroll="no">');
        DBMS_OUTPUT.PUT_LINE('PRO  <script type="text/xml">');
        DBMS_OUTPUT.PUT_LINE('PRO   <!--FXTMODEL-->');
      END IF;

      DBMS_OUTPUT.PUT_LINE('SELECT :mon_report FROM DUAL;');

      IF '^^rdbms_version.' LIKE '11.1%' THEN
        DBMS_OUTPUT.PUT_LINE('PRO    <!--FXTMODEL-->');
        DBMS_OUTPUT.PUT_LINE('PRO   </script>');
        DBMS_OUTPUT.PUT_LINE('PRO   <script language="JavaScript" type="text/javascript" src="emviewers/scripts/loadswf.js">');
        DBMS_OUTPUT.PUT_LINE('PRO    <!--Load report viewer-->');
        DBMS_OUTPUT.PUT_LINE('PRO   </script>');
        DBMS_OUTPUT.PUT_LINE('PRO   <iframe name="_history" frameborder="0" scrolling="no" width="22" height="0">');
        DBMS_OUTPUT.PUT_LINE('PRO    <html>');
        DBMS_OUTPUT.PUT_LINE('PRO     <head>');
        DBMS_OUTPUT.PUT_LINE('PRO      <meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1"/>');
        DBMS_OUTPUT.PUT_LINE('PRO      <script type="text/javascript" language="JavaScript1.2" charset="utf-8">');
        DBMS_OUTPUT.PUT_LINE('PRO                 var v = new top.Vars(top.getSearch(window)); <!-- ; -->');
        DBMS_OUTPUT.PUT_LINE('PRO                 var fv = v.toString("$_"); <!-- ; -->');
        DBMS_OUTPUT.PUT_LINE('PRO               </script>');
        DBMS_OUTPUT.PUT_LINE('PRO     </head>');
        DBMS_OUTPUT.PUT_LINE('PRO     <body>');
        DBMS_OUTPUT.PUT_LINE('PRO      <script type="text/javascript" language="JavaScript1.2" charset="utf-8" src="emviewers/scripts/document.js">');
        DBMS_OUTPUT.PUT_LINE('PRO       <!--Run document script-->');
        DBMS_OUTPUT.PUT_LINE('PRO      </script>');
        DBMS_OUTPUT.PUT_LINE('PRO     </body>');
        DBMS_OUTPUT.PUT_LINE('PRO    </html>');
        DBMS_OUTPUT.PUT_LINE('PRO   </iframe>');
        DBMS_OUTPUT.PUT_LINE('PRO  </body>');
        DBMS_OUTPUT.PUT_LINE('PRO </html>');
      END IF;

      DBMS_OUTPUT.PUT_LINE('SELECT ''<!-- ''||TO_CHAR(SYSDATE, ''YYYY-MM-DD/HH24:MI:SS'')||'' -->'' FROM dual;');
      DBMS_OUTPUT.PUT_LINE('SPO OFF;');
    END LOOP;
    CLOSE mon_cv;
  ELSE
    DBMS_OUTPUT.PUT_LINE('-- SQL Monitor Reports are available on 11.1 and higher, and they are part of the Oracle Tuning pack.');
  END IF;
END;
/

SPO OFF;

-- 11g
@^^files_prefix._5_sql_monitor.sql

/**************************************************************************************************/

/* -------------------------
 *
 * wrap up
 *
 * ------------------------- */

-- turing trace off
ALTER SESSION SET SQL_TRACE = FALSE;
--ALTER SESSION SET STATISTICS_LEVEL = 'TYPICAL';

-- get udump directory path
COL udump_path NEW_V udump_path FOR A500;
SELECT value||DECODE(INSTR(value, '/'), 0, '\', '/') udump_path FROM v$parameter2 WHERE name = 'user_dump_dest';

-- tkprof for trace from execution of tool in case someone reports slow performance in tool
HOS tkprof ^^udump_path.*^^script._^^unique_id.*.trc ^^files_prefix._tkprof_nosort.txt
HOS tkprof ^^udump_path.*^^script._^^unique_id.*.trc ^^files_prefix._tkprof_sort.txt sort=prsela exeela fchela

-- windows workaround (copy below will error out on linux and unix)
HOS copy ^^udump_path.*^^script._^^unique_id.*.trc ^^udump_path.^^script._^^unique_id..trc
HOS tkprof ^^udump_path.^^script._^^unique_id..trc ^^files_prefix._tkprof_nosort.txt
HOS tkprof ^^udump_path.^^script._^^unique_id..trc ^^files_prefix._tkprof_sort.txt sort=prsela exeela fchela

SPO ^^script..log APP
SELECT 'END: '||TO_CHAR(SYSDATE, 'YYYY-MM-DD/HH24:MI:SS') FROM dual;
SPO OFF;

/**************************************************************************************************
 *
 * end_common: from begin_common to end_common sqlhc.sql and sqlhcxec.sql are identical
 *
 **************************************************************************************************/

-- zip now in case DBMS_SQLDIAG.DUMP_TRACE disconnects
HOS zip -m ^^files_prefix..zip ^^files_prefix._1_health_check.html
HOS zip -m ^^files_prefix..zip ^^files_prefix._2_diagnostics.html
HOS zip -m ^^files_prefix..zip ^^files_prefix._3_execution_plans.html
HOS zip -m ^^files_prefix..zip ^^files_prefix._4_sql_detail.html
HOS zip -m ^^files_prefix._9_log.zip ^^script..log
HOS zip -m ^^files_prefix._9_log.zip sql_shared_cursor_sum_^^sql_id..sql
HOS zip -m ^^files_prefix._9_log.zip sql_shared_cursor_col_^^sql_id..sql
HOS zip -m ^^files_prefix._9_log.zip sql_shared_cursor_cur_^^sql_id..sql
HOS zip -m ^^files_prefix._9_log.zip ^^files_prefix._tkprof_*.txt
HOS zip -m ^^files_prefix._9_log.zip ^^files_prefix._5_sql_monitor.sql
HOS zip -m ^^files_prefix..zip ^^files_prefix._9_log.zip
HOS zip -m ^^files_prefix._5_sql_monitor.zip ^^files_prefix._*_5_sql_monitor.html
HOS zip -m ^^files_prefix..zip ^^files_prefix._5_sql_monitor.zip

-- generate DBMS_SQLDIAG.DUMP_TRACE 10053. this api is called down here in case it disconnects.
EXEC DBMS_APPLICATION_INFO.SET_CLIENT_INFO('^^method.: DBMS_SQLDIAG.DUMP_TRACE - ' || TO_CHAR(SYSDATE, 'YYYY-MM-DD/HH24:MI:SS'));
BEGIN
  IF '^^rdbms_version.' >= '11.2' THEN
    DBMS_SQLDIAG.DUMP_TRACE (
      p_sql_id    => :sql_id,
      p_component => 'Optimizer',
      p_file_id   => 'DBMS_SQLDIAG_10053_^^unique_id.');
  END IF;
END;
/
EXEC DBMS_APPLICATION_INFO.SET_CLIENT_INFO('^^method.: DBMS_SQLDIAG.DUMP_TRACE Done - ' || TO_CHAR(SYSDATE, 'YYYY-MM-DD/HH24:MI:SS'));

-- copy DBMS_SQLDIAG.DUMP_TRACE 10053
SET TERM ON;
PRO Ignore CP or COPY error below
SET TERM OFF;
HOS cp ^^udump_path.*_DBMS_SQLDIAG_10053_^^unique_id.*.trc   ^^files_prefix._6_10053_trace_from_cursor.trc
HOS copy ^^udump_path.*_DBMS_SQLDIAG_10053_^^unique_id.*.trc ^^files_prefix._6_10053_trace_from_cursor.trc
HOS zip -m ^^files_prefix..zip ^^files_prefix._6_10053_trace_from_cursor.trc
SET TERM ON;
PRO
PRO ^^files_prefix..zip has been created.
PRO
HOS unzip -l ^^files_prefix..zip
SET TERM OFF;
-- end
EXEC DBMS_APPLICATION_INFO.SET_MODULE(module_name => NULL, action_name => NULL);
EXEC DBMS_APPLICATION_INFO.SET_CLIENT_INFO(client_info => '^^sqldx_prefix.');
@@sqldx.sql ^^license. ^^sqldx_output. ^^sql_id.
SET TERM ON ECHO OFF FEED 6 VER ON SHOW OFF HEA ON LIN 80 NEWP 1 PAGES 14 LONG 80 LONGC 80 SQLC MIX TAB ON TRIMS OFF TI OFF TIMI OFF ARRAY 15 NUMF "" SQLP SQL> SUF sql BLO . RECSEP WR APPI OFF SERVEROUT OFF AUTOT OFF;
PRO
SET DEF ON;
HOS zip -m &&files_prefix..zip &&sqldx_prefix.*
PRO
PRO SQLDX files have been added to &&files_prefix..zip
PRO
HOS unzip -l &&files_prefix..zip
CL COL;
UNDEF 1 2 method script mos_doc doc_ver doc_date doc_link bug_link input_parameter input_sql_id input_license unique_id sql_id signature signaturef license udump_path sqldx_prefix sqldx_output;
