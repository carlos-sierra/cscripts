----------------------------------------------------------------------------------------
--
-- File name:   cs_dbms_stats_operations.sql
--
-- Purpose:     Generate DBMS_STATS.report_stats_operations
--
-- Author:      Carlos Sierra
--
-- Version:     2021/07/30
--
-- Usage:       Execute connected to CDB or PDB.
--
--              Enter optional parameters when requested.
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @cs_dbms_stats_operations.sql
--
-- Notes:       Developed and tested on 12.1.0.2.
--
---------------------------------------------------------------------------------------
--
@@cs_internal/cs_primary.sql
@@cs_internal/cs_cdb_warn.sql
@@cs_internal/cs_set.sql
@@cs_internal/cs_def.sql
@@cs_internal/cs_file_prefix.sql
--
DEF cs_script_name = 'cs_dbms_stats_operations';
--
SELECT '&&cs_file_prefix._&&cs_script_name.' cs_file_name FROM DUAL;
--
DEF cs_hours_range_default = '24';
@@cs_internal/cs_sample_time_from_and_to.sql
@@cs_internal/cs_snap_id_from_and_to.sql
--
PRO 3. Detail Level: [{BASIC}|TYPICAL|ALL]
DEF cs2_detail_level = '&3.';
UNDEF 3;
COL cs2_detail_level NEW_V cs2_detail_level NOPRI;
SELECT CASE WHEN UPPER(TRIM('&&cs2_detail_level.')) IN ('TYPICAL','BASIC','ALL') THEN UPPER(TRIM('&&cs2_detail_level.')) ELSE 'BASIC' END AS cs2_detail_level FROM DUAL
/
--
PRO
PRO 4. Format: [{TEXT}|HTML|XML]
DEF cs2_format = '&4.';
UNDEF 4;
COL cs2_format NEW_V cs2_format NOPRI;
SELECT CASE WHEN UPPER(TRIM('&&cs2_format.')) IN ('TEXT','HTML','XML') THEN UPPER(TRIM('&&cs2_format.')) ELSE 'TEXT' END AS cs2_format FROM DUAL
/
COL cs2_file_suffix NEW_V cs2_file_suffix NOPRI;
SELECT CASE '&&cs2_format.' WHEN 'TEXT' THEN 'txt' WHEN 'HTML' THEN 'html' WHEN 'XML' THEN 'xml' ELSE 'txt' END AS cs2_file_suffix FROM DUAL
/
--
@@cs_internal/cs_spool_head.sql
PRO SQL> @&&cs_script_name..sql "&&cs_sample_time_from." "&&cs_sample_time_to." "&&cs2_detail_level." "&&cs2_format."
@@cs_internal/cs_spool_id.sql
--
@@cs_internal/cs_spool_id_sample_time.sql
--
PRO DETAIL_LEVEL : "&&cs2_detail_level."
PRO FORMAT       : "&&cs2_format."
PRO
--
-- opens new spool if html or xml, or continues with existing if txt
SET HEA OFF PAGES 0;
SPO &&cs_file_name..&&cs2_file_suffix. APP
--
SELECT DBMS_STATS.report_stats_operations(detail_level => '&&cs2_detail_level.', format => '&&cs2_format.', since => TO_TIMESTAMP('&&cs_sample_time_from.', '&&cs_datetime_full_format.'), until => TO_TIMESTAMP('&&cs_sample_time_to.', '&&cs_datetime_full_format.')) FROM DUAL
/
--
SPO OFF;
SET HEA ON PAGES 100;
HOS chmod 644 &&cs_file_name..&&cs2_file_suffix.
-- continues with original spool
SPO &&cs_file_name..txt APP
--
PRO
PRO SQL> @&&cs_script_name..sql "&&cs_sample_time_from." "&&cs_sample_time_to." "&&cs2_detail_level." "&&cs2_format."
--
@@cs_internal/cs_spool_tail.sql
@@cs_internal/cs_undef.sql
@@cs_internal/cs_reset.sql
--