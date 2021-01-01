----------------------------------------------------------------------------------------
--
-- File name:   cs_tempseg_usage.sql
--
-- Purpose:     Temporary (Temp) Segment Usage (text report)
--
-- Author:      Carlos Sierra
--
-- Version:     2020/12/09
--
-- Usage:       Execute connected to CDB or PDB.
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @cs_tempseg_usage.sql
--
-- Notes:       Developed and tested on 12.1.0.2.
--
---------------------------------------------------------------------------------------
--
SET HEA ON LIN 2490 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF LONG 240000 LONGC 2400 NUM 20 SERVEROUT OFF;
ALTER SESSION SET NLS_DATE_FORMAT = 'YYYY-MM-DD"T"HH24:MI:SS';

SELECT SUM(blocks) AS blocks,
       COUNT(DISTINCT session_addr) AS sessions,
       sql_id, segtype, tablespace
  FROM v$tempseg_usage
 GROUP BY
       sql_id, segtype, tablespace
 ORDER BY
       1 DESC
/


SET HEA ON LIN 2490 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF LONG 240000 LONGC 2400 NUM 20 SERVEROUT OFF;
ALTER SESSION SET NLS_DATE_FORMAT = 'YYYY-MM-DD"T"HH24:MI:SS';

COL age_secs FOR 999,990;
COL last_call_secs FOR 999,990;
COL sid_serial FOR A13;
COL mbs FOR 999,990 HEA 'MBs';
--
BREAK ON machine SKIP PAGE DUPL;
--
SELECT /*+ OPT_PARAM('_px_cdb_view_enabled' 'FALSE') */ 
       s.machine,
       s.logon_time,
       (SYSDATE - s.logon_time) * 24 * 3600 AS age_secs,
       s.last_call_et AS last_call_secs,
       s.status,
       s.sid||','||s.serial# AS sid_serial,
       SUM(t.blocks * block_size)/1e6 AS mbs
  FROM v$tempseg_usage t,
       v$session s,
       cdb_tablespaces c
 WHERE s.con_id = t.con_id
   AND s.saddr = t.session_addr
   AND s.serial# = t.session_num
   AND c.con_id = t.con_id
   AND c.tablespace_name = t.tablespace
 GROUP BY
       s.machine, s.logon_time, s.last_call_et, s.status, s.sid, s.serial#
 ORDER BY
       s.machine, s.logon_time, s.last_call_et, s.status, s.sid, s.serial#
/

