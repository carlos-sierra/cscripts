----------------------------------------------------------------------------------------
--
-- File name:   cs_sessions_per_machine_awr_report.sql
--
-- Purpose:     Sessions per Machine from AWR
--
-- Author:      Carlos Sierra
--
-- Version:     2018/12/03
--
-- Usage:       Execute connected to CDB or PDB
--
--              Enter range of dates and filters when requested.
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @cs_sessions_per_machine_awr_report.sql
--
-- Notes:       Developed and tested on 12.1.0.2.
--
---------------------------------------------------------------------------------------
--
@@cs_internal/cs_primary.sql
@@cs_internal/cs_set.sql
@@cs_internal/cs_def.sql
@@cs_internal/cs_file_prefix.sql
--
DEF cs_script_name = 'cs_sessions_per_machine_awr_report';
DEF cs_hours_range_default = '48';
--
@@cs_internal/cs_sample_time_from_and_to.sql
@@cs_internal/cs_snap_id_from_and_to.sql
--
--ALTER SESSION SET container = CDB$ROOT;
--
SELECT '&&cs_file_prefix._&&cs_script_name.' cs_file_name FROM DUAL;
--
@@cs_internal/cs_spool_head.sql
PRO SQL> @&&cs_script_name..sql "&&cs_sample_time_from." "&&cs_sample_time_to." 
@@cs_internal/cs_spool_id.sql
--
COL p95 HEA '95th PCTL';
COL p97 HEA '97th PCTL';
COL p99 HEA '99th PCTL';
COL p99 HEA '99th PCTL';
COL p999 HEA '99.9th PCTL';
COL max HEA 'MAX';
COL max_sample_time FOR A19;
COL first_sample_time FOR A19;
COL last_sample_time FOR A19;
--
BREAK ON REPORT;
COMPUTE SUM LABEL 'TOTAL' OF p95 p97 p99 p999 max ON REPORT;
--
WITH 
by_sample AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       machine,
       sample_id,
       COUNT(*) cnt,
       MAX(sample_time) sample_time,
       ROW_NUMBER() OVER (PARTITION BY machine ORDER BY COUNT(*) DESC) row_number
  FROM dba_hist_active_sess_history
 WHERE machine IS NOT NULL
   AND sample_time >= TO_TIMESTAMP('&&cs_sample_time_from.', '&&cs_datetime_full_format.') 
   AND sample_time < TO_TIMESTAMP('&&cs_sample_time_to.', '&&cs_datetime_full_format.')
   AND dbid = TO_NUMBER('&&cs_dbid.')
   AND instance_number = TO_NUMBER('&&cs_instance_number.')
   AND snap_id BETWEEN TO_NUMBER('&&cs_snap_id_from.') AND TO_NUMBER('&&cs_snap_id_to.')
 GROUP BY
       machine,
       sample_id
)
SELECT s1.machine,
       PERCENTILE_DISC(0.95) WITHIN GROUP (ORDER BY s1.cnt) p95,
       PERCENTILE_DISC(0.97) WITHIN GROUP (ORDER BY s1.cnt) p97,
       PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY s1.cnt) p99,
       PERCENTILE_DISC(0.999) WITHIN GROUP (ORDER BY s1.cnt) p999,
       MAX(s1.cnt) max,
       (SELECT TO_CHAR(s2.sample_time, '&&cs_datetime_full_format.') FROM by_sample s2 WHERE s2.machine = s1.machine AND s2.row_number = 1) max_sample_time,
       TO_CHAR(MIN(s1.sample_time), '&&cs_datetime_full_format.') first_sample_time,
       TO_CHAR(MAX(s1.sample_time), '&&cs_datetime_full_format.') last_sample_time
  FROM by_sample s1
 GROUP BY
       s1.machine
 ORDER BY
       s1.machine
/
--
CLEAR BREAK COMPUTE;
--
PRO
PRO SQL> @&&cs_script_name..sql "&&cs_sample_time_from." "&&cs_sample_time_to." 
--
@@cs_internal/cs_spool_tail.sql
--
--ALTER SESSION SET CONTAINER = &&cs_con_name.;
--
@@cs_internal/cs_undef.sql
@@cs_internal/cs_reset.sql
--