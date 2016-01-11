SPO coe_load_sql_profile.log;
SET DEF ON TERM OFF ECHO ON FEED OFF VER OFF HEA ON LIN 2000 PAGES 100 LONG 8000000 LONGC 800000 TRIMS ON TI OFF TIMI OFF SERVEROUT ON SIZE 1000000 NUM 20 SQLP SQL>;
SET SERVEROUT ON SIZE UNL;
REM
REM $Header: 215187.1 coe_load_sql_profile.sql 11.4.5.5 2013/03/01 carlos.sierra $
REM
REM Copyright (c) 2000-2013, Oracle Corporation. All rights reserved.
REM
REM AUTHOR
REM   carlos.sierra@oracle.com
REM
REM SCRIPT
REM   coe_load_sql_profile.sql
REM
REM DESCRIPTION
REM   This script loads a plan from a modified SQL into a Custom SQL
REM   Profile for the original SQL.
REM   If a good performing plan only reproduces with CBO Hints
REM   then you can load the plan of the modified version of the
REM   SQL into a Custom SQL Profile for the orignal SQL.
REM   In other words, the original SQL can use the plan that was
REM   generated out of the SQL with hints.
REM
REM PRE-REQUISITES
REM   1. Have in cache or AWR the text for the original SQL.
REM   2. Have in cache or AWR the plan for the modified SQL
REM      (usually with hints).
REM
REM PARAMETERS
REM   1. ORIGINAL_SQL_ID (required)
REM   2. MODIFIED_SQL_ID (required)
REM   3. PLAN_HASH_VALUE (required)
REM
REM EXECUTION
REM   1. Connect into SQL*Plus as user with access to data dictionary
REM      and privileges to create SQL Profiles. Do not use SYS.
REM   2. Execute script coe_load_sql_profile.sql passing first two
REM      parameters inline or until requested by script.
REM   3. Provide plan hash value of the modified SQL when asked.
REM   4. Use a DBA user but not SYS. Do not connect as SYS as the staging
REM      table cannot be created in SYS schema and you will receive an error:
REM      ORA-19381: cannot create staging table in SYS schema
REM
REM EXAMPLE
REM   # sqlplus system
REM   SQL> START coe_load_sql_profile.sql gnjy0mn4y9pbm b8f3mbkd8bkgh
REM   SQL> START coe_load_sql_profile.sql;
REM
REM NOTES
REM   1. This script works on 10g or higher.
REM   2. For a similar script for 11g use coe_load_sql_baseline.sql,
REM      which uses SQL Plan Baselines instead of Custom SQL Profiles.
REM   3. For possible errors see coe_load_sql_profile.log
REM   4. If you get "ORA-06532: Subscript outside of limit, ORA-06512: at line 1"
REM      Then you may consider this change (only in a test and disposable system):
REM      create or replace TYPE sys.sqlprof_attr AS VARRAY(5000) of VARCHAR2(500);
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
SELECT plan_hash_value
  FROM gv$sql_plan
 WHERE sql_id = TRIM('&&modified_sql_id.')
   AND other_xml IS NOT NULL
 UNION
SELECT plan_hash_value
  FROM dba_hist_sql_plan
 WHERE sql_id = TRIM('&&modified_sql_id.')
   AND other_xml IS NOT NULL ),
m AS (
SELECT plan_hash_value,
       SUM(elapsed_time)/SUM(executions) avg_et_secs
  FROM gv$sql
 WHERE sql_id = TRIM('&&modified_sql_id.')
   AND executions > 0
 GROUP BY
       plan_hash_value ),
a AS (
SELECT plan_hash_value,
       SUM(elapsed_time_total)/SUM(executions_total) avg_et_secs
  FROM dba_hist_sqlstat
 WHERE sql_id = TRIM('&&modified_sql_id.')
   AND executions_total > 0
 GROUP BY
       plan_hash_value )
SELECT p.plan_hash_value,
       ROUND(NVL(m.avg_et_secs, a.avg_et_secs)/1e6, 3) avg_et_secs
  FROM p, m, a
 WHERE p.plan_hash_value = m.plan_hash_value(+)
   AND p.plan_hash_value = a.plan_hash_value(+)
 ORDER BY
       avg_et_secs NULLS LAST;
PRO
PRO Parameter 3:
PRO PLAN_HASH_VALUE (required)
PRO
DEF plan_hash_value = '&3';
PRO
PRO Values passed to coe_load_sql_profile:
PRO ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
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
SPO coe_load_sql_profile_&&original_sql_id..log;
GET coe_load_sql_profile.log;
.

-- get user
COL connected_user NEW_V connected_user FOR A30;
SELECT USER connected_user FROM DUAL;

VAR sql_text CLOB;
VAR other_xml CLOB;
VAR signature NUMBER;
VAR name VARCHAR2(30);

EXEC :sql_text := NULL;
EXEC :other_xml := NULL;
EXEC :signature := NULL;
EXEC :name := NULL;

-- get sql_text from memory
DECLARE
  l_sql_text VARCHAR2(32767);
BEGIN -- 10g see bug 5017909
  FOR i IN (SELECT DISTINCT piece, sql_text
              FROM gv$sqltext_with_newlines
             WHERE sql_id = TRIM('&&original_sql_id.')
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
    RAISE_APPLICATION_ERROR(-20100, 'SQL_TEXT for original SQL_ID &&original_sql_id. was not found in memory (gv$sqltext_with_newlines) or AWR (dba_hist_sqltext).');
  END IF;
END;
/
SET TERM OFF;

-- get other_xml from memory
BEGIN
  FOR i IN (SELECT other_xml
              FROM gv$sql_plan
             WHERE sql_id = TRIM('&&modified_sql_id.')
               AND plan_hash_value = TO_NUMBER(TRIM('&&plan_hash_value.'))
               AND other_xml IS NOT NULL
             ORDER BY
                   child_number, id)
  LOOP
    :other_xml := i.other_xml;
    EXIT; -- 1st
  END LOOP;
EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('getting modified other_xml from memory: '||SQLERRM);
    :other_xml := NULL;
END;
/

-- get other_xml from awr
BEGIN
  IF :other_xml IS NULL OR NVL(DBMS_LOB.GETLENGTH(:other_xml), 0) = 0 THEN
    FOR i IN (SELECT other_xml
                FROM dba_hist_sql_plan
               WHERE sql_id = TRIM('&&modified_sql_id.')
                 AND plan_hash_value = TO_NUMBER(TRIM('&&plan_hash_value.'))
                 AND other_xml IS NOT NULL
               ORDER BY
                     id)
    LOOP
      :other_xml := i.other_xml;
      EXIT; -- 1st
    END LOOP;
  END IF;
EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('getting modified other_xml from awr: '||SQLERRM);
    :other_xml := NULL;
END;
/

-- other_xml as found
SELECT :other_xml FROM DUAL;

-- validate other_xml
SET TERM ON;
BEGIN
  IF :other_xml IS NULL THEN
    RAISE_APPLICATION_ERROR(-20101, 'PLAN for modified SQL_ID &&modified_sql_id. and PHV &&plan_hash_value. was not found in memory (gv$sql_plan) or AWR (dba_hist_sql_plan).');
  END IF;
END;
/

SET ECHO OFF;
DECLARE
  h SYS.SQLPROF_ATTR := SYS.SQLPROF_ATTR ();
  idx INTEGER := 0;
  l_pos NUMBER;
  l_hint VARCHAR2(32767);
  description VARCHAR2(500);

  PROCEDURE add_hint (p_hint IN VARCHAR2)
  IS
  BEGIN
    idx := idx + 1;
    DBMS_OUTPUT.PUT_LINE(LPAD(idx, 4, '0')||' '||p_hint);
    h.EXTEND;
    h(idx) := p_hint;
  END add_hint;

BEGIN
  add_hint('BEGIN_OUTLINE_DATA');
  FOR i IN (SELECT /*+ opt_param('parallel_execution_enabled', 'false') */
                   SUBSTR(EXTRACTVALUE(VALUE(d), '/hint'), 1, 4000) hint
              FROM TABLE(XMLSEQUENCE(EXTRACT(XMLTYPE(:other_xml), '/*/outline_data/hint'))) d)
  LOOP
    l_hint := i.hint;
    WHILE NVL(LENGTH(l_hint), 0) > 0
    LOOP
      IF LENGTH(l_hint) <= 500 THEN
        add_hint(l_hint);
        l_hint := NULL;
      ELSE
        l_pos := INSTR(SUBSTR(l_hint, 1, 500), ' ', -1);
        add_hint(SUBSTR(l_hint, 1, l_pos));
        l_hint := '   '||SUBSTR(l_hint, l_pos);
      END IF;
    END LOOP;
  END LOOP;
  add_hint('END_OUTLINE_DATA');

  :signature := DBMS_SQLTUNE.SQLTEXT_TO_SIGNATURE(:sql_text);
  :name := UPPER(TRIM('&&original_sql_id.'))||'_'||TRIM('&&plan_hash_value.');
  description := UPPER('original:'||TRIM('&&original_sql_id.')||' modified:'||TRIM('&&modified_sql_id.')||' phv:'||TRIM('&&plan_hash_value.')||' signature:'||:signature||' created by coe_load_sql_profile.sql');

  -- create custom sql profile for original sql using plan from modified sql
  DBMS_SQLTUNE.IMPORT_SQL_PROFILE (
    sql_text    => :sql_text, -- original sql
    profile     => h, -- plan from modified sql
    name        => :name,
    description => description,
    category    => 'DEFAULT',
    validate    => TRUE,
    replace     => TRUE,
    force_match => FALSE /* TRUE:FORCE (match even when different literals in SQL). FALSE:EXACT (similar to CURSOR_SHARING) */ );

  -- drop sql profile staging table for original sql (if one exists)
  BEGIN
    DBMS_OUTPUT.PUT_LINE('dropping staging table "STGTAB_SQLPROF_'||UPPER(TRIM('&&original_sql_id.'))||'"');
    EXECUTE IMMEDIATE 'DROP TABLE STGTAB_SQLPROF_'||UPPER(TRIM('&&original_sql_id.'));
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('staging table "STGTAB_SQLPROF_'||UPPER(TRIM('&&original_sql_id.'))||'" did not exist');
  END;

  -- create sql profile staging table for original sql
  DBMS_OUTPUT.PUT_LINE('creating staging table "STGTAB_SQLPROF_'||UPPER(TRIM('&&original_sql_id.'))||'"');
  DBMS_SQLTUNE.CREATE_STGTAB_SQLPROF  (
    table_name  => 'STGTAB_SQLPROF_'||UPPER(TRIM('&&original_sql_id.')),
    schema_name => '&&connected_user.' );

  -- packs new sql profile for original sql
  DBMS_OUTPUT.PUT_LINE('packaging new sql profile into staging table "STGTAB_SQLPROF_'||UPPER(TRIM('&&original_sql_id.'))||'"');
  DBMS_SQLTUNE.PACK_STGTAB_SQLPROF (
     profile_name         => :name,
     staging_table_name   => 'STGTAB_SQLPROF_'||UPPER(TRIM('&&original_sql_id.')),
     staging_schema_owner => '&&connected_user.' );
END;
/

-- profile_name
COL profile_name NEW_V profile_name FOR A30;
SELECT :name profile_name FROM DUAL;

-- display details of new sql_profile
SET ECHO ON;
REM
REM SQL Profile
REM ~~~~~~~~~~~
REM
SELECT signature, name, category, type, status
  FROM dba_sql_profiles WHERE name = :name;
SELECT description
  FROM dba_sql_profiles WHERE name = :name;
SET ECHO OFF;
PRO
PRO ****************************************************************************
PRO * Enter &&connected_user. password to export staging table STGTAB_SQLPROF_&&original_sql_id.
PRO ****************************************************************************
HOS exp &&connected_user. tables=&&connected_user..STGTAB_SQLPROF_&&original_sql_id. file=STGTAB_SQLPROF_&&original_sql_id..dmp statistics=NONE indexes=N constraints=N grants=N triggers=N
PRO
PRO If you need to implement this Custom SQL Profile on a similar system,
PRO import and unpack using these commands:
PRO
PRO imp &&connected_user. file=STGTAB_SQLPROF_&&original_sql_id..dmp tables=STGTAB_SQLPROF_&&original_sql_id. ignore=Y
PRO
PRO BEGIN
PRO   DBMS_SQLTUNE.UNPACK_STGTAB_SQLPROF (
PRO     profile_name => '&&profile_name.',
PRO     replace => TRUE,
PRO     staging_table_name => 'STGTAB_SQLPROF_&&original_sql_id.',
PRO     staging_schema_owner => '&&connected_user.' );;
PRO END;;
PRO /
PRO
SPO OFF;
HOS zip -m coe_load_sql_profile_&&original_sql_id. coe_load_sql_profile_&&original_sql_id..log STGTAB_SQLPROF_&&original_sql_id..dmp coe_load_sql_profile.log
HOS zip -d coe_load_sql_profile_&&original_sql_id. coe_load_sql_profile.log
WHENEVER SQLERROR CONTINUE;
SET DEF ON TERM ON ECHO OFF FEED 6 VER ON HEA ON LIN 80 PAGES 14 LONG 80 LONGC 80 TRIMS OFF TI OFF TIMI OFF SERVEROUT OFF NUM 10 SQLP SQL>;
SET SERVEROUT OFF;
UNDEFINE 1 2 3 original_sql_id modified_sql_id plan_hash_value profile_name
CL COL
PRO
PRO coe_load_sql_profile completed.
