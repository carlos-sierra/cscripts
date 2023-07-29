----------------------------------------------------------------------------------------
--
-- File name:   cs_systemstate.sql
--
-- Purpose:     Generate System State Dump Trace
--
-- Author:      Carlos Sierra
--
-- Version:     2020/12/09
--
-- Usage:       Execute connected to CDB or PDB.
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @cs_systemstate.sql
--
-- Notes:       Developed and tested on 12.1.0.2.
--
---------------------------------------------------------------------------------------
--
ALTER SESSION SET tracefile_identifier = 'iod_systemstate';
COL trace_file NEW_V trace_file;
SELECT value trace_file FROM v$diag_info WHERE name = 'Default Trace File';
oradebug setmypid
oradebug unlimit
oradebug dump systemstate 266 
oradebug tracefile_name 
HOS cp &&trace_file. /tmp
