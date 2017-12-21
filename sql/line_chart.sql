--SET TERM OFF HEA OFF LIN 32767 NEWP NONE PAGES 0 FEED OFF ECHO OFF VER OFF LONG 32000 LONGC 2000 WRA ON TRIMS ON TRIM ON TI OFF TIMI OFF NUM 20 SQLBL ON BLO . RECSEP OFF;
SET HEA ON LIN 500 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF;
PRO
DEF report_title = "Line Chart Report";
DEF report_abstract_1 = "<br>This line chart is an aggregate per month.";
DEF report_abstract_2 = "<br>It can be by day or any other slice size.";
DEF report_abstract_3 = "";
DEF report_abstract_4 = "";
DEF chart_title = "Amount Sold over 4 years";
DEF xaxis_title = "Sales between 1998-2001";
--DEF vaxis_title = "Amount Sold per Hour";
--DEF vaxis_title = "Amount Sold per Day";
DEF vaxis_title = "Amount Sold per Month";
DEF vaxis_baseline = ", baseline:2200000";
DEF chart_foot_note_1 = "<br>1) Drag to Zoom, and right click to reset Chart.";
DEF chart_foot_note_2 = "<br>2) Some other note.";
DEF chart_foot_note_3 = "";
DEF chart_foot_note_4 = "";
DEF report_foot_note = "This is a sample line chart report.";
PRO
SPO line_chart.html;
PRO <html>
PRO <!-- $Header: line_chart.sql 2014-07-27 carlos.sierra $ -->
PRO <head>
PRO <title>line_chart.html</title>
PRO
PRO <style type="text/css">
PRO body   {font:10pt Arial,Helvetica,Geneva,sans-serif; color:black; background:white;}
PRO h1     {font-size:16pt; font-weight:bold; color:#336699; border-bottom:1px solid #cccc99; margin-top:0pt; margin-bottom:0pt; padding:0px 0px 0px 0px;}
PRO h2     {font-size:14pt; font-weight:bold; color:#336699; margin-top:4pt; margin-bottom:0pt;}
PRO h3     {font-size:12pt; font-weight:bold; color:#336699; margin-top:4pt; margin-bottom:0pt;}
PRO pre    {font:8pt monospace;Monaco,"Courier New",Courier;}
PRO a      {color:#663300;}
PRO table  {font-size:8pt; border_collapse:collapse; empty-cells:show; white-space:nowrap; border:1px solid #cccc99;}
PRO li     {font-size:8pt; color:black; padding-left:4px; padding-right:4px; padding-bottom:2px;}
PRO th     {font-weight:bold; color:white; background:#0066CC; padding-left:4px; padding-right:4px; padding-bottom:2px;}
PRO td     {color:black; background:#fcfcf0; vertical-align:top; border:1px solid #cccc99;}
PRO td.c   {text-align:center;}
PRO font.n {font-size:8pt; font-style:italic; color:#336699;}
PRO font.f {font-size:8pt; color:#999999; border-top:1px solid #cccc99; margin-top:30pt;}
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
PRO ['Date Column', 'Number Column 1']
/****************************************************************************************/
WITH
my_query AS (
/* query below selects one date_column and a small set of number_columns */
SELECT --TRUNC(time_id, 'HH24') date_column /* preserve the column name */
       --TRUNC(time_id, 'DD') date_column /* preserve the column name */
       TRUNC(time_id, 'MM') date_column /* preserve the column name */
       , SUM(amount_sold) number_column_1 /* add below more columns if needed (modify 3 places) */
  FROM sh.sales
 GROUP BY
       --TRUNC(time_id, 'HH24') /* aggregate per hour, but it could be any other */
       --TRUNC(time_id, 'DD') /* aggregate per day, but it could be any other */
       TRUNC(time_id, 'MM') /* aggregate per month, but it could be any other */
/* end of query */
)
/****************************************************************************************/
/* no need to modify the date column below, but you may need to add some number columns */
SELECT ', [new Date('||
       TO_CHAR(q.date_column, 'YYYY')|| /* year */
       ','||(TO_NUMBER(TO_CHAR(q.date_column, 'MM')) - 1)|| /* month - 1 */
       --','||TO_CHAR(q.date_column, 'DD')|| /* day */
       --','||TO_CHAR(q.date_column, 'HH24')|| /* hour */
       --','||TO_CHAR(q.date_column, 'MI')|| /* minute */
       --','||TO_CHAR(q.date_column, 'SS')|| /* second */
       ')'||
       ','||q.number_column_1|| /* add below more columns if needed (modify 3 places) */
       ']'
  FROM my_query q
 ORDER BY
       date_column
/
/****************************************************************************************/
PRO ]);
PRO
PRO var options = {
PRO backgroundColor: {fill: '#fcfcf0', stroke: '#336699', strokeWidth: 1},
PRO explorer: {actions: ['dragToZoom', 'rightClickToReset'], maxZoomIn: 0.1},
PRO title: '&&chart_title.',
PRO titleTextStyle: {fontSize: 16, bold: false},
PRO focusTarget: 'category',
PRO legend: {position: 'right', textStyle: {fontSize: 12}},
PRO tooltip: {textStyle: {fontSize: 10}},
PRO hAxis: {title: '&&xaxis_title.', gridlines: {count: -1}},
PRO vAxis: {title: '&&vaxis_title.' &&vaxis_baseline., gridlines: {count: -1}}
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
PRO <div id="chart_div" style="width: 900px; height: 500px;"></div>
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


