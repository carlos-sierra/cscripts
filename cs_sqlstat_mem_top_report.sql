----------------------------------------------------------------------------------------
--
-- File name:   tsm.sql | cs_sqlstat_mem_top_report.sql
--
-- Purpose:     SQL Statistics Current (MEM) - Top SQL Report
--
-- Author:      Carlos Sierra
--
-- Version:     2021/07/19
--
-- Usage:       Execute connected to CDB or PDB.
--
--              Enter optional parameters when requested.
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @cs_sqlstat_mem_top_report.sql
--
-- Notes:       *** Requires Oracle Diagnostics Pack License ***
--
--              Developed and tested on 12.1.0.2.
--
---------------------------------------------------------------------------------------
--
@@cs_internal/cs_primary.sql
@@cs_internal/cs_cdb_warn.sql
@@cs_internal/cs_set.sql
@@cs_internal/cs_def.sql
@@cs_internal/cs_file_prefix.sql
--
DEF cs_script_name = 'cs_sqlstat_mem_top_report';
DEF cs_script_acronym = 'tsm.sql | ';
--
DEF def_top = '10';
DEF skip_module = '--';
DEF skip_parsing_schema_name = '--';
--
SELECT '&&cs_file_prefix._&&cs_script_name.' cs_file_name FROM DUAL;
--
@@cs_internal/&&cs_script_name._param.sql
--
COL cs_begin_date_from NEW_V cs_begin_date_from NOPRI;
COL cs_end_date_to NEW_V cs_end_date_to NOPRI;
SELECT TO_CHAR(CAST(MAX(end_interval_time) AS DATE), '&&cs_datetime_full_format.') AS cs_begin_date_from,
       TO_CHAR(SYSDATE, '&&cs_datetime_full_format.') AS cs_end_date_to
FROM dba_hist_snapshot
WHERE dbid = TO_NUMBER('&&cs_dbid.')
AND instance_number = TO_NUMBER('&&cs_instance_number.')
/
--
--ALTER SESSION SET container = CDB$ROOT;
--
@@cs_internal/cs_spool_head.sql
PRO SQL> @&&cs_script_name..sql "&&top_n." "&&kiev_tx." "&&sql_text_piece." "&&sql_id." 
@@cs_internal/cs_spool_id.sql
--
PRO TOP_N        : "&&top_n." [{&&def_top.}|1-100]
PRO SQL_TYPE     : "&&kiev_tx." [{*}|TP|RO|BG|IG|UN|TP,RO|TP,RO,BG]
PRO SQL_TEXT_LIKE: "%&&sql_text_piece.%"
PRO SQL_ID       : "&&sql_id."
--
@@cs_internal/cs_sqlstat_top_report_col.sql
@@cs_internal/cs_sqlstat_top_report_db_latency.sql
@@cs_internal/cs_sqlstat_top_report_cpu_latency.sql
@@cs_internal/cs_sqlstat_top_report_db_load.sql
@@cs_internal/cs_sqlstat_top_report_cpu_load.sql
@@cs_internal/cs_sqlstat_top_report_gets.sql
@@cs_internal/cs_sqlstat_top_report_reads.sql
@@cs_internal/cs_sqlstat_top_report_executions.sql
@@cs_internal/cs_sqlstat_top_report_parses.sql
@@cs_internal/cs_sqlstat_top_report_gets_pe.sql
@@cs_internal/cs_sqlstat_top_report_reads_pe.sql
@@cs_internal/cs_sqlstat_top_report_sharable_memory.sql
@@cs_internal/cs_sqlstat_top_report_version_count.sql
--
PRO
PRO SQL> @&&cs_script_name..sql "&&top_n." "&&kiev_tx." "&&sql_text_piece." "&&sql_id." 
--
@@cs_internal/cs_spool_tail.sql
--
--ALTER SESSION SET CONTAINER = &&cs_con_name.;
--
@@cs_internal/cs_undef.sql
@@cs_internal/cs_reset.sql
--