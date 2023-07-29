----------------------------------------------------------------------------------------
--
-- File name:   snapper_sid.sql | cs_snapper_sid.sql
--
-- Purpose:     Sessions Snapper for one SID using Tanel Poder Snapper
--
-- Author:      Carlos Sierra
--
-- Version:     2020/12/16
--
-- Usage:       Execute connected to PDB or CDB. Pass SID when requested.
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @cs_snapper_sid.sql
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
DEF cs_script_name = 'cs_snapper_sid';
DEF cs_script_acronym = 'snapper_sid.sql | ';
--
PRO
PRO Executing: SQL> @@snapper.sql ash=sid+service_name+module+machine 5 1 all
@@snapper.sql ash=sid+service_name+module+machine 5 1 all
UNDEF 1 2 3 4;
--
PRO 1. SID: 
DEF cs_sid = '&1.';
UNDEF 1;
--
SELECT '&&cs_file_prefix._&&cs_script_name.' cs_file_name FROM DUAL;
--
@@cs_internal/cs_spool_head.sql
PRO SQL> @&&cs_script_name..sql "&&cs_sid."
@@cs_internal/cs_spool_id.sql
--
PRO SID          : "&&cs_sid."
PRO
--
DEF sid = '&&cs_sid.';
PRO Snapper #1 out of 6
@@snapper_sid.sql
--
DEF sid = '&&cs_sid.';
PRO Snapper #2 out of 6
@@snapper_sid.sql
--
DEF sid = '&&cs_sid.';
PRO Snapper #3 out of 6
@@snapper_sid.sql
--
DEF sid = '&&cs_sid.';
PRO Snapper #4 out of 6
@@snapper_sid.sql
--
DEF sid = '&&cs_sid.';
PRO Snapper #5 out of 6
@@snapper_sid.sql
--
DEF sid = '&&cs_sid.';
PRO Snapper #6 out of 6
@@snapper_sid.sql
--
PRO
PRO SQL> @&&cs_script_name..sql "&&cs_sid."
--
@@cs_internal/cs_spool_tail.sql
@@cs_internal/cs_undef.sql
@@cs_internal/cs_reset.sql
--