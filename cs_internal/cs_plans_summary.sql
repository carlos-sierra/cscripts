COL con_id FOR 999 HEA 'Con|ID';
COL pdb_name FOR A30 HEA 'PDB Name' FOR A30 TRUNC;
COL last_active_time FOR A19 HEA 'Last Active Time';
COL plan_hash_value FOR 9999999999 HEA 'Plan Hash|Value';
COL plan_hash_value_2 FOR 9999999999 HEA 'Plan Hash|Value 2';
COL full_plan_hash_value FOR 9999999999 HEA 'Full Plan|Hash Value';
COL cursors FOR 9,999,990 HEA 'Child|Cursors';
COL valid FOR 9,999,990 HEA 'Valid|Cursors';
COL invalid FOR 9,999,990 HEA 'Invalid|Cursors';
COL obsolete FOR 9,999,990 HEA 'Obsolete|Cursors';
COL shareable FOR 9,999,990 HEA 'Shareable|Cursors';
COL bind_sens FOR 9,999,990 HEA 'Bind|Sensitive|Cursors';
COL bind_aware FOR 9,999,990 HEA 'Bind|Aware|Cursors';
COL executions FOR 999,999,999,999,990 HEA 'Total|Executions';
COL avg_et_ms_pe FOR 99,999,990.000 HEA 'Avg Elapsed|Time (ms)|Per Execution';
COL avg_cpu_ms_pe FOR 99,999,990.000 HEA 'Avg CPU|Time (ms)|Per Execution';
COL avg_bg_pe FOR 999,999,999,990 HEA 'Avg|Buffer Gets|Per Execution';
COL avg_disk_pe FOR 999,999,999,990 HEA 'Avg|Disk Reads|Per Execution';
COL avg_row FOR 999,999,990.000 HEA 'Avg Rows|Processed|Per Execution';
COL avg_et_ms_pr FOR 99,999,990.000 HEA 'Avg Elapsed|Time (ms)|Per Row Proc';
COL avg_cpu_ms_pr FOR 99,999,990.000 HEA 'Avg CPU|Time (ms)|Per Row Proc';
COL avg_bg_pr FOR 999,999,999,990.0 HEA 'Avg|Buffer Gets|Per Row Proc';
COL avg_disk_pr FOR 999,999,999,990.0 HEA 'Avg|Disk Reads|Per Row Proc';
COL bg_per_capped_rows FOR 999,999,999,990 HEA 'Avg|Buffer Gets|Per Capped Rows';
COL ms_per_capped_rows FOR 99,999,990.000 HEA 'Avg CPU|Time (ms)|Per Capped Rows';
--
PRO
PRO PLANS SUMMARY (v$sql)
PRO ~~~~~~~~~~~~~
SELECT s.con_id,
       c.name AS pdb_name,
       TO_CHAR(MAX(s.last_active_time), '&&cs_datetime_full_format.') AS last_active_time,
       s.plan_hash_value,
       p.plan_hash_value_2,
       s.full_plan_hash_value,
       COUNT(*) AS cursors,
       '|' AS "|",
       SUM(CASE SUBSTR(s.object_status, 1, 5) WHEN 'VALID' THEN 1 ELSE 0 END) AS valid,
       SUM(CASE SUBSTR(s.object_status, 1, 7) WHEN 'INVALID' THEN 1 ELSE 0 END) AS invalid,       
       SUM(CASE s.is_obsolete WHEN 'Y' THEN 1 ELSE 0 END) AS obsolete,
       SUM(CASE s.is_shareable WHEN 'Y' THEN 1 ELSE 0 END) AS shareable,
       SUM(CASE s.is_bind_sensitive WHEN 'Y' THEN 1 ELSE 0 END) AS bind_sens,
       SUM(CASE s.is_bind_aware WHEN 'Y' THEN 1 ELSE 0 END) AS bind_aware,
       '|' AS "|",
       SUM(s.executions) AS executions,
       SUM(s.elapsed_time)/NULLIF(SUM(s.executions), 0)/1e3 AS avg_et_ms_pe,
       SUM(s.cpu_time)/NULLIF(SUM(s.executions), 0)/1e3 AS avg_cpu_ms_pe,
       SUM(s.buffer_gets)/NULLIF(SUM(s.executions), 0) AS avg_bg_pe,
       SUM(s.disk_reads)/NULLIF(SUM(s.executions), 0) AS avg_disk_pe,
       SUM(s.rows_processed)/NULLIF(SUM(s.executions), 0) AS avg_row,
       '|' AS "|",
       SUM(s.elapsed_time)/NULLIF(SUM(s.rows_processed), 0)/1e3 AS avg_et_ms_pr,
       SUM(s.cpu_time)/NULLIF(SUM(s.rows_processed), 0)/1e3 AS avg_cpu_ms_pr,
       CASE WHEN SUM(s.cpu_time)/NULLIF(SUM(s.rows_processed), 0)/1e3 > &&cs_cpu_ms_per_row. THEN '*' END AS h,
       SUM(s.buffer_gets)/NULLIF(SUM(s.rows_processed), 0) AS avg_bg_pr,
       CASE WHEN SUM(s.buffer_gets)/NULLIF(SUM(s.rows_processed), 0) > &&cs_buffer_gets_per_row. THEN '*' END AS h,
       SUM(s.disk_reads)/NULLIF(SUM(s.rows_processed), 0) AS avg_disk_pr,
       CASE WHEN SUM(s.disk_reads)/NULLIF(SUM(s.rows_processed), 0) > &&cs_disk_reads_per_row. THEN '*' END AS h,
       '|' AS "|",
       (SUM(s.buffer_gets)/NULLIF(SUM(s.executions), 0)) / GREATEST(SUM(s.rows_processed)/NULLIF(SUM(s.executions), 0), &&cs_min_rows_per_exec_cap.) AS bg_per_capped_rows,
       (SUM(s.cpu_time)/NULLIF(SUM(s.executions), 0)/1e3) / GREATEST(SUM(s.rows_processed)/NULLIF(SUM(s.executions), 0), &&cs_min_rows_per_exec_cap.) AS ms_per_capped_rows
  FROM v$sql s,
       v$containers c
       OUTER APPLY ( -- could be CROSS APPLY since we expect one and only one row 
         SELECT TO_NUMBER(EXTRACTVALUE(XMLTYPE(p.other_xml),'/*/info[@type = "plan_hash_2"]')) AS plan_hash_value_2 
           FROM v$sql_plan p
          WHERE p.con_id = s.con_id
            AND p.address = s.address
            AND p.hash_value = s.hash_value
            AND p.sql_id = s.sql_id
            AND p.plan_hash_value = s.plan_hash_value
            AND p.child_address = s.child_address
            AND p.child_number = s.child_number
            AND p.other_xml IS NOT NULL
            AND p.id = 1
            AND ROWNUM >= 1 /* MATERIALIZE NO_MERGE */
          ORDER BY
                p.timestamp DESC, p.id
          FETCH FIRST 1 ROW ONLY -- redundant. expecting one and only one row 
       ) p
 WHERE s.sql_id = '&&cs_sql_id.'
   AND c.con_id = s.con_id
 GROUP BY
       s.con_id, c.name, s.plan_hash_value, p.plan_hash_value_2, s.full_plan_hash_value
 ORDER BY
       1, 3, 4, 5, 6
/
PRO Note (H) = "*" means High. Expecting less than &&cs_cpu_ms_per_row. CPU ms per row processed, less than &&cs_buffer_gets_per_row. Buffer Gets per row processed, and less than &&cs_disk_reads_per_row. Disk Reads per row processed.
--
