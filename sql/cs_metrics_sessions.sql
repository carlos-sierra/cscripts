SET HEA ON LIN 2490 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF LONG 240000 LONGC 2400 SERVEROUT OFF;
--
-- minutes [1|5|15] as per metrics interval
DEF minutes = '1';
--
WITH
sessions_subtotals AS (
SELECT /*+ NO_MERGE */
       REPLACE(c.name, '$') pdb_name,
       NVL(a.machine, 'UNKNOWN') machine,
       'ACTIVE' session_status,
       a.session_type,
       REPLACE(a.session_state, ' ', '-') session_state,
       CASE a.session_state WHEN 'ON CPU' THEN 'ON-CPU' ELSE REPLACE(REPLACE(a.wait_class, '/'), ' ', '-') END wait_class,
       ROUND(COUNT(*) / (&&minutes. * 60), 3) session_count
  FROM v$active_session_history a,
       v$containers c
 WHERE a.sample_time > SYSTIMESTAMP - INTERVAL '&&minutes.' MINUTE
   AND c.con_id = a.con_id
 GROUP BY
       c.name,
       NVL(a.machine, 'UNKNOWN'),
       a.session_type,
       REPLACE(a.session_state, ' ', '-'),
       CASE a.session_state WHEN 'ON CPU' THEN 'ON-CPU' ELSE REPLACE(REPLACE(a.wait_class, '/'), ' ', '-') END
 UNION ALL
SELECT /*+ NO_MERGE */
       CASE s.con_id WHEN 0 THEN 'CDB' ELSE REPLACE(c.name, '$') END pdb_name,
       NVL(s.machine, 'UNKNOWN') machine,
       s.status session_status,
       CASE s.type WHEN 'BACKGROUND' THEN s.type ELSE 'FOREGROUND' END session_type,
       CASE 
         WHEN s.state = 'WAITING' THEN s.state
         WHEN s.status = 'ACTIVE' THEN 'ON-CPU'
         WHEN s.status = 'INACTIVE' THEN 'WAITING'
         ELSE s.status
       END session_state,
       CASE 
         WHEN s.state = 'WAITING' THEN REPLACE(REPLACE(s.wait_class, '/'), ' ', '-')
         WHEN s.status = 'ACTIVE' THEN 'ON-CPU'
         WHEN s.status = 'INACTIVE' THEN NVL(REPLACE(REPLACE(s.wait_class, '/'), ' ', '-'), 'INACTIVE')
         ELSE s.status
       END wait_class,
       COUNT(*) session_count
  FROM v$session s,
       v$containers c
 WHERE (s.con_id = 0 OR s.status <> 'ACTIVE')
   AND c.con_id(+) = s.con_id
 GROUP BY
       CASE s.con_id WHEN 0 THEN 'CDB' ELSE REPLACE(c.name, '$') END,
       NVL(s.machine, 'UNKNOWN'),
       s.status,
       CASE s.type WHEN 'BACKGROUND' THEN s.type ELSE 'FOREGROUND' END,
       CASE 
         WHEN s.state = 'WAITING' THEN s.state
         WHEN s.status = 'ACTIVE' THEN 'ON-CPU'
         WHEN s.status = 'INACTIVE' THEN 'WAITING'
         ELSE s.status
       END,
       CASE 
         WHEN s.state = 'WAITING' THEN REPLACE(REPLACE(s.wait_class, '/'), ' ', '-')
         WHEN s.status = 'ACTIVE' THEN 'ON-CPU'
         WHEN s.status = 'INACTIVE' THEN NVL(REPLACE(REPLACE(s.wait_class, '/'), ' ', '-'), 'INACTIVE')
         ELSE s.status
       END
)
SELECT SUM(s.session_count) metric_value,
       CASE GROUPING(s.pdb_name) WHEN 1 THEN 'ALL' ELSE s.pdb_name END||'_'||
       CASE GROUPING(s.machine) WHEN 1 THEN 'ALL' ELSE s.machine END||'_'||
       CASE GROUPING(s.session_status) WHEN 1 THEN 'ALL' ELSE s.session_status END||'_'||
       CASE GROUPING(s.session_type) WHEN 1 THEN 'ALL' ELSE s.session_type END||'_'||
       CASE GROUPING(s.session_state) WHEN 1 THEN 'ALL' ELSE s.session_state END||'_'||
       CASE GROUPING(s.wait_class) WHEN 1 THEN 'ALL' ELSE s.wait_class END metric_name
  FROM sessions_subtotals s
 GROUP BY CUBE(s.pdb_name, s.machine, s.session_status, s.session_type, s.session_state, s.wait_class)
/
