--
COL resource_manager_plan NEW_V resource_manager_plan FOR A30;
SELECT REPLACE(value, 'FORCE:') resource_manager_plan FROM v$parameter WHERE name = 'resource_manager_plan';
--
COL comments FOR A64 HEA 'Reference/Comments';
COL status FOR A20;
COL mandatory FOR A9;
COL pluggable_database FOR A30 HEA 'PDB Name';
COL avg_running_sessions FOR 9,990.000 HEA 'Average|Running|Sessions';
COL running_sessions_limit FOR 999,990.0 HEA 'Running|Sessions|Limit';
COL shares FOR 9,990 HEA 'Shares';
COL utilization_limit FOR 9,990 HEA 'CPUs|Allotted %'
COL parallel_server_limit FOR 9,990 HEA 'Parallel|Alloted %';
COL directive_type FOR A20 HEA 'Directive Type';
COL begin_date FOR A19 HEA 'Begin Date';
COL end_date FOR A19 HEA 'End Date';
COL reference FOR A64 HEA 'Reference/Comments';
COL snap_time HEA 'Created';
COL aas_req FOR 999,990.0 HEA 'CPUs|Required|tot';
COL aas_pct FOR 999,990 HEA 'CPUs|Required|pct%';
COL aas_avg FOR 999,990.0 HEA 'CPUs|Required|avg';
COL aas_p95 FOR 999,990 HEA 'CPUs|Required|p95';
COL aas_p99 FOR 999,990 HEA 'CPUs|Required|p99';
COL aas_avg_c FOR 999,990.0 HEA 'CPUs|Consumed|avg';
COL aas_p95_c FOR 999,990 HEA 'CPUs|Consumed|p95';
COL aas_p99_c FOR 999,990 HEA 'CPUs|Consumed|p99';
COL directive_dml FOR A3 HEA 'DML';
--
