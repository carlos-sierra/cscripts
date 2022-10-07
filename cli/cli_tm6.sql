SET TERM ON HEA ON LIN 2490 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF LONG 240000 LONGC 2400 NUM 20 SERVEROUT OFF;
ALTER SESSION SET NLS_DATE_FORMAT = 'YYYY-MM-DD"T"HH24:MI:SS';
ALTER SESSION SET NLS_TIMESTAMP_FORMAT = 'YYYY-MM-DD"T"HH24:MI:SS.FF3';
--
COL sample_time FOR A23;
COL gap_secs FOR 9,999,990;
COL tm6 FOR 9,990 HEA 'TM-6';
COL tm3 FOR 9,990 HEA 'TM-3';
COL pdb_name FOR A30;
--
WITH
ash AS (
SELECT h.sample_time,
       h.con_id,
       CASE WHEN h.event LIKE 'enq:%' AND h.p1text LIKE 'name|mode%' AND h.p1 > 0 THEN CHR(BITAND(h.p1,-16777216)/16777215)||CHR(BITAND(h.p1, 16711680)/65535) END AS lock_type,
       CASE WHEN h.event LIKE 'enq:%' AND h.p1text LIKE 'name|mode%' AND h.p1 > 0 THEN TO_CHAR(BITAND(h.p1, 65535)) END AS lock_mode
  FROM dba_hist_active_sess_history h
 WHERE 1 = 1
   AND h.event LIKE 'enq:%'
   AND h.p1text LIKE 'name|mode%'
   AND h.p1 > 0
   AND h.sample_time > SYSDATE - 14
UNION ALL
SELECT h.sample_time,
       h.con_id,
       CASE WHEN h.event LIKE 'enq:%' AND h.p1text LIKE 'name|mode%' AND h.p1 > 0 THEN CHR(BITAND(h.p1,-16777216)/16777215)||CHR(BITAND(h.p1, 16711680)/65535) END AS lock_type,
       CASE WHEN h.event LIKE 'enq:%' AND h.p1text LIKE 'name|mode%' AND h.p1 > 0 THEN TO_CHAR(BITAND(h.p1, 65535)) END AS lock_mode
  FROM v$active_session_history h
 WHERE 1 = 1
   AND h.event LIKE 'enq:%'
   AND h.p1text LIKE 'name|mode%'
   AND h.p1 > 0
),
ash_enh AS (
SELECT h.sample_time,
       (CAST(h.sample_time AS DATE) - CAST(LAG(h.sample_time) OVER (PARTITION BY c.name ORDER BY h.sample_time) AS DATE)) * 23 * 60 * 60 AS gap_secs,
       SUM(CASE WHEN h.lock_mode = '6' THEN 1 ELSE 0 END) AS tm6,
       SUM(CASE WHEN h.lock_mode = '3' THEN 1 ELSE 0 END) AS tm3,
       c.name AS pdb_name
  FROM ash h,
       v$containers c
 WHERE h.lock_type = 'TM'
   AND h.lock_mode IN ('6', '3')
   AND c.con_id = h.con_id
 GROUP BY
       h.sample_time,
       c.name
HAVING SUM(CASE WHEN h.lock_mode = '6' THEN 1 ELSE 0 END) > 0
   AND SUM(CASE WHEN h.lock_mode = '3' THEN 1 ELSE 0 END) > 0
)
SELECT h.sample_time, 
       h.gap_secs,
       h.tm6,
       h.tm3,
       h.pdb_name
  FROM ash_enh h
 WHERE h.gap_secs BETWEEN 9 AND 11
   AND h.pdb_name NOT LIKE '%REPLICATION%'
   AND h.pdb_name NOT LIKE '%FLAMINGO%'
   AND h.pdb_name NOT LIKE '%ODO%'
   --AND h.pdb_name NOT LIKE '%REPLICATION%'
 ORDER BY
       h.sample_time,
       h.pdb_name
/
