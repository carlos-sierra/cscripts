COL perc FOR 990.0 HEA 'Perc%';
COL samples FOR 999,999,990 HEA 'Samples';
COL sql_plan_hash_value FOR 9999999999 HEA 'Plan|Hash Value';
COL sql_plan_line_id FOR 9999 HEA 'Plan|Line';
COL in_connection_mgmt FOR A6 HEA 'In|Connec|Mgmt';
COL in_parse FOR A6 HEA 'In|Parse';
COL in_hard_parse FOR A6 HEA 'In|Hard|Parse';
COL in_sql_execution FOR A6 HEA 'In|SQL|Exec';
COL in_plsql_execution FOR A6 HEA 'In|PLSQL|Exec';
COL in_plsql_rpc FOR A6 HEA 'In|PLSQL|RPC';
COL in_plsql_compilation FOR A6 HEA 'In|PLSQL|Compil';
COL in_java_execution FOR A6 HEA 'In|Java|Exec';
COL in_bind FOR A6 HEA 'In|Bind';
COL in_cursor_close FOR A6 HEA 'In|Cursor|Close';
COL in_sequence_load FOR A6 HEA 'In|Seq|Load';
COL on_cpu_or_wait_event FOR A50 HEA 'ON CPU or Timed Event';
--
COL dummy FOR A1 NOPRI;
BREAK ON dummy SKIP PAGE;
COMPUTE SUM LABEL 'TOTAL' OF perc samples ON dummy;
--
PRO
PRO ASH (v$active_session_history)
PRO ~~~
WITH
ash_detailed AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       100 * COUNT(*) / SUM(COUNT(*)) OVER() AS perc,
       COUNT(*) AS samples,
       h.sql_plan_hash_value,
       h.sql_plan_line_id,
       CASE h.session_state WHEN 'ON CPU' THEN h.session_state ELSE h.wait_class||' - '||h.event END AS on_cpu_or_wait_event,
       h.in_connection_mgmt,
       h.in_parse,
       h.in_hard_parse,
       h.in_sql_execution,
       h.in_plsql_execution,
       h.in_plsql_rpc,
       h.in_plsql_compilation,
       h.in_java_execution,
       h.in_bind,
       h.in_cursor_close,
       h.in_sequence_load
  FROM v$active_session_history h
 WHERE h.sql_id = '&&cs_sql_id.'
 GROUP BY
       h.sql_plan_hash_value,
       h.sql_plan_line_id,
       CASE h.session_state WHEN 'ON CPU' THEN h.session_state ELSE h.wait_class||' - '||h.event END,
       h.in_connection_mgmt,
       h.in_parse,
       h.in_hard_parse,
       h.in_sql_execution,
       h.in_plsql_execution,
       h.in_plsql_rpc,
       h.in_plsql_compilation,
       h.in_java_execution,
       h.in_bind,
       h.in_cursor_close,
       h.in_sequence_load
)
SELECT '1' AS dummy,
       100 * SUM(samples) / SUM(SUM(samples)) OVER() AS perc,
       SUM(samples) AS samples,
       sql_plan_hash_value,
       sql_plan_line_id,
       on_cpu_or_wait_event,
       in_connection_mgmt,
       in_parse,
       in_hard_parse,
       in_sql_execution,
       in_plsql_execution,
       in_plsql_rpc,
       in_plsql_compilation,
       in_java_execution,
       in_bind,
       in_cursor_close,
       in_sequence_load
  FROM ash_detailed
 GROUP BY
       sql_plan_hash_value,
       sql_plan_line_id,
       on_cpu_or_wait_event,
       in_connection_mgmt,
       in_parse,
       in_hard_parse,
       in_sql_execution,
       in_plsql_execution,
       in_plsql_rpc,
       in_plsql_compilation,
       in_java_execution,
       in_bind,
       in_cursor_close,
       in_sequence_load
-- UNION ALL
--SELECT '2' AS dummy,
--       100 * SUM(samples) / SUM(SUM(samples)) OVER() AS perc,
--       SUM(samples) AS samples,
--       sql_plan_hash_value,
--       sql_plan_line_id,
--       on_cpu_or_wait_event,
--       NULL in_connection_mgmt,
--       NULL in_parse,
--       NULL in_hard_parse,
--       NULL in_sql_execution,
--       NULL in_plsql_execution,
--       NULL in_plsql_rpc,
--       NULL in_plsql_compilation,
--       NULL in_java_execution,
--       NULL in_bind,
--       NULL in_cursor_close,
--       NULL in_sequence_load
--  FROM ash_detailed
-- GROUP BY
--       sql_plan_hash_value,
--       sql_plan_line_id,
--       on_cpu_or_wait_event
 UNION ALL
SELECT '3' AS dummy,
       100 * SUM(samples) / SUM(SUM(samples)) OVER() AS perc,
       SUM(samples) AS samples,
       sql_plan_hash_value,
       TO_NUMBER(NULL) sql_plan_line_id,
       on_cpu_or_wait_event,
       NULL in_connection_mgmt,
       NULL in_parse,
       NULL in_hard_parse,
       NULL in_sql_execution,
       NULL in_plsql_execution,
       NULL in_plsql_rpc,
       NULL in_plsql_compilation,
       NULL in_java_execution,
       NULL in_bind,
       NULL in_cursor_close,
       NULL in_sequence_load
  FROM ash_detailed
 GROUP BY
       sql_plan_hash_value,
       on_cpu_or_wait_event
 UNION ALL
SELECT '4' AS dummy,
       100 * SUM(samples) / SUM(SUM(samples)) OVER() AS perc,
       SUM(samples) AS samples,
       sql_plan_hash_value,
       TO_NUMBER(NULL) sql_plan_line_id,
       NULL on_cpu_or_wait_event,
       NULL in_connection_mgmt,
       NULL in_parse,
       NULL in_hard_parse,
       NULL in_sql_execution,
       NULL in_plsql_execution,
       NULL in_plsql_rpc,
       NULL in_plsql_compilation,
       NULL in_java_execution,
       NULL in_bind,
       NULL in_cursor_close,
       NULL in_sequence_load
  FROM ash_detailed
 GROUP BY
       sql_plan_hash_value
 UNION ALL
SELECT '5' AS dummy,
       100 * SUM(samples) / SUM(SUM(samples)) OVER() AS perc,
       SUM(samples) AS samples,
       TO_NUMBER(NULL) sql_plan_hash_value,
       TO_NUMBER(NULL) sql_plan_line_id,
       on_cpu_or_wait_event,
       NULL in_connection_mgmt,
       NULL in_parse,
       NULL in_hard_parse,
       NULL in_sql_execution,
       NULL in_plsql_execution,
       NULL in_plsql_rpc,
       NULL in_plsql_compilation,
       NULL in_java_execution,
       NULL in_bind,
       NULL in_cursor_close,
       NULL in_sequence_load
  FROM ash_detailed
 GROUP BY
       on_cpu_or_wait_event
 ORDER BY
       1 ASC, 2 DESC, 3 DESC
/
--
PRO
PRO ASH 7d (dba_hist_active_sess_history)
PRO ~~~~~~
WITH
ash_detailed AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       100 * COUNT(*) / SUM(COUNT(*)) OVER() AS perc,
       COUNT(*) AS samples,
       h.sql_plan_hash_value,
       h.sql_plan_line_id,
       CASE h.session_state WHEN 'ON CPU' THEN h.session_state ELSE h.wait_class||' - '||h.event END AS on_cpu_or_wait_event,
       h.in_connection_mgmt,
       h.in_parse,
       h.in_hard_parse,
       h.in_sql_execution,
       h.in_plsql_execution,
       h.in_plsql_rpc,
       h.in_plsql_compilation,
       h.in_java_execution,
       h.in_bind,
       h.in_cursor_close,
       h.in_sequence_load
  FROM dba_hist_active_sess_history h
 WHERE h.sql_id = '&&cs_sql_id.'
   AND h.dbid = TO_NUMBER('&&cs_dbid.')
   AND h.instance_number = TO_NUMBER('&&cs_instance_number.')
   AND h.sample_time > SYSDATE - 7
   AND h.snap_id >= &&cs_7d_snap_id.
 GROUP BY
       h.sql_plan_hash_value,
       h.sql_plan_line_id,
       CASE h.session_state WHEN 'ON CPU' THEN h.session_state ELSE h.wait_class||' - '||h.event END,
       h.in_connection_mgmt,
       h.in_parse,
       h.in_hard_parse,
       h.in_sql_execution,
       h.in_plsql_execution,
       h.in_plsql_rpc,
       h.in_plsql_compilation,
       h.in_java_execution,
       h.in_bind,
       h.in_cursor_close,
       h.in_sequence_load
)
SELECT '1' AS dummy,
       100 * SUM(samples) / SUM(SUM(samples)) OVER() AS perc,
       SUM(samples) AS samples,
       sql_plan_hash_value,
       sql_plan_line_id,
       on_cpu_or_wait_event,
       in_connection_mgmt,
       in_parse,
       in_hard_parse,
       in_sql_execution,
       in_plsql_execution,
       in_plsql_rpc,
       in_plsql_compilation,
       in_java_execution,
       in_bind,
       in_cursor_close,
       in_sequence_load
  FROM ash_detailed
 GROUP BY
       sql_plan_hash_value,
       sql_plan_line_id,
       on_cpu_or_wait_event,
       in_connection_mgmt,
       in_parse,
       in_hard_parse,
       in_sql_execution,
       in_plsql_execution,
       in_plsql_rpc,
       in_plsql_compilation,
       in_java_execution,
       in_bind,
       in_cursor_close,
       in_sequence_load
-- UNION ALL
--SELECT '2' AS dummy,
--       100 * SUM(samples) / SUM(SUM(samples)) OVER() AS perc,
--       SUM(samples) AS samples,
--       sql_plan_hash_value,
--       sql_plan_line_id,
--       on_cpu_or_wait_event,
--       NULL in_connection_mgmt,
--       NULL in_parse,
--       NULL in_hard_parse,
--       NULL in_sql_execution,
--       NULL in_plsql_execution,
--       NULL in_plsql_rpc,
--       NULL in_plsql_compilation,
--       NULL in_java_execution,
--       NULL in_bind,
--       NULL in_cursor_close,
--       NULL in_sequence_load
--  FROM ash_detailed
-- GROUP BY
--       sql_plan_hash_value,
--       sql_plan_line_id,
--       on_cpu_or_wait_event
 UNION ALL
SELECT '3' AS dummy,
       100 * SUM(samples) / SUM(SUM(samples)) OVER() AS perc,
       SUM(samples) AS samples,
       sql_plan_hash_value,
       TO_NUMBER(NULL) sql_plan_line_id,
       on_cpu_or_wait_event,
       NULL in_connection_mgmt,
       NULL in_parse,
       NULL in_hard_parse,
       NULL in_sql_execution,
       NULL in_plsql_execution,
       NULL in_plsql_rpc,
       NULL in_plsql_compilation,
       NULL in_java_execution,
       NULL in_bind,
       NULL in_cursor_close,
       NULL in_sequence_load
  FROM ash_detailed
 GROUP BY
       sql_plan_hash_value,
       on_cpu_or_wait_event
 UNION ALL
SELECT '4' AS dummy,
       100 * SUM(samples) / SUM(SUM(samples)) OVER() AS perc,
       SUM(samples) AS samples,
       sql_plan_hash_value,
       TO_NUMBER(NULL) sql_plan_line_id,
       NULL on_cpu_or_wait_event,
       NULL in_connection_mgmt,
       NULL in_parse,
       NULL in_hard_parse,
       NULL in_sql_execution,
       NULL in_plsql_execution,
       NULL in_plsql_rpc,
       NULL in_plsql_compilation,
       NULL in_java_execution,
       NULL in_bind,
       NULL in_cursor_close,
       NULL in_sequence_load
  FROM ash_detailed
 GROUP BY
       sql_plan_hash_value
 UNION ALL
SELECT '5' AS dummy,
       100 * SUM(samples) / SUM(SUM(samples)) OVER() AS perc,
       SUM(samples) AS samples,
       TO_NUMBER(NULL) sql_plan_hash_value,
       TO_NUMBER(NULL) sql_plan_line_id,
       on_cpu_or_wait_event,
       NULL in_connection_mgmt,
       NULL in_parse,
       NULL in_hard_parse,
       NULL in_sql_execution,
       NULL in_plsql_execution,
       NULL in_plsql_rpc,
       NULL in_plsql_compilation,
       NULL in_java_execution,
       NULL in_bind,
       NULL in_cursor_close,
       NULL in_sequence_load
  FROM ash_detailed
 GROUP BY
       on_cpu_or_wait_event
 ORDER BY
       1 ASC, 2 DESC, 3 DESC
/
--
CL BRE COMP;
--