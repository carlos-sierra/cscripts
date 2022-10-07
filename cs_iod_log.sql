----------------------------------------------------------------------------------------
--
-- File name:   cs_iod_log.sql
--
-- Purpose:     IOD PL/SQL Libraries Log
--
-- Author:      Carlos Sierra
--
-- Version:     2021/06/04
--
-- Usage:       Execute connected to CDB or PDB.
--
--              Enter optional parameters when requested.
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @cs_iod_log.sql
--
-- Notes:       Developed and tested on 12.1.0.2 and 19c.
--
---------------------------------------------------------------------------------------
--
@@cs_internal/cs_primary.sql
@@cs_internal/cs_cdb_warn.sql
@@cs_internal/cs_set.sql
@@cs_internal/cs_def.sql
@@cs_internal/cs_file_prefix.sql
--
DEF cs_script_name = 'cs_iod_log';
--
SELECT '&&cs_file_prefix._&&cs_script_name.' cs_file_name FROM DUAL;
--
DEF cs_hours_range_default = '24';
@@cs_internal/cs_sample_time_from_and_to.sql
@@cs_internal/cs_snap_id_from_and_to.sql
--
@@cs_internal/&&cs_set_container_to_cdb_root.
--
COL log_entries FOR 999,999,990;
COL log_name FOR A128;
COL min_log_time FOR A23;
COL max_log_time FOR A23;
--
SELECT COUNT(*) AS log_entries, MIN(log_time) AS min_log_time, MAX(log_time) AS max_log_time, UPPER(log_name) AS log_name
  FROM &&cs_tools_schema..iod_log_msg
 WHERE log_time BETWEEN TO_TIMESTAMP('&&cs_sample_time_from.', '&&cs_datetime_full_format.') AND TO_TIMESTAMP('&&cs_sample_time_to.', '&&cs_datetime_full_format.')
 GROUP BY UPPER(log_name) 
 ORDER BY UPPER(log_name) 
/
@@cs_internal/&&cs_set_container_to_curr_pdb.
--
PRO
PRO 3. Log Name (opt): 
DEF cs2_log_name = '&3.';
UNDEF 3;
--
PRO
PRO 4. Message LIKE predicate (opt): 
DEF cs2_filter = '&4.';
UNDEF 4;
--
PRO
PRO 5. Message NOT LIKE predicate (opt): 
DEF cs2_anti_filter = '&5.';
UNDEF 5;
--
@@cs_internal/cs_spool_head.sql
PRO SQL> @&&cs_script_name..sql "&&cs_sample_time_from." "&&cs_sample_time_to." "&&cs2_log_name." "&&cs2_filter." "&&cs2_anti_filter."
@@cs_internal/cs_spool_id.sql
--
@@cs_internal/cs_spool_id_sample_time.sql
--
PRO LOG_NAME     : "&&cs2_log_name."
PRO LIKE_PRED    : "&&cs2_filter."
PRO NOT_LIKE_PRED: "&&cs2_anti_filter."
--
@@cs_internal/&&cs_set_container_to_cdb_root.
--
COL log_time FOR A23;
COL gap_secs FOR 999,990;
COL log_level FOR A9;
COL log_name FOR A128;
COL log_msg FOR A256;
--
SELECT log_time, (CAST(log_time AS DATE) - CAST(LAG(log_time) OVER(ORDER BY log_time) AS DATE)) * 24 * 3600 AS gap_secs,
       log_level, log_msg, log_name --, sess_osuser, sess_machine, sess_username, sess_schemaname
  FROM &&cs_tools_schema..iod_log_msg
 WHERE log_time BETWEEN TO_TIMESTAMP('&&cs_sample_time_from.', '&&cs_datetime_full_format.') AND TO_TIMESTAMP('&&cs_sample_time_to.', '&&cs_datetime_full_format.')
   AND UPPER(log_name) LIKE '%'||UPPER(NVL('&&cs2_log_name.', log_name))||'%'
   AND UPPER(log_msg) LIKE UPPER('%&&cs2_filter.%')
   AND ('&&cs2_anti_filter.' IS NULL OR UPPER(log_msg) NOT LIKE UPPER('%&&cs2_anti_filter.%'))
 ORDER BY log_time
/
--
PRO
PRO SQL> @&&cs_script_name..sql "&&cs_sample_time_from." "&&cs_sample_time_to." "&&cs2_log_name." "&&cs2_filter." "&&cs2_anti_filter."
--
@@cs_internal/cs_spool_tail.sql
--
@@cs_internal/&&cs_set_container_to_curr_pdb.
--
@@cs_internal/cs_undef.sql
@@cs_internal/cs_reset.sql
--