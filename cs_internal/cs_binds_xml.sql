COL con_id FOR 999 HEA 'Con|ID';
COL pdb_name FOR A30 HEA 'PDB Name' FOR A30 TRUNC;
COL sum_seconds FOR 999,999,990 HEA 'Sum Dur Secs';
COL avg_seconds FOR 999,999,990 HEA 'Avg Dur Secs';
COL max_seconds FOR 999,999,990 HEA 'Max Dur Secs';
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
PRO SQL MONITOR BINDS by Sum Secs (v$sql_monitor) Top 100
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
       XMLTABLE( '/binds/bind'
                  PASSING XMLTYPE(REPLACE(REPLACE(ASCIISTR(mon.binds_xml), '\FFFF'), CHR(0)))
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
       binds
      --  status,
      --  sid||','||serial# AS sid_serial#,
      --  --username,
      --  machine,
      --  TRIM(
      --  CASE WHEN module IS NOT NULL THEN 'm:'||SUBSTR(module, 1, 64) END||
      --  CASE WHEN action IS NOT NULL THEN ' a:'||SUBSTR(action, 1, 64) END||
      --  CASE WHEN program IS NOT NULL THEN ' p:'||SUBSTR(program, 1, 64) END
      --  ) AS module_action_program
  FROM execs e
 GROUP BY
       con_id,
       sql_plan_hash_value,
       binds
      --  status,
      --  username,
      --  sid,
      --  serial#,
      --  machine,
      --  module,
      --  action,
      --  program
 ORDER BY
       1 DESC,
       2 DESC,
       3 DESC,
       5
FETCH FIRST 100 ROWS ONLY
/
--
PRO
PRO SQL MONITOR BINDS by Last Captured (v$sql_monitor) Last 100
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
       XMLTABLE( '/binds/bind'
                  PASSING XMLTYPE(REPLACE(REPLACE(ASCIISTR(mon.binds_xml), '\FFFF'), CHR(0)))
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
),
top AS (
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
       binds
      --  status,
      --  sid||','||serial# AS sid_serial#,
       --username,
      --  machine,
      --  TRIM(
      --  CASE WHEN module IS NOT NULL THEN 'm:'||SUBSTR(module, 1, 64) END||
      --  CASE WHEN action IS NOT NULL THEN ' a:'||SUBSTR(action, 1, 64) END||
      --  CASE WHEN program IS NOT NULL THEN ' p:'||SUBSTR(program, 1, 64) END
      --  ) AS module_action_program
  FROM execs e
 GROUP BY
       con_id,
       sql_plan_hash_value,
       binds
      --  status,
      --  username,
      --  sid,
      --  serial#,
      --  machine,
      --  module,
      --  action,
      --  program
 ORDER BY
       1 DESC
FETCH FIRST 100 ROWS ONLY
)
SELECT last_refresh_time,
       sum_seconds,
       avg_seconds,
       max_seconds,
       execs,
       avg_et_secs,
       avg_cpu_secs,
       avg_buffer_gets,
       avg_disk_reads,
       con_id,
       pdb_name,
       sql_plan_hash_value,
       binds
      --  status,
      --  sid_serial#,
       --username,
      --  machine,
      --  module_action_program
  FROM top
 ORDER BY
       last_refresh_time
/
--
PRO
PRO SQL MONITOR BINDS by Sum of Elapsed Time (v$sql_monitor) Top 100
PRO ~~~~~~~~~~~~~~~~~
--
COL sum_duration_secs FOR 999,990 HEA 'Sum|Duration|Seconds';
COL sum_elapsed_secs FOR 999,990 HEA 'Sum|Elapsed|Seconds';
COL sum_cpu_secs FOR 999,990 HEA 'Sum|CPU|Seconds';
COL sum_buffer_gets FOR 999,999,999,990 HEA 'Sum|Buffer|Gets';
COL sum_disk_reads FOR 999,999,999,990 HEA 'Sum|Disk|Reads';
COL avg_duration_secs FOR 999,990 HEA 'Avg|Duration|Seconds';
COL avg_elapsed_secs FOR 999,990 HEA 'Avg|Elapsed|Seconds';
COL avg_cpu_secs FOR 999,990 HEA 'Avg|CPU|Seconds';
COL avg_buffer_gets FOR 999,999,999,990 HEA 'Avg|Buffer|Gets';
COL avg_disk_reads FOR 999,999,999,990 HEA 'Avg|Disk|Reads';
COL max_duration_secs FOR 999,990 HEA 'Max|Duration|Seconds';
COL max_elapsed_secs FOR 999,990 HEA 'Max|Elapsed|Seconds';
COL max_cpu_secs FOR 999,990 HEA 'Max|CPU|Seconds';
COL max_buffer_gets FOR 999,999,999,990 HEA 'Max|Buffer|Gets';
COL max_disk_reads FOR 999,999,999,990 HEA 'Max|Disk|Reads';
COL cnt FOR 999,990 HEA 'Count';
COL name_and_value FOR A200 HEA 'Bind Name and Value';
COL min_sql_exec_start HEA 'Min SQL|Exec Start';
COL max_last_refresh_time HEA 'Max Last|Refresh Time';
COL d1 FOR A1 HEA '|';
COL d2 FOR A1 HEA '|';
COL d3 FOR A1 HEA '|';
COL d4 FOR A1 HEA '|';
--
WITH 
mon AS (
SELECT s.key,
       s.con_id,
       s.sql_plan_hash_value,
       s.sql_exec_id,
       s.sql_exec_start,
       s.last_refresh_time,
       (s.last_refresh_time - s.sql_exec_start) * 24 * 3600 AS seconds,
       s.status,
       s.username,
       s.sid,
       s.session_serial# AS serial#,
       s.elapsed_time,
       s.cpu_time,
       s.buffer_gets,
       s.disk_reads,
       s.module,
       s.action,
       s.program,
       bv.pos,
       bv.name,
       bv.type,
       bv.maxlen,
       bv.len,
       bv.value
  FROM v$sql_monitor s, 
       xmltable( '/binds/bind'
                  passing xmltype(REPLACE(REPLACE(ASCIISTR(s.binds_xml), '\FFFF'), CHR(0)))
                  COLUMNS name   VARCHAR2( 30 )   path '@name' ,
                          pos    NUMBER           path '@pos',
                          type   VARCHAR2( 15 )   path '@dtystr' ,
                          maxlen NUMBER           path '@maxlen', 
                          len    NUMBER           path '@len',
                          value  VARCHAR2( 4000 ) path '.'
               ) bv
 WHERE s.sql_id = '&&cs_sql_id.'
   AND s.status LIKE 'DONE%'
   AND s.binds_xml IS NOT NULL
),
grp AS (
SELECT SUM(seconds) AS sum_duration_secs,
       SUM(elapsed_time) / POWER(10, 6) AS sum_elapsed_secs,
       SUM(cpu_time) / POWER(10, 6) AS sum_cpu_secs,
       SUM(buffer_gets) AS sum_buffer_gets,
       SUM(disk_reads) AS sum_disk_reads,
       AVG(seconds) AS avg_duration_secs,
       AVG(elapsed_time) / POWER(10, 6) AS avg_elapsed_secs,
       AVG(cpu_time) / POWER(10, 6) AS avg_cpu_secs,
       AVG(buffer_gets) AS avg_buffer_gets,
       AVG(disk_reads) AS avg_disk_reads,
       MAX(seconds) AS max_duration_secs,
       MAX(elapsed_time) / POWER(10, 6) AS max_elapsed_secs,
       MAX(cpu_time) / POWER(10, 6) AS max_cpu_secs,
       MAX(buffer_gets) AS max_buffer_gets,
       MAX(disk_reads) AS max_disk_reads,
       COUNT(*) AS cnt,
       MIN(sql_exec_start) AS min_sql_exec_start,
       MAX(last_refresh_time) AS max_last_refresh_time,
       name,
       value
  FROM mon
 GROUP BY
       name,
       value
)
SELECT sum_duration_secs,
       sum_elapsed_secs,
       sum_cpu_secs,
       sum_buffer_gets,
       sum_disk_reads,
       '|' AS d1,
       avg_duration_secs,
       avg_elapsed_secs,
       avg_cpu_secs,
       avg_buffer_gets,
       avg_disk_reads,
       '|' AS d2,
       max_duration_secs,
       max_elapsed_secs,
       max_cpu_secs,
       max_buffer_gets,
       max_disk_reads,
       '|' AS d3,
       name||' = '||value AS name_and_value,
       '|' AS d4,
       cnt,
       min_sql_exec_start,
       max_last_refresh_time
  FROM grp
 ORDER BY
       sum_duration_secs DESC,
       name,
       value
 FETCH FIRST 100 ROWS ONLY
/
