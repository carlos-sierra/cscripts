COL applicationname HEA 'Application Name';
COL transactionname HEA 'Transaction Name';
COL latency_secs_sum FOR 9,999,990 HEA 'SUM (secs)';
COL latency_ms_avg FOR 9,999,990 HEA 'AVG (ms)';
COL latency_ms_max FOR 9,999,990 HEA 'MAX (ms)';
COL latency_ms_p50 FOR 9,999,990 HEA 'P50 (ms)';
COL latency_ms_p90 FOR 9,999,990 HEA 'P90 (ms)';
COL latency_ms_p95 FOR 9,999,990 HEA 'P95 (ms)';
COL latency_ms_p99 FOR 9,999,990 HEA 'P99 (ms)';
COL latency_ms_p999 FOR 9,999,990 HEA 'P99.9 (ms)';
COL transactions FOR 9,999,990 HEA 'Transactions';
COL min_begintime FOR A23 HEA 'Min Begin Time';
COL max_endtime FOR A23 HEA 'Max End Time';
--
PRO
PRO Top KIEV Transaction Names ending between &&cs_sample_time_from. and &&cs_sample_time_to. UTC (sorted by "SUM (secs)")
PRO ~~~~~~~~~~~~~~~~~~~~~~~~~~
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
SELECT kt.applicationname,
       kt.transactionname,
       ROUND(SUM(kt.latency_ms)/1e3) AS latency_secs_sum,
       COUNT(DISTINCT kt.transactionid||'.'||kt.committransactionid) AS transactions,
       ROUND(AVG(kt.latency_ms)) AS latency_ms_avg,
       PERCENTILE_DISC(0.50) WITHIN GROUP (ORDER BY kt.latency_ms) latency_ms_p50,
       PERCENTILE_DISC(0.90) WITHIN GROUP (ORDER BY kt.latency_ms) latency_ms_p90,
       PERCENTILE_DISC(0.95) WITHIN GROUP (ORDER BY kt.latency_ms) latency_ms_p95,
       PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY kt.latency_ms) latency_ms_p99,
       PERCENTILE_DISC(0.999) WITHIN GROUP (ORDER BY kt.latency_ms) latency_ms_p999,
       MAX(kt.latency_ms) AS latency_ms_max,
       TO_CHAR(MIN(kt.begintime), '&&cs_timestamp_full_format.') min_begintime,
       TO_CHAR(MAX(kt.endtime), '&&cs_timestamp_full_format.') max_endtime
  FROM kt
 GROUP BY
       kt.applicationname,
       kt.transactionname
 ORDER BY
       3 DESC
 FETCH FIRST 100 ROWS ONLY
/