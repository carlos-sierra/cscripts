----------------------------------------------------------------------------------------
--
-- File name:   cs_sprf_kiev_wf_futureWork.sql
--
-- Purpose:     Create SQL Profile for specic KIEV scan (futureWork,resumptionTimestamp) on all PDBs
--
-- Author:      Carlos Sierra
--
-- Version:     2021/05/25
--
-- Usage:       Connecting into CDB.
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @cs_sprf_kiev_wf_futureWork.sql
--
-- Notes:       Developed and tested on 12.1.0.2 and 19c.
--
---------------------------------------------------------------------------------------
--
DEF sql_decoration = "performScanQuery(futureWork,resumptionTimestamp)%(1 = 1)%ASC";
DEF phv_to_pin = "2784194979";
DEF implementation_script = "DBPERF-7140_2021-05-25T14.17.58Z_SEA_RGN_KIEV01_CCC_WFAAS_cs_sprf_export_IMPLEMENT.sql";
DEF rollback_script = "DBPERF-7140_2021-05-25T14.17.58Z_SEA_RGN_KIEV01_CCC_WFAAS_cs_sprf_export_ROLLBACK.sql";
--
@@cs_internal/cs_primary.sql
@@cs_internal/cs_cdb_warn.sql
@@cs_internal/cs_set.sql
@@cs_internal/cs_def.sql
@@cs_internal/cs_file_prefix.sql
--
DEF cs_script_name = 'cs_sprf_kiev_wf_futureWork';
--
SELECT '&&cs_file_prefix._&&cs_script_name.' AS cs_file_name FROM DUAL;
--
@@cs_internal/cs_spool_head.sql
PRO SQL> @&&cs_script_name..sql 
@@cs_internal/cs_spool_id.sql
--
COL double_ampersand NEW_V double_ampersand NOPRI;
SELECT CHR(38)||CHR(38) AS double_ampersand FROM DUAL;
COL export_version NEW_V export_version NOPRI;
SELECT TO_CHAR(SYSDATE, 'YYMMDDHH24MISS') AS export_version FROM DUAL;
VAR sql_to_be_fixed NUMBER;
EXEC :sql_to_be_fixed := 0;
--
PRO please wait...
@@kiev/kiev_fs.sql "&&sql_decoration."
DEF summary_before = '&&cs_file_name..txt';
@@kiev/cs_sprf_implement_internal.sql
--
-- continues with original spool
SPO &&cs_file_name..txt APP
--
PRO
PRO SQL> @&&cs_script_name..sql
PRO
--
@@cs_internal/cs_spool_tail.sql
@@cs_internal/cs_undef.sql
@@cs_internal/cs_reset.sql
--
PRO
HOS ls -l &&cs_file_prefix._&&cs_script_name.*.*
PRO
PRINT sql_to_be_fixed;
PRO
-- PAUSE hit "return" to execute idempotent script &&cs_file_name._IMPLEMENT.sql
@&&cs_file_name._IMPLEMENT.sql
--
PRO please wait...
@@kiev/kiev_fs.sql "&&sql_decoration."
DEF summary_after = '&&cs_file_name..txt';
PRO
PRO ***************************************
PRO * BEFORE
PRO ***************************************
HOS cat &&summary_before.
PRO
PRO ***************************************
PRO * AFTER
PRO ***************************************
HOS cat &&summary_after.
--