----------------------------------------------------------------------------------------
--
-- File name:   core_util_chart.sql
--
--              *** Requires Oracle Diagnostics Pack License ***
--
-- Purpose:     Line Chart for CPU Cores Utilization 
--
-- Author:      Carlos Sierra
--
-- Version:     2018/05/30
--
-- Usage:       Execute connected into the CDB.
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @core_util_chart.sql
--
-- Notes:       Accesses AWR data thus you must have an Oracle Diagnostics Pack License.
--
--              Developed and tested on 12.1.0.2.
--
--              *** Requires Oracle Diagnostics Pack License ***
--
---------------------------------------------------------------------------------------
--
-- exit graciously if executed on standby
WHENEVER SQLERROR EXIT SUCCESS;
DECLARE
  l_open_mode VARCHAR2(20);
BEGIN
  SELECT open_mode INTO l_open_mode FROM v$database;
  IF l_open_mode <> 'READ WRITE' THEN
    raise_application_error(-20000, 'Must execute on PRIMARY');
  END IF;
END;
/
WHENEVER SQLERROR CONTINUE;
--

DEF days_of_history_default = '60';
DEF forecast_days_default = '15';

PRO
PRO 1. Days of History: [{&&days_of_history_default.}|<1-60>]
DEF days_of_history = '&1.';

COL days_of_history NEW_V days_of_history NOPRI;
SELECT NVL('&&days_of_history.', '&&days_of_history_default.') days_of_history FROM DUAL
/

PRO
PRO 2. Forecast Days: [{&&forecast_days_default.}|<1-60>]
DEF forecast_days = '&2.';

COL forecast_days NEW_V forecast_days NOPRI;
SELECT NVL('&&forecast_days.', '&&forecast_days_default.') forecast_days FROM DUAL
/

SET HEA ON LIN 1000 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF;

COL dbid NEW_V dbid NOPRI;
COL db_name NEW_V db_name NOPRI;
SELECT dbid, LOWER(name) db_name FROM v$database
/

COL instance_number NEW_V instance_number NOPRI;
COL host_name NEW_V host_name NOPRI;
SELECT instance_number, LOWER(host_name) host_name FROM v$instance
/

COL locale NEW_V locale NOPRI;
SELECT LOWER(REPLACE(SUBSTR('&&host_name.', 1 + INSTR('&&host_name.', '.', 1, 2), 30), '.', '_')) locale FROM DUAL
/

COL output_file_name NEW_V output_file_name NOPRI;
SELECT 'core_util_&&locale._&&db_name._'||TO_CHAR(SYSDATE, 'YYYYMMDD_HH24MISS') output_file_name FROM DUAL
/

PRO
DEF report_title = "CPU Cores Utilization";
DEF report_abstract_1 = "LOCALE: &&locale.";
DEF report_abstract_2 = "<br>DATABASE: &&db_name.";
DEF report_abstract_3 = "<br>HOST: &&host_name.";
DEF chart_title = "&&report_title.";
DEF xaxis_title = "";
DEF vaxis_title = "Percent";
DEF vaxis_baseline = "";
DEF chart_foot_note_1 = "<br>1) Drag to Zoom, and right click to reset Chart.";
DEF report_foot_note = "&&output_file_name..html based on dba_hist_osstat";
PRO
ALTER SESSION SET STATISTICS_LEVEL = 'ALL';

SPO &&output_file_name..html;
PRO <html>
PRO <!-- $Header: line_chart.sql 2014-07-27 carlos.sierra $ -->
PRO <head>
PRO <title>&&output_file_name..html</title>
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
PRO 'Date Column','Utilization Percent','Moving 1d Window','Linear Regression','Forecast','100%'
PRO ]
/****************************************************************************************/
SET HEA OFF PAGES 0;
WITH 
snaps_per_day AS (
SELECT 24 * 60 / (
       -- awr_snap_interval_minutes
       24 * 60 * EXTRACT(day FROM snap_interval) + 
       60 * EXTRACT(hour FROM snap_interval) + 
       EXTRACT(minute FROM snap_interval) 
       )
       value 
  FROM dba_hist_wr_control
),
threads_per_core AS (
SELECT (t.value / c.value) value
  FROM v$osstat c, v$osstat t
 WHERE c.con_id = 0
   AND c.stat_name = 'NUM_CPU_CORES' 
   AND t.con_id = c.con_id
   AND t.stat_name = 'NUM_CPUS'
),
busy_time_ts AS (
SELECT o.snap_id,
       CAST(s.end_interval_time AS DATE) end_date_time,
       ROW_NUMBER() OVER (ORDER BY o.snap_id DESC) row_number_desc,
       CAST(s.startup_time AS DATE) - (LAG(CAST(s.startup_time AS DATE)) OVER (ORDER BY o.snap_id)) startup_gap,
       ((o.value - LAG(o.value) OVER (ORDER BY o.snap_id)) / 100) /
       ((CAST(s.end_interval_time AS DATE) - CAST(LAG(s.end_interval_time) OVER (ORDER BY o.snap_id) AS DATE)) * 24 * 60 * 60)
       cpu_utilization
  FROM dba_hist_osstat o,
       dba_hist_snapshot s
 WHERE o.dbid = (SELECT dbid FROM v$database)
   AND o.instance_number = SYS_CONTEXT('USERENV', 'INSTANCE')
   AND o.stat_name = 'BUSY_TIME'
   AND s.snap_id = o.snap_id
   AND s.dbid = o.dbid
   AND s.instance_number = o.instance_number
),
cpu_util_ts1 AS (
SELECT u.snap_id,
       u.end_date_time,
       u.row_number_desc,
       ROW_NUMBER() OVER (ORDER BY u.end_date_time ASC) row_number_asc,
       u.cpu_utilization * t.value y1,
       AVG(u.cpu_utilization * t.value) OVER (ORDER BY u.snap_id ROWS BETWEEN ROUND(s.value) PRECEDING AND CURRENT ROW) y2
  FROM busy_time_ts u,
       threads_per_core t,
       snaps_per_day s
 WHERE 1 = 1
   AND u.startup_gap = 0
   AND u.row_number_desc <= NVL(GREATEST(&&days_of_history. * s.value, 1), 1)
),
lower_bound AS (
SELECT end_date_time, y1, y2
  FROM cpu_util_ts1
 WHERE row_number_asc = 1
),
upper_bound AS (
SELECT end_date_time, y1, y2
  FROM cpu_util_ts1
 WHERE row_number_desc = 1
),
cpu_util_ts2 AS (
SELECT u.snap_id,
       u.end_date_time,
       u.row_number_desc,
       u.row_number_asc,
       (u.end_date_time - b.end_date_time) x,
       u.y1, u.y2 
  FROM cpu_util_ts1 u,
       lower_bound b
),
linear_regr_ts AS (
SELECT snap_id,
       end_date_time, 
       row_number_desc,
       row_number_asc,
       x,
       y1, y2,
       REGR_SLOPE(y1, x) OVER () m,
       REGR_INTERCEPT(y1, x) OVER () b
  FROM cpu_util_ts2
),
linear_regr AS (
SELECT m, -- slope
       b -- intercept
  FROM linear_regr_ts
 WHERE row_number_desc = 1 -- it does not matter which row we get (first, last, or anything in between)
),
cpu_util_ts3 AS (
SELECT u.end_date_time,
       u.x,
       u.y1, u.y2,
       (r.m * u.x) + r.b y8 /* y8 = (m * x) + b */
  FROM cpu_util_ts2 u,
       linear_regr r
),
cpu_util_ts4 AS (
SELECT q.end_date_time,
       q.x,
       q.y1, 
       q.y2,
       q.y8,
       CASE WHEN q.end_date_time = u.end_date_time THEN u.y2 ELSE TO_NUMBER(NULL) END y9
  FROM cpu_util_ts3 q, upper_bound u
 UNION ALL
SELECT (u.end_date_time + LEVEL) end_date_time,
       LEVEL x,
       TO_NUMBER(NULL) y1,
       TO_NUMBER(NULL) y2,
       TO_NUMBER(NULL) y8,
       (r.m * LEVEL + u.y2) y9
  FROM upper_bound u, linear_regr r
CONNECT BY LEVEL <= &&forecast_days.
)
SELECT ', [new Date('||
       TO_CHAR(q.end_date_time, 'YYYY')|| /* year */
       ','||(TO_NUMBER(TO_CHAR(q.end_date_time, 'MM')) - 1)|| /* month - 1 */
       ','||TO_CHAR(q.end_date_time, 'DD')|| /* day */
       ','||TO_CHAR(q.end_date_time, 'HH24')|| /* hour */
       ','||TO_CHAR(q.end_date_time, 'MI')|| /* minute */
       ','||TO_CHAR(q.end_date_time, 'SS')|| /* second */
       ')'||
       ','||q.y1||
       ','||q.y2||
       ','||q.y8||
       ','||q.y9||
       ',100'||
       ']'
  FROM cpu_util_ts4 q
 ORDER BY
       q.end_date_time
/
SET HEA ON PAGES 100;
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
PRO <div id="chart_div" class="google-chart"></div>
PRO <font class="n">Notes:</font>
PRO <font class="n">&&chart_foot_note_1.</font>
--PRO <pre>
--L
--PRO </pre>
PRO <br>
PRO <font class="f">&&report_foot_note.</font>
PRO </body>
PRO </html>
SPO OFF;
PRO
PRO &&output_file_name..html
PRO
CL COL;
UNDEF 1 2;