SPO profiler.log
SET DEF ^ TERM OFF ECHO ON VER OFF SERVEROUT ON SIZE 1000000;
REM
REM $Header: 243755.1 profiler.sql 11.4.4.7 2012/07/02 carlos.sierra $
REM
REM Copyright (c) 2000-2012, Oracle Corporation. All rights reserved.
REM
REM AUTHOR
REM   carlos.sierra@oracle.com
REM
REM SCRIPT
REM   profiler.sql
REM
REM DESCRIPTION
REM   Generates an HTML report out of an execution of the PL/SQL
REM   Profiler DBMS_PROFILER. It focuses on those calls with the
REM   highest elapsed time.
REM
REM PRE-REQUISITES
REM   1. PL/SQL Profiler tables must exist:
REM
REM      PLSQL_PROFILER_RUNS
REM      PLSQL_PROFILER_UNITS
REM      PLSQL_PROFILER_DATA
REM
REM      If they do not exist or are not accesible to application
REM      user, proceed to create them connected as your application
REM      user:
REM
REM      SQL> CONN application_user/password
REM      SQL> @?/rdbms/admin/proftab.sql
REM
REM   2. Package DBMS_PROFILER must be installed. If it is missing
REM      and you need to install it, connect as SYS and execute:
REM
REM      SQL> CONN sys/password AS SYSDBA
REM      SQL> @?/rdbms/admin/profload.sql
REM
REM   3. On pre 11g systems where the PLAN_TABLE does not exist, it
REM      can be created connecting as SYS:
REM
REM      SQL> CONN sys/password AS SYSDBA
REM      SQL> @?/rdbms/admin/utlxplan.sql
REM      SQL> GRANT ALL ON sys.plan_table TO public;
REM      SQL> CREATE PUBLIC SYNONYM plan_table FOR sys.plan_table;
REM
REM   4. Create a PL/SQL Profiler run. Connect as your application
REM      user:
REM
REM      SQL> CONN application_user/password
REM      SQL> EXEC DBMS_PROFILER.START_PROFILER('optional comment');
REM      SQL> <<execute here your transaction to be profiled>>
REM      SQL> EXEC DBMS_PROFILER.STOP_PROFILER;
REM
REM      Refer to Oracle® Database PL/SQL Packages and Types
REM      Reference for information in how to use DBMS_PROFILER.
REM
REM   5. Use this profiler.sql script. Connected as your application
REM      user.
REM
REM PARAMETERS
REM   1. PL/SQL Profiler run_id.
REM
REM EXECUTION
REM   1. Start SQL*Plus connecting as application user that executed
REM      PL/SQL Profiler.
REM   2. Execute script profiler.sql passing run_id.
REM
REM EXAMPLE
REM   SQL> START [path]profiler.sql
REM
REM NOTES
REM   1. For possible errors see profiler.log.
REM
DEF top_consumers = '10';
DEF lines_before_and_after = '10';

/**************************************************************************************************/

SET TERM ON ECHO OFF;

COL runid FOR 99999;
COL run_owner FOR A25;
COL run_date FOR A15;
COL run_comment FOR A30;
SELECT runid,
       SUBSTR(run_owner, 1, 25) run_owner,
       TO_CHAR(run_date, 'DD-MON-YY HH24:MI') run_date,
       SUBSTR(run_comment, 1, 30) run_comment
  FROM plsql_profiler_runs
 ORDER BY
       runid;

PRO
PRO Parameter 1:
PRO RUNID (required)
PRO
DEF runid = '^1';
PRO

PRO Value passed:
PRO ~~~~~~~~~~~~
PRO RUNID: "^^runid."
PRO
SET TERM OFF;

VAR runid NUMBER;
EXEC :runid := TO_NUMBER('^^runid.');

SET ECHO ON TIMI ON;

DEF script = 'profiler';
DEF method = 'PROFILER';
DEF mos_doc = '243755.1';
DEF doc_ver = '11.4.4.7';
DEF doc_date = '2012/07/02';
DEF doc_link = 'https://support.oracle.com/CSP/main/article?cmd=show&type=NOT&id=';
DEF bug_link = 'https://support.oracle.com/CSP/main/article?cmd=show&type=BUG&id=';

/**************************************************************************************************/

/* -------------------------
 *
 * assembly title
 *
 * ------------------------- */

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

-- YYYYMMDD_HH24MISS
COL time_stamp NEW_V time_stamp FOR A15;
SELECT TO_CHAR(SYSDATE, 'YYYYMMDD_HH24MISS') time_stamp FROM DUAL;

-- YYYY-MM-DD/HH24:MI:SS
COL time_stamp2 NEW_V time_stamp2 FOR A20;
SELECT TO_CHAR(SYSDATE, 'YYYY-MM-DD/HH24:MI:SS') time_stamp2 FROM DUAL;

-- get run info
COL run_owner NEW_V run_owner;
COL run_date NEW_V run_date FOR A20;
COL run_comment NEW_V run_comment;
COL run_total_time NEW_V run_total_time FOR A24;
SELECT run_owner,
       TO_CHAR(run_date, 'YYYY-MM-DD/HH24:MI:SS') run_date,
       run_comment,
       TRIM(TO_CHAR(run_total_time/1e9, '99999999999990D999999990')) run_total_time
  FROM plsql_profiler_runs
 WHERE runid = :runid;

/* -------------------------
 *
 * roll up library total time
 *
 * ------------------------- */

BEGIN
  FOR i IN (SELECT runid, unit_number
              FROM plsql_profiler_units
             WHERE runid = :runid
               AND NVL(total_time, 0) = 0)
  LOOP
    DBMS_PROFILER.ROLLUP_UNIT(i.runid, i.unit_number); -- performs implicit commit
  END LOOP;
END;
/

/* -------------------------
 *
 * transaction begins: will rollback at the end
 *
 * ------------------------- */

SAVEPOINT save_point_1;
DELETE plan_table;

/* -------------------------
 *
 * line# adjustments to compensate for offset reported on bug 4044091
 *
 * ------------------------- */

-- borrowed from old version of profile.sql
DECLARE
  offset NUMBER;
  CURSOR c1_triggers IS
    SELECT unit_owner, unit_name, unit_type, unit_number
      FROM plsql_profiler_units
     WHERE runid = :runid
       AND unit_type = 'TRIGGER';
BEGIN
  FOR c1 IN c1_triggers LOOP
    SELECT NVL(MIN(line) - 1, -1)
      INTO offset
      FROM all_source
     WHERE owner = c1.unit_owner
       AND name  = c1.unit_name
       AND type  = c1.unit_type
       AND (UPPER(text) LIKE '%BEGIN%' OR UPPER(text) LIKE '%DECLARE%');

    IF offset > 0 THEN
      UPDATE plsql_profiler_data
         SET line# = line# + offset
       WHERE runid = :runid
         AND unit_number = c1.unit_number;
    END IF;
  END LOOP;
END;
/

/* -------------------------
 *
 * find top consumers
 *
 * ------------------------- */

-- position = row_num
-- parent_id = parent_line#
-- id = line#
-- search_columns = runid
-- object_instance = unit_number

-- top consumers
INSERT INTO plan_table (search_columns, object_instance, id, parent_id, position)
SELECT runid, unit_number, line#, line#, ROWNUM
  FROM (SELECT /*+ NO_MERGE */
               runid,
               unit_number,
               line#
          FROM plsql_profiler_data
         WHERE runid = :runid
         ORDER BY
               total_time DESC) v
 WHERE ROWNUM <= ^^top_consumers.;

-- add some lines before and after top consumers
BEGIN
  FOR i IN (SELECT * FROM plan_table)
  LOOP
    FOR j IN 1 .. ^^lines_before_and_after.
    LOOP
      INSERT INTO plan_table (search_columns, object_instance, id, parent_id, position)
      VALUES (i.search_columns, i.object_instance, i.parent_id - j, i.parent_id, i.position);
      INSERT INTO plan_table (search_columns, object_instance, id, parent_id, position)
      VALUES (i.search_columns, i.object_instance, i.parent_id + j, i.parent_id, i.position);
    END LOOP;
  END LOOP;
END;
/

/**************************************************************************************************/

/* -------------------------
 *
 * main report
 *
 * ------------------------- */

-- setup to produce report
SET ECHO OFF FEED OFF VER OFF SHOW OFF HEA OFF LIN 2000 NEWP NONE PAGES 0 LONG 200000 LONGC 2000 SQLC MIX TAB ON TRIMS ON TI OFF TIMI OFF ARRAY 100 NUMF "" SQLP SQL> SUF sql BLO . RECSEP OFF APPI OFF AUTOT OFF;

VAR LT VARCHAR2(10);
VAR GT VARCHAR2(10);

EXEC :LT := CHR(38)||'LT;';
EXEC :GT := CHR(38)||'GT;';

/* -------------------------
 *
 * heading
 *
 * ------------------------- */
SPO ^^script._^^database_name_short._^^host_name_short._^^rdbms_version._^^time_stamp..html;

PRO <html>
PRO <!-- $Header: ^^mos_doc. ^^script..sql ^^doc_ver. ^^doc_date. carlos.sierra $ -->
PRO <!-- Copyright (c) 2000-2012, Oracle Corporation. All rights reserved. -->
PRO <!-- Author: carlos.sierra@oracle.com -->
PRO
PRO <head>
PRO <title>^^script._^^database_name_short._^^host_name_short._^^rdbms_version._^^time_stamp..html</title>
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
PRO td.rr {text-align:right; color:crimson; background:#fcfcf0;} /* right and red */
PRO td.rrr {text-align:right; background:crimson;} /* right and super red  */
PRO font.n {font-size:8pt; font-style:italic; color:#336699;} /* table footnote in blue */
PRO font.f {font-size:8pt; color:#999999;} /* footnote in gray */
PRO </style>
PRO

PRO </head>
PRO <body>
PRO <h1><a target="MOS" href="^^doc_link.^^mos_doc.">^^mos_doc.</a> ^^method.
PRO ^^doc_ver. Report: ^^script._^^database_name_short._^^host_name_short._^^rdbms_version._^^time_stamp..html</h1>
PRO

PRO <pre>
PRO RUNID     : ^^runid.
PRO Owner     : ^^run_owner.
PRO Date      : ^^run_date.
PRO Comment   : ^^run_comment.
PRO Total Time: ^^run_total_time. (seconds)
PRO RDBMS     : ^^rdbms_version.
PRO Platform  : ^^platform.
PRO </pre>

PRO <ul>
PRO <li><a href="#tc">Top ^^top_consumers. Lines as per Total Time</a></li>
PRO <li><a href="#tpl">Top ^^top_consumers. Profiled PL/SQL Libraries</a></li>
PRO <li><a href="#apl">All Profiled PL/SQL Libraries</a></li>
PRO </ul>

/* -------------------------
 *
 * Top Consumers
 *
 * ------------------------- */
PRO <a name="tc"></a><h2>Top ^^top_consumers. Lines as per Total Time</h2>
PRO
PRO <table>
PRO
PRO <tr>
PRO <th>Top</th>
PRO <th>Lib<br>#</th>
PRO <th>Type</th>
PRO <th>Owner</th>
PRO <th>Name</th>
PRO <th>Line<br>#</th>
PRO <th>Times<br>Line<br>Exec</th>
PRO <th>Total<br>Time<br>(seconds)</th>
PRO <th>Min<br>Time<br>(seconds)</th>
PRO <th>Max<br>Time<br>(seconds)</th>
PRO <th>Line Text</th>
PRO </tr>
PRO

SELECT '<tr>'||CHR(10)||
       '<td class="r"><a href="#tc_'||pt.position||'">'||pt.position||'</a></td>'||CHR(10)||
       '<td class="r">'||pu.unit_number||'</td>'||CHR(10)||
       '<td nowrap>'||pu.unit_type||'</td>'||CHR(10)||
       '<td>'||DECODE(pu.unit_owner, '<anonymous>', NULL, pu.unit_owner)||'</td>'||CHR(10)||
       '<td>'||DECODE(pu.unit_name, '<anonymous>', NULL, pu.unit_name)||'</td>'||CHR(10)||
       '<td class="r">'||pt.id||'</td>'||CHR(10)|| -- line#
       '<td class="r">'||pd.total_occur||'</td>'||CHR(10)||
       '<td class="'||DECODE(pt.id, pt.parent_id, 'rr', 'r')||'"><a href="#tc_'||pt.position||'">'||TO_CHAR(pd.total_time/1e9, '99999999999990D999999990')||'</a></td>'||CHR(10)||
       '<td class="r">'||TO_CHAR(pd.min_time/1e9, '99999999999990D999999990')||'</td>'||CHR(10)||
       '<td class="r">'||TO_CHAR(pd.max_time/1e9, '99999999999990D999999990')||'</td>'||CHR(10)||
       '<td nowrap><pre>'||
       (SELECT REPLACE(REPLACE(ds.text, '<', :LT), '>', :GT)
          FROM dba_source ds
         WHERE ds.owner = pu.unit_owner
           AND ds.name = pu.unit_name
           AND ds.type = DECODE(pu.unit_type, 'PACKAGE SPEC', 'PACKAGE', pu.unit_type)
           AND ds.line = pt.id)||
       '</pre></td>'||CHR(10)|| -- source line_text
       '</tr>'||CHR(10) line_text
  FROM plan_table pt,
       plsql_profiler_units pu,
       plsql_profiler_data pd
 WHERE pt.id = pt.parent_id -- just top lines
   AND pu.runid = pt.search_columns
   AND pu.unit_number = pt.object_instance
   AND pd.runid(+) = pt.search_columns
   AND pd.unit_number(+) = pt.object_instance
   AND pd.line#(+) = pt.id
 ORDER BY
       pt.position,
       pt.id;

SELECT '<tr>'||CHR(10)||
       '<td></td>'||CHR(10)||
       '<td></td>'||CHR(10)||
       '<td>TOTAL</td>'||CHR(10)||
       '<td></td>'||CHR(10)||
       '<td></td>'||CHR(10)||
       '<td></td>'||CHR(10)|| -- line#
       '<td></td>'||CHR(10)||
       '<td class="r">'||TO_CHAR(SUM(pd.total_time)/1e9, '99999999999990D999999990')||'</td>'||CHR(10)||
       '<td></td>'||CHR(10)||
       '<td></td>'||CHR(10)||
       '<td></td>'||CHR(10)|| -- source line_text
       '</tr>'||CHR(10) line_text
  FROM plan_table pt,
       plsql_profiler_units pu,
       plsql_profiler_data pd
 WHERE pt.id = pt.parent_id -- just top lines
   AND pu.runid = pt.search_columns
   AND pu.unit_number = pt.object_instance
   AND pd.runid(+) = pt.search_columns
   AND pd.unit_number(+) = pt.object_instance
   AND pd.line#(+) = pt.id;

PRO
PRO </table>
PRO

SELECT v2.line_text
  FROM (
SELECT pt.position,
       1 line_type,
       0 line#,
       '<a name="tc_'||pt.position||'"></a><h3>#'||pt.position||' Top Consumer</h3>'||CHR(10)||CHR(10)||
       'Displays ^^lines_before_and_after. lines before and after #'||pt.position||' top consumer.'||CHR(10)||CHR(10)||
       '<table>'||CHR(10)||CHR(10)||
       '<tr>'||CHR(10)||
       '<th>Lib<br>#</th>'||CHR(10)||
       '<th>Type</th>'||CHR(10)||
       '<th>Owner</th>'||CHR(10)||
       '<th>Name</th>'||CHR(10)||
       '<th>Line<br>#</th>'||CHR(10)||
       '<th>Times<br>Line<br>Exec</th>'||CHR(10)||
       '<th>Total<br>Time<br>(seconds)</th>'||CHR(10)||
       '<th>Min<br>Time<br>(seconds)</th>'||CHR(10)||
       '<th>Max<br>Time<br>(seconds)</th>'||CHR(10)||
       '<th>Line Text</th>'||CHR(10)||
       '</tr>'||CHR(10) line_text
  FROM plan_table pt
 WHERE pt.id = pt.parent_id
 UNION ALL
SELECT v.* FROM (
SELECT /*+ NO_MERGE */
       pt.position,
       2 line_type,
       pt.id line#,
       CHR(10)||'<tr>'||CHR(10)||
       '<td class="r">'||pu.unit_number||'</td>'||CHR(10)||
       '<td nowrap>'||pu.unit_type||'</td>'||CHR(10)||
       '<td>'||DECODE(pu.unit_owner, '<anonymous>', NULL, pu.unit_owner)||'</td>'||CHR(10)||
       '<td>'||DECODE(pu.unit_name, '<anonymous>', NULL, pu.unit_name)||'</td>'||CHR(10)||
       '<td class="r">'||pt.id||'</td>'||CHR(10)|| -- line#
       '<td class="r">'||pd.total_occur||'</td>'||CHR(10)||
       '<td class="'||DECODE(pt.id, pt.parent_id, 'rr', 'r')||'">'||TO_CHAR(pd.total_time/1e9, '99999999999990D999999990')||'</td>'||CHR(10)||
       '<td class="r">'||TO_CHAR(pd.min_time/1e9, '99999999999990D999999990')||'</td>'||CHR(10)||
       '<td class="r">'||TO_CHAR(pd.max_time/1e9, '99999999999990D999999990')||'</td>'||CHR(10)||
       '<td nowrap><pre>'||
       (SELECT REPLACE(REPLACE(ds.text, '<', :LT), '>', :GT)
          FROM dba_source ds
         WHERE ds.owner = pu.unit_owner
           AND ds.name = pu.unit_name
           AND ds.type = DECODE(pu.unit_type, 'PACKAGE SPEC', 'PACKAGE', pu.unit_type)
           AND ds.line = pt.id)||
       '</pre></td>'||CHR(10)|| -- source line_text
       '</tr>'||CHR(10) line_text
  FROM plan_table pt,
       plsql_profiler_units pu,
       plsql_profiler_data pd
 WHERE pt.id > 0 -- line# > 0
   AND pu.runid = pt.search_columns
   AND pu.unit_number = pt.object_instance
   AND pd.runid(+) = pt.search_columns
   AND pd.unit_number(+) = pt.object_instance
   AND pd.line#(+) = pt.id
 ORDER BY
       pt.position,
       pt.id) v
 UNION ALL
SELECT pt.position,
       4 line_type,
       0 line#,
       CHR(10)||'</table>'||CHR(10)||CHR(10) line_text
  FROM plan_table pt
 WHERE pt.id = pt.parent_id) v2
 ORDER BY
       v2.position,
       v2.line_type,
       v2.line#;

/* -------------------------
 *
 * Top Profiled PL/SQL Libraries
 *
 * ------------------------- */
PRO <a name="tpl"></a><h2>Top ^^top_consumers. Profiled PL/SQL Libraries</h2>
PRO
PRO <table>
PRO
PRO Ordered by total time.
PRO
PRO <tr>
PRO <th>Top</th>
PRO <th>Lib<br>#</th>
PRO <th>Type</th>
PRO <th>Owner</th>
PRO <th>Name</th>
PRO <th>Timestamp</th>
PRO <th>Total Time<br>(seconds)</th>
PRO <th>Version<br>($Header)</th>
PRO </tr>
PRO

SELECT CHR(10)||'<tr>'||CHR(10)||
       '<td nowrap class="r">'||ROWNUM||'</td>'||CHR(10)||
       v.line_text||CHR(10)||
       '</tr>'
  FROM (
SELECT /*+ NO_MERGE */
       '<td nowrap class="r">'||pu.unit_number||'</td>'||CHR(10)||
       '<td nowrap>'||pu.unit_type||'</td>'||CHR(10)||
       '<td nowrap>'||DECODE(pu.unit_owner, '<anonymous>', NULL, pu.unit_owner)||'</td>'||CHR(10)||
       '<td nowrap>'||DECODE(pu.unit_name, '<anonymous>', NULL, pu.unit_name)||'</td>'||CHR(10)||
       '<td nowrap>'||DECODE(TO_CHAR(pu.unit_timestamp, 'j'), '0000000', NULL, TO_CHAR(pu.unit_timestamp, 'YYYY-MM-DD/HH24:MI:SS'))||'</td>'||CHR(10)||
       '<td nowrap class="r">'||TO_CHAR(pu.total_time/1e9, '99999999999990D999999990')||'</td>'||CHR(10)||
       '<td nowrap><pre>'||
       (SELECT REPLACE(REPLACE(ds.text, '<', :LT), '>', :GT)
          FROM dba_source ds
         WHERE ds.owner = pu.unit_owner
           AND ds.name = pu.unit_name
           AND ds.type = DECODE(pu.unit_type, 'PACKAGE SPEC', 'PACKAGE', pu.unit_type)
           AND ds.line  < 51
           AND UPPER(ds.text) LIKE ('%$%HEADER%')
           AND ROWNUM  = 1)||
       '</pre></td>' -- source line_text
       line_text
  FROM plsql_profiler_units pu
 WHERE pu.runid = :runid
 ORDER BY
       pu.total_time DESC) v
 WHERE ROWNUM <= ^^top_consumers.;

SELECT CHR(10)||'<tr>'||CHR(10)||
       '<td></td>'||CHR(10)||
       '<td></td>'||CHR(10)||
       '<td>TOTAL</td>'||CHR(10)||
       '<td></td>'||CHR(10)||
       '<td></td>'||CHR(10)||
       '<td></td>'||CHR(10)||
       '<td class="r">'||TO_CHAR(SUM(v.total_time)/1e9, '99999999999990D999999990')||'</td>'||CHR(10)||
       '<td></td>'||CHR(10)||
       '</tr>'
  FROM (
SELECT /*+ NO_MERGE */
       total_time
  FROM plsql_profiler_units
 WHERE runid = :runid
 ORDER BY
       total_time DESC) v
 WHERE ROWNUM <= ^^top_consumers.;

PRO
PRO </table>
PRO

/* -------------------------
 *
 * All Profiled PL/SQL Libraries
 *
 * ------------------------- */
PRO <a name="apl"></a><h2>All Profiled PL/SQL Libraries</h2>
PRO
PRO Ordered first by library unit number "Lib #" and "ANONYMOUS BLOCK" last.
PRO Aggregates all "ANONYMOUS BLOCK" libraries, displaying only COUNT under "Lib #" and time SUM.
PRO
PRO <table>
PRO
PRO <tr>
PRO <th>Lib<br>#</th>
PRO <th>Type</th>
PRO <th>Owner</th>
PRO <th>Name</th>
PRO <th>Timestamp</th>
PRO <th>Total Time<br>(seconds)</th>
PRO <th>Version<br>($Header)</th>
PRO </tr>
PRO

SELECT CHR(10)||'<tr>'||CHR(10)||
       '<td nowrap class="r">'||pu.unit_number||'</td>'||CHR(10)||
       '<td nowrap>'||pu.unit_type||'</td>'||CHR(10)||
       '<td nowrap>'||DECODE(pu.unit_owner, '<anonymous>', NULL, pu.unit_owner)||'</td>'||CHR(10)||
       '<td nowrap>'||DECODE(pu.unit_name, '<anonymous>', NULL, pu.unit_name)||'</td>'||CHR(10)||
       '<td nowrap>'||DECODE(TO_CHAR(pu.unit_timestamp, 'j'), '0000000', NULL, TO_CHAR(pu.unit_timestamp, 'YYYY-MM-DD/HH24:MI:SS'))||'</td>'||CHR(10)||
       '<td nowrap class="r">'||TO_CHAR(pu.total_time/1e9, '99999999999990D999999990')||'</td>'||CHR(10)||
       '<td nowrap><pre>'||
       (SELECT REPLACE(REPLACE(ds.text, '<', :LT), '>', :GT)
          FROM dba_source ds
         WHERE ds.owner = pu.unit_owner
           AND ds.name = pu.unit_name
           AND ds.type = DECODE(pu.unit_type, 'PACKAGE SPEC', 'PACKAGE', pu.unit_type)
           AND ds.line  < 51
           AND UPPER(ds.text) LIKE ('%$%HEADER%')
           AND ROWNUM  = 1)||
       '</pre></td>'||CHR(10)|| -- source line_text
       '</tr>'
  FROM plsql_profiler_units pu
 WHERE pu.runid = :runid
   AND pu.unit_type <> 'ANONYMOUS BLOCK'
 ORDER BY
       pu.unit_number;

SELECT CHR(10)||'<tr>'||CHR(10)||
       '<td nowrap class="r">'||COUNT(*)||'</td>'||CHR(10)||
       '<td nowrap>ANONYMOUS BLOCK</td>'||CHR(10)||
       '<td nowrap></td>'||CHR(10)||
       '<td nowrap></td>'||CHR(10)||
       '<td nowrap></td>'||CHR(10)||
       '<td nowrap class="r">'||TO_CHAR(SUM(total_time)/1e9, '99999999999990D999999990')||'</td>'||CHR(10)||
       '<td nowrap></td>'||CHR(10)||
       '</tr>'
  FROM plsql_profiler_units
 WHERE runid = :runid
   AND unit_type = 'ANONYMOUS BLOCK';

SELECT CHR(10)||'<tr>'||CHR(10)||
       '<td></td>'||CHR(10)||
       '<td>TOTAL</td>'||CHR(10)||
       '<td></td>'||CHR(10)||
       '<td></td>'||CHR(10)||
       '<td></td>'||CHR(10)||
       '<td class="r">'||TO_CHAR(SUM(total_time)/1e9, '99999999999990D999999990')||'</td>'||CHR(10)||
       '<td nowrap></td>'||CHR(10)||
       '</tr>'
  FROM plsql_profiler_units
 WHERE runid = :runid;

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
PRO <font class="f">^^mos_doc. ^^method. ^^doc_ver. ^^time_stamp2.</font>
PRO </body>
PRO </html>

SPO OFF;

/* -------------------------
 *
 * nothing is updated to the db
 *
 * ------------------------- */
ROLLBACK TO save_point_1;

SET TERM ON ECHO OFF FEED 6 VER ON SHOW OFF HEA ON LIN 80 NEWP 1 PAGES 14 LONG 80 LONGC 80 SQLC MIX TAB ON TRIMS OFF TI OFF TIMI OFF ARRAY 15 NUMF "" SQLP SQL> SUF sql BLO . RECSEP WR APPI OFF SERVEROUT OFF AUTOT OFF;
PRO
PRO ^^method. file has been created:
PRO ^^script._^^database_name_short._^^host_name_short._^^rdbms_version._^^time_stamp..html.
PRO
CL COL;
SET DEF ON;
UNDEFINE 1 2 script mos_doc doc_ver doc_date doc_link bug_link runid;
