PRO DATE_TIME_UTC: &&cs_date_time.Z
PRO REFERENCE    : &&cs_extended_reference.
PRO JDBC_STRING  : &&cs_easy_connect_string.
PRO HOST_NAME    : &&cs_host_name. CPU_UTIL:&&cs_cpu_util_perc. LOAD:&&cs_cpu_load. CORES:&&cs_num_cpu_cores. THREADS:&&cs_num_cpus. &&cs_host_shape. &&cs_disk_config.
PRO CDB_NAME     : &&cs_db_name_u. CPU_COUNT:&&cs_cpu_count. AVG_RUN_SESS:&&cs_avg_running_sessions_cdb. DBRM_PLAN:&&cs_resource_manager_plan. &&cs_containers_count. VERSION:&&cs_db_version. STARTUP:&&cs_startup_time. &&cs_blackout_times.
PRO PDB_NAME     : &&cs_con_name. CON_ID:&&cs_con_id. ALLOTTED_CPU:&&cs_allotted_cpu. AVG_RUN_SESS:&&cs_avg_running_sessions_pdb. OPEN_MODE:&&cs_pdb_open_mode. CREATED:&&pdb_creation.
PRO APPLICATION  : &&cs_kiev_version. SCHEMA:&&cs_schema_name.
PRO SCRIPT_NAME  : &&cs_script_acronym.&&cs_script_name..sql
@@&&list_dg_members_script.