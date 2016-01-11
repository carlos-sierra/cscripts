SPO coe_load_sql_baseline.log;
SET DEF ON TERM OFF ECHO ON FEED OFF VER OFF HEA ON LIN 2000 PAGES 100 LONG 8000000 LONGC 800000 TRIMS ON TI OFF TIMI OFF SERVEROUT ON SIZE 1000000 NUM 20 SQLP SQL>;
SET SERVEROUT ON SIZE UNL;
REM
REM $Header: 215187.1 coe_load_sql_baseline.sql 11.4.5.8 2013/05/10 carlos.sierra $
REM
REM Copyright (c) 2000-2013, Oracle Corporation. All rights reserved.
REM
REM AUTHOR
REM   carlos.sierra@oracle.com
REM
REM SCRIPT
REM   coe_load_sql_baseline.sql
REM
REM DESCRIPTION
REM   This script loads a plan from a modified SQL into the SQL
REM   Plan Baseline of the original SQL.
REM   If a good performing plan only reproduces with CBO Hints
REM   then you can load the plan of the modified version of the
REM   SQL into the SQL Plan Baseline of the orignal SQL.
REM   In other words, the original SQL can use the plan that was
REM   generated out of the SQL with hints.
REM
REM PRE-REQUISITES
REM   1. Have in cache or AWR the text for the original SQL.
REM   2. Have in cache the plan for the modified SQL
REM      (usually with hints).
REM
REM PARAMETERS
REM   1. ORIGINAL_SQL_ID (required)
REM   2. MODIFIED_SQL_ID (required)
REM   3. PLAN_HASH_VALUE (required)
REM
REM EXECUTION
REM   1. Connect into SQL*Plus as user with access to data dictionary
REM      and privileges to create SQL Plan Baselines. Do not use SYS.
REM   2. Execute script coe_load_sql_baseline.sql passing first two
REM      parameters inline or until requested by script.
REM   3. Provide plan hash value of the modified SQL when asked.
REM
REM EXAMPLE
REM   # sqlplus system
REM   SQL> START coe_load_sql_baseline.sql gnjy0mn4y9pbm b8f3mbkd8bkgh
REM   SQL> START coe_load_sql_baseline.sql;
REM
REM NOTES
REM   1. This script works on 11g or higher.
REM   2. For a similar script for 10g use coe_load_sql_profile.sql,
REM      which uses custom SQL Profiles instead of SQL Baselines.
REM   3. For possible errors see coe_load_sql_baseline.log
REM   4. Use a DBA user but not SYS. Do not connect as SYS as the staging
REM      table cannot be created in SYS schema and you will receive an error:
REM      ORA-19381: cannot create staging table in SYS schema
REM
SET TERM ON ECHO OFF;
PRO
PRO Parameter 1:
PRO ORIGINAL_SQL_ID (required)
PRO
DEF original_sql_id = '&1';
PRO
PRO Parameter 2:
PRO MODIFIED_SQL_ID (required)
PRO
DEF modified_sql_id = '&2';
PRO
WITH
p AS (
SELECT DISTINCT plan_hash_value
  FROM gv$sql_plan
 WHERE sql_id = TRIM('&&modified_sql_id.')
   AND other_xml IS NOT NULL ),
m AS (
SELECT plan_hash_value,
       SUM(elapsed_time)/SUM(executions) avg_et_secs
  FROM gv$sql
 WHERE sql_id = TRIM('&&modified_sql_id.')
   AND executions > 0
 GROUP BY
       plan_hash_value )
SELECT p.plan_hash_value,
       ROUND(m.avg_et_secs/1e6, 3) avg_et_secs
  FROM p, m
 WHERE p.plan_hash_value = m.plan_hash_value
 ORDER BY
       avg_et_secs NULLS LAST;
PRO
PRO Parameter 3:
PRO PLAN_HASH_VALUE (required)
PRO
DEF plan_hash_value = '&3';
PRO
PRO Values passed to coe_load_sql_baseline:
PRO ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
PRO ORIGINAL_SQL_ID: "&&original_sql_id."
PRO MODIFIED_SQL_ID: "&&modified_sql_id."
PRO PLAN_HASH_VALUE: "&&plan_hash_value."
PRO
WHENEVER SQLERROR EXIT SQL.SQLCODE;
SET TERM OFF ECHO ON;

-- trim parameters
COL original_sql_id NEW_V original_sql_id FOR A30;
COL modified_sql_id NEW_V modified_sql_id FOR A30;
COL plan_hash_value NEW_V plan_hash_value FOR A30;
SELECT TRIM('&&original_sql_id.') original_sql_id, TRIM('&&modified_sql_id.') modified_sql_id, TRIM('&&plan_hash_value.') plan_hash_value FROM DUAL;

-- open log file
SPO coe_load_sql_baseline_&&original_sql_id..log;
GET coe_load_sql_baseline.log;
.

-- get user
COL connected_user NEW_V connected_user FOR A30;
SELECT USER connected_user FROM DUAL;

VAR sql_text CLOB;
VAR plan_name VARCHAR2(30);
EXEC :sql_text := NULL;
EXEC :plan_name := NULL;

-- get sql_text from memory
BEGIN
  SELECT REPLACE(sql_fulltext, CHR(00), ' ')
    INTO :sql_text
    FROM gv$sqlarea
   WHERE sql_id = TRIM('&&original_sql_id.')
     AND ROWNUM = 1;
EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('getting original sql_text from memory: '||SQLERRM);
    :sql_text := NULL;
END;
/

-- get sql_text from awr
BEGIN
  IF :sql_text IS NULL OR NVL(DBMS_LOB.GETLENGTH(:sql_text), 0) = 0 THEN
    SELECT REPLACE(sql_text, CHR(00), ' ')
      INTO :sql_text
      FROM dba_hist_sqltext
     WHERE sql_id = TRIM('&&original_sql_id.')
       AND sql_text IS NOT NULL
       AND ROWNUM = 1;
  END IF;
EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('getting original sql_text from awr: '||SQLERRM);
    :sql_text := NULL;
END;
/

-- sql_text as found
SELECT :sql_text FROM DUAL;

-- check is sql_text for original sql is available
SET TERM ON;
BEGIN
  IF :sql_text IS NULL THEN
    RAISE_APPLICATION_ERROR(-20100, 'SQL_TEXT for original SQL_ID &&original_sql_id. was not found in memory (gv$sqlarea) or AWR (dba_hist_sqltext).');
  END IF;
END;
/

-- check phv is found
DECLARE
  l_count NUMBER;
BEGIN
  SELECT COUNT(*)
    INTO l_count
    FROM gv$sql
   WHERE sql_id = TRIM('&&modified_sql_id.')
     AND plan_hash_value = TO_NUMBER(TRIM('&&plan_hash_value.'));

   IF l_count = 0 THEN
     RAISE_APPLICATION_ERROR(-20110, 'PHV &&plan_hash_value. for modified SQL_ID &&modified_sql_id. was not be found in memory (gv$sql).');
   END IF;
END;
/

SET ECHO OFF;
DECLARE
  plans NUMBER;
  description VARCHAR2(500);
  sys_sql_handle VARCHAR2(30);
  sys_plan_name VARCHAR2(30);
BEGIN
  -- create sql_plan_baseline for original sql using plan from modified sql
  plans :=
  DBMS_SPM.LOAD_PLANS_FROM_CURSOR_CACHE (
    sql_id          => TRIM('&&modified_sql_id.'),
    plan_hash_value => TO_NUMBER(TRIM('&&plan_hash_value.')),
    sql_text        => :sql_text );
  DBMS_OUTPUT.PUT_LINE('Plans Loaded: '||plans);

  -- find handle and plan_name for sql_plan_baseline just created
  SELECT sql_handle, plan_name
    INTO sys_sql_handle, sys_plan_name
    FROM dba_sql_plan_baselines
   WHERE creator = USER
     AND origin = 'MANUAL-LOAD'
     AND created = ( -- past 1 minute only
  SELECT MAX(created) max_created
    FROM dba_sql_plan_baselines
   WHERE creator = USER
     AND origin = 'MANUAL-LOAD'
     AND created > SYSDATE - (1/24/60));
  DBMS_OUTPUT.PUT_LINE('sys_sql_handle: "'||sys_sql_handle||'"');
  DBMS_OUTPUT.PUT_LINE('sys_plan_name: "'||sys_plan_name||'"');

  -- update description of new sql_plan_baseline
  description := UPPER('original:'||TRIM('&&original_sql_id.')||' modified:'||TRIM('&&modified_sql_id.')||' phv:'||TRIM('&&plan_hash_value.')||' created by coe_load_sql_baseline.sql');
  plans :=
  DBMS_SPM.ALTER_SQL_PLAN_BASELINE (
    sql_handle      => sys_sql_handle,
    plan_name       => sys_plan_name,
    attribute_name  => 'description',
    attribute_value => description );
  DBMS_OUTPUT.PUT_LINE(plans||' plan(s) modified description: "'||description||'"');

  -- update plan_name of new sql_plan_baseline
  :plan_name := UPPER(TRIM('&&original_sql_id.')||'_'||TRIM('&&modified_sql_id.'));
  :plan_name := sys_plan_name; -- avoids ORA-38141: SQL plan baseline SQL_PLAN_64b0jqr2t1h3558b5ab4d does not exist
  IF :plan_name <> sys_plan_name THEN
    plans :=
    DBMS_SPM.ALTER_SQL_PLAN_BASELINE (
      sql_handle      => sys_sql_handle,
      plan_name       => sys_plan_name,
      attribute_name  => 'plan_name',
      attribute_value => :plan_name );
    DBMS_OUTPUT.PUT_LINE(plans||' plan(s) modified plan_name: "'||:plan_name||'"');
  END IF;

  -- drop baseline staging table for original sql (if one exists)
  BEGIN
    DBMS_OUTPUT.PUT_LINE('dropping staging table "STGTAB_BASELINE_'||UPPER(TRIM('&&original_sql_id.'))||'"');
    EXECUTE IMMEDIATE 'DROP TABLE STGTAB_BASELINE_'||UPPER(TRIM('&&original_sql_id.'));
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('staging table "STGTAB_BASELINE_'||UPPER(TRIM('&&original_sql_id.'))||'" did not exist');
  END;

  -- create baseline staging table for original sql
  DBMS_OUTPUT.PUT_LINE('creating staging table "STGTAB_BASELINE_'||UPPER(TRIM('&&original_sql_id.'))||'"');
  DBMS_SPM.CREATE_STGTAB_BASELINE (
    table_name  => 'STGTAB_BASELINE_'||UPPER(TRIM('&&original_sql_id.')),
    table_owner => '&&connected_user.' );

  -- packs new baseline for original sql
  DBMS_OUTPUT.PUT_LINE('packaging new sql baseline into staging table "STGTAB_BASELINE_'||UPPER(TRIM('&&original_sql_id.'))||'"');
  plans :=
  DBMS_SPM.PACK_STGTAB_BASELINE (
     table_name  => 'STGTAB_BASELINE_'||UPPER(TRIM('&&original_sql_id.')),
     table_owner => '&&connected_user.',
     sql_handle  => sys_sql_handle,
     plan_name   => :plan_name );
  DBMS_OUTPUT.PUT_LINE(plans||' pla(s) packaged');
END;
/

-- display details of new sql_plan_baseline
SET ECHO ON;
REM
REM SQL Plan Baseline
REM ~~~~~~~~~~~~~~~~~
REM
SELECT signature, sql_handle, plan_name, enabled, accepted, fixed--, reproduced (avail on 11.2.0.2)
  FROM dba_sql_plan_baselines WHERE plan_name = :plan_name;
SELECT description
  FROM dba_sql_plan_baselines WHERE plan_name = :plan_name;
SET ECHO OFF;
PRO
PRO ****************************************************************************
PRO * Enter &&connected_user. password to export staging table STGTAB_BASELINE_&&original_sql_id.
PRO ****************************************************************************
HOS exp &&connected_user. tables=&&connected_user..STGTAB_BASELINE_&&original_sql_id. file=STGTAB_BASELINE_&&original_sql_id..dmp statistics=NONE indexes=N constraints=N grants=N triggers=N
PRO
PRO If you need to implement this SQL Plan Baseline on a similar system,
PRO import and unpack using these commands:
PRO
PRO imp &&connected_user. file=STGTAB_BASELINE_&&original_sql_id..dmp tables=STGTAB_BASELINE_&&original_sql_id. ignore=Y
PRO
PRO SET SERVEROUT ON;;
PRO DECLARE
PRO   plans NUMBER;;
PRO BEGIN
PRO   plans := DBMS_SPM.UNPACK_STGTAB_BASELINE('STGTAB_BASELINE_&&original_sql_id.', '&&connected_user.');;
PRO   DBMS_OUTPUT.PUT_LINE(plans||' plan(s) unpackaged');;
PRO END;;
PRO /
PRO
SPO OFF;
HOS zip -m coe_load_sql_baseline_&&original_sql_id. coe_load_sql_baseline_&&original_sql_id..log STGTAB_BASELINE_&&original_sql_id..dmp coe_load_sql_baseline.log
HOS zip -d coe_load_sql_baseline_&&original_sql_id. coe_load_sql_baseline.log
WHENEVER SQLERROR CONTINUE;
SET DEF ON TERM ON ECHO OFF FEED 6 VER ON HEA ON LIN 80 PAGES 14 LONG 80 LONGC 80 TRIMS OFF TI OFF TIMI OFF SERVEROUT OFF NUM 10 SQLP SQL>;
SET SERVEROUT OFF;
UNDEFINE 1 2 3 original_sql_id modified_sql_id plan_hash_value
CL COL
PRO
PRO coe_load_sql_baseline completed.
