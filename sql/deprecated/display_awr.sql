REM $Header: 215187.1 display_awr.sql 11.4.5.8 2013/05/10 carlos.sierra $

PAU Requires Oracle Diagnostics Pack license. Hit "Enter" to proceed

ACC sql_text_piece PROMPT 'Enter SQL Text piece: '

SET PAGES 200 LONG 80000 ECHO ON;

COL sql_text PRI;

SELECT dbid, sql_id, sql_text /* exclude_me */
  FROM dba_hist_sqltext
 WHERE sql_text LIKE '%&&sql_text_piece.%'
   AND sql_text NOT LIKE '%/* exclude_me */%';

ACC dbid NUM PROMPT 'Enter DBID: ';

ACC sql_id PROMPT 'Enter SQL_ID: ';

SELECT p.snap_id, s.begin_interval_time, s.end_interval_time, /* exclude_me */
       p.plan_hash_value, p.executions_total, p.elapsed_time_total,
       CASE WHEN p.executions_total > 0 THEN ROUND(p.elapsed_time_total/p.executions_total/1e6, 3) END avg_secs_per_exec
  FROM dba_hist_sqlstat p,
       dba_hist_snapshot s
 WHERE p.dbid = &&dbid
   AND p.sql_id = '&&sql_id.'
   AND s.snap_id = p.snap_id
   AND s.dbid = p.dbid
   AND s.instance_number = p.instance_number
 ORDER BY
       p.snap_id, p.plan_hash_value;

ACC plan_hash_value PROMPT 'Enter Plan Hash Value: ';

SPO &&sql_id._&&plan_hash_value._awr.txt;

SET PAGES 2000 LIN 300 TRIMS ON ECHO ON FEED OFF HEA OFF;

SELECT * /* exclude_me */
FROM TABLE(DBMS_XPLAN.display_awr('&&sql_id.', TO_NUMBER('&&plan_hash_value.'), TO_NUMBER('&&dbid.'), 'ADVANCED'));

SPO OFF;

SET NUM 10 PAGES 14 LONG 80 LIN 80 TRIMS OFF ECHO OFF FEED 6 HEA ON;

UNDEF sql_text_piece dbid sql_id plan_hash_value
