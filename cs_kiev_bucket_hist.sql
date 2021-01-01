----------------------------------------------------------------------------------------
--
-- File name:   cs_kiev_bucket_hist.sql
--
-- Purpose:     KIEV Bucket History Report (for GC analysis)
--
-- Author:      Carlos Sierra
--
-- Version:     2020/12/06
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
COL username NEW_V username FOR A30 HEA 'OWNER';
SELECT u.username
  FROM dba_users u
 WHERE u.oracle_maintained = 'N' 
   AND u.username NOT LIKE 'C##'||CHR(37) 
   AND (SELECT COUNT(*) FROM dba_tables t WHERE t.owner = u.username AND t.table_name = 'KIEVBUCKETS') > 0
 ORDER BY u.username
/
PRO
PRO 1. Enter Owner
DEF cs_owner = '&1.';
UNDEF 1;
COL cs_owner NEW_V cs_owner FOR A30 NOPRI;
SELECT UPPER(NVL(TRIM('&&cs_owner.'), '&&username.')) AS cs_owner FROM DUAL
/
--
DEF num_rows = '0';
DEF kievlive_y = '0';
DEF kievlive_n = '0';
COL table_name FOR A30;
COL num_rows NEW_V num_rows FOR 999,999,999,990;
COL kievlive_y NEW_V kievlive_y FOR 999,999,999,990;
COL kievlive_n NEW_V kievlive_n FOR 999,999,999,990;
COL message FOR A12 TRUNC;
--
WITH
sqf1 AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       table_name,
       SUBSTR(UTL_RAW.CAST_TO_VARCHAR2(SUBSTR(LPAD(TO_CHAR(endpoint_value,'fmxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx'),30,'0'),1,12)), 1, 1) kievlive,
       endpoint_number - LAG(endpoint_number, 1, 0) OVER (PARTITION BY table_name ORDER BY endpoint_value) num_rows
  FROM dba_tab_histograms
 WHERE owner = '&&cs_owner.'
   AND column_name = 'KIEVLIVE'
),
sqf2 AS (
SELECT /*+ MATERIALIZE NO_MERGE */
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
  FROM &&cs_owner..kievbuckets b,
       dba_tables t,
       sqf2 y,
       sqf2 n
 WHERE t.owner = '&&cs_owner.'
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
DEF cs_table_name = '&2.';
UNDEF 2;
COL cs_table_name NEW_V cs_table_name FOR A30 NOPRI;
SELECT UPPER(TRIM('&&cs_table_name.')) AS cs_table_name FROM DUAL
/
--
DEF oldest_deleted_kievtxnid = '';
COL oldest_deleted_kievtxnid NEW_V oldest_deleted_kievtxnid;
SELECT TO_CHAR(MIN(CASE t.KievLive WHEN 'N' THEN t.KIEVTXNID END)) AS oldest_deleted_kievtxnid,
       NVL(COUNT(*), 0) AS num_rows,
       NVL(SUM(CASE t.KievLive WHEN 'Y' THEN 1 ELSE 0 END), 0) AS kievlive_y,
       NVL(SUM(CASE t.KievLive WHEN 'N' THEN 1 ELSE 0 END), 0) AS kievlive_n
  FROM &&cs_owner..&&cs_table_name. t 
/
--
DEF gc_horizon = '';
COL gc_horizon NEW_V gc_horizon NOPRI;
SELECT TO_CHAR(k.BEGINTIME, '&&cs_datetime_full_format.') AS gc_horizon
  FROM &&cs_owner..kievtransactions k
 WHERE k.COMMITTRANSACTIONID = TO_NUMBER('&&oldest_deleted_kievtxnid.')
/
--
SELECT COALESCE('&&gc_horizon.', TO_CHAR(MIN(k.BEGINTIME), '&&cs_datetime_full_format.')) AS gc_horizon
  FROM &&cs_owner..kievtransactions k
 WHERE '&&oldest_deleted_kievtxnid.' IS NULL
/
--
SELECT '&&cs_file_prefix._&&cs_script_name._&&cs_owner..&&cs_table_name.' cs_file_name FROM DUAL;
--
@@cs_internal/cs_spool_head.sql
PRO SQL> @&&cs_script_name..sql "&&cs_owner." "&&cs_table_name."
@@cs_internal/cs_spool_id.sql
--
PRO OWNER        : &&cs_owner.
PRO TABLE_NAME   : &&cs_table_name.
--
SET PAGES 120;
COL row_number FOR 9999 HEA '#';
COL transactions FOR 999,999,999,990 HEA 'NUM_ROWS';
COL gc_horizon_time FOR A19 HEA 'TIME';
COL horizon_hrs FOR 9,999,990.0 HEA 'HOURS';
--
PRO
PRO TABLE: &&cs_owner..&&cs_table_name.
PRO ~~~~~
SELECT TO_NUMBER('&&num_rows.') AS num_rows,
       TO_NUMBER('&&kievlive_y.') AS kievlive_y,
       TO_NUMBER('&&kievlive_n.') AS kievlive_n       
  FROM DUAL
/
--
PRO
PRO GC Horizon
PRO ~~~~~~~~~~
SELECT '&&gc_horizon.' AS gc_horizon_time, 
       ROUND((SYSDATE - TO_DATE('&&gc_horizon.', '&&cs_datetime_full_format.')) * 24, 1) AS horizon_hrs,
       TO_NUMBER('&&oldest_deleted_kievtxnid.') AS kievtxnid,
       CASE
         WHEN TO_NUMBER('&&kievlive_y.') > 0 AND TO_NUMBER('&&kievlive_n.') = 0 THEN 'NO TOMBSTONE'
         WHEN ROUND((SYSDATE - TO_DATE('&&gc_horizon.', '&&cs_datetime_full_format.')) * 24, 1) > 8 THEN 'GC BOGUS' 
         WHEN ROUND((SYSDATE - TO_DATE('&&gc_horizon.', '&&cs_datetime_full_format.')) * 24, 1) > 4 THEN 'GC LAGGING' 
         WHEN ROUND((SYSDATE - TO_DATE('&&gc_horizon.', '&&cs_datetime_full_format.')) * 24, 1) >= 1.5 THEN 'GC NORMAL' 
         WHEN ROUND((SYSDATE - TO_DATE('&&gc_horizon.', '&&cs_datetime_full_format.')) * 24, 1) < 1.5 THEN 'NO GARBAGE' 
         ELSE 'UNEXPECTED'
       END AS message
  FROM DUAL
/
--
BREAK ON REPORT;
COMPUTE SUM LABEL 'TOTAL' OF transactions KievLive_Y KievLive_N ON REPORT;
PRO
PRO Rows by HOUR (up to last 50 hours)
PRO ~~~~~~~~~~~~
SELECT /*+ FULL(t) FULL(k) USE_HASH(t k) */
       ROW_NUMBER() OVER (ORDER BY TRUNC(k.BEGINTIME, 'HH') DESC) - 1 row_number,
       TO_CHAR(TRUNC(k.BEGINTIME, 'HH'), 'YYYY-MM-DD"T"HH24') HOUR,
       COUNT(*) transactions,
       SUM(CASE t.KievLive WHEN 'Y' THEN 1 ELSE 0 END) KievLive_Y,
       SUM(CASE t.KievLive WHEN 'N' THEN 1 ELSE 0 END) KievLive_N
  FROM &&cs_owner..&&cs_table_name. t,
       &&cs_owner..kievtransactions k
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
  FROM &&cs_owner..&&cs_table_name. t,
       &&cs_owner..kievtransactions k
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
  FROM &&cs_owner..&&cs_table_name. t,
       &&cs_owner..kievtransactions k
 WHERE k.COMMITTRANSACTIONID(+) = t.KIEVTXNID
 GROUP BY
       TRUNC(k.BEGINTIME, 'MM')
ORDER BY 2 NULLS FIRST
/
--
PRO
PRO Total
PRO ~~~~~
SELECT SUM(CASE t.KievLive WHEN 'Y' THEN 1 ELSE 0 END) KievLive_Y,
       SUM(CASE t.KievLive WHEN 'N' THEN 1 ELSE 0 END) KievLive_N
  FROM &&cs_owner..&&cs_table_name. t
/
--
PRO
PRO CBO stats history
PRO ~~~~~~~~~~~~~~~~~
SELECT TO_CHAR(h.analyzetime, '&&cs_datetime_full_format.') last_analyzed,
       h.rowcnt,
       h.blkcnt,
       --h.samplesize,
       h.avgrln
  FROM sys.wri$_optstat_tab_history h,
       dba_objects o
 WHERE h.analyzetime IS NOT NULL
   AND h.flags > 0
   AND o.object_id = h.obj#
   AND o.owner = '&&cs_owner.'
   AND o.object_name = '&&cs_table_name.'
   AND o.object_type = 'TABLE'
 ORDER BY 
       h.analyzetime
/
--
PRO
PRO &&cs_table_name. CBO stats current
PRO ~~~~~~~~~~~~~
SELECT TO_CHAR(last_analyzed, '&&cs_datetime_full_format.') last_analyzed,
       num_rows,
       blocks,
       --sample_size,
       avg_row_len
  FROM dba_tables
 WHERE owner = '&&cs_owner.'
   AND table_name = '&&cs_table_name.'
/
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
PRO &&cs_table_name. Change Rate
PRO ~~~~~~~~~~~~~
SELECT DISTINCT
       t.num_rows,
       ROUND((m.inserts - m.deletes) / (m.timestamp - t.last_analyzed)) growth_per_day,
       ROUND(100 * (m.inserts - m.deletes) / (m.timestamp - t.last_analyzed) / t.num_rows, 1) percent,
       ROUND(m.inserts / (m.timestamp - t.last_analyzed)) inserts_per_day,
       ROUND(m.updates / (m.timestamp - t.last_analyzed)) updates_per_day,
       ROUND(m.deletes / (m.timestamp - t.last_analyzed)) deletes_per_day,
       TO_CHAR(t.last_analyzed, '&&cs_datetime_full_format.') last_analyzed,
       TO_CHAR(m.timestamp, '&&cs_datetime_full_format.') timestamp,
       ROUND((m.timestamp - t.last_analyzed) * 24, 1) hours_since_gathering
  FROM dba_tables t,
       dba_tab_modifications m
 WHERE t.owner = '&&cs_owner.'
   AND t.table_name = '&&cs_table_name.'
   AND m.table_owner = t.owner
   AND m.table_name = t.table_name
/
--
PRO
PRO SQL> @&&cs_script_name..sql "&&cs_owner." "&&cs_table_name."
--
@@cs_internal/cs_spool_tail.sql
@@cs_internal/cs_undef.sql
@@cs_internal/cs_reset.sql
--