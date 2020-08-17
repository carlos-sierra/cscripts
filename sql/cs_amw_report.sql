----------------------------------------------------------------------------------------
--
-- File name:   cs_amw_report.sql
--
-- Purpose:     Automatic Maintenance Window Report
--
-- Author:      Carlos Sierra
--
-- Version:     2020/07/28
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
COL attribute_name FOR A30;
COL value FOR A30;
PRO
PRO dba_scheduler_global_attribute
PRO ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
SELECT c.name AS pdb_name, t.attribute_name, t.value FROM cdb_scheduler_global_attribute t, v$containers c WHERE t.attribute_name IN ('DEFAULT_TIMEZONE', 'LOG_HISTORY', 'MAX_JOB_SLAVE_PROCESSES') AND c.con_id = t.con_id ORDER BY c.name, t.attribute_name;
--
COL pdb_name FOR A30 TRUNC;
COL task_name FOR A30;
COL parameter_name FOR A30;
COL parameter_value FOR A30;
PRO
PRO dba_advisor_parameters
PRO ~~~~~~~~~~~~~~~~~~~~~~
SELECT c.name AS pdb_name, t.task_name, t.parameter_name, t.parameter_value FROM cdb_advisor_parameters t, v$containers c WHERE t.task_name IN ('SYS_AUTO_SPM_EVOLVE_TASK', 'SYS_AI_SPM_EVOLVE_TASK', 'SYS_AUTO_SQL_TUNING_TASK') AND t.parameter_name IN ('ACCEPT_PLANS', 'ACCEPT_SQL_PROFILES') AND c.con_id = t.con_id ORDER BY c.name, t.task_name, t.parameter_name, t.parameter_value;
--
COL pdb_name FOR A30 TRUNC;
COL task_name FOR A30;
COL enabled FOR A8;
PRO
PRO dba_autotask_schedule_control
PRO ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
SELECT c.name AS pdb_name, t.task_name, t.enabled FROM cdb_autotask_schedule_control t, v$containers c WHERE t.task_name IN ('Auto SPM Task', 'Auto STS Capture Task') AND c.con_id = t.con_id ORDER BY c.name, t.task_name;
--
COL pdb_name FOR A30 TRUNC;
COL client_name FOR A40;
COL status FOR A8;
PRO
PRO dba_autotask_client
PRO ~~~~~~~~~~~~~~~~~~~
SELECT c.name AS pdb_name, t.client_name, t.status FROM cdb_autotask_client t, v$containers c WHERE t.client_name IN ('auto optimizer stats collection', 'sql tuning advisor', 'auto space advisor') AND c.con_id = t.con_id ORDER BY c.name, t.client_name;
--
COL pdb_name FOR A30 TRUNC;
COL window_name FOR A20;
COL enabled FOR A8;
COL resource_plan FOR A30;
COL duration FOR A20;
COL repeat_interval FOR A90;
PRO
PRO dba_scheduler_windows
PRO ~~~~~~~~~~~~~~~~~~~~~
SELECT c.name AS pdb_name, t.window_name, t.enabled, t.resource_plan, t.duration, t.repeat_interval FROM cdb_scheduler_windows t, v$containers c WHERE c.con_id = t.con_id ORDER BY c.name, t.window_name;
--
COL pdb_name FOR A30 TRUNC;
COL window_name FOR A20;
COL optimizer_stats FOR A20;
COL sql_tune_advisor FOR A20;
COL segment_advisor FOR A20;
PRO
PRO dba_autotask_window_clients
PRO ~~~~~~~~~~~~~~~~~~~~~~~~~~~
SELECT c.name AS pdb_name, t.window_name, t.optimizer_stats, t.sql_tune_advisor, t.segment_advisor FROM cdb_autotask_window_clients t, v$containers c WHERE t.window_name IN ('MONDAY_WINDOW', 'TUESDAY_WINDOW', 'WEDNESDAY_WINDOW', 'THURSDAY_WINDOW', 'FRIDAY_WINDOW', 'SATURDAY_WINDOW', 'SUNDAY_WINDOW') AND c.con_id = t.con_id ORDER BY c.name, t.window_name;
--
PRO
PRO SQL> @&&cs_script_name..sql
--
@@cs_internal/cs_spool_tail.sql
@@cs_internal/cs_undef.sql
@@cs_internal/cs_reset.sql
--
