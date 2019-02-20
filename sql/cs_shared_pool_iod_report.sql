----------------------------------------------------------------------------------------
--
-- File name:   cs_shared_pool_iod_report.sql
--
-- Purpose:     Shared Pool SubPools History Report from IOD
--
-- Author:      Carlos Sierra
--
-- Version:     2018/12/16
--
-- Usage:       Execute connected to CDB
--
--              Enter range of dates.
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @cs_shared_pool_iod_report.sql
--
-- Notes:       Developed and tested on 12.1.0.2.
--
---------------------------------------------------------------------------------------
--
@@cs_internal/cs_secondary.sql
--@@cs_internal/cs_pdb_warn.sql
@@cs_internal/cs_set.sql
@@cs_internal/cs_def.sql
@@cs_internal/cs_file_prefix.sql
--
DEF cs_script_name = 'cs_shared_pool_iod_report';
DEF cs_hours_range_default = '336';
--
@@cs_internal/cs_sample_time_from_and_to.sql
@@cs_internal/cs_snap_id_from_and_to.sql
--
COL cs2_pdb_name NEW_V cs2_pdb_name FOR A30 NOPRI;
SELECT SYS_CONTEXT('USERENV', 'CON_NAME') cs2_pdb_name FROM DUAL;
ALTER SESSION SET container = CDB$ROOT;
--
SELECT '&&cs_file_prefix._&&cs_file_date_time._&&cs_reference_sanitized._&&cs_script_name.' cs_file_name FROM DUAL;
--
@@cs_internal/cs_spool_head.sql
PRO SQL> @&&cs_script_name..sql "&&cs_sample_time_from." "&&cs_sample_time_to." 
@@cs_internal/cs_spool_id.sql
--
PRO TIME_FROM    : &&cs_sample_time_from. (&&cs_snap_id_from.)
PRO TIME_TO      : &&cs_sample_time_to. (&&cs_snap_id_to.)
--
COL end_time FOR A19 HEA 'End Time';
COL Total FOR 9,999.000 HEA 'Total';
COL free_memory FOR 9,999.000 HEA 'free memory';
COL SQLA FOR 9,999.000;
COL KGLH0 FOR 9,999.000;
COL KGLHD FOR 9,999.000;
COL db_block_hash_buckets FOR 9,999.000 HEA 'db_block_hash_buckets';
COL KQR_X_SO FOR 9,999.000 HEA 'KQR X SO';
COL KGLDA FOR 9,999.000;
COL SQLP FOR 9,999.000;
COL KQR_L_PO FOR 9,999.000 HEA 'KQR L PO';
COL kglsim_object_batch FOR 9,999.000;
COL KGLS FOR 9,999.000;
COL Result_Cache FOR 9,999.000;
COL PDBHP FOR 9,999.000;
COL other_subpools FOR 9,999.000 HEA 'other subpools';
--
PRO
PRO Shared Pool - SubPools (GBs)
PRO ~~~~~~~~~~~~~~~~~~~~~~
WITH
sgastat AS (
SELECT snap_time,
       ROUND(SUM(CASE WHEN name IS NULL THEN bytes ELSE 0 END)/POWER(2,30), 3) Total,
       ROUND(SUM(CASE name WHEN 'SQLA' THEN bytes ELSE 0 END)/POWER(2,30), 3) SQLA,
       ROUND(SUM(CASE name WHEN 'KGLH0' THEN bytes ELSE 0 END)/POWER(2,30), 3) KGLH0,
       ROUND(SUM(CASE name WHEN 'KGLHD' THEN bytes ELSE 0 END)/POWER(2,30), 3) KGLHD,
       ROUND(SUM(CASE name WHEN 'db_block_hash_buckets' THEN bytes ELSE 0 END)/POWER(2,30), 3) db_block_hash_buckets,
       ROUND(SUM(CASE name WHEN 'KGLS' THEN bytes ELSE 0 END)/POWER(2,30), 3) KGLS,
       ROUND(SUM(CASE name WHEN 'PDBHP' THEN bytes ELSE 0 END)/POWER(2,30), 3) PDBHP,
       ROUND(SUM(CASE name WHEN 'KQR X SO' THEN bytes ELSE 0 END)/POWER(2,30), 3) KQR_X_SO,
       ROUND(SUM(CASE name WHEN 'KQR L PO' THEN bytes ELSE 0 END)/POWER(2,30), 3) KQR_L_PO,
       ROUND(SUM(CASE name WHEN 'KGLDA' THEN bytes ELSE 0 END)/POWER(2,30), 3) KGLDA,
       ROUND(SUM(CASE name WHEN 'Result Cache' THEN bytes ELSE 0 END)/POWER(2,30), 3) Result_Cache,
       ROUND(SUM(CASE name WHEN 'SQLP' THEN bytes ELSE 0 END)/POWER(2,30), 3) SQLP,
       ROUND(SUM(CASE name WHEN 'kglsim object batch' THEN bytes ELSE 0 END)/POWER(2,30), 3) kglsim_object_batch,
       ROUND(SUM(CASE name WHEN 'free memory' THEN bytes ELSE 0 END)/POWER(2,30), 3) free_memory
  FROM c##iod.iod_sgastat
 WHERE snap_time BETWEEN TO_DATE('&&cs_sample_time_from.', '&&cs_datetime_full_format') AND TO_DATE('&&cs_sample_time_to.', '&&cs_datetime_full_format')
   AND pool = 'shared pool'
 GROUP BY
       snap_time
)
SELECT CAST(snap_time AS DATE) end_time,
       Total,
       SQLA,
       KGLH0,
       KGLHD,
       db_block_hash_buckets,
       KGLS,
       PDBHP,
       KQR_X_SO,
       KQR_L_PO,
       Result_Cache,
       KGLDA,
       SQLP,
       kglsim_object_batch,
       Total - (free_memory + SQLA + KGLH0 + KGLHD + db_block_hash_buckets + KQR_X_SO + KGLDA + SQLP + KQR_L_PO + kglsim_object_batch + KGLS + Result_Cache + PDBHP) other_subpools,
       free_memory
  FROM sgastat
 ORDER BY
       snap_time
/
--
PRO
PRO SQL> @&&cs_script_name..sql "&&cs_sample_time_from." "&&cs_sample_time_to."
--
@@cs_internal/cs_spool_tail.sql
--
ALTER SESSION SET CONTAINER = &&cs2_pdb_name.;
--
@@cs_internal/cs_undef.sql
@@cs_internal/cs_reset.sql
--