----------------------------------------------------------------------------------------
--
-- File name:   cs_shared_pool_iod_area_chart.sql
--
-- Purpose:     Shared Pool SubPools History Chart from IOD
--
-- Author:      Carlos Sierra
--
-- Version:     2019/01/02
--
-- Usage:       Execute connected to CDB
--
--              Enter range of dates.
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @cs_sgastat_iod_chart.sql
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
DEF cs_script_name = 'cs_shared_pool_iod_area_chart';
DEF cs_hours_range_default = '336';
--
@@cs_internal/cs_sample_time_from_and_to.sql
@@cs_internal/cs_snap_id_from_and_to.sql
--
COL cs2_pdb_name NEW_V cs2_pdb_name FOR A30 NOPRI;
SELECT SYS_CONTEXT('USERENV', 'CON_NAME') cs2_pdb_name FROM DUAL;
ALTER SESSION SET container = CDB$ROOT;
--
--
SELECT '&&cs_file_prefix._&&cs_file_date_time._&&cs_reference_sanitized._&&cs_script_name.' cs_file_name FROM DUAL;
--
DEF report_title = "Shared Pool SubPool Stats IOD";
DEF chart_title = "Shared Pool SubPools";
DEF xaxis_title = "between &&cs_sample_time_from. and &&cs_sample_time_to.";
DEF vaxis_title = "GBs";
--
-- (isStacked is true and baseline is null) or (not isStacked and baseline >= 0)
--DEF is_stacked = "isStacked: false,";
DEF is_stacked = "isStacked: true,";
--DEF vaxis_baseline = ", baseline:0";
DEF vaxis_baseline = "";
DEF chart_foot_note_2 = "<br>2)";
--DEF chart_foot_note_2 = "<br>2) Granularity: &&cs2_granularity. [{MI}|SS|HH|DD]";
DEF chart_foot_note_3 = "";
--DEF chart_foot_note_3 = "<br>";
DEF chart_foot_note_4 = "";
DEF report_foot_note = "&&cs_script_name..sql";
--
@@cs_internal/cs_spool_head_chart.sql
--
PRO ,'SQLA'    
PRO ,'KGLH0'       
PRO ,'KGLHD'        
PRO ,'db_block_hash_buckets'   
PRO ,'KGLS'   
PRO ,'PDBHP'
PRO ,'KQR X SO'       
PRO ,'KQR L PO'        
PRO ,'Result Cache'   
PRO ,'KGLDA'   
PRO ,'SQLP'   
PRO ,'kglsim object batch'   
PRO ,'other subpools'   
PRO ,'free memory'   
PRO ]
--
SET HEA OFF PAGES 0;
/****************************************************************************************/
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
SELECT ', [new Date('||
       TO_CHAR(q.snap_time, 'YYYY')|| /* year */
       ','||(TO_NUMBER(TO_CHAR(q.snap_time, 'MM')) - 1)|| /* month - 1 */
       ','||TO_CHAR(q.snap_time, 'DD')|| /* day */
       ','||TO_CHAR(q.snap_time, 'HH24')|| /* hour */
       ','||TO_CHAR(q.snap_time, 'MI')|| /* minute */
       ','||TO_CHAR(q.snap_time, 'SS')|| /* second */
       ')'||
       ','||q.SQLA|| 
       ','||q.KGLH0|| 
       ','||q.KGLHD|| 
       ','||q.db_block_hash_buckets|| 
       ','||q.KGLS|| 
       ','||q.PDBHP|| 
       ','||q.KQR_X_SO|| 
       ','||q.KQR_L_PO|| 
       ','||q.Result_Cache|| 
       ','||q.KGLDA|| 
       ','||q.SQLP|| 
       ','||q.kglsim_object_batch|| 
       ','||(q.Total - (q.free_memory + q.SQLA + q.KGLH0 + q.KGLHD + q.db_block_hash_buckets + q.KQR_X_SO + q.KGLDA + q.SQLP + q.KQR_L_PO + q.kglsim_object_batch + q.KGLS + q.Result_Cache + q.PDBHP))|| 
       ','||q.free_memory|| 
       ']'
  FROM sgastat q
 ORDER BY
       q.snap_time
/
/****************************************************************************************/
SET HEA ON PAGES 100;
--
-- [Line|Area]
DEF cs_chart_type = 'Area';
@@cs_internal/cs_spool_id_chart.sql
@@cs_internal/cs_spool_tail_chart.sql
PRO scp &&cs_host_name.:&&cs_file_prefix._*_&&cs_reference_sanitized._*.* &&cs_local_dir.
PRO
PRO SQL> @&&cs_script_name..sql "&&cs_sample_time_from." "&&cs_sample_time_to."
--
ALTER SESSION SET CONTAINER = &&cs2_pdb_name.;
--
@@cs_internal/cs_undef.sql
@@cs_internal/cs_reset.sql
--