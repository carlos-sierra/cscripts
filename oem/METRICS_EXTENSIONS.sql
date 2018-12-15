-- ME$LONGOPS
-- Long Operations (KIEV)
-- KIEV DML taking over 1 minute
-- every 15 mins
-- Warning: > 1200
WITH
kiev_buckets AS (
SELECT /*+ NO_MERGE */
       con_id, COUNT(*) cnt
  FROM cdb_tables
 WHERE table_name = 'KIEVBUCKETS'
 GROUP BY
       con_id
),
metric AS (
SELECT /*+ NO_MERGE */
         o.elapsed_seconds 
       value,
         'pdb:'||c.name||'('||o.con_id||'), '||
         'sql_id:'||o.sql_id||', '||
         'phv:'||o.sql_plan_hash_value||', '||
         'line:'||sql_plan_line_id||', '||
         'start:'||TO_CHAR(o.sql_exec_start, 'YYYY-MM-DD"T"HH24:MI:SS')||', '||
         'last_upd:'||TO_CHAR(o.last_update_time, 'YYYY-MM-DD"T"HH24:MI:SS')||', '||
         'exec_id:'||o.sql_exec_id||', '||
         'sid,serial#:'||o.sid||','||o.serial#
       key_value
  FROM v$session_longops o,
       v$containers c,
       kiev_buckets k
 WHERE 1 = 1
   AND o.sql_exec_start > SYSDATE - (60 / 24 / 60) /* only sql execution started within last 60 mins */
   AND o.last_update_time > SYSDATE - (15 / 24 / 60) /* only ops updated within last 15 mins */
   AND o.elapsed_seconds > 60 /* only DML taking over 1 minute */
   AND (SELECT a.name FROM v$sql s, audit_actions a WHERE s.sql_id = o.sql_id AND a.action = s.command_type AND ROWNUM = 1) IN ('SELECT', 'INSERT', 'UPDATE', 'DELETE')
   AND c.con_id = o.con_id
   AND c.open_mode = 'READ WRITE' /* only DG PRIMARY */
   AND k.con_id = o.con_id /* only KIEV */
   AND k.cnt > 0 /* redundant */
)
SELECT m.value, /* Seconds (number) */
       m.key_value /* Key (string) */
  FROM metric m
/
-- [%metric_id%] SQL operation over %value% seconds (warning threshold is %warning_threshold%) %keyValue%  

-- ME$LONGREPS
-- Long Reports (KIEV)
-- KIEV Monitored SQL taking over 1 minute
-- every 15 mins
-- Warning: > 1200
WITH
kiev_buckets AS (
SELECT /*+ NO_MERGE */
       con_id, COUNT(*) cnt
  FROM cdb_tables
 WHERE table_name = 'KIEVBUCKETS'
 GROUP BY
       con_id
),
metric AS (
SELECT /*+ NO_MERGE */
         ROUND((r.period_end_time - r.period_start_time) * 24 * 3600) 
       value,
         'pdb:'||c.name||'('||r.con_id||'), '||
         'sql_id:'||r.key1||', '||
         'start:'||TO_CHAR(r.period_start_time, 'YYYY-MM-DD"T"HH24:MI:SS')||', '||
         'end:'||TO_CHAR(r.period_end_time, 'YYYY-MM-DD"T"HH24:MI:SS')||', '||
         'rpt_id:'||r.report_id||', '||
         'sid,serial#:'||r.session_id||','||r.session_serial#
       key_value
  FROM cdb_hist_reports r,
       v$containers c,
       kiev_buckets k
 WHERE 1 = 1
   AND r.component_name = 'sqlmonitor' /* SQL Monitor Report */
   AND r.period_end_time > SYSDATE - (15 / 24 / 60) /* only executions completed past 15 mins */
   AND (r.period_end_time - r.period_start_time) * 24 * 3600 > 60 /* only Monitored SQL taking over 1 minute */
   AND (SELECT a.name FROM v$sql s, audit_actions a  WHERE s.sql_id = r.key1 AND a.action = s.command_type AND ROWNUM = 1) IN ('SELECT', 'INSERT', 'UPDATE', 'DELETE')
   AND c.con_id = r.con_id
   AND c.open_mode = 'READ WRITE' /* only DG PRIMARY */
   AND k.con_id = r.con_id /* only KIEV */
   AND k.cnt > 0 /* redundant */
)
SELECT m.value, /* Seconds (number) */
       m.key_value /* Key (string) */
  FROM metric m
/
-- [%metric_id%] SQL execution lasted %value% seconds (warning threshold is %warning_threshold%) %keyValue%  


