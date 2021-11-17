----------------------------------------------------------------------------------------
--
-- File name:   cs_tables.sql
--
-- Purpose:     All Tables and Top N Tables (text report)
--
-- Author:      Carlos Sierra
--
-- Version:     2021/09/09
--
-- Usage:       Execute connected to PDB or CDB.
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @cs_tables.sql
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
DEF cs_script_name = 'cs_tables';
--
SELECT '&&cs_file_prefix._&&cs_script_name.' cs_file_name FROM DUAL;
--
@@cs_internal/cs_spool_head.sql
PRO SQL> @&&cs_script_name..sql 
@@cs_internal/cs_spool_id.sql
--
BREAK ON REPORT;
COMPUTE SUM OF total_MB table_MB indexes_MB tabs lobs_MB est_data_MB lobs idxs num_rows ON REPORT;
--
DEF specific_table = '';
DEF order_by = 't.pdb_name, t.owner, t.table_name';
DEF fetch_first_N_rows = '10000';
PRO
PRO All Tables
PRO ~~~~~~~~~~
@@cs_internal/cs_tables_internal.sql
--
DEF specific_table = '';
DEF order_by = 'NVL(t.bytes,0)+NVL(i.bytes,0)+NVL(l.bytes,0) DESC';
DEF fetch_first_N_rows = '20';
PRO
PRO Top Tables
PRO ~~~~~~~~~~
@@cs_internal/cs_tables_internal.sql
--
PRO
PRO SQL> @&&cs_script_name..sql
--
@@cs_internal/cs_spool_tail.sql
@@cs_internal/cs_undef.sql
@@cs_internal/cs_reset.sql
--
