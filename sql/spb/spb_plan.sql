DEF spb_script = 'spb_plan';
----------------------------------------------------------------------------------------
--
-- File name:   spb_plan.sql
--
-- Purpose:     Display SQL Plan Baseline for given SQL_ID
--
-- Author:      Carlos Sierra
--
-- Version:     2018/05/13
--
-- Usage:       Connecting into PDB.
--
--              Enter SQL_ID when requested.
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @spb_plan.sql
--
-- Notes:       Accesses AWR data thus you must have an Oracle Diagnostics Pack License.
--
--              Developed and tested on 12.1.0.2.
--
---------------------------------------------------------------------------------------
--
@@spb_internal_begin.sql
--
---------------------------------------------------------------------------------------
--
@@spb_internal_plans_perf.sql
--
---------------------------------------------------------------------------------------
--
PRO
PRO BASELINES SUMMARY
PRO ~~~~~~~~~~~~~~~~~
@@spb_internal_list.sql
--
---------------------------------------------------------------------------------------
--
PRO
PRO SQL PLAN BASELINES
PRO ~~~~~~~~~~~~~~~~~~
@@spb_internal_plan.sql
--
---------------------------------------------------------------------------------------
--
PRO
PRO BASELINES SUMMARY
PRO ~~~~~~~~~~~~~~~~~
@@spb_internal_list.sql
--
@@spb_internal_end.sql
