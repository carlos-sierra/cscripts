----------------------------------------------------------------------------------------
--
-- File name:   iod_indexes_rebuild_online_mon.sql
--
-- Purpose:     Monitors execution of iod_indexes_rebuild_online.sql
--
-- Author:      Carlos Sierra
--
-- Version:     2017/10/01
--
-- Usage:       Execute on CDB$ROOT. OEM ready.
--
-- Example:     @iod_indexes_rebuild_online_mon.sql
--
---------------------------------------------------------------------------------------
SET SERVEROUT ON ECHO OFF FEED OFF VER OFF TAB OFF LINES 300 TRIMS ON TRIM ON TI OFF TIMI OFF;
SHOW PDBS;
COL action FOR A32;
PRO
PRO IOD sessions
PRO ~~~~~~~~~~~~
SELECT sid, serial#, module, action, last_call_et et_secs
  FROM v$session
 WHERE status = 'ACTIVE'
   AND type = 'USER'
   AND module LIKE '%IOD%'
 ORDER BY
       sid, serial#
/
