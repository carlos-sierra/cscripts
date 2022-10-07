-- cs_cursors_performance.sql: called by cs_planx.sql, cs_sqlperf.sql and cs_purge_cursor.sql (deprecated)
COL con_id FOR 999 HEA 'Con|ID';
COL pdb_name FOR A30 HEA 'PDB Name' FOR A30 TRUNC;
COL last_active_time FOR A19 HEA 'Last Active Time';
COL child_number FOR 999999 HEA 'Child|Number';
COL plan_hash_value FOR 9999999999 HEA 'Plan|Hash Value';
COL full_plan_hash_value FOR 9999999999 HEA 'Full Plan|Hash Value';
COL users_executing FOR 9,999 HEA 'Users|Exec';
COL avg_et_ms FOR 99,999,990.000 HEA 'Avg Elapsed|Time (ms)';
COL avg_cpu_ms FOR 99,999,990.000 HEA 'Avg CPU|Time (ms)';
COL avg_bg FOR 999,999,990 HEA 'Avg|Buffer Gets';
COL avg_row FOR 999,999,990.000 HEA 'Avg|Rows Processed';
COL executions FOR 999,999,999,990 HEA 'Executions';
COL tot_et_secs FOR 99,999,990 HEA 'Total Elapsed|Time (secs)';
COL tot_cpu_secs FOR 99,999,990 HEA 'Total CPU|Time (secs)';
COL tot_buffer_gets FOR 999,999,999,990 HEA 'Total|Buffer Gets';
COL tot_rows_processed FOR 999,999,999,990 HEA 'Total|Rows Processed';
COL object_status FOR A14 HEA 'Object Status';
COL is_obsolete FOR A8 HEA 'Is|Obsolete';
COL is_shareable FOR A9 HEA 'Is|Shareable';
COL is_bind_aware FOR A9 HEA 'Is Bind|Aware';
COL is_bind_sensitive FOR A9 HEA 'Is Bind|Sensitive';
--
PRO
PRO CURSORS PERFORMANCE (v$sql)
PRO ~~~~~~~~~~~~~~~~~~~
SELECT s.con_id,
       c.name AS pdb_name,
       TO_CHAR(s.last_active_time, '&&cs_datetime_full_format.') AS last_active_time,
       s.child_number,
       s.plan_hash_value,
       s.full_plan_hash_value,
       '|' AS "|",
       s.object_status,  
       s.is_obsolete,
       s.is_shareable,
       s.is_bind_sensitive,
       s.is_bind_aware,
       s.users_executing,
       '|' AS "|",
       s.executions,
       s.elapsed_time/NULLIF(s.executions,0)/1e3 AS avg_et_ms,
       s.cpu_time/NULLIF(s.executions,0)/1e3 AS avg_cpu_ms,
       s.buffer_gets/NULLIF(s.executions,0) AS avg_bg,
       s.rows_processed/NULLIF(s.executions,0) AS avg_row,
       '|' AS "|",
       s.elapsed_time/1e6 AS tot_et_secs,
       s.cpu_time/1e6 AS tot_cpu_secs,
       s.buffer_gets AS tot_buffer_gets,
       s.rows_processed AS tot_rows_processed
  FROM v$sql s,
       v$containers c
 WHERE s.sql_id = '&&cs_sql_id.'
   AND c.con_id = s.con_id
 ORDER BY
       s.con_id,
       s.last_active_time,
       s.child_number
/
--