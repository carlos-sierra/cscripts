PRO 1. Enter KIEV Transaction: C=commitTx | B=beginTx | R=read | G=GC | O=Other | CB=commitTx+beginTx | <null>=commitTx+beginTx+read+GC+Other (default null)
DEF kiev_tx = '&1.';
PRO 2. SQL with a Plan Baseline only?: N | Y (default N)
DEF spb_only = '&2.';
PRO 3. SQL_ID: (default null)
DEF sql_id = '&3.';
PRO 4. Plan Hash Value: (default null)
DEF phv = '&4.';
SET HEA ON LIN 500 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF;
SET HEA OFF PAGES 0;
COL current_time NEW_V current_time FOR A15;
SELECT 'current_time: ' x, TO_CHAR(SYSDATE, 'YYYYMMDD_HH24MISS') current_time FROM DUAL;
COL x_container NEW_V x_container;
SELECT 'NONE' x_container FROM DUAL;
SELECT REPLACE(SYS_CONTEXT('USERENV', 'CON_NAME'), '$') x_container FROM DUAL;
PRO
DEF report_title = "SQL Executions";
DEF report_abstract_1 = "KIEV Transaction:(&&kiev_tx.). (C)=commitTx | (B)=beginTx | (R)=read | (G)=GC | (CB)=commitTx+beginTx | (O)ther | ()=ALL";
DEF report_abstract_2 = "<br>Container:(&&x_container.). SQL with a Plan Baseline only?:(&&spb_only.). (N) | (Y) | ()=N";
DEF report_abstract_3 = "<br>SQL_ID:(&&sql_id.). ()=ALL. Plan Hash Value:(&&phv.). ()=ALL.";
DEF report_abstract_4 = "";
DEF chart_title = "&&x_container Tx(&&kiev_tx.) SPB(&&spb_only.) SQL_ID(&&sql_id.) PHV(&&phv.)";
DEF xaxis_title = "SQL Executions";
DEF vaxis_title = "SQL Executions";
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
SPO dba_hist_sqlstat_execs_&&x_container._Tx&&kiev_tx._SPB&&spb_only._S&&sql_id._P&&phv._&&current_time..html;
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
PRO 'Executions'
PRO ]
/****************************************************************************************/
WITH
all_sql AS (
SELECT DISTINCT con_id, sql_id, sql_text 
  FROM v$sql 
 WHERE executions > 0
   AND object_status = 'VALID'
   AND is_obsolete = 'N'
   AND is_shareable = 'Y'
   AND (sql_id = '&&sql_id.' OR '&&sql_id.' IS NULL OR UPPER(TRIM('&&sql_id.')) IN ('ALL', 'NULL')) 
   AND CASE 
       WHEN UPPER(TRIM('&&spb_only.')) = 'Y' AND sql_plan_baseline IS NULL THEN 0
       WHEN UPPER(TRIM('&&spb_only.')) = 'Y' AND sql_plan_baseline IS NOT NULL THEN 1
       WHEN UPPER(TRIM('&&spb_only.')) = 'N' THEN 1
       ELSE 1 
       END = 1
--UNION
--SELECT DISTINCT sql_id, DBMS_LOB.SUBSTR(sql_text, 1000) FROM dba_hist_sqltext
),
all_sql_with_type AS (
SELECT con_id, sql_id, sql_text, 
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
         ELSE 'OTHER'
        END application_module
  FROM all_sql
),
my_tx_sql AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       con_id, sql_id, MAX(sql_text) sql_text, MAX(application_module) application_module
  FROM all_sql_with_type
 WHERE application_module IS NOT NULL
  AND (  
         (NVL('&&kiev_tx.', 'CBRGO') LIKE '%C%' AND application_module = 'COMMIT') OR
         (NVL('&&kiev_tx.', 'CBRGO') LIKE '%B%' AND application_module = 'BEGIN') OR
         (NVL('&&kiev_tx.', 'CBRGO') LIKE '%R%' AND application_module = 'READ') OR
         (NVL('&&kiev_tx.', 'CBRGO') LIKE '%G%' AND application_module = 'GC') OR
         (NVL('&&kiev_tx.', 'CBRGO') LIKE '%O%' AND application_module = 'OTHER') OR
         UPPER(TRIM('&&kiev_tx.')) IN ('ALL', 'NULL')
      )
 GROUP BY
       con_id, sql_id
),
my_query AS (
/* query below selects one date_column and a small set of number_columns */
SELECT s.snap_id,
       CAST(s.end_interval_time AS DATE) end_date,
       ROUND(SUM(h.elapsed_time_delta)/SUM(h.executions_delta)/1e3, 3) avg_et_ms_per_exec,
       ROUND(SUM(h.cpu_time_delta)/SUM(h.executions_delta)/1e3, 3) avg_cpu_ms_per_exec,
       ROUND(SUM(h.elapsed_time_delta)/1e6) et_secs,
       ROUND(SUM(h.cpu_time_delta)/1e6) cpu_secs,
       SUM(h.executions_delta) executions
  FROM dba_hist_sqlstat h, dba_hist_snapshot s
 WHERE h.executions_delta > 0
   AND ('&&sql_id.' IS NULL OR UPPER(TRIM('&&sql_id.')) IN ('ALL', 'NULL') OR h.sql_id = '&&sql_id.')
   AND ('&&phv.' IS NULL OR UPPER(TRIM('&&phv.')) IN ('ALL', 'NULL') OR h.plan_hash_value = TO_NUMBER('&&phv.'))
   AND s.snap_id = h.snap_id
   AND s.dbid = h.dbid
   AND s.instance_number = h.instance_number
   AND (h.con_id, h.sql_id) IN (SELECT con_id, sql_id FROM my_tx_sql)
 GROUP BY
       s.snap_id,
       s.end_interval_time
/* end of query */
)
SELECT ', [new Date('||
       TO_CHAR(q.end_date, 'YYYY')|| /* year */
       ','||(TO_NUMBER(TO_CHAR(q.end_date, 'MM')) - 1)|| /* month - 1 */
       ','||TO_CHAR(q.end_date, 'DD')|| /* day */
       ','||TO_CHAR(q.end_date, 'HH24')|| /* hour */
       ','||TO_CHAR(q.end_date, 'MI')|| /* minute */
       ','||TO_CHAR(q.end_date, 'SS')|| /* second */
       ')'||
       ','||q.executions|| 
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

SET HEA ON PAGES 100;
