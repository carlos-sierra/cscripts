SPO sqldx.log
SET DEF ON;
SET DEF ^ TERM OFF ECHO ON VER OFF SERVEROUT ON SIZE UNL;
REM
REM $Header: 1366133.1 sqldx.sql 12.1.04 2013/11/11 carlos.sierra mauro.pagano $
REM
REM Copyright (c) 2000-2013, Oracle Corporation. All rights reserved.
REM
REM AUTHOR
REM   carlos.sierra@oracle.com
REM   mauro.pagano@oracle.com
REM
REM SCRIPT
REM   sqldx.sql SQL Dynamic eXtract
REM
REM DESCRIPTION
REM   Produces a set of reports with information about one SQL
REM   statement.
REM
REM   This script does not install any objects in the database.
REM   It does not perform any DDL commands.
REM   It can be used in Dataguard or any read-only database.
REM
REM PRE-REQUISITES
REM   1. Execute as SYS or user with DBA role or user with access
REM      to data dictionary views.
REM
REM PARAMETERS
REM   1. Oracle Pack license (Tuning or Diagnostics) T|D
REM   2. Output Type (HTML or CSV or Both) H|C|B
REM   3. SQL_ID of interest.
REM
REM EXECUTION
REM   1. Start SQL*Plus connecting as SYS or user with DBA role or
REM      user with access to data dictionary views.
REM   2. Execute script sqldx.sql passing values for parameters.
REM
REM EXAMPLE
REM   # sqlplus / as sysdba
REM   SQL> START [path]sqldx.sql [T|D] [H|C|B] [SQL_ID]
REM   SQL> START sqldx.sql T B 51x6yr9ym5hdc
REM
REM NOTES
REM   1. For possible errors see sqldx.log.
REM   2. If site has both Tuning and Diagnostics licenses then
REM      specified T (Oracle Tuning pack includes Oracle Diagnostics)
REM
DEF script = 'sqldx';
DEF module = 'SQLDX';
DEF mos_doc = '1366133.1';
DEF doc_ver = '12.1.04';
DEF doc_date = '2013/11/11';
DEF max_rows_threshold = 10000;

/**************************************************************************************************/

SET TERM ON ECHO OFF;
PRO
PRO Parameter 1:
PRO Oracle Pack License (Tuning or Diagnostics) [T|D] (required)
PRO
DEF input_license = '^1';
PRO
SET TERM OFF;

COL olicense NEW_V olicense FOR A1;
SELECT 'license: ' x, NVL(UPPER(SUBSTR(TRIM('^^input_license.'), 1, 1)), 'N') olicense FROM DUAL;
VAR olicense CHAR(1);
EXEC :olicense := '^^olicense.';

SET TERM ON;
WHENEVER SQLERROR EXIT SQL.SQLCODE;

BEGIN
  IF '^^olicense.' IS NULL OR '^^olicense.' NOT IN ('T', 'D', 'N') THEN
    RAISE_APPLICATION_ERROR(-20100, 'Oracle Pack License (Tuning or Diagnostics) must be specified as "T" or "D".');
  END IF;
END;
/

WHENEVER SQLERROR CONTINUE;

PRO
PRO Parameter 2:
PRO Output Type (HTML or CSV or Both) [H|C|B] (required)
PRO
DEF input_output_type = '^2';
PRO
SET TERM OFF;

COL output_type NEW_V output_type FOR A1;
SELECT 'output_type: ' x, NVL(UPPER(SUBSTR(TRIM('^^input_output_type.'), 1, 1)), 'B') output_type FROM DUAL;
VAR output_type CHAR(1);
EXEC :output_type := UPPER(SUBSTR('^^output_type.', 1, 1));

SET TERM ON;
WHENEVER SQLERROR EXIT SQL.SQLCODE;

BEGIN
  IF '^^output_type.' IS NULL OR '^^output_type.' NOT IN ('H', 'C', 'B', 'N') THEN
    RAISE_APPLICATION_ERROR(-20100, 'Output Type (HTML or CSV or Both) must be specified as "H" or "C" or "B".');
  END IF;
END;
/

WHENEVER SQLERROR CONTINUE;

PRO
PRO Parameter 3:
PRO SQL_ID of the SQL to be analyzed (required)
PRO
DEF input_sql_id = '^3';
PRO

PRO Values passed:
PRO License: "^^input_license."
PRO Output : "^^input_output_type."
PRO SQL_ID : "^^input_sql_id."
PRO

/**************************************************************************************************/

SET TERM OFF;

-- get current time
COL current_time NEW_V current_time FOR A15;
SELECT 'current_time: ' x, TO_CHAR(SYSDATE, 'YYYYMMDD_HH24MISS') current_time FROM DUAL;

-- get file names prefix if executed from sqlt or sqlhc
SELECT 'client_info: ' x, SYS_CONTEXT('USERENV', 'CLIENT_INFO') client_info FROM DUAL;
COL prefix NEW_V prefix FOR A256;
-- sqldx.sql can be executed stand alone or called from sqlt or sqlhc
SELECT 'prefix: ' x, CASE WHEN SUBSTR(SYS_CONTEXT('USERENV', 'CLIENT_INFO'), 1, 4) IN ('sqlt', 'sqlh') THEN SYS_CONTEXT('USERENV', 'CLIENT_INFO') ELSE '^^script._^^current_time.' END prefix FROM DUAL;

-- get dblink if executed from sqltxtrsby
VAR module_name VARCHAR2(256);
VAR action_name VARCHAR2(256);
EXEC DBMS_APPLICATION_INFO.READ_MODULE(module_name => :module_name, action_name => :action_name);
COL my_dblink NEW_V my_dblink FOR A256;
SELECT 'my_dblink: ' x, CASE WHEN :module_name = 'sqltxtrsby' AND SUBSTR(:action_name, 1, 1) = '@' THEN :action_name ELSE NULL END my_dblink FROM DUAL;

-- reset module, action and client info
EXEC DBMS_APPLICATION_INFO.SET_MODULE(module_name => NULL, action_name => NULL);
EXEC DBMS_APPLICATION_INFO.SET_CLIENT_INFO(client_info => NULL);

-- get dbid
COL dbid NEW_V dbid;
SELECT 'dbid: ' x, dbid FROM v$database^^my_dblink.;

COL sql_id NEW_V sql_id FOR A13;
SELECT 'sql_id mem: ' x, sql_id
  FROM gv$sqlarea^^my_dblink.
 WHERE sql_id = TRIM('^^input_sql_id.')
 UNION
SELECT 'sql_id awr: ' x, sql_id
  FROM dba_hist_sqltext^^my_dblink.
 WHERE :olicense IN ('T', 'D')
   AND dbid = ^^dbid.
   AND sql_id = TRIM('^^input_sql_id.');
SELECT 'sql_id: ' x, NVL('^^sql_id.', TRIM('^^input_sql_id.')) sql_id FROM DUAL;
VAR sql_id VARCHAR2(13);
EXEC :sql_id := '^^sql_id.';

SET TERM ON;
WHENEVER SQLERROR EXIT SQL.SQLCODE;

BEGIN
  IF '^^sql_id.' IS NULL THEN
    IF :olicense IN ('T', 'D') THEN
      RAISE_APPLICATION_ERROR(-20200, 'SQL_ID "^^input_sql_id." not found in memory nor in AWR.');
    ELSE
      RAISE_APPLICATION_ERROR(-20200, 'SQL_ID "^^input_sql_id." not found in memory.');
    END IF;
  END IF;
END;
/

WHENEVER SQLERROR CONTINUE;
SET TERM OFF;

-- get file names prefix by sql_id
COL prefix1 NEW_V prefix1 FOR A256;
SELECT 'prefix1: ' x, '^^prefix._^^sql_id.' prefix1 FROM DUAL;

-- get file names prefix by global
COL prefix4 NEW_V prefix4 FOR A256;
SELECT 'prefix4: ' x, '^^prefix._global' prefix4 FROM DUAL;

-- get file names prefix by table
COL prefix5 NEW_V prefix5 FOR A256;
SELECT 'prefix5: ' x, '^^prefix._table' prefix5 FROM DUAL;

-- set module, action and client info
EXEC DBMS_APPLICATION_INFO.SET_MODULE(module_name => '^^module. ^^doc_ver.', action_name => '^^script..sql');
EXEC DBMS_APPLICATION_INFO.SET_CLIENT_INFO(client_info => '^^module.');

/**************************************************************************************************/

/* -------------------------
 *
 * get sql_text
 *
 * ------------------------- */

SET TERM ON;
PRO
PRO ### ... getting SQL text ...
PRO
SET TERM OFF;

VAR sql_text CLOB;
EXEC :sql_text := NULL;

-- get sql_text from memory
DECLARE
  l_sql_text VARCHAR2(32767);
BEGIN -- 10g see bug 5017909
  DBMS_OUTPUT.PUT_LINE('getting sql_text from memory');
  FOR i IN (SELECT DISTINCT piece, sql_text
              FROM gv$sqltext_with_newlines^^my_dblink.
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
  IF :olicense IN ('T', 'D') AND (:sql_text IS NULL OR NVL(DBMS_LOB.GETLENGTH(:sql_text), 0) = 0) THEN
    DBMS_OUTPUT.PUT_LINE('getting sql_text from awr');
    SELECT REPLACE(sql_text, CHR(00), ' ')
      INTO :sql_text
      FROM dba_hist_sqltext^^my_dblink.
     WHERE :olicense IN ('T', 'D')
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

SELECT 'sql_text: ' x, :sql_text FROM DUAL;

/* -------------------------
 *
 * get signature
 *
 * ------------------------- */

SET TERM ON;
PRO
PRO ### ... getting signature ...
PRO
SET TERM OFF;

-- signature (force=false)
VAR signature NUMBER;
BEGIN
  IF :olicense = 'T' AND :sql_text IS NOT NULL THEN
    :signature := DBMS_SQLTUNE.SQLTEXT_TO_SIGNATURE(:sql_text, FALSE);
  ELSE
    :signature := -1;
  END IF;
END;
/
COL signature NEW_V signature FOR A20;
SELECT 'signature: ' x, TO_CHAR(:signature) signature FROM DUAL;
COL prefix2 NEW_V prefix2 FOR A256;
SELECT 'prefix2: ' x, '^^prefix._^^signature._exact' prefix2 FROM DUAL;

-- signature (force=true)
VAR signaturef NUMBER;
BEGIN
  IF :olicense = 'T' AND :sql_text IS NOT NULL THEN
    :signaturef := DBMS_SQLTUNE.SQLTEXT_TO_SIGNATURE(:sql_text, TRUE);
  ELSE
    :signaturef := -1;
  END IF;
END;
/
COL signaturef NEW_V signaturef FOR A20;
SELECT 'signaturef: ' x, TO_CHAR(:signaturef) signaturef FROM DUAL;
COL prefix3 NEW_V prefix3 FOR A256;
SELECT 'prefix3: ' x, '^^prefix._^^signaturef._force' prefix3 FROM DUAL;

/* -------------------------
 *
 * get tables
 *
 * ------------------------- */

SET TERM ON;
PRO
PRO ### ... getting tables ...
PRO
SET TERM OFF;

VAR tables_list CLOB;
EXEC :tables_list := NULL;

-- get list of tables from execution plan
-- format (('owner', 'table_name'), (), ()...)
DECLARE
  l_pair VARCHAR2(32767);
BEGIN
  DBMS_LOB.CREATETEMPORARY(:tables_list, TRUE, DBMS_LOB.SESSION);
  FOR i IN (WITH object AS (
  	    SELECT /*+ MATERIALIZE */
  	           object_owner owner, object_name name
  	      FROM gv$sql_plan^^my_dblink.
  	     WHERE inst_id IN (SELECT inst_id FROM gv$instance)
  	       AND sql_id = '^^sql_id.'
  	       AND object_owner IS NOT NULL
  	       AND object_name IS NOT NULL
  	     UNION
  	    SELECT object_owner owner, object_name name
  	      FROM dba_hist_sql_plan^^my_dblink.
  	     WHERE :olicense IN ('T', 'D')
  	       AND dbid = ^^dbid.
  	       AND sql_id = '^^sql_id.'
  	       AND object_owner IS NOT NULL
  	       AND object_name IS NOT NULL
  	    )
  	    SELECT 'TABLE', t.owner, t.table_name
  	      FROM dba_tab_statistics^^my_dblink. t, -- include fixed objects
  	           object o
  	     WHERE t.owner = o.owner
  	       AND t.table_name = o.name
  	     UNION
  	    SELECT 'TABLE', i.table_owner, i.table_name
  	      FROM dba_indexes^^my_dblink. i,
  	           object o
  	     WHERE i.owner = o.owner
  	       AND i.index_name = o.name)
  LOOP
    IF l_pair IS NULL THEN
      DBMS_LOB.WRITEAPPEND(:tables_list, 1, '(');
    ELSE
      DBMS_LOB.WRITEAPPEND(:tables_list, 1, ',');
    END IF;
    l_pair := '('''''||i.owner||''''','''''||i.table_name||''''')';
    DBMS_LOB.WRITEAPPEND(:tables_list, LENGTH(l_pair), l_pair);
  END LOOP;
  IF l_pair IS NULL THEN
    l_pair := '(''''DUMMY'''',''''DUMMY'''')';
    DBMS_LOB.WRITEAPPEND(:tables_list, LENGTH(l_pair), l_pair);
  ELSE
    DBMS_LOB.WRITEAPPEND(:tables_list, 1, ')');
  END IF;
END;
/

SET LONG 2000000 LONGC 2000;
SELECT 'tables_list: ' x, :tables_list FROM DUAL;

SET LIN 32767;
COL tables_list NEW_V tables_list FOR A32767;
SELECT :tables_list tables_list FROM DUAL;

/**************************************************************************************************/

-- produce driver script

SET TERM OFF ECHO OFF FEED OFF VER OFF SHOW OFF HEA OFF LIN 2000 NUM 20 NEWP NONE PAGES 0 LONG 2000000 LONGC 2000 SQLC MIX TAB ON TRIMS ON TI OFF TIMI OFF ARRAY 100 NUMF "" SQLP SQL> SUF sql BLO . RECSEP OFF APPI OFF AUTOT OFF SERVEROUT ON SIZE UNL;

SET TERM ON;
PRO
PRO ### ... generating dynamic script, please wait ...
PRO
SET TERM OFF;

SPO ^^prefix1._driver.sql;
PRO REM $Header: ^^mos_doc. ^^prefix1._driver.sql ^^doc_ver. ^^doc_date. carlos.sierra $
PRO REM created by ^^script..sql
SET DEF ON;
DEF subst_var = '^';
PRO SET DEF ON;;
PRO SET DEF ^ TERM OFF ECHO OFF FEED OFF VER OFF SHOW OFF HEA OFF LIN 2000 NUM 20 NEWP NONE PAGES 0 LONG 2000000 LONGC 2000 SQLC MIX TAB ON TRIMS ON TI OFF TIMI OFF ARRAY 100 NUMF "" SQLP SQL> SUF sql BLO . RECSEP OFF APPI OFF AUTOT OFF SERVEROUT ON SIZE UNL;;
SET DEF ^;
PRO ALTER SESSION SET nls_numeric_characters = ".,";;
PRO ALTER SESSION SET nls_date_format = 'YYYY-MM-DD/HH24:MI:SS';;
PRO ALTER SESSION SET nls_timestamp_format = 'YYYY-MM-DD/HH24:MI:SS.FF';;
PRO ALTER SESSION SET nls_timestamp_tz_format = 'YYYY-MM-DD/HH24:MI:SS.FF TZH:TZM';;
PRO ALTER SESSION SET nls_sort = 'BINARY';;
PRO ALTER SESSION SET nls_comp = 'BINARY';;
PRO CL BRE COL;;
PRO -- YYYY-MM-DD/HH24:MI:SS
PRO COL time_stamp1 NEW_V time_stamp1 FOR A20;;
PRO /*********************************************************************************/

DECLARE
  l_cnt INTEGER;
  l_tbls_h INTEGER;
  l_tbls_c INTEGER;
  l_table_name VARCHAR2(32767);
  l_file_name VARCHAR2(32767);
  l_columns_list VARCHAR2(32767);

  PROCEDURE put_line (p_line IN VARCHAR2)
  IS
    l_pos INTEGER := 1;
  BEGIN
    WHILE l_pos < LENGTH(p_line)
    LOOP
      DBMS_OUTPUT.PUT_LINE(SUBSTR(p_line, l_pos, LEAST(2000, LENGTH(p_line) - l_pos + 1)));
      l_pos := l_pos + 2000;
    END LOOP;
  END put_line;

  PROCEDURE put_header (
    p_prefix IN VARCHAR2,
    p_id     IN VARCHAR2 )
  IS
  BEGIN
    put_line('PRO <html>');
    put_line('PRO <!-- $Header: ^^mos_doc. ^^script..sql ^^doc_ver. ^^doc_date. carlos.sierra $ -->');
    put_line('PRO <!-- Copyright (c) 2000-2013, Oracle Corporation. All rights reserved. -->');
    put_line('PRO <!-- Author: carlos.sierra@oracle.com -->');
    put_line('PRO');
    put_line('PRO <head>');
    put_line('PRO <title>'||p_prefix||'_'||l_file_name||'.html</title>');
    put_line('PRO');
    put_line('PRO <style type="text/css">');
    --put_line('PRO body {font:10pt Arial,Helvetica,Verdana,Geneva,sans-serif; color:black; background:white;}');
    --put_line('PRO a {font-weight:bold; color:#663300;}');
    --put_line('PRO pre {font:8pt Monaco,"Courier New",Courier,monospace;} /* for code */');
    put_line('PRO h1 {font-size:16pt; font-weight:bold; color:#336699;}');
    --put_line('PRO h2 {font-size:14pt; font-weight:bold; color:#336699;}');
    --put_line('PRO h3 {font-size:12pt; font-weight:bold; color:#336699;}');
    --put_line('PRO li {font-size:10pt; font-weight:bold; color:#336699; padding:0.1em 0 0 0;}');
    put_line('PRO table {font-size:8pt; color:black; background:white;}');
    put_line('PRO th {font-weight:bold; background:#cccc99; color:#336699; vertical-align:bottom; padding-left:3pt; padding-right:3pt; padding-top:1pt; padding-bottom:1pt;}');
    put_line('PRO td {text-align:left; background:#fcfcf0; vertical-align:top; padding-left:3pt; padding-right:3pt; padding-top:1pt; padding-bottom:1pt;}');
    --put_line('PRO td.c {text-align:center;} /* center */');
    --put_line('PRO td.l {text-align:left;} /* left (default) */');
    --put_line('PRO td.r {text-align:right;} /* right */');
    --put_line('PRO font.n {font-size:8pt; font-style:italic; color:#336699;} /* table footnote in blue */');
    put_line('PRO font.f {font-size:8pt; color:#999999;} /* footnote in gray */');
    put_line('PRO </style>');
    put_line('PRO');
    put_line('PRO </head>');
    put_line('PRO <body>');
    put_line('PRO <h1>^^mos_doc. ^^module. ^^doc_ver. '||p_id||' '||l_table_name||'</h1>');
    put_line('PRO');
  END put_header;

  PROCEDURE put_footer
  IS
  BEGIN
    put_line('PRO');
    put_line('SELECT ''<!-- ''||TO_CHAR(SYSDATE, ''YYYY-MM-DD/HH24:MI:SS'')||'' -->'' FROM dual;');
    put_line('PRO <hr size="3">');
    put_line('PRO <font class="f">^^mos_doc. ^^module. ^^doc_ver. ^^subst_var.^^subst_var.time_stamp1.</font>');
    put_line('PRO </body>');
    put_line('PRO </html>');
  END put_footer;

  FUNCTION get_columns_list(p_table_name IN VARCHAR2)
  RETURN VARCHAR2
  IS
    l2_count INTEGER := 0;
    l2_columns_list VARCHAR2(32767) := NULL;
  BEGIN
    IF '^^my_dblink.' IS NULL THEN
      RETURN '*'; -- all columns
    ELSE -- exclude LOBs for sqltxtrsby
      FOR i IN (SELECT column_name
                  FROM dba_tab_columns^^my_dblink.
                 WHERE owner = 'SYS'
                   AND table_name = p_table_name
                   AND data_type NOT IN ('CLOB', 'LONG', 'BLOB') -- CLOB causes "ORA-64202: remote temporary or abstract LOB locator is encountered" on sqltxtrsby
                 ORDER BY
                       column_id)
      LOOP
        l2_count := l2_count + 1;
        IF l2_count = 1 THEN
          l2_columns_list := i.column_name;
        ELSE
          l2_columns_list := l2_columns_list||', '||i.column_name;
        END IF;
      END LOOP;
      RETURN l2_columns_list;
    END IF;
  END get_columns_list;

  PROCEDURE describe_table(p_table_name IN VARCHAR2)
  IS
    l_tab_comments VARCHAR2(32767);
  BEGIN
    BEGIN
      SELECT comments INTO l_tab_comments FROM dba_tab_comments WHERE owner = 'SYS' AND table_name = p_table_name AND table_type = 'VIEW';
      put_line('PRO '||l_tab_comments);
    EXCEPTION
      WHEN OTHERS THEN
        NULL;
    END;

    put_line('SET HEA ON PAGES 25 MARK HTML ON TABLE "" ENTMAP OFF SPOOL OFF;');
    put_line('SELECT col.column_id "#",');
    put_line('       ''<pre>''||col.column_name||''</pre>'' "Name",');
    put_line('       ''<pre>''||DECODE(nullable, ''N'', ''NOT NULL'')||''</pre>'' "Null?",');
    put_line('       ''<pre>''||col.data_type||(CASE WHEN data_type LIKE ''%CHAR%'' THEN ''(''||data_length||'')'' END)||''</pre>'' "Type",');
    put_line('       ''<pre>''||REPLACE(REPLACE(REPLACE(com.comments, ''>'', CHR(38)||''GT;''), ''<'', CHR(38)||''LT;''), CHR(10), ''<br>'')||''</pre>'' "Comments"');
    put_line('  FROM dba_tab_columns col,');
    put_line('       dba_col_comments com');
    put_line(' WHERE col.owner = ''SYS''');
    put_line('   AND col.table_name = '''||p_table_name||'''');
    put_line('   AND com.owner(+) = col.owner');
    put_line('   AND com.table_name(+) = col.table_name');
    put_line('   AND com.column_name(+) = col.column_name');
    put_line(' ORDER BY col.column_id;');
    put_line('SET HEA OFF PAGES 0 MARK HTML OFF;');
  END describe_table;

BEGIN
  IF :olicense IN ('D', 'T') AND :output_type IN ('H', 'C', 'B') THEN

    -- by sql_id
    BEGIN
      put_line('SET TERM ON;');
      put_line('PRO ###');
      put_line('PRO ### by sql_id');
      put_line('PRO ###');
      put_line('SET TERM OFF;');

      l_tbls_h := 0;
      l_tbls_c := 0;

      FOR i IN (SELECT table_name, column_name
                  FROM dba_tab_columns^^my_dblink.
                 WHERE column_name = 'SQL_ID'
                   AND owner = 'SYS'
                   AND data_type = 'VARCHAR2'
                   AND data_length = 13
                   AND (table_name LIKE 'WR%' OR table_name LIKE 'DBA%' OR table_name LIKE 'SQL%' OR table_name LIKE 'GV!_%' ESCAPE '!' /* GV_$ */)
                   AND table_name NOT LIKE 'SQLT%'
				   AND table_name NOT LIKE '%LOGSTDBY%'
                 ORDER BY
                       table_name)
      LOOP
        l_table_name := REPLACE(i.table_name, 'GV_$', 'GV$');
        l_file_name := REPLACE(l_table_name, '$', 's');

        l_cnt := NULL;
        BEGIN
          DBMS_APPLICATION_INFO.SET_MODULE(module_name => '^^script..sql', action_name => 'SQL_ID '||i.table_name);
          DBMS_APPLICATION_INFO.SET_CLIENT_INFO(i.table_name||' '||TO_CHAR(SYSDATE, 'YYYY-MM-DD/HH24:MI:SS'));
          EXECUTE IMMEDIATE 'SELECT COUNT(*) FROM '||l_table_name||'^^my_dblink. WHERE '||i.column_name||' = ''^^sql_id.''' INTO l_cnt;
          DBMS_APPLICATION_INFO.SET_MODULE(module_name => NULL, action_name => NULL);
          DBMS_APPLICATION_INFO.SET_CLIENT_INFO(NULL);
        EXCEPTION
          WHEN OTHERS THEN
            put_line('-- skip: '||l_table_name||' by sql_id. reason: '||SQLERRM);
        END;

        IF l_cnt > 0 THEN
          l_columns_list := get_columns_list(i.table_name);

          put_line('SELECT TO_CHAR(SYSDATE, ''YYYY-MM-DD/HH24:MI:SS'') time_stamp1 FROM DUAL;');
          put_line('EXEC DBMS_APPLICATION_INFO.SET_MODULE(module_name => ''^^script..sql'', action_name => ''SQL_ID '||i.table_name||''');');
          put_line('EXEC DBMS_APPLICATION_INFO.SET_CLIENT_INFO('''||i.table_name||' ^^subst_var.^^subst_var.time_stamp1.'');');

          put_line('-- select: '||l_table_name||' by sql_id. count(*): '||l_cnt);
          put_line('SET TERM ON;');
          put_line('PRO ^^subst_var.^^subst_var.time_stamp1. '||l_table_name||';');
          put_line('SET TERM OFF;');

          -- sql_id html
          IF :output_type IN ('H', 'B') THEN
            l_tbls_h := l_tbls_h + 1;
            put_line('COL sql_text PRI;');
            put_line('COL sql_fulltext PRI;');
            IF l_table_name IN ('GV$SQLAREA', 'DBA_HIST_SQLTEXT') THEN
              put_line('CL BRE;');
            ELSE
              put_line('BRE ON sql_text ON sql_fulltext;');
            END IF;
            put_line('SPO ^^prefix1._'||l_file_name||'.html;');
            put_header('^^prefix1.', '^^sql_id.');
            describe_table(i.table_name);
            put_line('SET HEA ON PAGES 25 MARK HTML ON TABLE "" SPOOL OFF;');
            put_line('SELECT ROWNUM "#", v.* FROM (SELECT /*+ NO_MERGE */ '||l_columns_list||' FROM '||l_table_name||'^^my_dblink. WHERE '||i.column_name||' = ''^^sql_id.'' AND ROWNUM <= ^^max_rows_threshold.) v;');
            put_line('SET HEA OFF PAGES 0 MARK HTML OFF;');
            put_footer;
            put_line('SPO OFF;');
          ELSE
            put_line('-- output_type: '||:output_type);
          END IF;

          -- sql_id csv
          IF :output_type IN ('C', 'B') THEN
            l_tbls_c := l_tbls_c + 1;
            IF l_table_name IN ('GV$SQLAREA', 'DBA_HIST_SQLTEXT') THEN
              put_line('COL sql_text PRI;');
              put_line('COL sql_fulltext PRI;');
              put_line('BRE ON sql_text ON sql_fulltext;');
            ELSE
              put_line('COL sql_text NOPRI;');
              put_line('COL sql_fulltext NOPRI;');
              put_line('CL BRE;');
            END IF;
            put_line('SPO ^^prefix1._'||l_file_name||'.csv;');
            put_line('SET HEA ON PAGES 50000 LIN 32767 LONGC 4000 COLSEP '','';');
            put_line('SELECT '||l_columns_list||' FROM '||l_table_name||'^^my_dblink. WHERE '||i.column_name||' = ''^^sql_id.'' AND ROWNUM <= ^^max_rows_threshold.;');
            put_line('SET HEA OFF PAGES 0 LIN 2000 LONGC 2000 COLSEP '' '';');
            put_line('SPO OFF;');
          ELSE
            put_line('-- output_type: '||:output_type);
          END IF;

          put_line('EXEC DBMS_APPLICATION_INFO.SET_MODULE(module_name => NULL, action_name => NULL);');
          put_line('EXEC DBMS_APPLICATION_INFO.SET_CLIENT_INFO(NULL);');
          put_line('/*********************************************************************************/');
        ELSIF l_cnt = 0 THEN
          put_line('-- skip: '||l_table_name||' by sql_id. reason: COUNT(*) = 0');
        END IF;
      END LOOP;

      put_line('COL sql_text PRI;');
      put_line('COL sql_fulltext PRI;');
      put_line('CL BRE;');
      put_line('/*********************************************************************************/');

      IF l_tbls_h > 0 THEN
        put_line('HOS zip -m ^^prefix1._html ^^prefix1._*.html');
        put_line('HOS unzip -l ^^prefix1._html');
      END IF;

      IF l_tbls_c > 0 THEN
        put_line('HOS zip -m ^^prefix1._csv ^^prefix1._*.csv');
        put_line('HOS unzip -l ^^prefix1._csv');
      END IF;

      IF l_tbls_h + l_tbls_c > 0 THEN
        put_line('HOS zip -m ^^prefix. ^^prefix1._*.zip');
        put_line('HOS unzip -l ^^prefix.');
        put_line('/*********************************************************************************/');
      END IF;
    END;

    -- by exact signature
    BEGIN
      put_line('SET TERM ON;');
      put_line('PRO ###');
      put_line('PRO ### by exact signature');
      put_line('PRO ###');
      put_line('SET TERM OFF;');

      l_tbls_h := 0;
      l_tbls_c := 0;

      FOR i IN (SELECT c1.table_name, c1.column_name
                  FROM dba_tab_columns^^my_dblink. c1
                 WHERE :olicense = 'T'
                   AND :signature > 0
                   AND c1.column_name IN ('SIGNATURE', 'EXACT_MATCHING_SIGNATURE')
                   AND c1.owner = 'SYS'
                   AND c1.data_type = 'NUMBER'
                   AND (c1.table_name LIKE 'WR%' OR c1.table_name LIKE 'DBA%' OR c1.table_name LIKE 'SQL%' OR c1.table_name LIKE 'GV!_%' ESCAPE '!' /* GV_$ */)
                   AND c1.table_name NOT LIKE 'SQLT%'
				   AND c1.table_name NOT LIKE '%LOGSTDBY%'
                   AND NOT EXISTS (
                SELECT NULL
                  FROM dba_tab_columns^^my_dblink. c2
                 WHERE c2.owner = c1.owner
                   AND c2.table_name = c1.table_name
                   AND c2.column_name = 'SQL_ID'
                   AND c2.data_type = 'VARCHAR2'
                   AND c2.data_length = 13 )
                 ORDER BY
                       c1.table_name)
      LOOP
        l_table_name := REPLACE(i.table_name, 'GV_$', 'GV$');
        l_file_name := REPLACE(l_table_name, '$', 's');

        l_cnt := NULL;
        BEGIN
          DBMS_APPLICATION_INFO.SET_MODULE(module_name => '^^script..sql', action_name => 'EXACT_MATCHING_SIGNATURE '||i.table_name);
          DBMS_APPLICATION_INFO.SET_CLIENT_INFO(i.table_name||' '||TO_CHAR(SYSDATE, 'YYYY-MM-DD/HH24:MI:SS'));
          EXECUTE IMMEDIATE 'SELECT COUNT(*) FROM '||l_table_name||'^^my_dblink. WHERE '||i.column_name||' = ^^signature.' INTO l_cnt;
          DBMS_APPLICATION_INFO.SET_MODULE(module_name => NULL, action_name => NULL);
          DBMS_APPLICATION_INFO.SET_CLIENT_INFO(NULL);
        EXCEPTION
          WHEN OTHERS THEN
            put_line('-- skip: '||l_table_name||' by exact signature. reason: '||SQLERRM);
        END;

        IF l_cnt > 0 THEN
          l_columns_list := get_columns_list(i.table_name);

          put_line('SELECT TO_CHAR(SYSDATE, ''YYYY-MM-DD/HH24:MI:SS'') time_stamp1 FROM DUAL;');
          put_line('EXEC DBMS_APPLICATION_INFO.SET_MODULE(module_name => ''^^script..sql'', action_name => ''EXACT_MATCHING_SIGNATURE '||i.table_name||''');');
          put_line('EXEC DBMS_APPLICATION_INFO.SET_CLIENT_INFO('''||i.table_name||' ^^subst_var.^^subst_var.time_stamp1.'');');

          put_line('-- select: '||l_table_name||' by exact signature. count(*): '||l_cnt);
          put_line('SET TERM ON;');
          put_line('PRO ^^subst_var.^^subst_var.time_stamp1. '||l_table_name||';');
          put_line('SET TERM OFF;');

          -- exact signature html
          IF :output_type IN ('H', 'B') THEN
            l_tbls_h := l_tbls_h + 1;
            put_line('COL sql_text PRI;');
            put_line('COL sql_fulltext PRI;');
            IF l_table_name IN ('SQL$TEXT', 'DBA_SQL_PROFILES') THEN
              put_line('CL BRE;');
            ELSE
              put_line('BRE ON sql_text ON sql_fulltext;');
            END IF;
            put_line('SPO ^^prefix2._'||l_file_name||'.html;');
            put_header('^^prefix2.', '^^signature.');
            describe_table(i.table_name);
            put_line('SET HEA ON PAGES 25 MARK HTML ON TABLE "" SPOOL OFF;');
            put_line('SELECT ROWNUM "#", v.* FROM (SELECT /*+ NO_MERGE */ '||l_columns_list||' FROM '||l_table_name||'^^my_dblink. WHERE '||i.column_name||' = ^^signature. AND ROWNUM <= ^^max_rows_threshold.) v;');
            put_line('SET HEA OFF PAGES 0 MARK HTML OFF;');
            put_footer;
            put_line('SPO OFF;');
          ELSE
            put_line('-- output_type: '||:output_type);
          END IF;

          -- exact signature csv
          IF :output_type IN ('C', 'B') THEN
            l_tbls_c := l_tbls_c + 1;
            IF l_table_name IN ('SQL$TEXT', 'DBA_SQL_PROFILES') THEN
              put_line('COL sql_text PRI;');
              put_line('COL sql_fulltext PRI;');
              put_line('BRE ON sql_text ON sql_fulltext;');
            ELSE
              put_line('COL sql_text NOPRI;');
              put_line('COL sql_fulltext NOPRI;');
              put_line('CL BRE;');
            END IF;
            put_line('SPO ^^prefix2._'||l_file_name||'.csv;');
            put_line('SET HEA ON PAGES 50000 LIN 32767 LONGC 4000 COLSEP '','';');
            put_line('SELECT '||l_columns_list||' FROM '||l_table_name||'^^my_dblink. WHERE '||i.column_name||' = ^^signature. AND ROWNUM <= ^^max_rows_threshold.;');
            put_line('SET HEA OFF PAGES 0 LIN 2000 LONGC 2000 COLSEP '' '';');
            put_line('SPO OFF;');
          ELSE
            put_line('-- output_type: '||:output_type);
          END IF;

          put_line('EXEC DBMS_APPLICATION_INFO.SET_MODULE(module_name => NULL, action_name => NULL);');
          put_line('EXEC DBMS_APPLICATION_INFO.SET_CLIENT_INFO(NULL);');
          put_line('/*********************************************************************************/');
        ELSIF l_cnt = 0 THEN
          put_line('-- skip: '||l_table_name||' by exact signature. reason: COUNT(*) = 0');
        END IF;
      END LOOP;

      put_line('COL sql_text PRI;');
      put_line('COL sql_fulltext PRI;');
      put_line('CL BRE;');
      put_line('/*********************************************************************************/');

      IF l_tbls_h > 0 THEN
        put_line('HOS zip -m ^^prefix2._html ^^prefix2._*.html');
        put_line('HOS unzip -l ^^prefix2._html');
      END IF;

      IF l_tbls_c > 0 THEN
        put_line('HOS zip -m ^^prefix2._csv ^^prefix2._*.csv');
        put_line('HOS unzip -l ^^prefix2._csv');
      END IF;

      IF l_tbls_h + l_tbls_c > 0 THEN
        put_line('HOS zip -m ^^prefix. ^^prefix2._*.zip');
        put_line('HOS unzip -l ^^prefix.');
        put_line('/*********************************************************************************/');
      END IF;
    END;

    -- by force signature (only if different than exact signature)
    BEGIN
      put_line('SET TERM ON;');
      put_line('PRO ###');
      put_line('PRO ### by force signature');
      put_line('PRO ###');
      put_line('SET TERM OFF;');

      l_tbls_h := 0;
      l_tbls_c := 0;

      FOR i IN (SELECT c1.table_name, c1.column_name
                  FROM dba_tab_columns^^my_dblink. c1
                 WHERE :olicense = 'T'
                   AND :signaturef > 0
                   AND :signaturef <> :signature
                   AND c1.column_name IN ('SIGNATURE', 'FORCE_MATCHING_SIGNATURE')
                   AND c1.owner = 'SYS'
                   AND c1.data_type = 'NUMBER'
                   AND (c1.table_name LIKE 'WR%' OR c1.table_name LIKE 'DBA%' OR c1.table_name LIKE 'SQL%' OR c1.table_name LIKE 'GV!_%' ESCAPE '!' /* GV_$ */)
                   AND c1.table_name NOT LIKE 'SQLT%'
				   AND c1.table_name NOT LIKE '%LOGSTDBY%'
                 ORDER BY
                       c1.table_name)
      LOOP
        l_table_name := REPLACE(i.table_name, 'GV_$', 'GV$');
        l_file_name := REPLACE(l_table_name, '$', 's');

        l_cnt := NULL;
        BEGIN
          DBMS_APPLICATION_INFO.SET_MODULE(module_name => '^^script..sql', action_name => 'FORCE_MATCHING_SIGNATURE '||i.table_name);
          DBMS_APPLICATION_INFO.SET_CLIENT_INFO(i.table_name||' '||TO_CHAR(SYSDATE, 'YYYY-MM-DD/HH24:MI:SS'));
          EXECUTE IMMEDIATE 'SELECT COUNT(*) FROM '||l_table_name||'^^my_dblink. WHERE '||i.column_name||' = ^^signaturef.' INTO l_cnt;
          DBMS_APPLICATION_INFO.SET_MODULE(module_name => NULL, action_name => NULL);
          DBMS_APPLICATION_INFO.SET_CLIENT_INFO(NULL);
        EXCEPTION
          WHEN OTHERS THEN
            put_line('-- skip: '||l_table_name||' by force signature. reason: '||SQLERRM);
        END;

        IF l_cnt > 0 THEN
          l_columns_list := get_columns_list(i.table_name);

          put_line('SELECT TO_CHAR(SYSDATE, ''YYYY-MM-DD/HH24:MI:SS'') time_stamp1 FROM DUAL;');
          put_line('EXEC DBMS_APPLICATION_INFO.SET_MODULE(module_name => ''^^script..sql'', action_name => ''FORCE_MATCHING_SIGNATURE '||i.table_name||''');');
          put_line('EXEC DBMS_APPLICATION_INFO.SET_CLIENT_INFO('''||i.table_name||' ^^subst_var.^^subst_var.time_stamp1.'');');

          put_line('-- select: '||l_table_name||' by force signature. count(*): '||l_cnt);
          put_line('SET TERM ON;');
          put_line('PRO ^^subst_var.^^subst_var.time_stamp1. '||l_table_name||';');
          put_line('SET TERM OFF;');

          -- force signature html
          IF :output_type IN ('H', 'B') THEN
            l_tbls_h := l_tbls_h + 1;
            put_line('COL sql_text PRI;');
            put_line('COL sql_fulltext PRI;');
            IF l_table_name IN ('SQL$TEXT', 'DBA_SQL_PROFILES') THEN
              put_line('CL BRE;');
            ELSE
              put_line('BRE ON sql_text ON sql_fulltext;');
            END IF;
            put_line('SPO ^^prefix3._'||l_file_name||'.html;');
            put_header('^^prefix3.', '^^signaturef.');
            describe_table(i.table_name);
            put_line('SET HEA ON PAGES 25 MARK HTML ON TABLE "" SPOOL OFF;');
            put_line('SELECT ROWNUM "#", v.* FROM (SELECT /*+ NO_MERGE */ '||l_columns_list||' FROM '||l_table_name||'^^my_dblink. WHERE '||i.column_name||' = ^^signaturef. AND ROWNUM <= ^^max_rows_threshold.) v;');
            put_line('SET HEA OFF PAGES 0 MARK HTML OFF;');
            put_footer;
            put_line('SPO OFF;');
          ELSE
            put_line('-- output_type: '||:output_type);
          END IF;

          -- force signature csv
          IF :output_type IN ('C', 'B') THEN
            l_tbls_c := l_tbls_c + 1;
            IF l_table_name IN ('SQL$TEXT', 'DBA_SQL_PROFILES') THEN
              put_line('COL sql_text PRI;');
              put_line('COL sql_fulltext PRI;');
              put_line('BRE ON sql_text ON sql_fulltext;');
            ELSE
              put_line('COL sql_text NOPRI;');
              put_line('COL sql_fulltext NOPRI;');
              put_line('CL BRE;');
            END IF;
            put_line('SPO ^^prefix3._'||l_file_name||'.csv;');
            put_line('SET HEA ON PAGES 50000 LIN 32767 LONGC 4000 COLSEP '','';');
            put_line('SELECT '||l_columns_list||' FROM '||l_table_name||'^^my_dblink. WHERE '||i.column_name||' = ^^signaturef. AND ROWNUM <= ^^max_rows_threshold.;');
            put_line('SET HEA OFF PAGES 0 LIN 2000 LONGC 2000 COLSEP '' '';');
            put_line('SPO OFF;');
          ELSE
            put_line('-- output_type: '||:output_type);
          END IF;

          put_line('EXEC DBMS_APPLICATION_INFO.SET_MODULE(module_name => NULL, action_name => NULL);');
          put_line('EXEC DBMS_APPLICATION_INFO.SET_CLIENT_INFO(NULL);');
          put_line('/*********************************************************************************/');
        ELSIF l_cnt = 0 THEN
          put_line('-- skip: '||l_table_name||' by force signature. reason: COUNT(*) = 0');
        END IF;
      END LOOP;

      put_line('COL sql_text PRI;');
      put_line('COL sql_fulltext PRI;');
      put_line('CL BRE;');
      put_line('/*********************************************************************************/');

      IF l_tbls_h > 0 THEN
        put_line('HOS zip -m ^^prefix3._html ^^prefix3._*.html');
        put_line('HOS unzip -l ^^prefix3._html');
      END IF;

      IF l_tbls_c > 0 THEN
        put_line('HOS zip -m ^^prefix3._csv ^^prefix3._*.csv');
        put_line('HOS unzip -l ^^prefix3._csv');
      END IF;

      IF l_tbls_h + l_tbls_c > 0 THEN
        put_line('HOS zip -m ^^prefix. ^^prefix3._*.zip');
        put_line('HOS unzip -l ^^prefix.');
        put_line('/*********************************************************************************/');
      END IF;
    END;

    -- by table
    BEGIN
      put_line('SET TERM ON;');
      put_line('PRO ###');
      put_line('PRO ### by table');
      put_line('PRO ###');
      put_line('SET TERM OFF;');

      FOR i IN (SELECT c1.owner, c1.table_name
                  FROM dba_tab_columns^^my_dblink. c1
                 WHERE c1.column_name = 'TABLE_NAME'
                   AND c1.owner = 'SYS'
				   AND c1.table_name NOT LIKE '%LOGSTDBY%'
                   AND SUBSTR(c1.table_name, 1, 3) IN ('COL', 'DBA', 'ROL', 'TAB')
                   AND EXISTS (SELECT null
                                 FROM dba_tab_cols^^my_dblink. c2
                                WHERE c2.owner = c1.owner
                                  AND c2.table_name = c1.table_name
                                  AND c2.column_name IN ('TABLE_OWNER', 'OWNER', 'OWNER_NAME', 'SCHEMA_NAME', 'USER_NAME', 'USERNAME'))
                 ORDER BY
                       c1.table_name)
      LOOP
        FOR j IN (SELECT column_name
                    FROM dba_tab_columns^^my_dblink.
                   WHERE owner = i.owner
                     AND table_name = i.table_name
                     AND column_name IN ('TABLE_OWNER', 'OWNER', 'OWNER_NAME', 'SCHEMA_NAME', 'USER_NAME', 'USERNAME')
                   ORDER BY
                         CASE column_name
                         WHEN 'TABLE_OWNER' THEN 1
                         WHEN 'OWNER' THEN 2
                         WHEN 'OWNER_NAME' THEN 3
                         WHEN 'SCHEMA_NAME' THEN 4
                         WHEN 'USER_NAME' THEN 5
                         WHEN 'USERNAME' THEN 6
                         ELSE 7
                         END)
        LOOP
          l_table_name := REPLACE(i.table_name, 'GV_$', 'GV$');
	  l_file_name := REPLACE(l_table_name, '$', 's');

	  l_cnt := NULL;
	  BEGIN
	    DBMS_APPLICATION_INFO.SET_MODULE(module_name => '^^script..sql', action_name => 'TABLE '||i.table_name);
	    DBMS_APPLICATION_INFO.SET_CLIENT_INFO(i.table_name||' '||TO_CHAR(SYSDATE, 'YYYY-MM-DD/HH24:MI:SS'));
	    EXECUTE IMMEDIATE 'SELECT COUNT(*) FROM '||l_table_name||'^^my_dblink. WHERE ('||j.column_name||', table_name) IN ^^tables_list.' INTO l_cnt;
	    DBMS_APPLICATION_INFO.SET_MODULE(module_name => NULL, action_name => NULL);
	    DBMS_APPLICATION_INFO.SET_CLIENT_INFO(NULL);
	  EXCEPTION
	    WHEN OTHERS THEN
	      put_line('-- skip: '||l_table_name||' by table. reason: '||SQLERRM);
	  END;

          IF l_cnt > 0 THEN
            l_columns_list := get_columns_list(i.table_name);

            put_line('SELECT TO_CHAR(SYSDATE, ''YYYY-MM-DD/HH24:MI:SS'') time_stamp1 FROM DUAL;');
            put_line('EXEC DBMS_APPLICATION_INFO.SET_MODULE(module_name => ''^^script..sql'', action_name => ''TABLE '||i.table_name||''');');
            put_line('EXEC DBMS_APPLICATION_INFO.SET_CLIENT_INFO('''||i.table_name||' ^^subst_var.^^subst_var.time_stamp1.'');');

            put_line('-- select: '||l_table_name||' by table. count(*): '||l_cnt);
            put_line('SET TERM ON;');
            put_line('PRO ^^subst_var.^^subst_var.time_stamp1. '||l_table_name||';');
            put_line('SET TERM OFF;');

            -- table html
            IF :output_type IN ('H', 'B') THEN
              l_tbls_h := l_tbls_h + 1;
              put_line('SPO ^^prefix5._'||l_file_name||'.html;');
              put_header('^^prefix5.', NULL);
              describe_table(i.table_name);
              put_line('SET HEA ON PAGES 25 MARK HTML ON TABLE "" SPOOL OFF;');
              put_line('SELECT ROWNUM "#", v.* FROM (SELECT /*+ NO_MERGE */ '||l_columns_list||' FROM '||l_table_name||'^^my_dblink. WHERE ('||j.column_name||', table_name) IN ^^tables_list. AND ROWNUM <= ^^max_rows_threshold.) v;');
              put_line('SET HEA OFF PAGES 0 MARK HTML OFF;');
              put_footer;
              put_line('SPO OFF;');
            ELSE
              put_line('-- output_type: '||:output_type);
            END IF;

            -- table csv
            IF :output_type IN ('C', 'B') THEN
              l_tbls_c := l_tbls_c + 1;
              put_line('SPO ^^prefix5._'||l_file_name||'.csv;');
              put_line('SET HEA ON PAGES 50000 LIN 32767 LONGC 4000 COLSEP '','';');
              put_line('SELECT '||l_columns_list||' FROM '||l_table_name||'^^my_dblink. WHERE ('||j.column_name||', table_name) IN ^^tables_list. AND ROWNUM <= ^^max_rows_threshold.;');
              put_line('SET HEA OFF PAGES 0 LIN 2000 LONGC 2000 COLSEP '' '';');
              put_line('SPO OFF;');
            ELSE
              put_line('-- output_type: '||:output_type);
            END IF;

            put_line('EXEC DBMS_APPLICATION_INFO.SET_MODULE(module_name => NULL, action_name => NULL);');
            put_line('EXEC DBMS_APPLICATION_INFO.SET_CLIENT_INFO(NULL);');
            put_line('/*********************************************************************************/');
          ELSIF l_cnt = 0 THEN
            put_line('-- skip: '||l_table_name||' by table. reason: COUNT(*) = 0');
          END IF;

          EXIT; -- take 1st column only
        END LOOP;
      END LOOP;
      put_line('/*********************************************************************************/');

      IF l_tbls_h > 0 THEN
        put_line('HOS zip -m ^^prefix5._html ^^prefix5._*.html');
        put_line('HOS unzip -l ^^prefix5._html');
      END IF;

      IF l_tbls_c > 0 THEN
        put_line('HOS zip -m ^^prefix5._csv ^^prefix5._*.csv');
        put_line('HOS unzip -l ^^prefix5._csv');
      END IF;

      IF l_tbls_h + l_tbls_c > 0 THEN
        put_line('HOS zip -m ^^prefix. ^^prefix5._*.zip');
        put_line('HOS unzip -l ^^prefix.');
        put_line('/*********************************************************************************/');
      END IF;
    END;

    -- by global
    BEGIN
      put_line('SET TERM ON;');
      put_line('PRO ###');
      put_line('PRO ### by global');
      put_line('PRO ###');
      put_line('SET TERM OFF;');

      l_tbls_h := 0;
      l_tbls_c := 0;

      FOR i IN (SELECT DISTINCT table_name
                  FROM dba_tab_cols^^my_dblink.
                 WHERE owner = 'SYS'
                   AND (table_name LIKE 'WR%' OR table_name LIKE 'DBA%' OR table_name LIKE 'SQL%' OR table_name LIKE 'GV!_%' ESCAPE '!' /* GV_$ */)
                   AND table_name NOT LIKE 'SQLT%'
				   AND table_name NOT LIKE '%LOGSTDBY%'
                   --AND table_name IN ('DBA_HIST_SNAPSHOT', 'DBA_OBJECTS', 'GV_$PARAMETER2')
                   AND table_name IN ('DBA_HIST_SNAPSHOT', 'GV_$PARAMETER2')
                 ORDER BY
                       table_name)
      LOOP
        l_table_name := REPLACE(i.table_name, 'GV_$', 'GV$');
        l_file_name := REPLACE(l_table_name, '$', 's');

        l_cnt := NULL;
        BEGIN
          DBMS_APPLICATION_INFO.SET_MODULE(module_name => '^^script..sql', action_name => 'GLOBAL '||i.table_name);
          DBMS_APPLICATION_INFO.SET_CLIENT_INFO(i.table_name||' '||TO_CHAR(SYSDATE, 'YYYY-MM-DD/HH24:MI:SS'));
          EXECUTE IMMEDIATE 'SELECT COUNT(*) FROM '||l_table_name||'^^my_dblink.' INTO l_cnt;
          DBMS_APPLICATION_INFO.SET_MODULE(module_name => NULL, action_name => NULL);
          DBMS_APPLICATION_INFO.SET_CLIENT_INFO(NULL);
        EXCEPTION
          WHEN OTHERS THEN
            put_line('-- skip: '||l_table_name||' by global. reason: '||SQLERRM);
        END;

        IF l_cnt > 0 THEN
          l_columns_list := get_columns_list(i.table_name);

          put_line('SELECT TO_CHAR(SYSDATE, ''YYYY-MM-DD/HH24:MI:SS'') time_stamp1 FROM DUAL;');
          put_line('EXEC DBMS_APPLICATION_INFO.SET_MODULE(module_name => ''^^script..sql'', action_name => ''GLOBAL'');');
          put_line('EXEC DBMS_APPLICATION_INFO.SET_CLIENT_INFO('''||i.table_name||' ^^subst_var.^^subst_var.time_stamp1.'');');

          put_line('-- select: '||l_table_name||' by global. count(*): '||l_cnt);
          put_line('SET TERM ON;');
          put_line('PRO ^^subst_var.^^subst_var.time_stamp1. '||l_table_name||';');
          put_line('SET TERM OFF;');

          -- global html
          IF :output_type IN ('H', 'B') THEN
            l_tbls_h := l_tbls_h + 1;
            put_line('SPO ^^prefix4._'||l_file_name||'.html;');
            put_header('^^prefix4.', NULL);
            describe_table(i.table_name);
            put_line('SET HEA ON PAGES 25 MARK HTML ON TABLE "" SPOOL OFF;');
            put_line('SELECT ROWNUM "#", v.* FROM (SELECT /*+ NO_MERGE */ '||l_columns_list||' FROM '||l_table_name||'^^my_dblink. WHERE ROWNUM <= ^^max_rows_threshold.) v;');
            put_line('SET HEA OFF PAGES 0 MARK HTML OFF;');
            put_footer;
            put_line('SPO OFF;');
          ELSE
            put_line('-- output_type: '||:output_type);
          END IF;

          -- global csv
          IF :output_type IN ('C', 'B') THEN
            l_tbls_c := l_tbls_c + 1;
            put_line('SPO ^^prefix4._'||l_file_name||'.csv;');
            put_line('SET HEA ON PAGES 50000 LIN 32767 LONGC 4000 COLSEP '','';');
            put_line('SELECT '||l_columns_list||' FROM '||l_table_name||'^^my_dblink. WHERE ROWNUM <= ^^max_rows_threshold.;');
            put_line('SET HEA OFF PAGES 0 LIN 2000 LONGC 2000 COLSEP '' '';');
            put_line('SPO OFF;');
          ELSE
            put_line('-- output_type: '||:output_type);
          END IF;

          put_line('EXEC DBMS_APPLICATION_INFO.SET_MODULE(module_name => NULL, action_name => NULL);');
          put_line('EXEC DBMS_APPLICATION_INFO.SET_CLIENT_INFO(NULL);');
          put_line('/*********************************************************************************/');
        ELSIF l_cnt = 0 THEN
          put_line('-- skip: '||l_table_name||' by global. reason: COUNT(*) = 0');
        END IF;
      END LOOP;
      put_line('/*********************************************************************************/');

      IF l_tbls_h > 0 THEN
        put_line('HOS zip -m ^^prefix4._html ^^prefix4._*.html');
        put_line('HOS unzip -l ^^prefix4._html');
      END IF;

      IF l_tbls_c > 0 THEN
        put_line('HOS zip -m ^^prefix4._csv ^^prefix4._*.csv');
        put_line('HOS unzip -l ^^prefix4._csv');
      END IF;

      IF l_tbls_h + l_tbls_c > 0 THEN
        put_line('HOS zip -m ^^prefix. ^^prefix4._*.zip');
        put_line('HOS unzip -l ^^prefix.');
        put_line('/*********************************************************************************/');
      END IF;
    END;

   ELSE
    put_line('-- license: '||:olicense);
    put_line('-- output_type: '||:output_type);
  END IF;
END;
/

PRO SET TERM ON ECHO OFF FEED 6 VER ON SHOW OFF HEA ON LIN 80 NUM 10 NEWP 1 PAGES 14 LONG 80 LONGC 80 SQLC MIX TAB ON TRIMS OFF TI OFF TIMI OFF ARRAY 15 NUMF "" SQLP SQL> SUF sql BLO . RECSEP WR APPI OFF SERVEROUT OFF AUTOT OFF;;
PRO PRO
PRO PRO ^^prefix._*.zip files have been created.
PRO SET DEF ON;;
SPO OFF;

/**************************************************************************************************/

-- end
EXEC DBMS_APPLICATION_INFO.SET_MODULE(module_name => NULL, action_name => NULL);
EXEC DBMS_APPLICATION_INFO.SET_CLIENT_INFO(client_info => NULL);
SET TERM ON ECHO OFF FEED 6 VER ON SHOW OFF HEA ON LIN 80 NUM 10 NEWP 1 PAGES 14 LONG 80 LONGC 80 SQLC MIX TAB ON TRIMS OFF TI OFF TIMI OFF ARRAY 15 NUMF "" SQLP SQL> SUF sql BLO . RECSEP WR APPI OFF SERVEROUT OFF AUTOT OFF;
PRO
PRO ^^prefix1._driver.sql file has been created.
PRO
@^^prefix1._driver.sql
SET DEF ON;
SET DEF ^;
HOS zip -m ^^prefix1._log ^^prefix1._*.sql sqldx.log
HOS unzip -l ^^prefix1._log
HOS zip -m ^^prefix. ^^prefix1._log.zip
PRO
PRO ^^module. files have been created.
PRO
HOS unzip -l ^^prefix.
CL COL;
SET DEF ON;
UNDEF 1 2 3 script module mos_doc doc_ver doc_date dbid input_sql_id input_license input_output_type current_time prefix prefix1 prefix2 prefix3 sql_id signature signaturef olicense output_type signature signaturef my_dblink;
