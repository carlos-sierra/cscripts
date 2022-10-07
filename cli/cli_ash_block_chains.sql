DEF times_cpu_cores = '10';
DEF days = 14;
DEF text_piece = 'control';
--
SET TERM ON HEA ON LIN 2490 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF LONG 240000 LONGC 2400 NUM 20 SERVEROUT OFF;
ALTER SESSION SET NLS_DATE_FORMAT = 'YYYY-MM-DD"T"HH24:MI:SS';
ALTER SESSION SET NLS_TIMESTAMP_FORMAT = 'YYYY-MM-DD"T"HH24:MI:SS.FF3';
--
SET PAGES 0 TIMI ON;
WITH
constants AS
(SELECT o.value AS num_cpu_cores, d.name AS db_name, (SELECT COUNT(*) FROM v$containers WHERE con_id > 2) AS containers FROM v$osstat o, v$database d WHERE o.stat_name = 'NUM_CPU_CORES'),
sess_proc AS (
SELECT /*+ MATERIALIZE NO_MERGE */ DISTINCT s.sid, s.serial#, p.spid, p.pname FROM v$session s, v$process p WHERE p.addr = s.paddr AND ROWNUM >= 1
),
sqlstats AS (
SELECT /*+ MATERIALIZE NO_MERGE */ DISTINCT s.sql_id, SUBSTR(s.sql_text, 1, 40) AS sql_text FROM v$sqlstats s WHERE ROWNUM >= 1
),
procedures AS (
SELECT /*+ OPT_PARAM('_px_cdb_view_enabled' 'FALSE') MATERIALIZE NO_MERGE */ DISTINCT p.con_id, p.object_id, p.subprogram_id, p.owner, p.object_name, p.procedure_name FROM cdb_procedures p WHERE ROWNUM >= 1
),
ash AS (
SELECT /*+ MATERIALIZE NO_MERGE */ h.sample_id, h.sample_time, h.session_state, h.wait_class, h.event, h.session_id, h.session_serial#, h.blocking_session, h.blocking_session_serial#, h.sql_id, h.module, h.machine, c.name AS pdb_name, h.con_id, h.plsql_entry_object_id, h.plsql_entry_subprogram_id
  FROM dba_hist_active_sess_history h, v$containers c
 WHERE h.sample_time > SYSDATE - &&days.
   AND c.con_id(+) = h.con_id
   AND ROWNUM >= 1
),
ash_extended AS (
SELECT /*+ MATERIALIZE NO_MERGE ORDERED */ 
       h0.sample_time, COUNT(*) AS sessions, h0.session_state||' on: "'||h0.wait_class||' - '||h0.event||'"' AS h0_timed_event, 
       h0.blocking_session||CASE WHEN h0.blocking_session IS NOT NULL THEN ',' END||h0.blocking_session_serial# AS h1_session_serial, CASE h1.session_state WHEN 'ON CPU' THEN h1.session_state WHEN 'WAITING' THEN h1.session_state||' on: "'||h1.wait_class||' - '||h1.event||'"' END h1_timed_event, h1.sql_id AS h1_sql_id, h1.module AS h1_module, h1.machine AS h1_machine,
       (SELECT p.pname FROM sess_proc p WHERE p.sid = h0.blocking_session AND p.serial# = h0.blocking_session_serial#) AS h1_pname, s1.sql_text AS s1_sql_text,
       p1.owner||CASE WHEN p1.object_name IS NOT NULL THEN '.'||p1.object_name END||CASE WHEN p1.procedure_name IS NOT NULL THEN '.'||p1.procedure_name END AS p1_proced_name,
       h1.blocking_session||CASE WHEN h1.blocking_session IS NOT NULL THEN ',' END||h1.blocking_session_serial# AS h2_session_serial, CASE h2.session_state WHEN 'ON CPU' THEN h2.session_state WHEN 'WAITING' THEN h2.session_state||' on: "'||h2.wait_class||' - '||h2.event||'"' END h2_timed_event, h2.sql_id AS h2_sql_id, h2.module AS h2_module, h2.machine AS h2_machine,
       (SELECT p.pname FROM sess_proc p WHERE p.sid = h1.blocking_session AND p.serial# = h1.blocking_session_serial#) AS h2_pname, s2.sql_text AS s2_sql_text,
       p2.owner||CASE WHEN p2.object_name IS NOT NULL THEN '.'||p2.object_name END||CASE WHEN p2.procedure_name IS NOT NULL THEN '.'||p2.procedure_name END AS p2_proced_name,
       h2.blocking_session||CASE WHEN h2.blocking_session IS NOT NULL THEN ',' END||h2.blocking_session_serial# AS h3_session_serial, CASE h3.session_state WHEN 'ON CPU' THEN h3.session_state WHEN 'WAITING' THEN h4.session_state||' on: "'||h3.wait_class||' - '||h3.event||'"' END h3_timed_event, h3.sql_id AS h3_sql_id, h3.module AS h3_module, h3.machine AS h3_machine,
       (SELECT p.pname FROM sess_proc p WHERE p.sid = h2.blocking_session AND p.serial# = h2.blocking_session_serial#) AS h3_pname, s3.sql_text AS s3_sql_text,
       p3.owner||CASE WHEN p3.object_name IS NOT NULL THEN '.'||p3.object_name END||CASE WHEN p3.procedure_name IS NOT NULL THEN '.'||p3.procedure_name END AS p3_proced_name,
       h3.blocking_session||CASE WHEN h3.blocking_session IS NOT NULL THEN ',' END||h3.blocking_session_serial# AS h4_session_serial, CASE h4.session_state WHEN 'ON CPU' THEN h4.session_state WHEN 'WAITING' THEN h1.session_state||' on: "'||h4.wait_class||' - '||h4.event||'"' END h4_timed_event, h4.sql_id AS h4_sql_id, h4.module AS h4_module, h4.machine AS h4_machine,
       (SELECT p.pname FROM sess_proc p WHERE p.sid = h3.blocking_session AND p.serial# = h3.blocking_session_serial#) AS h4_pname, s4.sql_text AS s4_sql_text,
       p4.owner||CASE WHEN p4.object_name IS NOT NULL THEN '.'||p4.object_name END||CASE WHEN p4.procedure_name IS NOT NULL THEN '.'||p4.procedure_name END AS p4_proced_name
  FROM ash h0, ash h1, ash h2, ash h3, ash h4, sqlstats s1, sqlstats s2, sqlstats s3, sqlstats s4, procedures p1, procedures p2, procedures p3, procedures p4
 WHERE h0.session_state = 'WAITING'
   AND h0.blocking_session IS NOT NULL
   AND h0.blocking_session_serial# IS NOT NULL
   AND h1.sample_id(+) = h0.sample_id
   AND h1.session_id(+) = h0.blocking_session
   AND h1.session_serial#(+) = h0.blocking_session_serial#
   AND s1.sql_id(+) = h1.sql_id
   AND h2.sample_id(+) = h1.sample_id
   AND h2.session_id(+) = h1.blocking_session
   AND h2.session_serial#(+) = h1.blocking_session_serial#
   AND s2.sql_id(+) = h2.sql_id
   AND h3.sample_id(+) = h2.sample_id
   AND h3.session_id(+) = h2.blocking_session
   AND h3.session_serial#(+) = h2.blocking_session_serial#
   AND s3.sql_id(+) = h3.sql_id
   AND h4.sample_id(+) = h3.sample_id
   AND h4.session_id(+) = h3.blocking_session
   AND h4.session_serial#(+) = h3.blocking_session_serial#
   AND s4.sql_id(+) = h4.sql_id
   AND p1.con_id(+) = h1.con_id 
   AND p1.object_id(+) = h1.plsql_entry_object_id
   AND p1.subprogram_id(+) = h1.plsql_entry_subprogram_id
   AND p2.con_id(+) = h2.con_id 
   AND p2.object_id(+) = h2.plsql_entry_object_id
   AND p2.subprogram_id(+) = h2.plsql_entry_subprogram_id
   AND p3.con_id(+) = h3.con_id 
   AND p3.object_id(+) = h3.plsql_entry_object_id
   AND p3.subprogram_id(+) = h3.plsql_entry_subprogram_id
   AND p4.con_id(+) = h4.con_id 
   AND p4.object_id(+) = h4.plsql_entry_object_id
   AND p4.subprogram_id(+) = h4.plsql_entry_subprogram_id
   AND ROWNUM >= 1
 GROUP BY
       h0.sample_time, h0.session_state, h0.wait_class, h0.event, 
       h0.blocking_session, h0.blocking_session_serial#, h1.session_state, h1.wait_class, h1.event, h1.sql_id, h1.module, h1.machine, s1.sql_text, h1.con_id, h1.plsql_entry_object_id, h1.plsql_entry_subprogram_id, p1.owner, p1.object_name, p1.procedure_name,
       h1.blocking_session, h1.blocking_session_serial#, h2.session_state, h2.wait_class, h2.event, h2.sql_id, h2.module, h2.machine, s2.sql_text, h2.con_id, h2.plsql_entry_object_id, h2.plsql_entry_subprogram_id, p2.owner, p2.object_name, p2.procedure_name,
       h2.blocking_session, h2.blocking_session_serial#, h3.session_state, h3.wait_class, h3.event, h3.sql_id, h3.module, h3.machine, s3.sql_text, h3.con_id, h3.plsql_entry_object_id, h3.plsql_entry_subprogram_id, p3.owner, p3.object_name, p3.procedure_name,
       h3.blocking_session, h3.blocking_session_serial#, h4.session_state, h4.wait_class, h4.event, h4.sql_id, h4.module, h4.machine, s4.sql_text, h4.con_id, h4.plsql_entry_object_id, h4.plsql_entry_subprogram_id, p4.owner, p4.object_name, p4.procedure_name
),
final AS (
SELECT /*+ MATERIALIZE NO_MERGE */ 
                                                            '+----------------------------------------------------------------'||
                                                   CHR(10)||'| 1. On '||TO_CHAR(h.sample_time, 'YYYY-MM-DD"T"HH24:MI:SS.FF3')||' ('||TRIM(TO_CHAR(h.sample_time, 'Day'))||')'||
                                                   CHR(10)||'|    '||TRIM(TO_CHAR(h.sessions, '999,990'))||' Active Sessions'||
                                                   CHR(10)||'|    from CDB '||c.db_name||', which hosts '||c.containers||' PDBs with '||c.num_cpu_cores||' CPU Cores'||
                                                   CHR(10)||'|    '||h.h0_timed_event||
       CASE WHEN h1_session_serial IS NOT NULL THEN
                                                   CHR(10)||'|    *** were blocked by session below: ***'||
                                                   CHR(10)||'| 2. sid,ser: '||h1_session_serial||
         CASE WHEN h1_pname IS NOT NULL       THEN CHR(10)||'|    process: '||h1_pname END||
         CASE WHEN h1_sql_id IS NOT NULL      THEN CHR(10)||'|    sql_id : '||h1_sql_id||' '||s1_sql_text END||
         CASE WHEN h1_module IS NOT NULL      THEN CHR(10)||'|    module : '||h1_module END||
         CASE WHEN p1_proced_name IS NOT NULL THEN CHR(10)||'|    library: '||p1_proced_name END||
         CASE WHEN h1_machine IS NOT NULL     THEN CHR(10)||'|    machine: '||h1_machine END||
         CASE WHEN h1_timed_event IS NOT NULL THEN CHR(10)||'|    '||h1_timed_event END
       END||
       CASE WHEN h2_session_serial IS NOT NULL THEN
                                                   CHR(10)||'|    *** which was blocked by session below: ***'||
                                                   CHR(10)||'| 3. sid,ser: '||h2_session_serial||
         CASE WHEN h2_pname IS NOT NULL   THEN     CHR(10)||'|    process: '||h2_pname END||
         CASE WHEN h2_sql_id IS NOT NULL  THEN     CHR(10)||'|    sql_id : '||h2_sql_id||' '||s2_sql_text END||
         CASE WHEN h2_module IS NOT NULL  THEN     CHR(10)||'|    module : '||h2_module END||
         CASE WHEN p2_proced_name IS NOT NULL THEN CHR(10)||'|    library: '||p2_proced_name END||
         CASE WHEN h2_machine IS NOT NULL THEN     CHR(10)||'|    machine: '||h2_machine END||
         CASE WHEN h2_timed_event IS NOT NULL THEN CHR(10)||'|    '||h2_timed_event END
       END||
       CASE WHEN h3_session_serial IS NOT NULL THEN
                                                   CHR(10)||'|    *** which was blocked by session below: ***'||
                                                   CHR(10)||'| 4. sid,ser: '||h3_session_serial||
         CASE WHEN h3_pname IS NOT NULL   THEN     CHR(10)||'|    process: '||h3_pname END||
         CASE WHEN h3_sql_id IS NOT NULL  THEN     CHR(10)||'|    sql_id : '||h3_sql_id||' '||s3_sql_text END||
         CASE WHEN h3_module IS NOT NULL  THEN     CHR(10)||'|    module : '||h3_module END||
         CASE WHEN p3_proced_name IS NOT NULL THEN CHR(10)||'|    library: '||p3_proced_name END||
         CASE WHEN h3_machine IS NOT NULL THEN     CHR(10)||'|    machine: '||h3_machine END||
         CASE WHEN h3_timed_event IS NOT NULL THEN CHR(10)||'|    '||h3_timed_event END
       END||
       CASE WHEN h4_session_serial IS NOT NULL THEN
                                                   CHR(10)||'|    *** which was blocked by session below: ***'||
                                                   CHR(10)||'| 5. sid,ser: '||h4_session_serial||
         CASE WHEN h4_pname IS NOT NULL   THEN     CHR(10)||'|    process: '||h4_pname END||
         CASE WHEN h4_sql_id IS NOT NULL  THEN     CHR(10)||'|    sql_id : '||h4_sql_id||' '||s4_sql_text END||
         CASE WHEN h4_module IS NOT NULL  THEN     CHR(10)||'|    module : '||h4_module END||
         CASE WHEN p4_proced_name IS NOT NULL THEN CHR(10)||'|    library: '||p4_proced_name END||
         CASE WHEN h4_machine IS NOT NULL THEN     CHR(10)||'|    machine: '||h4_machine END||
         CASE WHEN h4_timed_event IS NOT NULL THEN CHR(10)||'|    '||h4_timed_event END
       END||
                                                   CHR(10)||'+----------------------------------------------------------------'
       AS block_chain
  FROM ash_extended h, constants c
 WHERE h.sessions >= &&times_cpu_cores. * c.num_cpu_cores
   AND ROWNUM >= 1
)
SELECT /*+ MONITOR GATHER_PLAN_STATISTICS */
       block_chain
  FROM final
 WHERE LOWER(block_chain) LIKE LOWER('%&&text_piece.%')
ORDER BY 1
/
