REM $Header: 215187.1 3_mon_reports.sql 11.4.5.8 2013/05/10 carlos.sierra $
SET ECHO OFF FEED OFF VER OFF SHOW OFF HEA OFF LIN 2000 NUM 20 NEWP NONE PAGES 0 LONG 2000000 LONGC 2000 SQLC MIX TAB ON TRIMS ON TI OFF TIMI OFF ARRAY 100 NUMF "" SQLP SQL> SUF sql BLO . RECSEP OFF APPI OFF AUTOT OFF SERVEROUT ON SIZE UNL;

SPO reports_driver.sql;
PRO SET ECHO OFF FEED OFF VER OFF SHOW OFF HEA OFF LIN 2000 NUM 20 NEWP NONE PAGES 0 LONG 2000000 LONGC 2000 SQLC MIX TAB ON TRIMS ON TI OFF TIMI OFF ARRAY 100 NUMF "" SQLP SQL> SUF sql BLO . RECSEP OFF APPI OFF AUTOT OFF SERVEROUT ON SIZE UNL;;
BEGIN
  FOR i IN (SELECT t.sql_id, t.key, t.ROWID row_id FROM v_sql_monitor t WHERE t.report_date IS NULL)
  LOOP
    DBMS_OUTPUT.PUT_LINE('SPO sql_id_'||i.sql_id||'_key_'||i.key||'.html;');
    DBMS_OUTPUT.PUT_LINE('SELECT mon_report FROM v_sql_monitor WHERE sql_id = '''||i.sql_id||''' AND key = '||i.key||';');
    DBMS_OUTPUT.PUT_LINE('SPO OFF;');
    DBMS_OUTPUT.PUT_LINE('UPDATE v_sql_monitor SET report_date = SYSDATE WHERE ROWID = '''||i.row_id||''';');
    DBMS_OUTPUT.PUT_LINE('HOS zip -m mon_reports sql_id_'||i.sql_id||'_key_'||i.key||'.html');
  END LOOP;
END;
/
PRO COMMIT;;
PRO SET TERM ON ECHO OFF FEED 6 VER ON SHOW OFF HEA ON LIN 80 NUM 10 NEWP 1 PAGES 14 LONG 80 LONGC 80 SQLC MIX TAB ON TRIMS OFF TI OFF TIMI OFF ARRAY 15 NUMF "" SQLP SQL> SUF sql BLO . RECSEP WR APPI OFF SERVEROUT OFF AUTOT OFF;;
SPO OFF;

@reports_driver.sql

HOS zip -m mon_reports reports_driver.sql
HOS unzip -l mon_reports

SET TERM ON ECHO OFF FEED 6 VER ON SHOW OFF HEA ON LIN 80 NUM 10 NEWP 1 PAGES 14 LONG 80 LONGC 80 SQLC MIX TAB ON TRIMS OFF TI OFF TIMI OFF ARRAY 15 NUMF "" SQLP SQL> SUF sql BLO . RECSEP WR APPI OFF SERVEROUT OFF AUTOT OFF;

/***********************************/

REM Special thanks to <igor.afonin@gmail.com> for suggesting this html report

SPO mon_main.html;

PRO <html>
PRO <!-- $Header: 215187.1 3_mon_reports.sql 11.4.5.8 2013/05/10 carlos.sierra $ -->
PRO <!-- Copyright (c) 2000-2013, Oracle Corporation. All rights reserved. -->
PRO <!-- Author: carlos.sierra@oracle.com -->
PRO <!-- Special thanks to <igor.afonin@gmail.com> for suggesting this html report -->
PRO
PRO <head>
PRO <title>mon_main.html</title>
PRO
PRO <style type="text/css">
PRO a {font-weight:bold; color:#663300;}
PRO h1 {font-size:16pt; font-weight:bold; color:#336699;}
PRO table {font-size:8pt; color:black; background:white;}
PRO th {font-weight:bold; background:#cccc99; color:#336699; vertical-align:bottom; padding-left:3pt; padding-right:3pt; padding-top:1pt; padding-bottom:1pt;}
PRO td {text-align:left; background:#fcfcf0; vertical-align:top; padding-left:3pt; padding-right:3pt; padding-top:1pt; padding-bottom:1pt;}
PRO font.f {font-size:8pt; color:#999999;} /* footnote in gray */
PRO </style>
PRO
PRO </head>
PRO <body>
PRO <h1>215187.1 mon_main.html 11.4.5.8</h1>
PRO

SET HEA ON PAGES 25 MARK HTML ON TABLE "" ENTMAP OFF SPOOL OFF;

SELECT ROWNUM "#", v.*
  FROM (
SELECT TO_CHAR(sql_exec_start, 'YYYY-MM-DD HH24:MI:SS') sql_exec_start,
       TO_CHAR(last_refresh_time, 'YYYY-MM-DD HH24:MI:SS') last_refresh_time,
       ROUND((last_refresh_time - sql_exec_start) * 24 * 60 * 60, 3) elapsed_secs,
       status,
       username,
       TO_CHAR(capture_date, 'YYYY-MM-DD HH24:MI:SS') capture_date,
       TO_CHAR(report_date, 'YYYY-MM-DD HH24:MI:SS') report_date,
       --'<a href="sql_id_'||sql_id||'_key_'||key||'.html">sql_id_'||sql_id||'_key_'||key||'.html</a>' report,
       sql_id,
       '<a href="sql_id_'||sql_id||'_key_'||key||'.html">'||key||'</a>' key,
       sql_text
  FROM v_sql_monitor
 ORDER BY
       sql_exec_start DESC ) v;

SET HEA OFF PAGES 0 MARK HTML OFF;

PRO
PRO <hr size="3">
PRO <font class="f">215187.1 3_mon_reports.sql 11.4.5.8</font>
PRO </body>
PRO </html>

SPO OFF;

HOS zip -m mon_reports mon_main.html
HOS unzip -l mon_reports
