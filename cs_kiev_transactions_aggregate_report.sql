----------------------------------------------------------------------------------------
--
-- File name:   cs_kiev_transactions_aggregate_report.sql
--
-- Purpose:     KIEV Transactions Aggregate (Latency|TPS|Count) Report
--
-- Author:      Carlos Sierra
--
-- Version:     2021/04/07
--
-- Usage:       Execute connected to PDB
--
--              Enter range of dates, KIEV owner and granularity when requested.
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @cs_kiev_transactions_aggregate_report.sql
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
DEF cs_script_name = 'cs_kiev_transactions_aggregate_report';
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
PRO 4. Granularity: [{5MI}|SS|MI|15MI|HH|DD]
DEF cs2_granularity = '&4.';
UNDEF 4;
COL cs2_granularity NEW_V cs2_granularity NOPRI;
SELECT NVL(UPPER(TRIM('&&cs2_granularity.')), '5MI') cs2_granularity FROM DUAL;
SELECT CASE WHEN '&&cs2_granularity.' IN ('SS', 'MI', '5MI', '15MI', 'HH', 'DD') THEN '&&cs2_granularity.' ELSE '5MI' END cs2_granularity FROM DUAL;
--
COL cs2_plus_days NEW_V cs2_plus_days NOPRI;
SELECT CASE '&&cs2_granularity.' 
         WHEN 'SS' THEN '(1/24/3600)' -- 1 second
         WHEN 'MI' THEN '(1/24/60)' -- 1 minute
         WHEN '5MI' THEN '(5/24/60)' -- 5 minutes
         WHEN '15MI' THEN '(15/24/60)' -- 15 minutes
         WHEN 'HH' THEN '(1/24)' -- 1 hour
         WHEN 'DD' THEN '1' -- 1 day
         ELSE '(5/24/60)' -- default of 5 minutes
       END cs2_plus_days 
  FROM DUAL
/
--
SELECT '&&cs_file_prefix._&&cs_script_name.' cs_file_name FROM DUAL;
--
@@cs_internal/cs_spool_head.sql
PRO SQL> @&&cs_script_name..sql "&&cs_sample_time_from." "&&cs_sample_time_to." "&&kiev_owner." "&&cs2_granularity." 
@@cs_internal/cs_spool_id.sql
--
@@cs_internal/cs_spool_id_sample_time.sql
--
PRO OWNER        : &&kiev_owner.
PRO GRANULARITY  : "&&cs2_granularity." [{5MI}|SS|MI|15MI|HH|DD]
--
COL endtime_from FOR A19 TRUNC HEA 'Transactions|End Time - From';
COL endtime_to FOR A19 TRUNC HEA 'Transactions|End Time - To';
COL transactions FOR 999,999,990 HEA 'Transactions|Count';
COL seconds FOR 999,990 HEA 'Seconds';
COL tps FOR 999,990.000 HEA 'Transactions|Per Sec (TPS)';
COL avg_latency_ms FOR 9,999,990.000 HEA 'AVG|Latency (ms)';
COL pctl_50_latency_ms FOR 9,999,990 HEA '50th PCTL|Latency (ms)';
COL pctl_90_latency_ms FOR 9,999,990 HEA '90th PCTL|Latency (ms)';
COL pctl_95_latency_ms FOR 9,999,990 HEA '95th PCTL|Latency (ms)';
COL pctl_99_latency_ms FOR 9,999,990 HEA '99th PCTL|Latency (ms)';
COL pctl_999_latency_ms FOR 9,999,990 HEA '99.9th PCTL|Latency (ms)';
COL max_latency_ms FOR 9,999,990 HEA 'MAX|Latency (ms)';
--
PRO 
PRO KIEV Transactions ending between &&cs_sample_time_from. and &&cs_sample_time_to. UTC (aggregated by &&cs2_granularity.)
PRO ~~~~~~~~~~~~~~~~~
--
WITH
FUNCTION ceil_timestamp (p_timestamp IN TIMESTAMP)
RETURN DATE
IS
BEGIN
  IF '&&cs2_granularity.' = 'SS' THEN
    RETURN CAST(p_timestamp AS DATE) + &&cs2_plus_days.;
  ELSIF '&&cs2_granularity.' = '15MI' THEN
    RETURN TRUNC(CAST(p_timestamp AS DATE), 'HH') + FLOOR(TO_NUMBER(TO_CHAR(CAST(p_timestamp AS DATE), 'MI')) / 15) * 15 / (24 * 60) + &&cs2_plus_days.;
  ELSIF '&&cs2_granularity.' = '5MI' THEN
    RETURN TRUNC(CAST(p_timestamp AS DATE), 'HH') + FLOOR(TO_NUMBER(TO_CHAR(CAST(p_timestamp AS DATE), 'MI')) / 5) * 5 / (24 * 60) + &&cs2_plus_days.;
  ELSE
    RETURN TRUNC(CAST(p_timestamp AS DATE) + &&cs2_plus_days., '&&cs2_granularity.');
  END IF;
END ceil_timestamp;
/****************************************************************************************/
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
   AND kt.endtime > TO_TIMESTAMP('&&cs_sample_time_from.', '&&cs_datetime_full_format.') - INTERVAL '1' HOUR
   AND kt.endtime < TO_TIMESTAMP('&&cs_sample_time_to.', '&&cs_datetime_full_format.') + INTERVAL '1' HOUR
),
ktg AS (
SELECT LAG(ceil_timestamp(kt.endtime)) OVER (ORDER BY ceil_timestamp(kt.endtime)) AS endtime_from,
       ceil_timestamp(kt.endtime) AS endtime_to,
       COUNT(*) AS transactions,
       ROUND(AVG(latency_ms), 3) AS avg_latency_ms,
       PERCENTILE_DISC(0.50) WITHIN GROUP (ORDER BY latency_ms) AS pctl_50_latency_ms,
       PERCENTILE_DISC(0.90) WITHIN GROUP (ORDER BY latency_ms) AS pctl_90_latency_ms,
       PERCENTILE_DISC(0.95) WITHIN GROUP (ORDER BY latency_ms) AS pctl_95_latency_ms,
       PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY latency_ms) AS pctl_99_latency_ms,
       PERCENTILE_DISC(0.999) WITHIN GROUP (ORDER BY latency_ms) AS pctl_999_latency_ms,
       MAX(latency_ms) AS max_latency_ms
  FROM kt
 GROUP BY
       ceil_timestamp(kt.endtime)
),
kte AS (
SELECT ktg.endtime_from,
       ktg.endtime_to,
       ktg.transactions,
       (ktg.endtime_to - ktg.endtime_from) * 24 * 3600 AS seconds,
       ROUND(ktg.transactions / ((ktg.endtime_to - ktg.endtime_from) * 24 * 3600), 3) AS tps,
       ktg.avg_latency_ms,
       ktg.pctl_50_latency_ms,
       ktg.pctl_90_latency_ms,
       ktg.pctl_95_latency_ms,
       ktg.pctl_99_latency_ms,
       ktg.pctl_999_latency_ms,
       ktg.max_latency_ms
  FROM ktg
 WHERE ktg.endtime_from >= TO_TIMESTAMP('&&cs_sample_time_from.', '&&cs_datetime_full_format.')
   AND ktg.endtime_from <= TO_TIMESTAMP('&&cs_sample_time_to.', '&&cs_datetime_full_format.')
   AND ktg.endtime_to >= TO_TIMESTAMP('&&cs_sample_time_from.', '&&cs_datetime_full_format.')
   AND ktg.endtime_to <= TO_TIMESTAMP('&&cs_sample_time_to.', '&&cs_datetime_full_format.')
   AND ktg.endtime_to > ktg.endtime_from
)
SELECT TO_CHAR(kte.endtime_from, '&&cs_datetime_full_format.') endtime_from,
       TO_CHAR(kte.endtime_to, '&&cs_datetime_full_format.') endtime_to,
       kte.seconds,
       kte.transactions,
       kte.tps,
       kte.avg_latency_ms,
       kte.pctl_50_latency_ms,
       kte.pctl_90_latency_ms,
       kte.pctl_95_latency_ms,
       kte.pctl_99_latency_ms,
       kte.pctl_999_latency_ms,
       kte.max_latency_ms
  FROM kte
 ORDER BY
       kte.endtime_from
/
--
PRO
PRO SQL> @&&cs_script_name..sql "&&cs_sample_time_from." "&&cs_sample_time_to." "&&kiev_owner." "&&cs2_granularity." 
--
@@cs_internal/cs_spool_tail.sql
@@cs_internal/cs_undef.sql
@@cs_internal/cs_reset.sql
--