----------------------------------------------------------------------------------------
--
-- File name:   cs_sql_bind_capture_one.sql
--
-- Purpose:     SQL Bind Capture for given SQL_ID and Bind name (text report)
--
-- Author:      Carlos Sierra
--
-- Version:     2023/04/27
--
-- Usage:       Execute connected to PDB.
--
--              Enter SQL_ID and Bind name when requested.
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @cs_sql_bind_capture_one.sql
--
-- Notes:       Developed and tested on 19c
--
---------------------------------------------------------------------------------------
--
@@cs_internal/cs_primary.sql
@@cs_internal/cs_cdb_warn.sql
@@cs_internal/cs_set.sql
@@cs_internal/cs_def.sql
@@cs_internal/cs_file_prefix.sql
--
DEF cs_script_name = 'cs_sql_bind_capture_one';
DEF cs_hours_range_default = '168';
--
@@cs_internal/cs_sample_time_from_and_to.sql
@@cs_internal/cs_snap_id_from_and_to.sql
--
PRO 3. SQL_ID: 
DEF cs_sql_id = '&3.';
UNDEF 3;
--
PRO 4. Bind name: (e.g.: :1, :2, :3, :4, ...)
DEF cs_bind_name = '&4.';
UNDEF 4;
--
SELECT '&&cs_file_prefix._&&cs_script_name._&&cs_sql_id.' cs_file_name FROM DUAL;
--
@@cs_internal/cs_signature.sql
@@cs_internal/cs_spool_head.sql
PRO SQL> @&&cs_script_name..sql "&&cs_sample_time_from." "&&cs_sample_time_to." "&&cs_sql_id." "&&cs_bind_name."
@@cs_internal/cs_spool_id.sql
@@cs_internal/cs_spool_id_sample_time.sql
@@cs_internal/cs_spool_id_list_sql_id.sql
--
PRO BIND_NAME    : &&cs_bind_name.
--
@@cs_internal/cs_print_sql_text.sql
@@cs_internal/&&cs_set_container_to_cdb_root.
--
COL con_id FOR 999 HEA 'Con|ID';
COL pdb_name FOR A30 HEA 'PDB Name' FOR A30 TRUNC;
COL last_captured FOR A19 HEA 'Last Captured';
COL datatype_string FOR A15 HEA 'Data Type';
COL value_string FOR A200 HEA 'Bind Value';
COL max_length FOR 999999 HEA 'Max|Length';
--
PRO
PRO SQL BIND CAPTURE &&cs_bind_name. (&&cs_tools_schema..iod_sql_bind_capture)
PRO ~~~~~~~~~~~~~~~~
--
SELECT  TO_CHAR(c.last_captured, '&&cs_datetime_full_format.') AS last_captured,
        c.datatype_string,
        c.max_length,
        c.value_string,
        x.name AS pdb_name,
        c.con_id
  FROM &&cs_tools_schema..iod_sql_bind_capture c,
       v$containers x
 WHERE c.snap_time BETWEEN TO_DATE('&&cs_sample_time_from.', '&&cs_datetime_full_format.') AND TO_DATE('&&cs_sample_time_to.', '&&cs_datetime_full_format.')
   AND  &&cs_con_id. IN (1, c.con_id)
   AND c.sql_id = '&&cs_sql_id.'
   AND c.name = '&&cs_bind_name.'
   AND x.con_id = c.con_id
 ORDER BY
       c.last_captured,
       c.value_string
/
--
PRO
PRO SQL> @&&cs_script_name..sql "&&cs_sample_time_from." "&&cs_sample_time_to." "&&cs_sql_id." "&&cs_bind_name."
--
@@cs_internal/cs_spool_tail.sql
--
@@cs_internal/&&cs_set_container_to_curr_pdb.
--
@@cs_internal/cs_undef.sql
@@cs_internal/cs_reset.sql
--