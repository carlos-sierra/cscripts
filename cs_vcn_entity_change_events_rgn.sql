----------------------------------------------------------------------------------------
--
-- File name:   cs_vcn_entity_change_events_rgn.sql
--
-- Purpose:     Detect ENTITY_CHANGE_EVENTS_rgn stuck on a KIEV VCN PDB
--
-- Author:      Carlos Sierra
--
-- Version:     2022/11/01
--
-- Usage:       Execute connected to VCN PDB.
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @cs_vcn_entity_change_events_rgn.sql
--
-- Notes:       Developed and tested on 12.1.0.2. 
--
---------------------------------------------------------------------------------------
--
SET HEA ON LIN 2490 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF LONG 240000 LONGC 2400 SERVEROUT OFF;
--
COL events_rgn_owner NEW_V events_rgn_owner;
SELECT owner events_rgn_owner FROM dba_tables WHERE table_name = UPPER('ENTITY_CHANGE_EVENTS_rgn');
--
COL begintime FOR A23;
COL name FOR A200;
COL old_begintime FOR A23;
COL cnt FOR 999,999,990;
--
PRO
PRO Total Events
PRO ~~~~~~~~~~~~
WITH 
e AS (
SELECT COUNT(*) AS cnt,
       MIN(e.kievtxnid) AS min_kievtxnid
  FROM &&events_rgn_owner..ENTITY_CHANGE_EVENTS_rgn e
)
SELECT e.cnt, kt.begintime AS old_begintime
  FROM &&events_rgn_owner..kievtransactions kt, e
 WHERE kt.committransactionid = e.min_kievtxnid
/
PRO
PRO Oldest Events
PRO ~~~~~~~~~~~~~
WITH 
events_rgn_sq AS (
SELECT name, kievlive, kievtxnid, MAX(kievtxnid) OVER (PARTITION BY name) max_kievtxnid
  FROM &&events_rgn_owner..ENTITY_CHANGE_EVENTS_rgn
)
SELECT kt.begintime,
       (SYSDATE - CAST(kt.begintime AS DATE)) * 24 * 3600 age_in_seconds,
       ROUND((SYSDATE - CAST(kt.begintime AS DATE)) * 24, 1) age_in_hours,
       ROUND((SYSDATE - CAST(kt.begintime AS DATE)), 1) age_in_days,
       sq.kievtxnid, sq.name
  FROM events_rgn_sq sq,
       &&events_rgn_owner..kievtransactions kt
 WHERE sq.kievtxnid = sq.max_kievtxnid
   AND sq.kievlive = 'Y'
   AND kt.committransactionid(+) = sq.kievtxnid
 ORDER BY
       1,2
FETCH FIRST 10 ROWS ONLY
/
--
PRO
PRO Oldest Event
PRO ~~~~~~~~~~~~
SELECT MIN(kt.begintime) AS begintime,
       (SYSDATE - CAST(MIN(kt.begintime) AS DATE)) * 24 * 3600 age_in_seconds,
       ROUND((SYSDATE - CAST(MIN(kt.begintime) AS DATE)) * 24, 1) age_in_hours,
       ROUND((SYSDATE - CAST(MIN(kt.begintime) AS DATE)), 1) age_in_days
  FROM &&events_rgn_owner..kievtransactions kt
 WHERE kt.committransactionid = (SELECT MIN(e.kievtxnid) FROM &&events_rgn_owner..ENTITY_CHANGE_EVENTS_rgn e)
/
--
COL changeevent FOR A100;
PRO
PRO Oldest Event
PRO ~~~~~~~~~~~~
SELECT e.* 
  FROM &&events_rgn_owner..ENTITY_CHANGE_EVENTS_rgn e, &&events_rgn_owner..kievtransactions kt
 WHERE kt.committransactionid = e.kievtxnid
 ORDER BY
       e.kievtxnid
 FETCH FIRST 1 ROW ONLY
/
--
COL entityId FOR A100 HEA 'entityId';
COL compartmentId FOR A100 HEA 'compartmentId';
PRO
PRO Top entityId + compartmentId
PRO ~~~~~~~~~~~~~~~~~~~~~~~~~~~~
SELECT COUNT(*) AS cnt,
       JSON_VALUE(changeevent, '$.entityId') AS entityId,
       JSON_VALUE(changeevent, '$.compartmentId') AS compartmentId
  FROM &&events_rgn_owner..ENTITY_CHANGE_EVENTS_rgn e, &&events_rgn_owner..kievtransactions kt
 WHERE kt.committransactionid = e.KievTxnID
 GROUP BY
       JSON_VALUE(changeevent, '$.entityId'),
       JSON_VALUE(changeevent, '$.compartmentId')
 ORDER BY
       1 DESC
 FETCH FIRST 10 ROW ONLY
/

