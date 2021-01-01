----------------------------------------------------------------------------------------
--
-- File name:   dba_high_water_mark_statistics.sql
--
-- Purpose:     Database High Water Mark (HWM) Statistics
--
-- Author:      Carlos Sierra
--
-- Version:     2020/12/16
--
-- Usage:       Execute connected to CDB or PDB
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @dba_high_water_mark_statistics.sql
--
-- Notes:       Developed and tested on 12.1.0.2.
--
---------------------------------------------------------------------------------------
--
SET HEA ON LIN 2490 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF LONG 240000 LONGC 2400 NUM 20 SERVEROUT OFF;
--
COL version FOR A12;
COL name FOR A20;
COL description FOR A60;
BREAK ON version SKIP PAGE DUPL;
--
PRO
PRO dba_high_water_mark_statistics
PRO ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
SELECT version, name, highwater, last_value, description
  FROM dba_high_water_mark_statistics
ORDER BY version, name
/
--
PRO
PRO v$license
PRO ~~~~~~~~~
SELECT * 
  FROM v$license
/
--
COL resource_name FOR A30;
PRO
PRO v$resource_limit
PRO ~~~~~~~~~~~~~~~~
SELECT resource_name, current_utilization, max_utilization, initial_allocation, limit_value
  FROM v$resource_limit
 ORDER BY resource_name
/
