----------------------------------------------------------------------------------------
--
-- File name:   cs_sql_bind_capture.sql
--
-- Purpose:     SQL Bind Capture for given SQL_ID
--
-- Author:      Carlos Sierra
--
-- Version:     2021/07/21
--
-- Usage:       Execute connected to PDB.
--
--              Enter SQL_ID when requested.
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @cs_sql_bind_capture.sql
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
DEF cs_script_name = 'cs_sql_bind_capture';
DEF cs_hours_range_default = '168';
--
@@cs_internal/&&cs_set_container_to_cdb_root.
--
COL cs_hours_range_default NEW_V cs_hours_range_default NOPRI;
SELECT TRIM(TO_CHAR(LEAST(TRUNC((SYSDATE - MIN(snap_time)) * 24), TO_NUMBER('&&cs_hours_range_default.')))) AS cs_hours_range_default FROM &&cs_tools_schema..iod_sql_bind_capture
/
--
@@cs_internal/&&cs_set_container_to_curr_pdb.
--
@@cs_internal/cs_sample_time_from_and_to.sql
@@cs_internal/cs_snap_id_from_and_to.sql
--
PRO 3. SQL_ID: 
DEF cs_sql_id = '&3.';
UNDEF 3;
--
SELECT '&&cs_file_prefix._&&cs_script_name._&&cs_sql_id.' cs_file_name FROM DUAL;
--
@@cs_internal/cs_signature.sql
--
@@cs_internal/cs_spool_head.sql
PRO SQL> @&&cs_script_name..sql "&&cs_sample_time_from." "&&cs_sample_time_to." "&&cs_sql_id."
@@cs_internal/cs_spool_id.sql
--
@@cs_internal/cs_spool_id_sample_time.sql
--
PRO SQL_ID       : &&cs_sql_id.
PRO SQLHV        : &&cs_sqlid.
PRO SIGNATURE    : &&cs_signature.
PRO SQL_HANDLE   : &&cs_sql_handle.
PRO APPLICATION  : &&cs_application_category.
--
SET HEA OFF;
PRINT :cs_sql_text
SET HEA ON;
--
@@cs_internal/&&cs_set_container_to_cdb_root.
--
COL last_captured FOR A19;
COL child_number FOR 999999 HEA 'CHILD';
COL position FOR 990 HEA 'POS';
COL datatype_string FOR A20 HEA 'TYPE';
COL name_and_value FOR A200;
--
BRE ON last_captured SKIP PAGE ON child_number;
PRO
PRO SQL BIND CAPTURE (&&cs_tools_schema..iod_sql_bind_capture)
PRO ~~~~~~~~~~~~~~~~
--
SELECT  TO_CHAR(c.last_captured, '&&cs_datetime_full_format.') AS last_captured,
        c.child_number,
        c.position, 
        c.datatype_string,
        c.name||' = '||c.value_string AS name_and_value
  FROM &&cs_tools_schema..iod_sql_bind_capture c
 WHERE c.snap_time BETWEEN TO_DATE('&&cs_sample_time_from.', '&&cs_datetime_full_format.') AND TO_DATE('&&cs_sample_time_to.', '&&cs_datetime_full_format.')
   AND c.sql_id = '&&cs_sql_id.'
 ORDER BY
       c.last_captured,
       c.child_number,
       c.position
/
--
PRO
PRO SQL> @&&cs_script_name..sql "&&cs_sample_time_from." "&&cs_sample_time_to." "&&cs_sql_id."
--
@@cs_internal/cs_spool_tail.sql
--
@@cs_internal/&&cs_set_container_to_curr_pdb.
--
@@cs_internal/cs_undef.sql
@@cs_internal/cs_reset.sql
--