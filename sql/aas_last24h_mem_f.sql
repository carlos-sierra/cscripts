SET TERM OFF
COL db_name NEW_V db_name
SELECT name db_name FROM v$database;
SET PAGES 0 TIMING OFF FEED OFF
SPO aas_&&db_name._last24h_mem_f.html
PRO <!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
PRO <html xmlns="http://www.w3.org/1999/xhtml">
PRO <head>
PRO <meta http-equiv="Content-Type" content="text/html;charset=utf-8" />
PRO <title>AAS per Wait Class for Cluster</title>
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
PRO <script type="text/javascript" src="https://www.google.com/jsapi"></script>
PRO <script type="text/javascript">
PRO google.load("visualization", "1", {packages:["corechart"]})
PRO google.setOnLoadCallback(drawChart)
PRO function drawChart() {
PRO var data = google.visualization.arrayToDataTable([
PRO ['Date', 'On CPU', 'User I/O', 'System I/O', 'Cluster', 'Commit', 'Concurrency', 'Application', 'Administrative', 'Configuration', 'Network', 'Queueing', 'Scheduler', 'Other']
SELECT /*+  DYNAMIC_SAMPLING(4)   FULL(h.ash) FULL(h.evt) FULL(h.sn) USE_HASH(h.sn h.ash h.evt)   FULL(h.INT$DBA_HIST_ACT_SESS_HISTORY.sn) FULL(h.INT$DBA_HIST_ACT_SESS_HISTORY.ash) FULL(h.INT$DBA_HIST_ACT_SESS_HISTORY.evt)   USE_HASH(h.INT$DBA_HIST_ACT_SESS_HISTORY.sn h.INT$DBA_HIST_ACT_SESS_HISTORY.ash h.INT$DBA_HIST_ACT_SESS_HISTORY.evt)  */
       ', [new Date('||SUBSTR(end_time,1,4)||','||(TO_NUMBER(SUBSTR(end_time,6,2)) - 1)||','||SUBSTR(end_time,9,2)||','||SUBSTR(end_time,12,2)||','||SUBSTR(end_time,15,2)||','||NVL(SUBSTR(end_time,18,2),0)||',0)'||
       ', '||aas_on_cpu||' ,'||aas_user_io||' ,'||aas_system_io||' ,'||aas_cluster||' ,'||aas_commit||' ,'||aas_concurrency||' ,'||aas_application||' ,'||aas_administrative||' ,'||aas_configuration||' ,'||aas_network||' ,'||aas_queueing||' ,'||aas_scheduler||' ,'||aas_other||']'
  FROM (SELECT TO_CHAR(MAX(sample_time), 'YYYY-MM-DD HH24:MI:SS') end_time,
                ROUND(SUM(CASE session_state WHEN 'ON CPU'         THEN 1 ELSE 0 END) / 60, 3) aas_on_cpu,
                ROUND(SUM(CASE wait_class    WHEN 'User I/O'       THEN 1 ELSE 0 END) / 60, 3) aas_user_io,
                ROUND(SUM(CASE wait_class    WHEN 'System I/O'     THEN 1 ELSE 0 END) / 60, 3) aas_system_io,
                ROUND(SUM(CASE wait_class    WHEN 'Cluster'        THEN 1 ELSE 0 END) / 60, 3) aas_cluster,
                ROUND(SUM(CASE wait_class    WHEN 'Commit'         THEN 1 ELSE 0 END) / 60, 3) aas_commit,
                ROUND(SUM(CASE wait_class    WHEN 'Concurrency'    THEN 1 ELSE 0 END) / 60, 3) aas_concurrency,
                ROUND(SUM(CASE wait_class    WHEN 'Application'    THEN 1 ELSE 0 END) / 60, 3) aas_application,
                ROUND(SUM(CASE wait_class    WHEN 'Administrative' THEN 1 ELSE 0 END) / 60, 3) aas_administrative,
                ROUND(SUM(CASE wait_class    WHEN 'Configuration'  THEN 1 ELSE 0 END) / 60, 3) aas_configuration,
                ROUND(SUM(CASE wait_class    WHEN 'Network'        THEN 1 ELSE 0 END) / 60, 3) aas_network,
                ROUND(SUM(CASE wait_class    WHEN 'Queueing'       THEN 1 ELSE 0 END) / 60, 3) aas_queueing,
                ROUND(SUM(CASE wait_class    WHEN 'Scheduler'      THEN 1 ELSE 0 END) / 60, 3) aas_scheduler,
                ROUND(SUM(CASE wait_class    WHEN  'Other'         THEN 1 ELSE 0 END) / 60, 3) aas_other
           FROM gv$active_session_history h
          WHERE sample_time >= SYSDATE-1
            AND session_type = 'FOREGROUND'
          GROUP BY
                trunc(sample_time,'mi')
          ORDER BY
                1)
 WHERE aas_on_cpu IS NOT NULL;
PRO ]);
PRO 
PRO var options = {isStacked: true,
PRO chartArea:{left:90, top:75, width:'65%', height:'70%'},
PRO backgroundColor: {fill: 'white', stroke: '#336699', strokeWidth: 1},
PRO explorer: {actions: ['dragToZoom', 'rightClickToReset'], maxZoomIn: 0.01},
PRO title: '5a.618. AAS per Wait Class for Cluster',
PRO titleTextStyle: {fontSize: 18, bold: false},
PRO focusTarget: 'category',
PRO legend: {position: 'right', textStyle: {fontSize: 14}},
PRO tooltip: {textStyle: {fontSize: 14}},
PRO hAxis: {title: '12.1.0.2.0 cores:44(avg) threads:88(avg) hosts:2', gridlines: {count: -1}, titleTextStyle: {fontSize: 16, bold: false}},
PRO series: { 0: { color :'#34CF27'}, 1: { color :'#0252D7'},  2: { color :'#1E96DD'},  3: { color :'#CEC3B5'},  4: { color :'#EA6A05'},  5: { color :'#871C12'},  6: { color :'#C42A05'}, 7: {color :'#75763E'},
PRO 8: { color :'#594611'}, 9: { color :'#989779'}, 10: { color :'#C6BAA5'}, 11: { color :'#9FFA9D'}, 12: { color :'#F571A0'}, 13: { color :'#000000'}, 14: { color :'#ff0000'}
PRO },
PRO vAxis: {title: 'Average Active Sessions - AAS (stacked)',  gridlines: {count: -1}, titleTextStyle: {fontSize: 16, bold: false}}
PRO }
PRO 
PRO var chart = new google.visualization.AreaChart(document.getElementById('linechart'))
PRO chart.draw(data, options)
PRO }
PRO </script>
PRO </head>
PRO <body>
PRO <h1> AAS per Wait Class for Cluster <em>(DBA_HIST_ACTIVE_SESS_HISTORY)</em>  </h1>
PRO <br />
PRO <br />
PRO <div id="linechart" class="google-chart"></div>
PRO <br />
PRO <font class="n">Notes:<br />1) drag to zoom, and right click to reset<br />2) up to 1 days of awr history were considered</font>
PRO <font class="n"><br />3) </font>
PRO <pre>

PRO </pre>
PRO <br />
PRO <font class="f">edb360 (c) 2017. Version v1715 (2017-07-28). Timestamp: 2017-08-02T00:50:58  </font>
PRO </body>
PRO </html>
SPO OFF
SET TERM ON PAGES 80