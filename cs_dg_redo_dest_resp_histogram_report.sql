----------------------------------------------------------------------------------------
--
-- File name:   cs_dg_redo_dest_resp_histogram_report.sql
--
-- Purpose:     Data Guard (DG) REDO Transport Duration Report
--
-- Author:      Carlos Sierra
--
-- Version:     2021/06/15
--
-- Usage:       Execute connected to CDB.
--
--              Enter Source and Destination Hosts when requested.
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @cs_dg_redo_dest_resp_histogram_report.sql
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
DEF cs_script_name = 'cs_dg_redo_dest_resp_histogram_report';
DEF cs_hours_range_default = '8760';
--
ALTER SESSION SET container = CDB$ROOT;
--
COL cs_hours_range_default NEW_V cs_hours_range_default NOPRI;
SELECT TRIM(TO_CHAR(LEAST(TRUNC((SYSDATE - MIN(time)) * 24), TO_NUMBER('&&cs_hours_range_default.')))) AS cs_hours_range_default FROM C##IOD.dbc_redo_dest_histogram
/
--
@@cs_internal/cs_sample_time_from_and_to.sql
@@cs_internal/cs_snap_id_from_and_to.sql
--
COL source_host_name FOR A64 TRUNC;
SELECT DISTINCT host_name AS source_host_name
  FROM C##IOD.dbc_redo_dest_histogram
 WHERE time BETWEEN TO_DATE('&&cs_sample_time_from.', '&&cs_datetime_full_format.') AND TO_DATE('&&cs_sample_time_to.', '&&cs_datetime_full_format.')
 ORDER BY 1
/
PRO
PRO 3. Source Host Name: (opt)
DEF s_host_name = '&3.';
UNDEF 3;
--
COL dest_host_name FOR A64 TRUNC;
SELECT DISTINCT dest_host_name
  FROM C##IOD.dbc_redo_dest_histogram
 WHERE time BETWEEN TO_DATE('&&cs_sample_time_from.', '&&cs_datetime_full_format.') AND TO_DATE('&&cs_sample_time_to.', '&&cs_datetime_full_format.')
   AND host_name = NVL('&&s_host_name.', host_name)
 ORDER BY 1
/
PRO
PRO 3. Destination Host Name: (opt)
DEF d_host_name = '&4.';
UNDEF 4;
--
SELECT '&&cs_file_prefix._&&cs_script_name.' cs_file_name FROM DUAL;
--
@@cs_internal/cs_spool_head.sql
PRO SQL> @&&cs_script_name..sql "&&cs_sample_time_from." "&&cs_sample_time_to." "&&s_host_name." "&&d_host_name."
@@cs_internal/cs_spool_id.sql
--
@@cs_internal/cs_spool_id_sample_time.sql
--
PRO SOURCE       : "&&s_host_name."
PRO DESTINATION  : "&&d_host_name."
--
COL seconds FOR 999,999,990;
COL frequency FOR 999,990;
BREAK ON source_host_name SKIP PAGE DUPL ON dest_host_name SKIP PAGE DUPL;
--
PRO
PRO Data Guard (DG) REDO Transport Duration (v$redo_dest_resp_histogram)
PRO ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
SELECT host_name AS source_host_name, dest_host_name, time,  duration_seconds AS seconds, frequency
  FROM C##IOD.dbc_redo_dest_histogram
 WHERE time BETWEEN TO_DATE('&&cs_sample_time_from.', '&&cs_datetime_full_format.') AND TO_DATE('&&cs_sample_time_to.', '&&cs_datetime_full_format.')
   AND host_name = NVL('&&s_host_name.', host_name)
   AND dest_host_name = NVL('&&d_host_name.', dest_host_name)
 ORDER BY host_name, dest_host_name, time
/
--
CL BREAK COMPUTE;
--
PRO
PRO SQL> @&&cs_script_name..sql "&&cs_sample_time_from." "&&cs_sample_time_to." "&&s_host_name." "&&d_host_name."
--
@@cs_internal/cs_spool_tail.sql
--
ALTER SESSION SET CONTAINER = &&cs_con_name.;
--
@@cs_internal/cs_undef.sql
@@cs_internal/cs_reset.sql
--