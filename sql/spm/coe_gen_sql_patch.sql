SPO coe_gen_sql_patch.log;
DEF def_hint_text = 'GATHER_PLAN_STATISTICS MONITOR BIND_AWARE';
SET DEF ON TERM OFF ECHO ON FEED OFF VER OFF HEA ON LIN 2000 PAGES 100 LONG 8000000 LONGC 800000 TRIMS ON TI OFF TIMI OFF SERVEROUT ON SIZE 1000000 NUMF "" SQLP SQL>;
SET SERVEROUT ON SIZE UNL;
REM
REM $Header: 215187.1 coe_gen_sql_patch.sql 12.1.02 2013/09/00 carlos.sierra $
REM
REM Copyright (c) 2000-2013, Oracle Corporation. All rights reserved.
REM
REM AUTHOR
REM   carlos.sierra@oracle.com
REM
REM SCRIPT
REM   coe_gen_sql_patch.sql
REM
REM DESCRIPTION
REM   This script create a SQL Patch with some diagnostics
REM   CBO Hints for one SQL. It also produces some event 10053
REM   traces for same SQL.
REM
REM PRE-REQUISITES
REM   1. Oracle Diagnostics Pack license.
REM
REM PARAMETERS
REM   1. SQL_ID (required)
REM   2. HINT_TEXT (defaults to def_hint_text)
REM
REM EXECUTION
REM   1. Connect into SQL*Plus as SYS.
REM   2. Execute script coe_gen_sql_patch.sql passing SQL_ID
REM      and optional HINT_TEXT.
REM      (parameters can be passed inline or until requested).
REM
REM EXAMPLE
REM   # sqlplus system
REM   SQL> START coe_gen_sql_patch.sql [SQL_ID];
REM   SQL> START coe_gen_sql_patch.sql gnjy0mn4y9pbm;
REM   SQL> START coe_gen_sql_patch.sql;
REM
REM NOTES
REM   1. For possible errors see coe_gen_sql_patch.log
REM   2. Be aware that using this script requires a license
REM      for the Oracle Diagnostics Pack.
REM   3. Connect as SYS.
REM   4. To drop SQL Patch and stop 10053 on this SQL:
REM      EXEC DBMS_SQLDIAG.DROP_SQL_PATCH(name => 'coe_&&sql_id.');
REM      ALTER SYSTEM SET EVENTS 'trace[rdbms.SQL_Optimizer.*][sql:&&sql_id.] off';
REM   5. References:
REM      https://blogs.oracle.com/optimizer/entry/how_do_i_capture_a
REM      https://blogs.oracle.com/optimizer/entry/how_can_i_hint_a
REM      https://blogs.oracle.com/optimizer/entry/capturing_10053_trace_files_continued
REM      http://ronr.blogspot.com/2012/12/how-to-trace-optimizer-for-specific-sql.html
REM      http://kerryosborne.oracle-guy.com/scripts/gps.sql
REM
COL hint_text NEW_V hint_text FOR A300;
SET TERM ON ECHO OFF;
PRO
PRO Parameter 1:
PRO SQL_ID (required)
PRO
DEF sql_id_1 = '&1';
PRO
PRO Parameter 2:
PRO HINT_TEXT (default: &&def_hint_text.)
PRO
DEF hint_text_2 = '&2';
PRO
PRO Values passed to coe_gen_sql_patch:
PRO ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
PRO SQL_ID   : "&&sql_id_1."
PRO HINT_TEXT: "&&hint_text_2." (default: "&&def_hint_text.")
PRO
SET TERM OFF ECHO ON;
SELECT TRIM(NVL(REPLACE('&&hint_text_2.', '"', ''''''), '&&def_hint_text.')) hint_text FROM dual;
WHENEVER SQLERROR EXIT SQL.SQLCODE;

-- trim sql_id parameter
COL sql_id NEW_V sql_id FOR A30;
SELECT TRIM('&&sql_id_1.') sql_id FROM DUAL;

VAR sql_text CLOB;
VAR sql_text2 CLOB;
EXEC :sql_text := NULL;
EXEC :sql_text2 := NULL;

-- get sql_text from memory
DECLARE
  l_sql_text VARCHAR2(32767);
BEGIN -- 10g see bug 5017909
  FOR i IN (SELECT DISTINCT piece, sql_text
              FROM gv$sqltext_with_newlines
             WHERE sql_id = TRIM('&&sql_id.')
             ORDER BY 1, 2)
  LOOP
    IF :sql_text IS NULL THEN
      DBMS_LOB.CREATETEMPORARY(:sql_text, TRUE);
      DBMS_LOB.OPEN(:sql_text, DBMS_LOB.LOB_READWRITE);
    END IF;
    l_sql_text := REPLACE(i.sql_text, CHR(00), ' '); -- removes NUL characters
    DBMS_LOB.WRITEAPPEND(:sql_text, LENGTH(l_sql_text), l_sql_text); 
  END LOOP;
  -- if found in memory then sql_text is not null
  IF :sql_text IS NOT NULL THEN
    DBMS_LOB.CLOSE(:sql_text);
  END IF;
EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('getting sql_text from memory: '||SQLERRM);
    :sql_text := NULL;
END;
/

SELECT :sql_text FROM DUAL;

-- get sql_text from awr
DECLARE
  l_sql_text VARCHAR2(32767);
  l_clob_size NUMBER;
  l_offset NUMBER;
BEGIN
  IF :sql_text IS NULL OR NVL(DBMS_LOB.GETLENGTH(:sql_text), 0) = 0 THEN
    SELECT sql_text
      INTO :sql_text2
      FROM dba_hist_sqltext
     WHERE sql_id = TRIM('&&sql_id.')
       AND sql_text IS NOT NULL
       AND ROWNUM = 1;
  END IF;
  -- if found in awr then sql_text2 is not null
  IF :sql_text2 IS NOT NULL THEN
    l_clob_size := NVL(DBMS_LOB.GETLENGTH(:sql_text2), 0);
    l_offset := 1;
    DBMS_LOB.CREATETEMPORARY(:sql_text, TRUE);
    DBMS_LOB.OPEN(:sql_text, DBMS_LOB.LOB_READWRITE);
    -- store in clob as 64 character pieces 
    WHILE l_offset < l_clob_size
    LOOP
      IF l_clob_size - l_offset > 64 THEN
        l_sql_text := REPLACE(DBMS_LOB.SUBSTR(:sql_text2, 64, l_offset), CHR(00), ' ');
      ELSE -- last piece
        l_sql_text := REPLACE(DBMS_LOB.SUBSTR(:sql_text2, l_clob_size - l_offset + 1, l_offset), CHR(00), ' ');
      END IF;
      DBMS_LOB.WRITEAPPEND(:sql_text, LENGTH(l_sql_text), l_sql_text);
      l_offset := l_offset + 64;
    END LOOP;
    DBMS_LOB.CLOSE(:sql_text);
  END IF;
EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('getting sql_text from awr: '||SQLERRM);
    :sql_text := NULL;
END;
/


SELECT :sql_text2 FROM DUAL;
SELECT :sql_text FROM DUAL;

-- validate sql_text
BEGIN
  IF :sql_text IS NULL THEN
    RAISE_APPLICATION_ERROR(-20100, 'SQL_TEXT for SQL_ID &&sql_id. was not found in memory (gv$sqltext_with_newlines) or AWR (dba_hist_sqltext).');
  END IF;
END;
/

PRO generate SQL Patch for SQL "&&sql_id." with CBO Hints "&&hint_text."

-- generates 10053 CBO traces for existing cursors
-- to find traces on udump look for files with name *_<your_sql_id>_10053_c*
SELECT loaded_versions, invalidations, address, hash_value
FROM v$sqlarea WHERE sql_id = '&&sql_id.' ORDER BY 1;
SELECT child_number, plan_hash_value, executions, is_shareable
FROM v$sql WHERE sql_id = '&&sql_id.' ORDER BY 1, 2;
PRO *** 10053 for &&sql_id. ***
BEGIN
  FOR i IN (SELECT child_number FROM v$sql WHERE sql_id = '&&sql_id.' ORDER BY 1)
  LOOP
    DBMS_OUTPUT.PUT_LINE('child_number:'||i.child_number);
    BEGIN
      DBMS_SQLDIAG.DUMP_TRACE (
        p_sql_id       => '&&sql_id.',
        p_child_number => i.child_number,
        p_component    => 'Optimizer', /* 'Optimizer' or 'Compiler' */
        p_file_id      => '&&sql_id._10053_c'||i.child_number
      );
    EXCEPTION
      WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE(SQLERRM);
    END;
  END LOOP;
END;
/

-- turn on event 10053 CBO trace for the one sql
-- to find traces on udump (as per http://ronr.blogspot.com/2012/12/how-to-trace-optimizer-for-specific-sql.html)
-- grep -c "sql_id=<your_sql_id>" *.trc | grep -v :0$
ALTER SYSTEM SET EVENTS 'trace[rdbms.SQL_Optimizer.*][sql:&&sql_id.]';
-- to turn it off: ALTER SYSTEM SET EVENTS 'trace[rdbms.SQL_Optimizer.*][sql:&&sql_id.] off';

-- drop prior SQL Patch
WHENEVER SQLERROR CONTINUE;
PRO ignore errors
EXEC DBMS_SQLDIAG.DROP_SQL_PATCH(name => 'coe_&&sql_id.');
WHENEVER SQLERROR EXIT SQL.SQLCODE;

-- create SQL Patch
PRO you have to connect as SYS
BEGIN
  SYS.DBMS_SQLDIAG_INTERNAL.I_CREATE_PATCH (
    sql_text    => :sql_text,
    hint_text   => '&&hint_text.',
    name        => 'coe_&&sql_id.',
    category    => 'DEFAULT',
    description => '/*+ &&hint_text. */'
  );
END;
/

-- flush cursor from shared_pool
PRO *** before flush ***
SELECT inst_id, loaded_versions, invalidations, address, hash_value
FROM gv$sqlarea WHERE sql_id = '&&sql_id.' ORDER BY 1;
SELECT inst_id, child_number, plan_hash_value, executions, is_shareable
FROM gv$sql WHERE sql_id = '&&sql_id.' ORDER BY 1, 2;
PRO *** flushing &&sql_id. ***
BEGIN
  FOR i IN (SELECT address, hash_value
              FROM gv$sqlarea WHERE sql_id = '&&sql_id.')
  LOOP
    DBMS_OUTPUT.PUT_LINE(i.address||','||i.hash_value);
    BEGIN
      SYS.DBMS_SHARED_POOL.PURGE (
        name => i.address||','||i.hash_value,
        flag => 'C'
      );
    EXCEPTION
      WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE(SQLERRM);
    END;
  END LOOP;
END;
/
PRO *** after flush ***
SELECT inst_id, loaded_versions, invalidations, address, hash_value
FROM gv$sqlarea WHERE sql_id = '&&sql_id.' ORDER BY 1;
SELECT inst_id, child_number, plan_hash_value, executions, is_shareable
FROM gv$sql WHERE sql_id = '&&sql_id.' ORDER BY 1, 2;

WHENEVER SQLERROR CONTINUE;
SET DEF ON TERM ON ECHO OFF FEED 6 VER ON HEA ON LIN 80 PAGES 14 LONG 80 LONGC 80 TRIMS OFF TI OFF TIMI OFF SERVEROUT OFF NUMF "" SQLP SQL>;
SET SERVEROUT OFF;
PRO
PRO SQL Patch "coe_&&sql_id." will be used on next parse.
PRO Look for some new 10053 traces on udump:
PRO 1. files with name *_&&sql_id._10053_c*
PRO 2. grep -c "sql_id=&&sql_id." *.trc | grep -v :0$
PRO Monitor SQL performance with SQLT XTRACT.
PRO To drop SQL Patch and stop 10053 on this SQL:
PRO EXEC DBMS_SQLDIAG.DROP_SQL_PATCH(name => 'coe_&&sql_id.');
PRO ALTER SYSTEM SET EVENTS 'trace[rdbms.SQL_Optimizer.*][sql:&&sql_id.] off';
PRO
UNDEFINE 1 2 sql_id_1 sql_id hint_text_2 hint_text
CL COL
PRO
PRO coe_gen_sql_patch completed.
SPO OFF;
