ACC sql_text_piece PROMPT 'SQL Text Piece (opt): ';
ACC sql_id PROMPT 'SQL_ID (opt): ';

SET TERM OFF HEA OFF LIN 32767 NEWP NONE PAGES 0 FEED OFF ECHO OFF VER OFF LONG 32000 LONGC 2000 WRA ON TRIMS ON TRIM ON TI OFF TIMI OFF ARRAY 100 NUM 20 SQLBL ON BLO . RECSEP OFF;
COL current_time NEW_V current_time FOR A15;
SELECT 'current_time: ' x, TO_CHAR(SYSDATE, 'YYYYMMDD_HH24MISS') current_time FROM DUAL;
PRO
DEF report_title = "Average performance of KIEV Tx";
DEF report_abstract_1 = "<br>Average Elapsed Time and CPU Times of SQL statements part of a KIEV transaction.";
DEF report_abstract_2 = "<br>KIEV Transaction:(&&sql_text_piece.).";
DEF report_abstract_3 = "<br>SQL_ID: &&sql_id.";
DEF report_abstract_4 = "";
DEF chart_title = "Average performance of SQL statements on KIEV Tx &&sql_text_piece.";
DEF xaxis_title = "Average Elapsed and CPU Times";
DEF vaxis_title = "Avg Execution Time in Milliseconds";
COL cpu_count NEW_V cpu_count;
SELECT TO_CHAR(ROUND(TO_NUMBER(value) * 0.7)) cpu_count FROM v$parameter WHERE name = 'cpu_count'; 
DEF vaxis_baseline = ", baseline:&&cpu_count.";
DEF vaxis_baseline = "";;
DEF chart_foot_note_1 = "<br>1) Drag to Zoom, and right click to reset Chart.";
DEF chart_foot_note_2 = "<br>2) ";
DEF chart_foot_note_3 = "";
DEF chart_foot_note_4 = "";
DEF report_foot_note = "Based on dba_hist_sqlstat";
PRO
SPO dba_hist_sqlstat_text_&&current_time..html;
PRO <html>
PRO <!-- $Header: line_chart.sql 2014-07-27 carlos.sierra $ -->
PRO <head>
PRO <title>line_chart.html</title>
PRO
PRO <style type="text/css">
PRO body             {font:10pt Arial,Helvetica,Geneva,sans-serif; color:black; background:white;}
PRO h1               {font-size:16pt; font-weight:bold; color:#336699; border-bottom:1px solid #336699; margin-top:0pt; margin-bottom:0pt; padding:0px 0px 0px 0px;}
PRO h2               {font-size:14pt; font-weight:bold; color:#336699; margin-top:4pt; margin-bottom:0pt;}
PRO h3               {font-size:12pt; font-weight:bold; color:#336699; margin-top:4pt; margin-bottom:0pt;}
PRO pre              {font:8pt monospace,Monaco,"Courier New",Courier;}
PRO a                {color:#663300;}
PRO table            {font-size:8pt; border-collapse:collapse; empty-cells:show; white-space:nowrap; border:1px solid #336699;}
PRO li               {font-size:8pt; color:black; padding-left:4px; padding-right:4px; padding-bottom:2px;}
PRO th               {font-weight:bold; color:white; background:#0066CC; padding-left:4px; padding-right:4px; padding-bottom:2px;}
PRO tr               {color:black; background:white;}
PRO tr:hover         {color:white; background:#0066CC;}
PRO tr.main          {color:black; background:white;}
PRO tr.main:hover    {color:black; background:white;}
PRO td               {vertical-align:top; border:1px solid #336699;}
PRO td.c             {text-align:center;}
PRO font.n           {font-size:8pt; font-style:italic; color:#336699;}
PRO font.f           {font-size:8pt; color:#999999; border-top:1px solid #336699; margin-top:30pt;}
PRO div.google-chart {width:809px; height:500px;}
PRO </style>
PRO
PRO <script type="text/javascript" src="https://www.google.com/jsapi"></script>
PRO <script type="text/javascript">
PRO google.load("visualization", "1", {packages:["corechart"]})
PRO google.setOnLoadCallback(drawChart)
PRO
PRO function drawChart() {
PRO var data = google.visualization.arrayToDataTable([
/* add below more columns if needed (modify 3 places) */
PRO [
PRO 'Date Column', 
PRO 'CPU Time',
PRO 'Elapsed Time'
PRO ]
/****************************************************************************************/
WITH   
my_tx_sql AS (
SELECT DISTINCT sql_id
FROM v$sql
WHERE (UPPER(sql_text) LIKE UPPER('%&&sql_text_piece.%') AND UPPER(sql_text) NOT LIKE '%SQL_ID%') OR sql_id = '&&sql_text_piece.'
UNION 
SELECT DISTINCT sql_id
FROM dba_hist_sqltext
WHERE (UPPER(DBMS_LOB.SUBSTR(sql_text, 4000)) LIKE UPPER('%&&sql_text_piece.%') AND UPPER(DBMS_LOB.SUBSTR(sql_text, 4000)) NOT LIKE '%SQL_ID%') OR sql_id = '&&sql_text_piece.'
),
my_query AS (
/* query below selects one date_column and a small set of number_columns */
SELECT s.snap_id,
       CAST(s.end_interval_time AS DATE) end_date,
       ROUND(SUM(h.elapsed_time_delta)/SUM(h.executions_delta)/1000, 3) avg_et_ms_per_exec,
       ROUND(SUM(h.cpu_time_delta)/SUM(h.executions_delta)/1000, 3) avg_cpu_ms_per_exec
  FROM dba_hist_sqlstat h, dba_hist_snapshot s
 WHERE h.executions_delta > 0
   AND s.snap_id = h.snap_id
   AND s.dbid = h.dbid
   AND s.instance_number = h.instance_number
   AND ('&&sql_id.' IS NULL OR h.sql_id = '&&sql_id.')
   AND h.sql_id IN (SELECT sql_id FROM my_tx_sql)
 GROUP BY
       s.snap_id,
       s.end_interval_time
/* end of query */
)
/****************************************************************************************/
/* no need to modify the date column below, but you may need to add some number columns */
SELECT ', [new Date('||
       TO_CHAR(q.end_date, 'YYYY')|| /* year */
       ','||(TO_NUMBER(TO_CHAR(q.end_date, 'MM')) - 1)|| /* month - 1 */
       ','||TO_CHAR(q.end_date, 'DD')|| /* day */
       ','||TO_CHAR(q.end_date, 'HH24')|| /* hour */
       ','||TO_CHAR(q.end_date, 'MI')|| /* minute */
       ','||TO_CHAR(q.end_date, 'SS')|| /* second */
       ')'||
       ','||q.avg_cpu_ms_per_exec|| 
       ','||q.avg_et_ms_per_exec|| 
       ']'
  FROM my_query q
 ORDER BY
       q.end_date
/
/****************************************************************************************/
PRO ]);
PRO
PRO var options = {isStacked: true,
PRO chartArea:{left:90, top:75, width:'65%', height:'70%'},
PRO backgroundColor: {fill: 'white', stroke: '#336699', strokeWidth: 1},
PRO explorer: {actions: ['dragToZoom', 'rightClickToReset'], maxZoomIn: 0.01},
PRO title: '&&chart_title.',
PRO titleTextStyle: {fontSize: 18, bold: false},
PRO focusTarget: 'category',
PRO legend: {position: 'right', textStyle: {fontSize: 14}},
PRO tooltip: {textStyle: {fontSize: 14}},
PRO hAxis: {title: '&&xaxis_title.', gridlines: {count: -1}, titleTextStyle: {fontSize: 16, bold: false}},
PRO series: { 0: { color :'#34CF27'}, 1: { color :'#0252D7'},  2: { color :'#1E96DD'},  3: { color :'#CEC3B5'},  4: { color :'#EA6A05'},  5: { color :'#871C12'},  6: { color :'#C42A05'}, 7: {color :'#75763E'},
PRO 8: { color :'#594611'}, 9: { color :'#989779'}, 10: { color :'#C6BAA5'}, 11: { color :'#9FFA9D'}, 12: { color :'#F571A0'}, 13: { color :'#000000'}, 14: { color :'#ff0000'}},
PRO vAxis: {title: '&&vaxis_title.' &&vaxis_baseline., gridlines: {count: -1}, titleTextStyle: {fontSize: 16, bold: false}}
PRO }
PRO
PRO var chart = new google.visualization.LineChart(document.getElementById('chart_div'))
PRO chart.draw(data, options)
PRO }
PRO </script>
PRO </head>
PRO <body>
PRO <h1>&&report_title.</h1>
PRO &&report_abstract_1.
PRO &&report_abstract_2.
PRO &&report_abstract_3.
PRO &&report_abstract_4.
PRO <div id="chart_div" class="google-chart"></div>
PRO <font class="n">Notes:</font>
PRO <font class="n">&&chart_foot_note_1.</font>
PRO <font class="n">&&chart_foot_note_2.</font>
PRO <font class="n">&&chart_foot_note_3.</font>
PRO <font class="n">&&chart_foot_note_4.</font>
PRO <pre>
L
PRO </pre>
PRO <br>
PRO <font class="f">&&report_foot_note.</font>
PRO </body>
PRO </html>
SPO OFF;
UNDEF date, sql_id
SET TERM ON HEA ON LIN 80 NEWP 1 PAGES 14 FEED ON ECHO OFF VER ON LONG 80 LONGC 80 WRA ON TRIMS OFF TRIM OFF TI OFF TIMI OFF ARRAY 15 NUM 10 NUMF "" SQLBL OFF BLO ON RECSEP WR;
