----------------------------------------------------------------------------------------
--
-- File name:   cs_vcn_events.sql
--
-- Purpose:     Detect EVENTS_RGN stuck on a KIEV VCN PDB
--
-- Author:      Carlos Sierra
--
-- Version:     2020/12/09
--
-- Usage:       Execute connected to VCN PDB.
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @cs_vcn_events.sql
--
-- Notes:       Developed and tested on 12.1.0.2.
--
---------------------------------------------------------------------------------------
--
SET HEA ON LIN 2490 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF LONG 240000 LONGC 2400 SERVEROUT OFF;
--
COL events_rgn_owner NEW_V events_rgn_owner;
SELECT owner events_rgn_owner FROM dba_tables WHERE table_name = 'EVENTS_RGN';
--
COL name FOR A200;
COL name FOR A40 TRUNC;
--
WITH 
events_rgn_sq AS (
SELECT name, kievlive, kievtxnid, MAX(kievtxnid) OVER (PARTITION BY name) max_kievtxnid
  FROM &&events_rgn_owner..events_rgn
)
SELECT TO_CHAR(kt.begintime, 'YYYY-MM-DD"T"HH24:MI:SS') begintime,
       (SYSDATE - CAST(kt.begintime AS DATE)) * 24 * 3600 age_in_seconds,
       --ROUND((SYSDATE - CAST(kt.begintime AS DATE)) * 24, 1) age_in_hours,
       --ROUND((SYSDATE - CAST(kt.begintime AS DATE)), 1) age_in_days,
       sq.kievtxnid, sq.name
  FROM events_rgn_sq sq,
       &&events_rgn_owner..kievtransactions kt
 WHERE sq.kievtxnid = sq.max_kievtxnid
   AND sq.kievlive = 'Y'
   AND kt.committransactionid(+) = sq.kievtxnid
 ORDER BY
       1,2
FETCH FIRST 1000 ROWS ONLY
/
