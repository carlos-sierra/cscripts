COL con_id FOR 999 HEA 'Con|ID';
COL pdb_name FOR A30 HEA 'PDB Name' FOR A30 TRUNC;
COL sum_seconds FOR 999,999,990 HEA 'Sum Secs';
COL avg_seconds FOR 999,999,990 HEA 'Avg Secs';
COL max_seconds FOR 999,999,990 HEA 'Max Secs';
COL execs FOR 999,990 HEA 'Executions';
COL last_refresh_time FOR A19 HEA 'Last Captured';
COL con_id FOR 999 HEA 'Con|ID';
COL sql_plan_hash_value FOR 9999999999 HEA 'Plan|Hash Value';
COL binds FOR A300 HEA 'Binds (:name=value :name=value ...)' TRUNC;
COL status FOR A19 HEA 'Status';
COL username FOR A30 HEA 'Username' TRUNC;
COL machine FOR A64 HEA 'Machine';
COL sid_serial# FOR A12 HEA 'Sid,Serial#';
COL avg_et_secs FOR 999,999,990.0 HEA 'Avg ET Secs';
COL avg_cpu_secs FOR 999,999,990.0 HEA 'Avg CPU Secs';
COL avg_buffer_gets FOR 999,999,999,990 HEA 'Avg Buffer Gets';
COL avg_disk_reads FOR 999,999,999,990 HEA 'Avg Disk Reads';
COL module_action_program FOR A100 HEA 'Module Action Program' TRUNC;
--
PRO
PRO SQL MONITOR BINDS by Sum Secs (v$sql_monitor)
PRO ~~~~~~~~~~~~~~~~~
--
WITH 
mon AS (
SELECT s.con_id,
       s.sql_plan_hash_value,
       s.sql_exec_id,
       s.sql_exec_start,
       s.last_refresh_time,
       s.binds_xml,
       (s.last_refresh_time - s.sql_exec_start) * 24 * 3600 AS seconds,
       s.status,
       s.username,
       s.sid,
       s.session_serial# AS serial#,
       (SELECT e.machine FROM v$session e WHERE e.sid = s.sid AND e.serial# = s.session_serial# AND e.machine IS NOT NULL AND ROWNUM = 1) AS machine,
       s.elapsed_time,
       s.cpu_time,
       s.buffer_gets,
       s.disk_reads,
       s.module,
       s.action,
       s.program
  FROM v$sql_monitor s
 WHERE s.sql_id = '&&cs_sql_id.'
   AND (s.last_refresh_time - s.sql_exec_start) * 24 * 3600 >= 0
   AND s.binds_xml IS NOT NULL
),
bind AS (
SELECT mon.con_id,
       mon.sql_plan_hash_value,
       mon.sql_exec_id,
       mon.sql_exec_start,
       mon.last_refresh_time,
       mon.seconds,
       mon.status,
       mon.username,
       mon.sid,
       mon.serial#,
       mon.machine,
       mon.elapsed_time,
       mon.cpu_time,
       mon.buffer_gets,
       mon.disk_reads,
       mon.module,
       mon.action,
       mon.program,
       bv.name,
       bv.pos,
       bv.type,
       bv.maxlen,
       bv.len,
       bv.value
  FROM mon, 
       xmltable( '/binds/bind'
                  passing xmltype( mon.binds_xml )
                  COLUMNS name   VARCHAR2( 30 )   path '@name' ,
                          pos    NUMBER           path '@pos',
                          type   VARCHAR2( 15 )   path '@dtystr' ,
                          maxlen NUMBER           path '@maxlen', 
                          len    NUMBER           path '@len',
                          value  VARCHAR2( 4000 ) path '.'
               ) bv
),
execs AS (
SELECT con_id,
       sql_plan_hash_value,
       sql_exec_id,
       sql_exec_start,
       last_refresh_time,
       seconds,
       status,
       username,
       sid,
       serial#,
       machine,
       elapsed_time,
       cpu_time,
       buffer_gets,
       disk_reads,
       module,
       action,
       program,
       MAX(CASE pos WHEN  1 THEN      name||'='||value END)||
       MAX(CASE pos WHEN  2 THEN ' '||name||'='||value END)||
       MAX(CASE pos WHEN  3 THEN ' '||name||'='||value END)||
       MAX(CASE pos WHEN  4 THEN ' '||name||'='||value END)||
       MAX(CASE pos WHEN  5 THEN ' '||name||'='||value END)||
       MAX(CASE pos WHEN  6 THEN ' '||name||'='||value END)||
       MAX(CASE pos WHEN  7 THEN ' '||name||'='||value END)||
       MAX(CASE pos WHEN  8 THEN ' '||name||'='||value END)||
       MAX(CASE pos WHEN  9 THEN ' '||name||'='||value END)||
       MAX(CASE pos WHEN 10 THEN ' '||name||'='||value END)||
       MAX(CASE pos WHEN 11 THEN ' '||name||'='||value END)||
       MAX(CASE pos WHEN 12 THEN ' '||name||'='||value END)||
       MAX(CASE pos WHEN 13 THEN ' '||name||'='||value END)||
       MAX(CASE pos WHEN 14 THEN ' '||name||'='||value END)||
       MAX(CASE pos WHEN 15 THEN ' '||name||'='||value END)||
       MAX(CASE pos WHEN 16 THEN ' '||name||'='||value END)||
       MAX(CASE pos WHEN 17 THEN ' '||name||'='||value END)||
       MAX(CASE pos WHEN 18 THEN ' '||name||'='||value END)||
       MAX(CASE pos WHEN 19 THEN ' '||name||'='||value END)||
       MAX(CASE pos WHEN 20 THEN ' '||name||'='||value END)
       AS binds
  FROM bind
 GROUP BY
       con_id,
       sql_plan_hash_value,
       sql_exec_id,
       sql_exec_start,
       last_refresh_time,
       seconds,
       status,
       username,
       sid,
       serial#,
       machine,
       elapsed_time,
       cpu_time,
       buffer_gets,
       disk_reads,
       module,
       action,
       program
)
SELECT SUM(seconds) AS sum_seconds,
       ROUND(AVG(seconds)) AS avg_seconds,
       MAX(seconds) AS max_seconds,
       COUNT(*) AS execs,
       ROUND(AVG(elapsed_time)/1e6, 1) AS avg_et_secs,
       ROUND(AVG(cpu_time)/1e6, 1) AS avg_cpu_secs,
       ROUND(AVG(buffer_gets)) AS avg_buffer_gets,
       ROUND(AVG(disk_reads)) AS avg_disk_reads,
       MAX(last_refresh_time) AS last_refresh_time,
       con_id,
       (SELECT c.name FROM v$containers c WHERE c.con_id = e.con_id) AS pdb_name,
       sql_plan_hash_value,
       binds,
       status,
       sid||','||serial# AS sid_serial#,
       --username,
       machine,
       TRIM(
       CASE WHEN module IS NOT NULL THEN 'm:'||SUBSTR(module, 1, 64) END||
       CASE WHEN action IS NOT NULL THEN ' a:'||SUBSTR(action, 1, 64) END||
       CASE WHEN program IS NOT NULL THEN ' p:'||SUBSTR(program, 1, 64) END
       ) AS module_action_program
  FROM execs e
 GROUP BY
       con_id,
       sql_plan_hash_value,
       binds,
       status,
       username,
       sid,
       serial#,
       machine,
       module,
       action,
       program
 ORDER BY
       1 DESC,
       2 DESC,
       3 DESC,
       5
FETCH FIRST 300 ROWS ONLY
/
--
PRO
PRO SQL MONITOR BINDS by Last Captured (v$sql_monitor)
PRO ~~~~~~~~~~~~~~~~~
--
WITH 
mon AS (
SELECT s.con_id,
       s.sql_plan_hash_value,
       s.sql_exec_id,
       s.sql_exec_start,
       s.last_refresh_time,
       s.binds_xml,
       (s.last_refresh_time - s.sql_exec_start) * 24 * 3600 AS seconds,
       s.status,
       s.username,
       s.sid,
       s.session_serial# AS serial#,
       (SELECT e.machine FROM v$session e WHERE e.sid = s.sid AND e.serial# = s.session_serial# AND e.machine IS NOT NULL AND ROWNUM = 1) AS machine,
       s.elapsed_time,
       s.cpu_time,
       s.buffer_gets,
       s.disk_reads,
       s.module,
       s.action,
       s.program
  FROM v$sql_monitor s
 WHERE s.sql_id = '&&cs_sql_id.'
   AND (s.last_refresh_time - s.sql_exec_start) * 24 * 3600 >= 0
   AND s.binds_xml IS NOT NULL
),
bind AS (
SELECT mon.con_id,
       mon.sql_plan_hash_value,
       mon.sql_exec_id,
       mon.sql_exec_start,
       mon.last_refresh_time,
       mon.seconds,
       mon.status,
       mon.username,
       mon.sid,
       mon.serial#,
       mon.machine,
       mon.elapsed_time,
       mon.cpu_time,
       mon.buffer_gets,
       mon.disk_reads,
       mon.module,
       mon.action,
       mon.program,
       bv.name,
       bv.pos,
       bv.type,
       bv.maxlen,
       bv.len,
       bv.value
  FROM mon, 
       xmltable( '/binds/bind'
                  passing xmltype( mon.binds_xml )
                  COLUMNS name   VARCHAR2( 30 )   path '@name' ,
                          pos    NUMBER           path '@pos',
                          type   VARCHAR2( 15 )   path '@dtystr' ,
                          maxlen NUMBER           path '@maxlen', 
                          len    NUMBER           path '@len',
                          value  VARCHAR2( 4000 ) path '.'
               ) bv
),
execs AS (
SELECT con_id,
       sql_plan_hash_value,
       sql_exec_id,
       sql_exec_start,
       last_refresh_time,
       seconds,
       status,
       username,
       sid,
       serial#,
       machine,
       elapsed_time,
       cpu_time,
       buffer_gets,
       disk_reads,
       module,
       action,
       program,
       MAX(CASE pos WHEN  1 THEN      name||'='||value END)||
       MAX(CASE pos WHEN  2 THEN ' '||name||'='||value END)||
       MAX(CASE pos WHEN  3 THEN ' '||name||'='||value END)||
       MAX(CASE pos WHEN  4 THEN ' '||name||'='||value END)||
       MAX(CASE pos WHEN  5 THEN ' '||name||'='||value END)||
       MAX(CASE pos WHEN  6 THEN ' '||name||'='||value END)||
       MAX(CASE pos WHEN  7 THEN ' '||name||'='||value END)||
       MAX(CASE pos WHEN  8 THEN ' '||name||'='||value END)||
       MAX(CASE pos WHEN  9 THEN ' '||name||'='||value END)||
       MAX(CASE pos WHEN 10 THEN ' '||name||'='||value END)||
       MAX(CASE pos WHEN 11 THEN ' '||name||'='||value END)||
       MAX(CASE pos WHEN 12 THEN ' '||name||'='||value END)||
       MAX(CASE pos WHEN 13 THEN ' '||name||'='||value END)||
       MAX(CASE pos WHEN 14 THEN ' '||name||'='||value END)||
       MAX(CASE pos WHEN 15 THEN ' '||name||'='||value END)||
       MAX(CASE pos WHEN 16 THEN ' '||name||'='||value END)||
       MAX(CASE pos WHEN 17 THEN ' '||name||'='||value END)||
       MAX(CASE pos WHEN 18 THEN ' '||name||'='||value END)||
       MAX(CASE pos WHEN 19 THEN ' '||name||'='||value END)||
       MAX(CASE pos WHEN 20 THEN ' '||name||'='||value END)
       AS binds
  FROM bind
 GROUP BY
       con_id,
       sql_plan_hash_value,
       sql_exec_id,
       sql_exec_start,
       last_refresh_time,
       seconds,
       status,
       username,
       sid,
       serial#,
       machine,
       elapsed_time,
       cpu_time,
       buffer_gets,
       disk_reads,
       module,
       action,
       program
)
SELECT MAX(last_refresh_time) AS last_refresh_time,
       SUM(seconds) AS sum_seconds,
       ROUND(AVG(seconds)) AS avg_seconds,
       MAX(seconds) AS max_seconds,
       COUNT(*) AS execs,
       ROUND(AVG(elapsed_time)/1e6, 1) AS avg_et_secs,
       ROUND(AVG(cpu_time)/1e6, 1) AS avg_cpu_secs,
       ROUND(AVG(buffer_gets)) AS avg_buffer_gets,
       ROUND(AVG(disk_reads)) AS avg_disk_reads,
       con_id,
       (SELECT c.name FROM v$containers c WHERE c.con_id = e.con_id) AS pdb_name,
       sql_plan_hash_value,
       binds,
       status,
       sid||','||serial# AS sid_serial#,
       --username,
       machine,
       TRIM(
       CASE WHEN module IS NOT NULL THEN 'm:'||SUBSTR(module, 1, 64) END||
       CASE WHEN action IS NOT NULL THEN ' a:'||SUBSTR(action, 1, 64) END||
       CASE WHEN program IS NOT NULL THEN ' p:'||SUBSTR(program, 1, 64) END
       ) AS module_action_program
  FROM execs e
 GROUP BY
       con_id,
       sql_plan_hash_value,
       binds,
       status,
       username,
       sid,
       serial#,
       machine,
       module,
       action,
       program
 ORDER BY
       1
FETCH FIRST 300 ROWS ONLY
/
