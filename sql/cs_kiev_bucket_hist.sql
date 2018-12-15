----------------------------------------------------------------------------------------
--
-- File name:   cs_kiev_bucket_hist.sql
--
-- Purpose:     KIEV Bucket History Report
--
-- Author:      Carlos Sierra
--
-- Version:     2018/09/06
--
-- Usage:       Execute connected to PDB
--
--              Enter owner and table_name when requested.
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @cs_kiev_bucket_hist.sql
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
DEF cs_script_name = 'cs_kiev_bucket_hist';
--
COL table_owner NEW_V table_owner FOR A30 HEA 'OWNER'; 
SELECT owner table_owner 
  FROM dba_tables 
 WHERE table_name = 'KIEVBUCKETS' 
 ORDER BY 
       owner
/
PRO
PRO 1. Enter Owner
DEF owner = '&1.';
COL owner NEW_V owner;
SELECT UPPER(NVL('&&owner.', '&&table_owner.')) owner FROM DUAL
/
--
COL table_name FOR A30;
COL num_rows FOR 999,999,999,990;
COL kievlive_y FOR 999,999,999,990;
COL kievlive_n FOR 999,999,999,990;
--
WITH
sqf1 AS (
SELECT /*+ NO_MERGE */
       table_name,
       SUBSTR(UTL_RAW.CAST_TO_VARCHAR2(SUBSTR(LPAD(TO_CHAR(endpoint_value,'fmxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx'),30,'0'),1,12)), 1, 1) kievlive,
       endpoint_number - LAG(endpoint_number, 1, 0) OVER (PARTITION BY table_name ORDER BY endpoint_value) num_rows
  FROM dba_tab_histograms
 WHERE owner = '&&owner.'
   AND column_name = 'KIEVLIVE'
),
sqf2 AS (
SELECT /*+ NO_MERGE */
       table_name,
       kievlive,
       MAX(num_rows) num_rows
  FROM sqf1
 WHERE kievlive IN ('Y', 'N')
 GROUP BY
       table_name,
       kievlive
)
SELECT b.name table_name,
       b.maxgarbageage,
       t.num_rows,
       CASE WHEN NVL(y.num_rows, 0) + NVL(n.num_rows, 0) > 0 THEN ROUND(y.num_rows * t.num_rows / (NVL(y.num_rows, 0) + NVL(n.num_rows, 0))) END kievlive_y,
       CASE WHEN NVL(y.num_rows, 0) + NVL(n.num_rows, 0) > 0 THEN ROUND(n.num_rows * t.num_rows / (NVL(y.num_rows, 0) + NVL(n.num_rows, 0))) END kievlive_n
  FROM &&owner..kievbuckets b,
       dba_tables t,
       sqf2 y,
       sqf2 n
 WHERE t.owner = '&&owner.'
   AND t.table_name = UPPER(b.name)
   AND y.table_name(+) = t.table_name
   AND y.kievlive(+) = 'Y'
   AND n.table_name(+) = t.table_name
   AND n.kievlive(+) = 'N'
 ORDER BY
       b.name
/
PRO
PRO 2. Enter Table Name
DEF table_name = '&2.';
--
SELECT '&&cs_file_prefix._&&owner..&&table_name._&&cs_file_date_time._&&cs_reference_sanitized._&&cs_script_name.' cs_file_name FROM DUAL;
--
@@cs_internal/cs_spool_head.sql
PRO SQL> @&&cs_script_name..sql "&&owner." "&&table_name."
@@cs_internal/cs_spool_id.sql
--
PRO OWNER        : &&owner.
PRO TABLE_NAME   : &&table_name.
--
SET PAGES 120;
BREAK ON REPORT;
COMPUTE SUM LABEL 'TOTAL' OF transactions in_flight committed aborted failed KievLive_Y KievLive_N ON REPORT;
COL row_number FOR 9999 HEA '#';
COL transactions FOR 999,999,999,990 HEA 'NUM_ROWS';
--
PRO
PRO Garbage age
PRO ~~~~~~~~~~~
SELECT TO_CHAR(BEGINTIME, 'YYYY-MM-DD"T"HH24:MI:SS') garbage_time,
       (SYSDATE - CAST(BEGINTIME AS DATE)) * 24 * 3600 garbage_age_secs,
       KIEVTXNID,
       COMMITTRANSACTIONID
FROM
(
SELECT /*+ FULL(t) FULL(k) USE_HASH(t k) */
       ROW_NUMBER() OVER (ORDER BY k.BEGINTIME) row_number,
       k.BEGINTIME,
       t.KIEVTXNID,
       k.COMMITTRANSACTIONID
  FROM &&owner..&&table_name. t,
       &&owner..kievtransactions k
 WHERE k.COMMITTRANSACTIONID = t.KIEVTXNID
   AND t.KievLive = 'N'
)
 WHERE row_number = 1
/
--
PRO
PRO Rows by HOUR (up to last 50 hours)
PRO ~~~~~~~~~~~~
SELECT /*+ FULL(t) FULL(k) USE_HASH(t k) */
       ROW_NUMBER() OVER (ORDER BY TRUNC(k.BEGINTIME, 'HH') DESC) - 1 row_number,
       TO_CHAR(TRUNC(k.BEGINTIME, 'HH'), 'YYYY-MM-DD"T"HH24') HOUR,
       COUNT(*) transactions,
       SUM(CASE t.KievLive WHEN 'Y' THEN 1 ELSE 0 END) KievLive_Y,
       SUM(CASE t.KievLive WHEN 'N' THEN 1 ELSE 0 END) KievLive_N
  FROM &&owner..&&table_name. t,
       &&owner..kievtransactions k
 WHERE k.COMMITTRANSACTIONID = t.KIEVTXNID
   AND k.BEGINTIME > TRUNC(SYSDATE, 'HH') - (50/24)
 GROUP BY
       TRUNC(k.BEGINTIME, 'HH')
ORDER BY 2
/
--
PRO
PRO Rows by DAY (up to last 100 days)
PRO ~~~~~~~~~~~
SELECT /*+ FULL(t) FULL(k) USE_HASH(t k) */
       ROW_NUMBER() OVER (ORDER BY TRUNC(k.BEGINTIME) DESC) - 1 row_number,
       TO_CHAR(TRUNC(k.BEGINTIME), 'YYYY-MM-DD') DAY,
       COUNT(*) transactions,
       SUM(CASE t.KievLive WHEN 'Y' THEN 1 ELSE 0 END) KievLive_Y,
       SUM(CASE t.KievLive WHEN 'N' THEN 1 ELSE 0 END) KievLive_N
  FROM &&owner..&&table_name. t,
       &&owner..kievtransactions k
 WHERE k.COMMITTRANSACTIONID = t.KIEVTXNID
   AND k.BEGINTIME > TRUNC(SYSDATE) - 100
 GROUP BY
       TRUNC(k.BEGINTIME)
ORDER BY 2
/
--
PRO
PRO Rows by MONTH
PRO ~~~~~~~~~~~~~
SELECT /*+ FULL(t) FULL(k) USE_HASH(t k) */
       ROW_NUMBER() OVER (ORDER BY TRUNC(k.BEGINTIME, 'MM') DESC) - 1 row_number,
       TO_CHAR(TRUNC(k.BEGINTIME, 'MM'), 'YYYY-MM') MONTH,
       COUNT(*) transactions,
       SUM(CASE t.KievLive WHEN 'Y' THEN 1 ELSE 0 END) KievLive_Y,
       SUM(CASE t.KievLive WHEN 'N' THEN 1 ELSE 0 END) KievLive_N  
  FROM &&owner..&&table_name. t,
       &&owner..kievtransactions k
 WHERE k.COMMITTRANSACTIONID = t.KIEVTXNID
 GROUP BY
       TRUNC(k.BEGINTIME, 'MM')
ORDER BY 2
/
--
PRO
PRO Total
PRO ~~~~~
SELECT SUM(CASE t.KievLive WHEN 'Y' THEN 1 ELSE 0 END) KievLive_Y,
       SUM(CASE t.KievLive WHEN 'N' THEN 1 ELSE 0 END) KievLive_N
  FROM &&owner..&&table_name. t
/
--
PRO
PRO CBO stats history
PRO ~~~~~~~~~~~~~~~~~
SELECT TO_CHAR(h.analyzetime, 'YYYY-MM-DD"T"HH24:MI:SS') last_analyzed,
       h.rowcnt,
       h.blkcnt,
       --h.samplesize,
       h.avgrln
  FROM sys.wri$_optstat_tab_history h,
       dba_objects o
 WHERE h.analyzetime IS NOT NULL
   AND h.flags > 0
   AND o.object_id = h.obj#
   AND o.owner = UPPER(TRIM('&&owner.'))
   AND o.object_name = UPPER(TRIM('&&table_name.'))
   AND o.object_type = 'TABLE'
 ORDER BY 
       h.analyzetime
/
--
PRO
PRO &&table_name. CBO stats current
PRO ~~~~~~~~~~~~~
SELECT TO_CHAR(last_analyzed, 'YYYY-MM-DD"T"HH24:MI:SS') last_analyzed,
       num_rows,
       blocks,
       --sample_size,
       avg_row_len
  FROM dba_tables
 WHERE owner = UPPER(TRIM('&&owner.'))
   AND table_name = UPPER(TRIM('&&table_name.'))
/
--
-- safe to do. as name implies, it flushes this table modifications from sga so we can report on them
EXEC DBMS_STATS.FLUSH_DATABASE_MONITORING_INFO;
--
COL hours_since_gathering HEA 'HOURS|SINCE|GATHERING';
COL num_rows FOR 999,999,999,990;
COL inserts_per_day FOR 999,999,990 HEA 'INSERTS|PER DAY';
COL updates_per_day FOR 999,999,990 HEA 'UPDATES|PER DAY';
COL deletes_per_day FOR 999,999,990 HEA 'DELETES|PER DAY';
COL growth_per_day FOR 999,999,990 HEA 'GROWTH|PER_DAY';
COL percent FOR 9,990.0 HEA 'PERCENT|PER_DAY';
--
PRO
PRO &&table_name. Change Rate
PRO ~~~~~~~~~~~~~
SELECT DISTINCT
       t.num_rows,
       ROUND((m.inserts - m.deletes) / (m.timestamp - t.last_analyzed)) growth_per_day,
       ROUND(100 * (m.inserts - m.deletes) / (m.timestamp - t.last_analyzed) / t.num_rows, 1) percent,
       ROUND(m.inserts / (m.timestamp - t.last_analyzed)) inserts_per_day,
       ROUND(m.updates / (m.timestamp - t.last_analyzed)) updates_per_day,
       ROUND(m.deletes / (m.timestamp - t.last_analyzed)) deletes_per_day,
       TO_CHAR(t.last_analyzed, 'YYYY-MM-DD"T"HH24:MI:SS') last_analyzed,
       TO_CHAR(m.timestamp, 'YYYY-MM-DD"T"HH24:MI:SS') timestamp,
       ROUND((m.timestamp - t.last_analyzed) * 24, 1) hours_since_gathering
  FROM dba_tables t,
       dba_tab_modifications m
 WHERE t.owner = UPPER(TRIM('&&owner.'))
   AND t.table_name = UPPER(TRIM('&&table_name.'))
   AND m.table_owner = t.owner
   AND m.table_name = t.table_name
/
--
PRO
PRO SQL> @&&cs_script_name..sql "&&owner." "&&table_name."
--
@@cs_internal/cs_spool_tail.sql
@@cs_internal/cs_undef.sql
@@cs_internal/cs_reset.sql
--