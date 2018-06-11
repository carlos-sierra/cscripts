SET HEA ON LIN 500 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF;
SET PAGES 100;
PRO
COL granularity NEW_V granularity NOPRI;
PRO 1. Granularity [{MI}|HH24|DD] (MI=minute HH24=hour DD=day):
SELECT NVL(UPPER('&&1.'),'MI') granularity FROM DUAL
/
PRO
COL dbid NEW_V dbid NOPRI;
COL instance_number NEW_V instance_number NOPRI;
SELECT TO_CHAR(dbid) dbid, SYS_CONTEXT('USERENV', 'INSTANCE') instance_number FROM v$database
/
COL time_from_default NEW_V time_from_default NOPRI;
COL time_to_default NEW_V time_to_default NOPRI;
COL date_format NEW_V date_format NOPRI;
COL denominator NEW_V denominator NOPRI;
SELECT CASE '&&granularity.'
         WHEN 'HH24' THEN TO_CHAR(TRUNC(MAX(end_interval_time-7),'DD'),'YYYY-MM-DD"T"HH24:MI:SS') 
         WHEN 'DD' THEN TO_CHAR(TRUNC(GREATEST(MAX(end_interval_time-60),MIN(end_interval_time)),'DD')+1,'YYYY-MM-DD"T"HH24:MI:SS') 
         ELSE TO_CHAR(TRUNC(MAX(end_interval_time-1),'HH24'),'YYYY-MM-DD"T"HH24:MI:SS') 
       END time_from_default,
       CASE '&&granularity.'
         WHEN 'HH24' THEN TO_CHAR(TRUNC(MAX(end_interval_time),'HH24')-(1/24/60/60),'YYYY-MM-DD"T"HH24:MI:SS') 
         WHEN 'DD' THEN TO_CHAR(TRUNC(MAX(end_interval_time),'DD')-(1/24/60/60),'YYYY-MM-DD"T"HH24:MI:SS') 
         ELSE TO_CHAR(TRUNC(MAX(end_interval_time),'MI')-(1/24/60/60),'YYYY-MM-DD"T"HH24:MI:SS') 
       END time_to_default,
       CASE '&&granularity.'
         WHEN 'HH24' THEN 'YYYY-MM-DD"T"HH24'
         WHEN 'DD' THEN 'YYYY-MM-DD'
         ELSE 'YYYY-MM-DD"T"HH24:MI'
       END date_format,
       CASE '&&granularity.'
         WHEN 'HH24' THEN '360'
         WHEN 'DD' THEN '6240'
         ELSE '6'
       END denominator
  FROM dba_hist_snapshot
 WHERE dbid = TO_NUMBER('&&dbid.')
   AND instance_number = TO_NUMBER('&&instance_number.')
/
COL current_time NEW_V current_time NOPRI;
SELECT TO_CHAR(SYSDATE, 'YYYY-MM-DD"T"HH24:MI:SS') current_time FROM DUAL
/
PRO
PRO Current time: &&current_time.
PRO
PRO 2. Enter time FROM (default &&time_from_default.):
COL sample_time_from NEW_V sample_time_from NOPRI;
SELECT NVL('&&2.','&&time_from_default.') sample_time_from FROM DUAL
/
PRO
PRO 3. Enter time TO (default &&time_to_default.):
COL sample_time_to NEW_V sample_time_to NOPRI;
SELECT NVL('&&3.','&&time_to_default.') sample_time_to FROM DUAL
/
PRO 4. Enter SQL_ID (optional):
DEF sql_id = '&&4.';
PRO
COL min_snap_id NEW_V min_snap_id NOPRI;
SELECT TO_CHAR(MIN(snap_id)) min_snap_id
  FROM dba_hist_snapshot
 WHERE TO_TIMESTAMP('&&sample_time_from.', 'YYYY-MM-DD"T"HH24:MI:SS') BETWEEN begin_interval_time AND end_interval_time
   AND dbid = TO_NUMBER('&&dbid.')
   AND instance_number = TO_NUMBER('&&instance_number.')
/
COL max_snap_id NEW_V max_snap_id NOPRI;
SELECT TO_CHAR(MAX(snap_id)) max_snap_id
  FROM dba_hist_snapshot
 WHERE TO_TIMESTAMP('&&sample_time_to.', 'YYYY-MM-DD"T"HH24:MI:SS') BETWEEN begin_interval_time AND end_interval_time
   AND dbid = TO_NUMBER('&&dbid.')
   AND instance_number = TO_NUMBER('&&instance_number.')
/
SELECT 'current_time: ' x, TO_CHAR(SYSDATE, 'YYYYMMDD_HH24MISS') current_time FROM DUAL;
COL x_host_name NEW_V x_host_name;
SELECT host_name x_host_name FROM v$instance;
COL x_db_name NEW_V x_db_name;
SELECT name x_db_name FROM v$database;
COL x_container NEW_V x_container;
SELECT 'NONE' x_container FROM DUAL;
SELECT SYS_CONTEXT('USERENV', 'CON_NAME') x_container FROM DUAL;
COL num_cpu_cores NEW_V num_cpu_cores;
SELECT TO_CHAR(value) num_cpu_cores FROM v$osstat WHERE stat_name = 'NUM_CPU_CORES';
PRO
COL output_file_name NEW_V output_file_name NOPRI;
SELECT 'ash_awr_chart_'||LOWER(name)||'_'||LOWER(REPLACE(SUBSTR(host_name, 1 + INSTR(host_name, '.', 1, 2), 30), '.', '_'))||'_'||REPLACE(LOWER(SYS_CONTEXT('USERENV','CON_NAME')),'$')||'_'||(CASE WHEN '&&sql_id.' IS NOT NULL THEN '&&sql_id._' END)||TO_CHAR(SYSDATE, 'YYYYMMDD_HH24MISS') output_file_name FROM v$database, v$instance;
PRO
DEF report_title = "Average Active Sessions (AAS) &&x_container. &&sql_id.";
DEF report_abstract_1 = "DATABASE: &&x_db_name.";
DEF report_abstract_2 = "<br>PDB: &&x_container.";
DEF report_abstract_3 = "<br>HOST: &&x_host_name.";
DEF report_abstract_4 = "<br>CORES: &&num_cpu_cores.";
DEF report_abstract_5 = "<br>SQL_ID: &&sql_id.";
DEF chart_title = "&&x_container. &&sql_id.";
DEF xaxis_title = "between &&sample_time_from. and &&sample_time_to.";
DEF vaxis_title = "Average Active Sessions";
DEF vaxis_baseline = "";
DEF chart_foot_note_1 = "<br>1) Drag to Zoom, and right click to reset Chart.";
DEF chart_foot_note_2 = "";
DEF chart_foot_note_3 = "";
DEF chart_foot_note_4 = "";
DEF report_foot_note = "&&output_file_name..html";
PRO
SPO &&output_file_name..html;
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
PRO [
PRO 'Date Column'    , 
PRO 'ON CPU'         ,
PRO 'User I/O'       ,
PRO 'System I/O'     ,
PRO 'Cluster'        ,
PRO 'Commit'         ,
PRO 'Concurrency'    ,
PRO 'Application'    ,
PRO 'Administrative' ,
PRO 'Configuration'  ,
PRO 'Network'        ,
PRO 'Queueing'       ,
PRO 'Scheduler'      ,
PRO 'Other'          ,
PRO ]
/****************************************************************************************/
SET HEA OFF PAGES 0;
WITH   
my_query AS (
SELECT TRUNC(sample_time, '&&granularity.') time,
       ROUND(COUNT(*)/TO_NUMBER('&&denominator.'),1) aas_total, -- average active sessions on the database (on cpu or waiting)
       ROUND(SUM(CASE session_state WHEN 'ON CPU'         THEN 1 ELSE 0 END)/TO_NUMBER('&&denominator.'),1) aas_on_cpu,
       ROUND(SUM(CASE wait_class    WHEN 'User I/O'       THEN 1 ELSE 0 END)/TO_NUMBER('&&denominator.'),1) aas_user_io,
       ROUND(SUM(CASE wait_class    WHEN 'System I/O'     THEN 1 ELSE 0 END)/TO_NUMBER('&&denominator.'),1) aas_system_io,
       ROUND(SUM(CASE wait_class    WHEN 'Cluster'        THEN 1 ELSE 0 END)/TO_NUMBER('&&denominator.'),1) aas_cluster,
       ROUND(SUM(CASE wait_class    WHEN 'Commit'         THEN 1 ELSE 0 END)/TO_NUMBER('&&denominator.'),1) aas_commit,
       ROUND(SUM(CASE wait_class    WHEN 'Concurrency'    THEN 1 ELSE 0 END)/TO_NUMBER('&&denominator.'),1) aas_concurrency,
       ROUND(SUM(CASE wait_class    WHEN 'Application'    THEN 1 ELSE 0 END)/TO_NUMBER('&&denominator.'),1) aas_application,
       ROUND(SUM(CASE wait_class    WHEN 'Administrative' THEN 1 ELSE 0 END)/TO_NUMBER('&&denominator.'),1) aas_administrative,
       ROUND(SUM(CASE wait_class    WHEN 'Configuration'  THEN 1 ELSE 0 END)/TO_NUMBER('&&denominator.'),1) aas_configuration,
       ROUND(SUM(CASE wait_class    WHEN 'Network'        THEN 1 ELSE 0 END)/TO_NUMBER('&&denominator.'),1) aas_network,
       ROUND(SUM(CASE wait_class    WHEN 'Queueing'       THEN 1 ELSE 0 END)/TO_NUMBER('&&denominator.'),1) aas_queueing,
       ROUND(SUM(CASE wait_class    WHEN 'Scheduler'      THEN 1 ELSE 0 END)/TO_NUMBER('&&denominator.'),1) aas_scheduler,
       ROUND(SUM(CASE wait_class    WHEN 'Other'          THEN 1 ELSE 0 END)/TO_NUMBER('&&denominator.'),1) aas_other
  FROM dba_hist_active_sess_history
 WHERE sample_time BETWEEN TO_TIMESTAMP('&&sample_time_from.', 'YYYY-MM-DD"T"HH24:MI:SS') AND TO_TIMESTAMP('&&sample_time_to.', 'YYYY-MM-DD"T"HH24:MI:SS')
   AND ('&&sql_id.' IS NULL OR sql_id = '&&sql_id.')
   AND dbid = TO_NUMBER('&&dbid.')
   AND instance_number = TO_NUMBER('&&instance_number.')
   AND snap_id BETWEEN TO_NUMBER('&&min_snap_id.') AND TO_NUMBER('&&max_snap_id.')
 GROUP BY
       TRUNC(sample_time, '&&granularity.')
)
/****************************************************************************************/
SELECT ', [new Date('||
       TO_CHAR(q.time, 'YYYY')|| /* year */
       ','||(TO_NUMBER(TO_CHAR(q.time, 'MM')) - 1)|| /* month - 1 */
       ','||TO_CHAR(q.time, 'DD')|| /* day */
       ','||TO_CHAR(q.time, 'HH24')|| /* hour */
       ','||TO_CHAR(q.time, 'MI')|| /* minute */
       ','||TO_CHAR(q.time, 'SS')|| /* second */
       ')'||
       ','||q.aas_on_cpu|| 
       ','||q.aas_user_io|| 
       ','||q.aas_system_io|| 
       ','||q.aas_cluster|| 
       ','||q.aas_commit|| 
       ','||q.aas_concurrency|| 
       ','||q.aas_application|| 
       ','||q.aas_administrative|| 
       ','||q.aas_configuration|| 
       ','||q.aas_network|| 
       ','||q.aas_queueing|| 
       ','||q.aas_scheduler|| 
       ','||q.aas_other||
       ']'
  FROM my_query q
 ORDER BY
       q.time
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
PRO var chart = new google.visualization.AreaChart(document.getElementById('chart_div'))
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
PRO &&report_abstract_5.
PRO <div id="chart_div" class="google-chart"></div>
PRO <font class="n">Notes:</font>
PRO <font class="n">&&chart_foot_note_1.</font>
PRO <font class="n">&&chart_foot_note_2.</font>
PRO <font class="n">&&chart_foot_note_3.</font>
PRO <font class="n">&&chart_foot_note_4.</font>
--PRO <pre>
--L
--PRO </pre>
PRO <br>
PRO <font class="f">&&report_foot_note.</font>
PRO </body>
PRO </html>
SPO OFF;
PRO
PRO &&output_file_name..html;
PRO
SET HEA ON PAGES 100;
UNDEF 1 2 3 4 sql_id

