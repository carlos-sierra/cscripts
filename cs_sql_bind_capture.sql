----------------------------------------------------------------------------------------
--
-- File name:   cs_sql_bind_capture.sql
--
-- Purpose:     SQL Bind Capture for given SQL_ID
--
-- Author:      Carlos Sierra
--
-- Version:     2023/04/27
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
@@cs_internal/cs_spool_head.sql
PRO SQL> @&&cs_script_name..sql "&&cs_sample_time_from." "&&cs_sample_time_to." "&&cs_sql_id."
@@cs_internal/cs_spool_id.sql
@@cs_internal/cs_spool_id_sample_time.sql
@@cs_internal/cs_spool_id_list_sql_id.sql
@@cs_internal/cs_print_sql_text.sql
@@cs_internal/&&cs_set_container_to_cdb_root.
--
COL con_id FOR 999 HEA 'Con|ID';
COL pdb_name FOR A30 HEA 'PDB Name' FOR A30 TRUNC;
COL last_captured FOR A19 HEA 'Last Captured';
COL child_number FOR 999999 HEA 'Child|Number';
COL position FOR 990 HEA 'Pos';
COL datatype_string FOR A15 HEA 'Data Type';
COL name_and_value FOR A200 HEA 'Bind Name and Value';
COL max_length FOR 999999 HEA 'Max|Length';
--
BRE ON last_captured SKIP PAGE ON con_id ON pdb_name ON child_number;

PRO
PRO SQL BIND CAPTURE (&&cs_tools_schema..iod_sql_bind_capture)
PRO ~~~~~~~~~~~~~~~~
--
SELECT  TO_CHAR(c.last_captured, '&&cs_datetime_full_format.') AS last_captured,
        -- c.child_number, -- it seems there is a single child_number per capture
        c.position, 
        c.datatype_string,
        c.max_length,
        c.name||' = '||c.value_string AS name_and_value,
        x.name AS pdb_name,
        c.con_id
  FROM &&cs_tools_schema..iod_sql_bind_capture c,
       v$containers x
 WHERE c.snap_time BETWEEN TO_DATE('&&cs_sample_time_from.', '&&cs_datetime_full_format.') AND TO_DATE('&&cs_sample_time_to.', '&&cs_datetime_full_format.')
   AND  &&cs_con_id. IN (1, c.con_id)
   AND c.sql_id = '&&cs_sql_id.'
   AND x.con_id = c.con_id
 ORDER BY
       1, 2, 3
/
CL BRE;
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