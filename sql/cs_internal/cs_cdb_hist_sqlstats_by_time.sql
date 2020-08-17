COL con_id FOR 999 HEA 'Con|ID';
COL pdb_name FOR A30 HEA 'PDB Name' FOR A30 TRUNC;
COL begin_time FOR A7 HEA 'Month';
COL aas_db FOR 999,990.000 HEA 'Avg Active|Sessions|On Database';
COL aas_cpu FOR 999,990.000 HEA 'Avg Active|Sessions|On CPU';
COL executions FOR 999,999,999,999,990 HEA 'Total|Executions|By Month';
COL avg_et_ms_pe FOR 99,999,990.000 HEA 'Avg Elapsed|Time (ms)|Per Execution';
COL avg_cpu_ms_pe FOR 99,999,990.000 HEA 'Avg CPU|Time (ms)|Per Execution';
COL avg_bg_pe FOR 999,999,999,990 HEA 'Avg|Buffer Gets|Per Execution';
COL avg_disk_pe FOR 999,999,999,990 HEA 'Avg|Disk Reads|Per Execution';
COL avg_row FOR 999,999,990.000 HEA 'Avg Rows|Processed|Per Execution';
COL avg_et_ms_pr FOR 99,999,990.000 HEA 'Avg Elapsed|Time (ms)|Per Row Proc';
COL avg_cpu_ms_pr FOR 99,999,990.000 HEA 'Avg CPU|Time (ms)|Per Row Proc';
COL avg_bg_pr FOR 999,999,999,990 HEA 'Avg|Buffer Gets|Per Row Proc';
COL avg_disk_pr FOR 999,999,999,990 HEA 'Avg|Disk Reads|Per Row Proc';
COL plans FOR 99990 HEA 'Total|Plans';
COL pdbs FOR 9990 HEA 'Total|PDBs';
COL schemas FOR 999,990 HEA 'Total|Schemas';
--
BREAK ON REPORT;
COMPUTE AVG LABEL 'Average' OF aas_db aas_cpu executions avg_et_ms_pe avg_cpu_ms_pe avg_bg_pe avg_disk_pe avg_row avg_et_ms_pr avg_cpu_ms_pr avg_bg_pr avg_disk_pr plans pdbs schemas ON REPORT;
--
PRO
PRO SQL STATS BY MONTH (cdb_hist_sqlstat)
PRO ~~~~~~~~~~~~~~~~~~
SELECT TO_CHAR(TRUNC(s.begin_interval_time, 'MM'), 'YYYY-MM') AS begin_time,
       h.con_id,
       c.name AS pdb_name,
       '|' AS "|",
       SUM(h.elapsed_time_delta)/1e6/(24*3600*(CAST(MAX(s.end_interval_time) AS DATE) - CAST(MIN(s.begin_interval_time) AS DATE))) AS aas_db,
       SUM(h.cpu_time_delta)/1e6/(24*3600*(CAST(MAX(s.end_interval_time) AS DATE) - CAST(MIN(s.begin_interval_time) AS DATE))) AS aas_cpu,
       CASE WHEN SUM(h.cpu_time_delta)/1e6/(24*3600*(CAST(MAX(s.end_interval_time) AS DATE) - CAST(MIN(s.begin_interval_time) AS DATE))) > &&cs_aas_on_cpu_per_sql. THEN '*' END AS h,
       '|' AS "|",
       SUM(h.executions_delta) AS executions,
       SUM(h.elapsed_time_delta)/NULLIF(SUM(h.executions_delta), 0)/1e3 AS avg_et_ms_pe,
       SUM(h.cpu_time_delta)/NULLIF(SUM(h.executions_delta), 0)/1e3 AS avg_cpu_ms_pe,
       SUM(h.buffer_gets_delta)/NULLIF(SUM(h.executions_delta), 0) AS avg_bg_pe,
       SUM(h.disk_reads_delta)/NULLIF(SUM(h.executions_delta), 0) AS avg_disk_pe,
       SUM(h.rows_processed_delta)/NULLIF(SUM(h.executions_delta), 0) AS avg_row,
       '|' AS "|",
       SUM(h.elapsed_time_delta)/NULLIF(SUM(h.rows_processed_delta), 0)/1e3 AS avg_et_ms_pr,
       SUM(h.cpu_time_delta)/NULLIF(SUM(h.rows_processed_delta), 0)/1e3 AS avg_cpu_ms_pr,
       CASE WHEN SUM(h.cpu_time_delta)/NULLIF(SUM(h.rows_processed_delta), 0)/1e3 > &&cs_cpu_ms_per_row. THEN '*' END AS h,
       SUM(h.buffer_gets_delta)/NULLIF(SUM(h.rows_processed_delta), 0) AS avg_bg_pr,
       CASE WHEN SUM(h.buffer_gets_delta)/NULLIF(SUM(h.rows_processed_delta), 0) > &&cs_buffer_gets_per_row. THEN '*' END AS h,
       SUM(h.disk_reads_delta)/NULLIF(SUM(h.rows_processed_delta), 0) AS avg_disk_pr,
       CASE WHEN SUM(h.disk_reads_delta)/NULLIF(SUM(h.rows_processed_delta), 0) > &&cs_disk_reads_per_row. THEN '*' END AS h,
       '|' AS "|",
       COUNT (DISTINCT h.plan_hash_value) AS plans,
       COUNT (DISTINCT h.con_id) AS pdbs,
       COUNT (DISTINCT h.parsing_schema_name) AS schemas
  FROM cdb_hist_sqlstat h,
       dba_hist_snapshot s,
       v$containers c
 WHERE h.dbid = TO_NUMBER('&&cs_dbid.')
   AND h.instance_number = TO_NUMBER('&&cs_instance_number.')
   AND h.sql_id = '&&cs_sql_id.'
   AND s.snap_id = h.snap_id
   AND s.dbid = h.dbid
   AND s.instance_number = h.instance_number
   AND c.con_id = h.con_id
 GROUP BY
       TRUNC(s.begin_interval_time, 'MM'),
       h.con_id,
       c.name
 ORDER BY
       TRUNC(s.begin_interval_time, 'MM'),
       h.con_id
/       
PRO Note (H) = "*" means High. Expecting less than &&cs_cpu_ms_per_row. CPU ms per row processed, less than &&cs_buffer_gets_per_row. Buffer Gets per row processed, and less than &&cs_disk_reads_per_row. Disk Reads per row processed.
--
COL begin_time FOR A10 HEA 'Begin Date';
COL end_time FOR A10 HEA 'End Date';
COL executions FOR 999,999,999,999,990 HEA 'Total|Executions|By Week';
--
PRO
PRO SQL STATS BY WEEK (cdb_hist_sqlstat)
PRO ~~~~~~~~~~~~~~~~~
SELECT TO_CHAR(TRUNC(s.begin_interval_time, 'D'), 'YYYY-MM-DD') AS begin_time,
       TO_CHAR(TRUNC(s.begin_interval_time, 'D') + 6, 'YYYY-MM-DD') AS end_time,
       h.con_id,
       c.name AS pdb_name,
       '|' AS "|",
       SUM(h.elapsed_time_delta)/1e6/(24*3600*(CAST(MAX(s.end_interval_time) AS DATE) - CAST(MIN(s.begin_interval_time) AS DATE))) AS aas_db,
       SUM(h.cpu_time_delta)/1e6/(24*3600*(CAST(MAX(s.end_interval_time) AS DATE) - CAST(MIN(s.begin_interval_time) AS DATE))) AS aas_cpu,
       CASE WHEN SUM(h.cpu_time_delta)/1e6/(24*3600*(CAST(MAX(s.end_interval_time) AS DATE) - CAST(MIN(s.begin_interval_time) AS DATE))) > &&cs_aas_on_cpu_per_sql. THEN '*' END AS h,
       '|' AS "|",
       SUM(h.executions_delta) AS executions,
       SUM(h.elapsed_time_delta)/NULLIF(SUM(h.executions_delta), 0)/1e3 AS avg_et_ms_pe,
       SUM(h.cpu_time_delta)/NULLIF(SUM(h.executions_delta), 0)/1e3 AS avg_cpu_ms_pe,
       SUM(h.buffer_gets_delta)/NULLIF(SUM(h.executions_delta), 0) AS avg_bg_pe,
       SUM(h.disk_reads_delta)/NULLIF(SUM(h.executions_delta), 0) AS avg_disk_pe,
       SUM(h.rows_processed_delta)/NULLIF(SUM(h.executions_delta), 0) AS avg_row,
       '|' AS "|",
       SUM(h.elapsed_time_delta)/NULLIF(SUM(h.rows_processed_delta), 0)/1e3 AS avg_et_ms_pr,
       SUM(h.cpu_time_delta)/NULLIF(SUM(h.rows_processed_delta), 0)/1e3 AS avg_cpu_ms_pr,
       CASE WHEN SUM(h.cpu_time_delta)/NULLIF(SUM(h.rows_processed_delta), 0)/1e3 > &&cs_cpu_ms_per_row. THEN '*' END AS h,
       SUM(h.buffer_gets_delta)/NULLIF(SUM(h.rows_processed_delta), 0) AS avg_bg_pr,
       CASE WHEN SUM(h.buffer_gets_delta)/NULLIF(SUM(h.rows_processed_delta), 0) > &&cs_buffer_gets_per_row. THEN '*' END AS h,
       SUM(h.disk_reads_delta)/NULLIF(SUM(h.rows_processed_delta), 0) AS avg_disk_pr,
       CASE WHEN SUM(h.disk_reads_delta)/NULLIF(SUM(h.rows_processed_delta), 0) > &&cs_disk_reads_per_row. THEN '*' END AS h,
       '|' AS "|",
       COUNT (DISTINCT h.plan_hash_value) AS plans,
       COUNT (DISTINCT h.con_id) AS pdbs,
       COUNT (DISTINCT h.parsing_schema_name) AS schemas
  FROM cdb_hist_sqlstat h,
       dba_hist_snapshot s,
       v$containers c
 WHERE h.dbid = TO_NUMBER('&&cs_dbid.')
   AND h.instance_number = TO_NUMBER('&&cs_instance_number.')
   AND h.sql_id = '&&cs_sql_id.'
   AND s.snap_id = h.snap_id
   AND s.dbid = h.dbid
   AND s.instance_number = h.instance_number
   AND c.con_id = h.con_id
 GROUP BY
       TRUNC(s.begin_interval_time, 'D'),
       h.con_id,
       c.name
 ORDER BY
       TRUNC(s.begin_interval_time, 'D'),
       h.con_id
/       
PRO Note (H) = "*" means High. Expecting less than &&cs_cpu_ms_per_row. CPU ms per row processed, less than &&cs_buffer_gets_per_row. Buffer Gets per row processed, and less than &&cs_disk_reads_per_row. Disk Reads per row processed.
--
COL begin_time FOR A10 HEA 'Date';
COL executions FOR 999,999,999,999,990 HEA 'Total|Executions|By Day';
--
PRO
PRO SQL STATS BY DAY (cdb_hist_sqlstat)
PRO ~~~~~~~~~~~~~~~~
SELECT TO_CHAR(TRUNC(s.begin_interval_time, 'DD'), 'YYYY-MM-DD') AS begin_time,
       h.con_id,
       c.name AS pdb_name,
       '|' AS "|",
       SUM(h.elapsed_time_delta)/1e6/(24*3600*(CAST(MAX(s.end_interval_time) AS DATE) - CAST(MIN(s.begin_interval_time) AS DATE))) AS aas_db,
       SUM(h.cpu_time_delta)/1e6/(24*3600*(CAST(MAX(s.end_interval_time) AS DATE) - CAST(MIN(s.begin_interval_time) AS DATE))) AS aas_cpu,
       CASE WHEN SUM(h.cpu_time_delta)/1e6/(24*3600*(CAST(MAX(s.end_interval_time) AS DATE) - CAST(MIN(s.begin_interval_time) AS DATE))) > &&cs_aas_on_cpu_per_sql. THEN '*' END AS h,
       '|' AS "|",
       SUM(h.executions_delta) AS executions,
       SUM(h.elapsed_time_delta)/NULLIF(SUM(h.executions_delta), 0)/1e3 AS avg_et_ms_pe,
       SUM(h.cpu_time_delta)/NULLIF(SUM(h.executions_delta), 0)/1e3 AS avg_cpu_ms_pe,
       SUM(h.buffer_gets_delta)/NULLIF(SUM(h.executions_delta), 0) AS avg_bg_pe,
       SUM(h.disk_reads_delta)/NULLIF(SUM(h.executions_delta), 0) AS avg_disk_pe,
       SUM(h.rows_processed_delta)/NULLIF(SUM(h.executions_delta), 0) AS avg_row,
       '|' AS "|",
       SUM(h.elapsed_time_delta)/NULLIF(SUM(h.rows_processed_delta), 0)/1e3 AS avg_et_ms_pr,
       SUM(h.cpu_time_delta)/NULLIF(SUM(h.rows_processed_delta), 0)/1e3 AS avg_cpu_ms_pr,
       CASE WHEN SUM(h.cpu_time_delta)/NULLIF(SUM(h.rows_processed_delta), 0)/1e3 > &&cs_cpu_ms_per_row. THEN '*' END AS h,
       SUM(h.buffer_gets_delta)/NULLIF(SUM(h.rows_processed_delta), 0) AS avg_bg_pr,
       CASE WHEN SUM(h.buffer_gets_delta)/NULLIF(SUM(h.rows_processed_delta), 0) > &&cs_buffer_gets_per_row. THEN '*' END AS h,
       SUM(h.disk_reads_delta)/NULLIF(SUM(h.rows_processed_delta), 0) AS avg_disk_pr,
       CASE WHEN SUM(h.disk_reads_delta)/NULLIF(SUM(h.rows_processed_delta), 0) > &&cs_disk_reads_per_row. THEN '*' END AS h,
       '|' AS "|",
       COUNT (DISTINCT h.plan_hash_value) AS plans,
       COUNT (DISTINCT h.con_id) AS pdbs,
       COUNT (DISTINCT h.parsing_schema_name) AS schemas
  FROM cdb_hist_sqlstat h,
       dba_hist_snapshot s,
       v$containers c
 WHERE h.dbid = TO_NUMBER('&&cs_dbid.')
   AND h.instance_number = TO_NUMBER('&&cs_instance_number.')
   AND h.sql_id = '&&cs_sql_id.'
   AND s.snap_id = h.snap_id
   AND s.dbid = h.dbid
   AND s.instance_number = h.instance_number
   AND c.con_id = h.con_id
 GROUP BY
       TRUNC(s.begin_interval_time, 'DD'),
       h.con_id,
       c.name
 ORDER BY
       TRUNC(s.begin_interval_time, 'DD'),
       h.con_id
/       
PRO Note (H) = "*" means High. Expecting less than &&cs_cpu_ms_per_row. CPU ms per row processed, less than &&cs_buffer_gets_per_row. Buffer Gets per row processed, and less than &&cs_disk_reads_per_row. Disk Reads per row processed.
--
COL begin_time FOR A13 HEA 'Begin Time';
COL end_time FOR A13 HEA 'End Time';
COL executions FOR 999,999,999,999,990 HEA 'Total|Executions|By Hour';
--
PRO
PRO SQL STATS BY HOUR (cdb_hist_sqlstat)
PRO ~~~~~~~~~~~~~~~~~
SELECT TO_CHAR(TRUNC(s.begin_interval_time, 'HH24'), 'YYYY-MM-DD"T"HH24') AS begin_time,
       TO_CHAR(TRUNC(s.begin_interval_time, 'HH24') + (1/24), 'YYYY-MM-DD"T"HH24') AS end_time,
       h.con_id,
       c.name AS pdb_name,
       '|' AS "|",
       SUM(h.elapsed_time_delta)/1e6/(24*3600*(CAST(MAX(s.end_interval_time) AS DATE) - CAST(MIN(s.begin_interval_time) AS DATE))) AS aas_db,
       SUM(h.cpu_time_delta)/1e6/(24*3600*(CAST(MAX(s.end_interval_time) AS DATE) - CAST(MIN(s.begin_interval_time) AS DATE))) AS aas_cpu,
       CASE WHEN SUM(h.cpu_time_delta)/1e6/(24*3600*(CAST(MAX(s.end_interval_time) AS DATE) - CAST(MIN(s.begin_interval_time) AS DATE))) > &&cs_aas_on_cpu_per_sql. THEN '*' END AS h,
       '|' AS "|",
       SUM(h.executions_delta) AS executions,
       SUM(h.elapsed_time_delta)/NULLIF(SUM(h.executions_delta), 0)/1e3 AS avg_et_ms_pe,
       SUM(h.cpu_time_delta)/NULLIF(SUM(h.executions_delta), 0)/1e3 AS avg_cpu_ms_pe,
       SUM(h.buffer_gets_delta)/NULLIF(SUM(h.executions_delta), 0) AS avg_bg_pe,
       SUM(h.disk_reads_delta)/NULLIF(SUM(h.executions_delta), 0) AS avg_disk_pe,
       SUM(h.rows_processed_delta)/NULLIF(SUM(h.executions_delta), 0) AS avg_row,
       '|' AS "|",
       SUM(h.elapsed_time_delta)/NULLIF(SUM(h.rows_processed_delta), 0)/1e3 AS avg_et_ms_pr,
       SUM(h.cpu_time_delta)/NULLIF(SUM(h.rows_processed_delta), 0)/1e3 AS avg_cpu_ms_pr,
       CASE WHEN SUM(h.cpu_time_delta)/NULLIF(SUM(h.rows_processed_delta), 0)/1e3 > &&cs_cpu_ms_per_row. THEN '*' END AS h,
       SUM(h.buffer_gets_delta)/NULLIF(SUM(h.rows_processed_delta), 0) AS avg_bg_pr,
       CASE WHEN SUM(h.buffer_gets_delta)/NULLIF(SUM(h.rows_processed_delta), 0) > &&cs_buffer_gets_per_row. THEN '*' END AS h,
       SUM(h.disk_reads_delta)/NULLIF(SUM(h.rows_processed_delta), 0) AS avg_disk_pr,
       CASE WHEN SUM(h.disk_reads_delta)/NULLIF(SUM(h.rows_processed_delta), 0) > &&cs_disk_reads_per_row. THEN '*' END AS h,
       '|' AS "|",
       COUNT (DISTINCT h.plan_hash_value) AS plans,
       COUNT (DISTINCT h.con_id) AS pdbs,
       COUNT (DISTINCT h.parsing_schema_name) AS schemas
  FROM cdb_hist_sqlstat h,
       dba_hist_snapshot s,
       v$containers c
 WHERE h.dbid = TO_NUMBER('&&cs_dbid.')
   AND h.instance_number = TO_NUMBER('&&cs_instance_number.')
   AND h.sql_id = '&&cs_sql_id.'
   AND s.snap_id = h.snap_id
   AND s.dbid = h.dbid
   AND s.instance_number = h.instance_number
   AND c.con_id = h.con_id
 GROUP BY
       TRUNC(s.begin_interval_time, 'HH24'),
       h.con_id,
       c.name
 ORDER BY
       TRUNC(s.begin_interval_time, 'HH24'),
       h.con_id
/       
PRO Note (H) = "*" means High. Expecting less than &&cs_cpu_ms_per_row. CPU ms per row processed, less than &&cs_buffer_gets_per_row. Buffer Gets per row processed, and less than &&cs_disk_reads_per_row. Disk Reads per row processed.
--
CLEAR BREAK COMPUTE;
--
