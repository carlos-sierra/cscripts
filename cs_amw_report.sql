----------------------------------------------------------------------------------------
--
-- File name:   cs_amw_report.sql
--
-- Purpose:     Automatic Maintenance Window Report
--
-- Author:      Carlos Sierra
--
-- Version:     2021/09/20
--
-- Usage:       Execute connected to CDB or PDB.
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @cs_amw_report.sql
--
-- Notes:       Developed and tested on 12.1.0.2.
--
---------------------------------------------------------------------------------------
--
@@cs_internal/cs_primary.sql
--@@cs_internal/cs_cdb_warn.sql
@@cs_internal/cs_set.sql
@@cs_internal/cs_def.sql
@@cs_internal/cs_file_prefix.sql
--
DEF cs_script_name = 'cs_amw_report';
--
SELECT '&&cs_file_prefix._&&cs_script_name.' cs_file_name FROM DUAL;
--
@@cs_internal/cs_spool_head.sql
PRO SQL> @&&cs_script_name..sql
@@cs_internal/cs_spool_id.sql
--
COL pdb_name FOR A30 TRUNC;
COL task_name FOR A30;
COL parameter_name FOR A30;
COL parameter_value FOR A30;
PRO
PRO dba_advisor_parameters
PRO ~~~~~~~~~~~~~~~~~~~~~~
-- SELECT c.name AS pdb_name, t.task_name, t.parameter_name, t.parameter_value FROM cdb_advisor_parameters t, v$containers c WHERE t.task_name IN ('SYS_AUTO_SPM_EVOLVE_TASK', 'SYS_AI_SPM_EVOLVE_TASK', 'SYS_AUTO_SQL_TUNING_TASK') AND t.parameter_name IN ('ACCEPT_PLANS', 'ACCEPT_SQL_PROFILES') AND c.con_id = t.con_id ORDER BY c.name, t.task_name, t.parameter_name, t.parameter_value;
@@cs_internal/cs_pr_internal "SELECT c.name AS pdb_name, t.* FROM cdb_advisor_parameters t, v$containers c WHERE t.task_name LIKE ''%TASK'' AND t.parameter_name LIKE ''ACCEPT%'' AND c.con_id = t.con_id ORDER BY c.name, t.task_name, t.parameter_name, t.parameter_value"
--
-- COL pdb_name FOR A30 TRUNC;
-- COL task_name FOR A30;
-- COL enabled FOR A8;
-- PRO
-- PRO dba_autotask_schedule_control
-- PRO ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- SELECT c.name AS pdb_name, t.task_name, t.enabled FROM cdb_autotask_schedule_control t, v$containers c WHERE t.task_name IN ('Auto SPM Task', 'Auto STS Capture Task') AND c.con_id = t.con_id ORDER BY c.name, t.task_name;
-- @@cs_internal/cs_pr_internal "SELECT c.name AS pdb_name, t.* FROM cdb_autotask_schedule_control t, v$containers c WHERE t.task_name LIKE ''Auto % Task'' AND c.con_id = t.con_id ORDER BY c.name, t.task_name"
--
COL pdb_name FOR A30 TRUNC;
COL client_name FOR A40;
COL status FOR A8;
COL mean_job_duration FOR A30;
COL window_duration_last_7_days FOR A30;
COL window_duration_last_30_days FOR A30;
COL window_group FOR A20;
COL last_change FOR A25;
PRO
PRO dba_autotask_client
PRO ~~~~~~~~~~~~~~~~~~~
-- SELECT c.name AS pdb_name, t.client_name, t.status, t.window_group, t.mean_job_duration, t.window_duration_last_7_days, t.window_duration_last_30_days, t.last_change FROM cdb_autotask_client t, v$containers c WHERE t.client_name IN ('auto optimizer stats collection', 'sql tuning advisor', 'auto space advisor') AND c.con_id = t.con_id ORDER BY c.name, t.client_name;
@@cs_internal/cs_pr_internal "SELECT c.name AS pdb_name, t.* FROM cdb_autotask_client t, v$containers c WHERE c.con_id = t.con_id ORDER BY c.name, t.client_name"
--
COL pdb_name FOR A30 TRUNC;
COL client_name FOR A40;
COL status FOR A8;
COL window_start_time FOR A30;
COL window_end_time FOR A30;
COL window_duration FOR A30;
COL window_name FOR A20;
PRO
PRO dba_autotask_client_history
PRO ~~~~~~~~~~~~~~~~~~~~~~~~~~~
SELECT c.name AS pdb_name, t.client_name, t.window_start_time, t.window_end_time, t.window_duration, t.window_name, t.jobs_created, t.jobs_started, t.jobs_completed FROM cdb_autotask_client_history t, v$containers c WHERE c.con_id = t.con_id ORDER BY c.name, t.client_name, t.window_start_time;
-- @@cs_internal/cs_pr_internal "SELECT c.name AS pdb_name, t.* FROM cdb_autotask_client_history t, v$containers c WHERE c.con_id = t.con_id ORDER BY c.name, t.client_name, t.window_start_time"
--
COL client_name FOR A40;
COL job_name FOR A25;
COL job_scheduler_status FOR A10 HEA 'STATUS';
COL task_name FOR A30;
COL task_operation FOR A30;
COL task_target_type FOR A20;
COL task_target_name FOR A20;
COL task_priority FOR A20;
--
ALTER SESSION SET CONTAINER = CDB$ROOT;
--
PRO
PRO dba_autotask_client_job (from CDB$ROOT)
PRO ~~~~~~~~~~~~~~~~~~~~~~~
-- SELECT client_name, job_name, job_scheduler_status, task_name, task_operation, task_target_type, task_target_name, task_priority FROM dba_autotask_client_job;
@@cs_internal/cs_pr_internal "SELECT * FROM dba_autotask_client_job"
--
ALTER SESSION SET CONTAINER = &&cs_con_name.;
--
COL pdb_name FOR A30 TRUNC;
COL client_name FOR A40;
COL window_start_time FOR A30;
COL window_duration FOR A30;
COL window_name FOR A20;
COL job_name FOR A25;
COL job_status FOR A10 HEA 'STATUS';
COL job_start_time FOR A30;
COL job_duration FOR A30;
COL delay_mins FOR 999,999,990;
COL job_error FOR 9999999990;
COL job_info FOR A80;
PRO
PRO dba_autotask_job_history
PRO ~~~~~~~~~~~~~~~~~~~~~~~~
SELECT c.name AS pdb_name, t.client_name, t.window_start_time, t.window_duration, t.window_name, t.job_name, t.job_status, t.job_start_time, t.job_duration, EXTRACT(DAY FROM (t.job_start_time - t.window_start_time) * 24 * 60) AS delay_mins, t.job_error, t.job_info 
FROM cdb_autotask_job_history t, v$containers c WHERE c.con_id = t.con_id ORDER BY c.name, t.client_name, t.window_start_time;
-- @@cs_internal/cs_pr_internal "SELECT c.name AS pdb_name, t.* FROM cdb_autotask_job_history t, v$containers c WHERE c.con_id = t.con_id ORDER BY c.name, t.client_name, t.window_start_time"
--
COL pdb_name FOR A30 TRUNC;
COL client_name FOR A40;
COL operation_name FOR A30;
COL operation_tag FOR A15;
COL attributes FOR A60;
COL status FOR A10;
COL last_change FOR A30;
COL priority_override FOR A20;
COL use_resource_estimates FOR A25;
PRO
PRO dba_autotask_operation
PRO ~~~~~~~~~~~~~~~~~~~~~~
-- SELECT c.name AS pdb_name, t.client_name, t.operation_name, t.operation_tag, t.attributes, t.status, t.last_change, t.priority_override, t.use_resource_estimates FROM cdb_autotask_operation t, v$containers c WHERE c.con_id = t.con_id ORDER BY c.name, t.client_name, t.operation_name;
@@cs_internal/cs_pr_internal "SELECT c.name AS pdb_name, t.* FROM cdb_autotask_operation t, v$containers c WHERE c.con_id = t.con_id ORDER BY c.name, t.client_name, t.operation_name"
--
COL pdb_name FOR A30 TRUNC;
COL start_time FOR A30;
COL duration FOR A30;
COL window_name FOR A20;
PRO
PRO dba_autotask_schedule
PRO ~~~~~~~~~~~~~~~~~~~~~
SELECT c.name AS pdb_name, t.start_time, t.duration, t.window_name FROM cdb_autotask_schedule t, v$containers c WHERE c.con_id = t.con_id ORDER BY c.name, t.start_time;
--@@cs_internal/cs_pr_internal "SELECT c.name AS pdb_name, t.* FROM cdb_autotask_schedule t, v$containers c WHERE c.con_id = t.con_id ORDER BY c.name, t.start_time"
--
COL pdb_name FOR A30 TRUNC;
COL status FOR A10;
COL last_change FOR A30;
PRO
PRO dba_autotask_status
PRO ~~~~~~~~~~~~~~~~~~~
-- SELECT c.name AS pdb_name, t.status, t.last_change FROM cdb_autotask_status t, v$containers c WHERE c.con_id = t.con_id ORDER BY c.name;
@@cs_internal/cs_pr_internal "SELECT c.name AS pdb_name, t.* FROM cdb_autotask_status t, v$containers c WHERE c.con_id = t.con_id ORDER BY c.name"
--
PRO
PRO dba_autotask_task
PRO ~~~~~~~~~~~~~~~~~
@@cs_internal/cs_pr_internal "SELECT c.name AS pdb_name, t.* FROM cdb_autotask_task t, v$containers c WHERE c.con_id = t.con_id ORDER BY c.name"
--
COL pdb_name FOR A30 TRUNC;
COL window_name FOR A20;
COL window_active FOR A15;
COL autotask_status FOR A15;
COL optimizer_stats FOR A20;
COL sql_tune_advisor FOR A20;
COL segment_advisor FOR A20;
COL health_monitor FOR A20;
PRO
PRO dba_autotask_window_clients
PRO ~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- SELECT c.name AS pdb_name, t.window_name, t.window_active, t.autotask_status, t.optimizer_stats, t.sql_tune_advisor, t.segment_advisor, t.health_monitor FROM cdb_autotask_window_clients t, v$containers c WHERE t.window_name IN ('MONDAY_WINDOW', 'TUESDAY_WINDOW', 'WEDNESDAY_WINDOW', 'THURSDAY_WINDOW', 'FRIDAY_WINDOW', 'SATURDAY_WINDOW', 'SUNDAY_WINDOW') AND c.con_id = t.con_id ORDER BY c.name, t.window_name;
@@cs_internal/cs_pr_internal "SELECT c.name AS pdb_name, t.* FROM cdb_autotask_window_clients t, v$containers c WHERE c.con_id = t.con_id ORDER BY c.name, t.window_name"
--
COL pdb_name FOR A30 TRUNC;
COL window_start_time FOR A30;
COL window_end_time FOR A30;
COL window_name FOR A20;
PRO
PRO dba_autotask_window_history
PRO ~~~~~~~~~~~~~~~~~~~~~~~~~~~
SELECT c.name AS pdb_name, t.window_start_time, t.window_end_time, t.window_name FROM cdb_autotask_window_history t, v$containers c WHERE c.con_id = t.con_id ORDER BY c.name, t.window_start_time;
--@@cs_internal/cs_pr_internal "SELECT c.name AS pdb_name, t.* FROM cdb_autotask_window_history t, v$containers c WHERE c.con_id = t.con_id ORDER BY c.name, t.window_start_time"
--
COL pdb_name FOR A30 TRUNC;
COL attribute_name FOR A30;
COL value FOR A30;
PRO
PRO dba_scheduler_global_attribute
PRO ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- SELECT c.name AS pdb_name, t.attribute_name, t.value FROM cdb_scheduler_global_attribute t, v$containers c WHERE t.attribute_name IN ('DEFAULT_TIMEZONE', 'LOG_HISTORY', 'MAX_JOB_SLAVE_PROCESSES', 'MAX_JOB_SLAVE_PROCESSES', 'CURRENT_OPEN_WINDOW') AND c.con_id = t.con_id ORDER BY c.name, t.attribute_name;
@@cs_internal/cs_pr_internal "SELECT c.name AS pdb_name, t.* FROM cdb_scheduler_global_attribute t, v$containers c WHERE c.con_id = t.con_id ORDER BY c.name, t.attribute_name"
--
COL pdb_name FOR A30 TRUNC;
COL group_name FOR A30;
COL comments FOR A40;
PRO
PRO dba_scheduler_groups
PRO ~~~~~~~~~~~~~~~~~~~~
-- SELECT c.name AS pdb_name, g.group_name, g.enabled, g.number_of_members, g.comments FROM cdb_scheduler_groups g, v$containers c WHERE g.group_type = 'WINDOW' AND c.con_id = g.con_id ORDER BY c.name, g.group_name;
@@cs_internal/cs_pr_internal "SELECT c.name AS pdb_name, g.* FROM cdb_scheduler_groups g, v$containers c WHERE g.group_type = ''WINDOW'' AND c.con_id = g.con_id ORDER BY c.name, g.group_name"
--
COL pdb_name FOR A30 TRUNC;
COL owner FOR A30;
COL group_name FOR A30;
COL member_name FOR A30;
PRO
PRO dba_scheduler_group_members
PRO ~~~~~~~~~~~~~~~~~~~~~~~~~~~
SELECT c.name AS pdb_name, g.owner, g.group_name, g.member_name FROM cdb_scheduler_group_members g, v$containers c WHERE c.con_id = g.con_id ORDER BY c.name, g.owner, g.group_name, g.member_name;
--@@cs_internal/cs_pr_internal "SELECT c.name AS pdb_name, g.owner, g.group_name, g.member_name FROM cdb_scheduler_group_members g, v$containers c WHERE c.con_id = g.con_id ORDER BY c.name, g.owner, g.group_name, g.member_name"
--
COL pdb_name FOR A30 TRUNC;
COL owner FOR A20;
COL job_name FOR A30;
COL job_action FOR A60;
COL start_date FOR A25;
COL repeat_interval FOR A50;
COL job_class FOR A30;
COL enabled FOR A10;
COL state FOR A10;
COL last_start_date FOR A25;
COL last_run_duration FOR A30;
COL next_run_date FOR A25;
COL comments FOR A80;
--
PRO
PRO dba_scheduler_jobs
PRO ~~~~~~~~~~~~~~~~~~
SELECT c.name AS pdb_name, s.owner, s.job_name, s.job_type, s.job_action, s.start_date, s.repeat_interval, s.job_class, s.enabled, s.state, s.last_start_date, s.last_run_duration, s.next_run_date, s.comments FROM cdb_scheduler_jobs s, v$containers c WHERE c.con_id = s.con_id ORDER BY c.name, s.owner, s.job_name;
--@@cs_internal/cs_pr_internal "SELECT c.name AS pdb_name, s.* FROM cdb_scheduler_jobs s, v$containers c WHERE c.con_id = s.con_id ORDER BY c.name, s.owner, s.job_name"
--
COL pdb_name FOR A30 TRUNC;
COL owner FOR A20;
COL program_name FOR A30;
COL program_type FOR A16;
COL program_action FOR A60;
COL enabled FOR A7;
COL detached FOR A8;
COL comments FOR A80;
PRO
PRO dba_scheduler_programs
PRO ~~~~~~~~~~~~~~~~~~~~~~
SELECT c.name AS pdb_name, s.owner, s.program_name, s.program_type, s.program_action, s.number_of_arguments, s.enabled, s.detached, s.priority, s.weight, s.comments FROM cdb_scheduler_programs s, v$containers c WHERE c.con_id = s.con_id ORDER BY c.name, s.owner, s.program_name;
--@@cs_internal/cs_pr_internal "SELECT c.name AS pdb_name, s.* FROM cdb_scheduler_programs s, v$containers c WHERE c.con_id = s.con_id ORDER BY c.name, s.owner, s.program_name"
--
COL pdb_name FOR A30 TRUNC;
COL window_name FOR A20;
COL enabled FOR A8;
COL resource_plan FOR A30;
COL duration FOR A20;
COL repeat_interval FOR A70;
COL last_start_date FOR A25;
COL next_start_date FOR A25;
PRO
PRO dba_scheduler_windows
PRO ~~~~~~~~~~~~~~~~~~~~~
-- SELECT c.name AS pdb_name, t.window_name, t.enabled, t.active, t.resource_plan, t.duration, t.repeat_interval, t.last_start_date, t.next_start_date FROM cdb_scheduler_windows t, v$containers c WHERE c.con_id = t.con_id ORDER BY c.name, t.window_name;
@@cs_internal/cs_pr_internal "SELECT c.name AS pdb_name, t.* FROM cdb_scheduler_windows t, v$containers c WHERE c.con_id = t.con_id ORDER BY c.name, t.window_name"
--
COL pdb_name FOR A30 TRUNC;
COL log_date FOR A25;
COL req_start_date FOR A25;
COL actual_start_date FOR A25;
COL window_duration FOR A20;
COL actual_duration FOR A20;
COL window_name FOR A20;
COL additional_info FOR A80;
PRO
PRO dba_scheduler_window_details
PRO ~~~~~~~~~~~~~~~~~~~~~~~~~~~~
SELECT c.name AS pdb_name, t.log_date, t.req_start_date, t.actual_start_date, t.window_duration, t.actual_duration, t.window_name, t.additional_info FROM cdb_scheduler_window_details t, v$containers c WHERE c.con_id = t.con_id ORDER BY c.name, t.log_date;
--@@cs_internal/cs_pr_internal "SELECT c.name AS pdb_name, t.* FROM cdb_scheduler_window_details t, v$containers c WHERE c.con_id = t.con_id ORDER BY c.name, t.log_date"
--
PRO
PRO SQL> @&&cs_script_name..sql
--
@@cs_internal/cs_spool_tail.sql
@@cs_internal/cs_undef.sql
@@cs_internal/cs_reset.sql
--