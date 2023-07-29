----------------------------------------------------------------------------------------
--
-- File name:   cs_tempseg_usage.sql
--
-- Purpose:     Temporary (Temp) Segment Usage (text report)
--
-- Author:      Carlos Sierra
--
-- Version:     2023/03/08
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
--
COL pdb_name FOR A30;
SELECT SUM(t.blocks) AS blocks,
       COUNT(DISTINCT t.session_addr) AS sessions,
       t.con_id, c.name AS pdb_name, t.sql_id, t.sql_id_tempseg, t.segtype, t.tablespace
  FROM v$tempseg_usage t, v$containers c
 WHERE c.con_id = t.con_id
 GROUP BY
       t.con_id, c.name, t.sql_id, t.sql_id_tempseg, t.segtype, t.tablespace
 ORDER BY
       1 DESC
/
--
COL age_secs FOR 999,999,990;
COL last_call_secs FOR 999,999,990;
COL sid_serial FOR A13;
COL mbs FOR 999,990 HEA 'MBs';
COL sid_serial FOR A12;
BREAK ON machine SKIP PAGE DUPL;
--
SELECT /*+ OPT_PARAM('_px_cdb_view_enabled' 'FALSE') */ 
       s.machine,
       s.logon_time,
       (SYSDATE - s.logon_time) * 24 * 3600 AS age_secs,
       s.last_call_et AS last_call_secs,
       s.status,
       t.con_id,
       v.name AS pdb_name,
       s.sid||','||s.serial# AS sid_serial,
       s.type,
       s.sql_id,
       s.prev_sql_id,
       SUM(t.blocks * c.block_size)/1e6 AS mbs
  FROM v$tempseg_usage t,
       v$session s,
       cdb_tablespaces c,
       v$containers v
 WHERE s.con_id = t.con_id
   AND s.saddr = t.session_addr
   AND s.serial# = t.session_num
   AND c.con_id = t.con_id
   AND c.tablespace_name = t.tablespace
   AND v.con_id = c.con_id
 GROUP BY
       s.machine, s.logon_time, s.last_call_et, s.status, t.con_id, v.name, s.sid, s.serial#, s.type, s.sql_id, s.prev_sql_id
 ORDER BY
       s.machine, s.logon_time, s.last_call_et, s.status, t.con_id, v.name, s.sid, s.serial#, s.type, s.sql_id, s.prev_sql_id
/
-- PRO
-- PRO v$tempseg_usage
-- PRO ~~~~~~~~~~~~~~~
-- @@cs_internal/cs_pr_internal.sql "SELECT * FROM v$tempseg_usage;"
--