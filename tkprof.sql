----------------------------------------------------------------------------------------
--
-- File name:   tkprof.sql
--
-- Purpose:     Turns trace off and generates a TKPROF for trace under current session
--
-- Author:      Carlos Sierra
--
-- Version:     2013/10/15
--
-- Usage:       This scripts does not have parameters. Turn trace on, execute one or
--              many SQL statements, then execute this script. It will produce and
--              display a TKPROF out of your own trace.
--
-- Example:     @trace_on.sql
--              <any set of sql statements>
--              @tkprof.sql             
--
-- Description:
--
--              This script turns trace off, then it finds the name of the current 
--              session's trace and generates a TKPROF report out of it. Last, it shows
--              the generated TKPROF.
--              
--  Notes:            
--              
--              Be sure you turn trace on (event 10046 any level) before using this
--              script.
-- 
--              Developed and tested on 11.2.0.3
--
---------------------------------------------------------------------------------------
--
ALTER SESSION SET STATISTICS_LEVEL = 'TYPICAL';
ALTER SESSION SET SQL_TRACE = FALSE;
COL trace NEW_V trace;
SELECT value trace FROM v$diag_info WHERE name = 'Default Trace File';
HOS tkprof &&trace. &&_user._tkprof.txt sort=prsela exeela fchela 
HOS more &&_user._tkprof.txt
--
-- end