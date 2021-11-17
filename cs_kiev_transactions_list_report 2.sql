----------------------------------------------------------------------------------------
--
-- File name:   cs_kiev_transactions_list_report.sql
--
-- Purpose:     KIEV Transactions List
--
-- Author:      Carlos Sierra
--
-- Version:     2021/04/07
--
-- Usage:       Execute connected to PDB
--
--              Enter range of (end) dates and KIEV owner when requested.
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @cs_kiev_transactions_list_report.sql
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
DEF cs_script_name = 'cs_kiev_transactions_list_report';
DEF cs_hours_range_default = '24';
--
@@cs_internal/cs_sample_time_from_and_to.sql
@@cs_internal/cs_snap_id_from_and_to.sql
--
COL username NEW_V username FOR A30 HEA 'OWNER';
SELECT u.username
  FROM dba_users u
 WHERE u.oracle_maintained = 'N' 
   AND u.username NOT LIKE 'C##'||CHR(37) 
   AND (SELECT COUNT(*) FROM dba_tables t WHERE t.owner = u.username AND t.table_name = 'KIEVDATASTOREMETADATA') > 0
 ORDER BY u.username
/
PRO
COL kiev_owner NEW_V kiev_owner FOR A30 NOPRI;
PRO 3. Enter Owner
DEF kiev_owner = '&3.';
UNDEF 3;
SELECT UPPER(NVL('&&kiev_owner.', '&&username.')) kiev_owner FROM DUAL
/
--
PRO
PRO 4. Report: [{top}|all]
DEF cs2_report = '&4.';
UNDEF 4;
COL cs2_report NEW_V cs2_report NOPRI;
SELECT NVL(LOWER(TRIM('&&cs2_report.')), 'top') cs2_report FROM DUAL;
SELECT CASE WHEN '&&cs2_report.' IN ('top', 'all') THEN '&&cs2_report.' ELSE 'top' END AS cs2_report FROM DUAL;
--
COL cs2_order_by NEW_V cs2_order_by NOPRI;
SELECT CASE '&&cs2_report.' WHEN 'top' THEN 'latency_ms DESC' ELSE 'endtime' END AS cs2_order_by FROM DUAL;
VAR rows_count NUMBER;
BEGIN
  SELECT CASE '&&cs2_report.' WHEN 'top' THEN 30 ELSE 10000 END INTO :rows_count FROM DUAL;
END;
/
--
SELECT '&&cs_file_prefix._&&cs_script_name.' cs_file_name FROM DUAL;
--
@@cs_internal/cs_spool_head.sql
PRO SQL> @&&cs_script_name..sql "&&cs_sample_time_from." "&&cs_sample_time_to." "&&kiev_owner." "&&cs2_report."
@@cs_internal/cs_spool_id.sql
--
@@cs_internal/cs_spool_id_sample_time.sql
--
PRO OWNER        : &&kiev_owner.
PRO REPORT       : &&cs2_report. [{top}|all]
--
COL begintime FOR A23 HEA 'Begin Time';
COL endtime FOR A23 HEA 'End Time';
COL latency_ms FOR 9,999,990 HEA 'Duration|Latency (ms)';
COL transactionid HEA 'Transaction ID';
COL committransactionid HEA 'Commit|Transaction ID';
COL applicationname HEA 'Application Name';
COL transactionname HEA 'Transaction Name';
COL status HEA 'Status';
COL gcpruned FOR A6 HEA 'GC|Pruned';
--
PRO 
PRO KIEV Transactions ending between &&cs_sample_time_from. and &&cs_sample_time_to. UTC (sorted by &&cs2_order_by.)
PRO ~~~~~~~~~~~~~~~~~
--
WITH
kt AS (
SELECT kt.transactionid,
       kt.applicationname,
       kt.transactionname,
       kt.status,
       kt.begintime,
       kt.endtime,
       1000 * ((86400 * EXTRACT(DAY FROM (kt.endtime - kt.begintime))) + (3600 * EXTRACT(HOUR FROM (kt.endtime - kt.begintime))) + (60 * EXTRACT(MINUTE FROM (kt.endtime - kt.begintime))) + EXTRACT(SECOND FROM (kt.endtime - kt.begintime))) AS latency_ms,
       kt.committransactionid,
       kt.gcpruned
  FROM &&kiev_owner..kievtransactions kt
 WHERE 1 = 1
  --  AND kt.status = 'COMMITTED'
   AND kt.endtime > kt.begintime
   AND kt.endtime >= TO_TIMESTAMP('&&cs_sample_time_from.', '&&cs_datetime_full_format.') 
   AND kt.endtime < TO_TIMESTAMP('&&cs_sample_time_to.', '&&cs_datetime_full_format.')
)
SELECT TO_CHAR(kt.begintime, '&&cs_timestamp_full_format.') begintime,
       TO_CHAR(kt.endtime, '&&cs_timestamp_full_format.') endtime,
       kt.latency_ms,
       kt.transactionid,
       kt.committransactionid,
       kt.applicationname,
       kt.transactionname,
       kt.status,
       kt.gcpruned
  FROM kt
 ORDER BY
       kt.&&cs2_order_by.
 FETCH FIRST :rows_count ROWS ONLY
/
--
PRO
PRO SQL> @&&cs_script_name..sql "&&cs_sample_time_from." "&&cs_sample_time_to." "&&kiev_owner." "&&cs2_report."
--
@@cs_internal/cs_spool_tail.sql
@@cs_internal/cs_undef.sql
@@cs_internal/cs_reset.sql
--