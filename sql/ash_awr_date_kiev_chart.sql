ACC date PROMPT 'YYYY-MM-DD (opt): ';
PRO KIEV Transaction: C=commitTx | B=beginTx | R=read | G=GC | CB=commitTx+beginTx | <null>=commitTx+beginTx+read+GC
ACC kiev_tx PROMPT 'KIEV Transaction (opt): ';
ACC sql_id PROMPT 'SQL_ID (opt): ';

SET HEA ON LIN 500 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF;
SET HEA OFF PAGES 0;

COL query_date NEW_V query_date;
SELECT NVL('&&date.', TO_CHAR(SYSDATE, 'YYYY-MM-DD')) query_date FROM DUAL;
COL current_time NEW_V current_time FOR A15;
SELECT 'current_time: ' x, TO_CHAR(SYSDATE, 'YYYYMMDD_HH24MISS') current_time FROM DUAL;
PRO
DEF report_title = "Active Sessions on KIEV Tx";
DEF report_abstract_1 = "<br>Active Sessions on CPU or Timed Wait Class.";
DEF report_abstract_2 = "<br>KIEV Transaction:(&&kiev_tx.). (C)=commitTx | (B)=beginTx | (R)=read | (G)=GC | (CB)=commitTx+beginTx | ()=commitTx+beginTx+read+GC";
DEF report_abstract_3 = "<br>SQL_ID: &&sql_id.";
DEF report_abstract_4 = "";
DEF chart_title = "Active Sessions on KIEV Tx &&kiev_tx.";
DEF xaxis_title = "Active Sessions for &&query_date.";
DEF vaxis_title = "Active Sessions";
COL cpu_count NEW_V cpu_count;
SELECT TO_CHAR(ROUND(TO_NUMBER(value) * 0.7)) cpu_count FROM v$parameter WHERE name = 'cpu_count'; 
DEF vaxis_baseline = ", baseline:&&cpu_count.";
DEF vaxis_baseline = "";;
DEF chart_foot_note_1 = "<br>1) Drag to Zoom, and right click to reset Chart.";
DEF chart_foot_note_2 = "<br>2) ";
DEF chart_foot_note_3 = "";
DEF chart_foot_note_4 = "";
DEF report_foot_note = "Active Sessions for &&query_date.";
PRO
SPO ash_awr_date_kiev_&&current_time..html;
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
WITH   
all_sql AS (
SELECT DISTINCT sql_id, sql_text FROM v$sql WHERE '&&sql_id.' IS NULL OR sql_id = '&&sql_id.'
UNION
SELECT DISTINCT sql_id, DBMS_LOB.SUBSTR(sql_text, 1000) FROM dba_hist_sqltext WHERE '&&sql_id.' IS NULL OR sql_id = '&&sql_id.'
),
all_sql_with_type AS (
SELECT sql_id, sql_text, 
       CASE 
         WHEN sql_text LIKE '/* addTransactionRow('||CHR(37)||') */'||CHR(37) 
           OR sql_text LIKE '/* checkStartRowValid('||CHR(37)||') */'||CHR(37) 
         THEN 'BEGIN'
         WHEN sql_text LIKE '/* findMatchingRows('||CHR(37)||') */'||CHR(37) 
           OR sql_text LIKE '/* readTransactionsSince('||CHR(37)||') */'||CHR(37) 
           OR sql_text LIKE '/* writeTransactionKeys('||CHR(37)||') */'||CHR(37) 
           OR sql_text LIKE '/* setValueByUpdate('||CHR(37)||') */'||CHR(37) 
           OR sql_text LIKE '/* setValue('||CHR(37)||') */'||CHR(37) 
           OR sql_text LIKE '/* deleteValue('||CHR(37)||') */'||CHR(37) 
           OR sql_text LIKE '/* exists('||CHR(37)||') */'||CHR(37) 
           OR sql_text LIKE '/* existsUnique('||CHR(37)||') */'||CHR(37) 
           OR sql_text LIKE '/* updateIdentityValue('||CHR(37)||') */'||CHR(37) 
           OR sql_text LIKE 'LOCK TABLE '||CHR(37)||'KievTransactions IN EXCLUSIVE MODE'||CHR(37) 
           OR sql_text LIKE '/* getTransactionProgress('||CHR(37)||') */'||CHR(37) 
           OR sql_text LIKE '/* recordTransactionState('||CHR(37)||') */'||CHR(37) 
           OR sql_text LIKE '/* checkEndRowValid('||CHR(37)||') */'||CHR(37)
         THEN 'COMMIT'
         WHEN sql_text LIKE '/* getValues('||CHR(37)||') */'||CHR(37) 
           OR sql_text LIKE '/* getNextIdentityValue('||CHR(37)||') */'||CHR(37) 
           OR sql_text LIKE '/* performScanQuery('||CHR(37)||') */'||CHR(37)
         THEN 'READ'
         WHEN sql_text LIKE '/* populateBucketGCWorkspace */'||CHR(37) 
           OR sql_text LIKE '/* deleteBucketGarbage */'||CHR(37) 
           OR sql_text LIKE '/* Populate workspace for transaction GC */'||CHR(37) 
           OR sql_text LIKE '/* Delete garbage for transaction GC */'||CHR(37) 
           OR sql_text LIKE '/* Populate workspace in KTK GC */'||CHR(37) 
           OR sql_text LIKE '/* Delete garbage in KTK GC */'||CHR(37) 
           OR sql_text LIKE '/* hashBucket */'||CHR(37) 
         THEN 'GC'
        END application_module
  FROM all_sql
),
my_tx_sql AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       sql_id, MAX(sql_text) sql_text, MAX(application_module) application_module
  FROM all_sql_with_type
 WHERE application_module IS NOT NULL
  AND (  
         (NVL('&&kiev_tx.', 'CBRG') LIKE '%C%' AND application_module = 'COMMIT') OR
         (NVL('&&kiev_tx.', 'CBRG') LIKE '%B%' AND application_module = 'BEGIN') OR
         (NVL('&&kiev_tx.', 'CBRG') LIKE '%R%' AND application_module = 'READ') OR
         (NVL('&&kiev_tx.', 'CBRG') LIKE '%G%' AND application_module = 'GC')
      )
 GROUP BY
       sql_id
),
my_query AS (
/* query below selects one date_column and a small set of number_columns */
SELECT sample_id,
       sample_time,
       SUM(CASE session_state WHEN 'ON CPU'         THEN 1 ELSE 0 END) as_on_cpu,
       SUM(CASE wait_class    WHEN 'User I/O'       THEN 1 ELSE 0 END) as_user_io,
       SUM(CASE wait_class    WHEN 'System I/O'     THEN 1 ELSE 0 END) as_system_io,
       SUM(CASE wait_class    WHEN 'Cluster'        THEN 1 ELSE 0 END) as_cluster,
       SUM(CASE wait_class    WHEN 'Commit'         THEN 1 ELSE 0 END) as_commit,
       SUM(CASE wait_class    WHEN 'Concurrency'    THEN 1 ELSE 0 END) as_concurrency,
       SUM(CASE wait_class    WHEN 'Application'    THEN 1 ELSE 0 END) as_application,
       SUM(CASE wait_class    WHEN 'Administrative' THEN 1 ELSE 0 END) as_administrative,
       SUM(CASE wait_class    WHEN 'Configuration'  THEN 1 ELSE 0 END) as_configuration,
       SUM(CASE wait_class    WHEN 'Network'        THEN 1 ELSE 0 END) as_network,
       SUM(CASE wait_class    WHEN 'Queueing'       THEN 1 ELSE 0 END) as_queueing,
       SUM(CASE wait_class    WHEN 'Scheduler'      THEN 1 ELSE 0 END) as_scheduler,
       SUM(CASE wait_class    WHEN 'Other'          THEN 1 ELSE 0 END) as_other
  FROM dba_hist_active_sess_history
 WHERE sample_time BETWEEN TO_DATE('&&query_date.', 'YYYY-MM-DD') AND TO_DATE('&&query_date.', 'YYYY-MM-DD') + 1 - (1/24/60/60)
 --WHERE sample_time BETWEEN TO_DATE('&&query_date.', 'YYYY-MM-DD') - 3 AND TO_DATE('&&query_date.', 'YYYY-MM-DD') + 4 - (1/24/60/60)
   AND ('&&sql_id.' IS NULL OR sql_id = '&&sql_id.')
   AND sql_id IN (SELECT sql_id FROM my_tx_sql)
 GROUP BY
       sample_id,
       sample_time
/* end of query */
)
/****************************************************************************************/
/* no need to modify the date column below, but you may need to add some number columns */
SELECT ', [new Date('||
       TO_CHAR(q.sample_time, 'YYYY')|| /* year */
       ','||(TO_NUMBER(TO_CHAR(q.sample_time, 'MM')) - 1)|| /* month - 1 */
       ','||TO_CHAR(q.sample_time, 'DD')|| /* day */
       ','||TO_CHAR(q.sample_time, 'HH24')|| /* hour */
       ','||TO_CHAR(q.sample_time, 'MI')|| /* minute */
       ','||TO_CHAR(q.sample_time, 'SS')|| /* second */
       ')'||
       ','||q.as_on_cpu|| 
       ','||q.as_user_io|| 
       ','||q.as_system_io|| 
       ','||q.as_cluster|| 
       ','||q.as_commit|| 
       ','||q.as_concurrency|| 
       ','||q.as_application|| 
       ','||q.as_administrative|| 
       ','||q.as_configuration|| 
       ','||q.as_network|| 
       ','||q.as_queueing|| 
       ','||q.as_scheduler|| 
       ','||q.as_other||
       ']'
  FROM my_query q
 ORDER BY
       q.sample_time
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

SET HEA ON PAGES 100;
