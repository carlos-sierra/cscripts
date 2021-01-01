----------------------------------------------------------------------------------------
--
-- File name:   cs_wf_instances.sql
--
-- Purpose:     WF Instance and Step Instances counts on a KIEV WF PDB
--
-- Author:      Carlos Sierra
--
-- Version:     2020/12/09
--
-- Usage:       Execute connected to WF PDB.
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @cs_wf_instances.sql
--
-- Notes:       Developed and tested on 12.1.0.2.
--
---------------------------------------------------------------------------------------
--
SET HEA ON LIN 2490 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF LONG 240000 LONGC 2400 NUM 20 SERVEROUT OFF;
COL owner NEW_V owner NOPRI;
SELECT owner FROM dba_tables WHERE table_name = 'STEPINSTANCES' ORDER BY num_rows;\

PRO
PRO STEPINSTANCES
PRO ~~~~~~~~~~~~~
SELECT COUNT(*), workflowInstanceId FROM &&owner..STEPINSTANCES GROUP BY workflowInstanceId ORDER BY 1 DESC FETCH FIRST 30 ROWS ONLY;

PRO
PRO HISTORICALASSIGNMENT
PRO ~~~~~~~~~~~~~~~~~~~~
SELECT COUNT(*), workflowInstanceId FROM &&owner..HISTORICALASSIGNMENT GROUP BY workflowInstanceId ORDER BY 1 DESC FETCH FIRST 30 ROWS ONLY;

PRO
PRO HISTORICALASSIGNMENT
PRO ~~~~~~~~~~~~~~~~~~~~
SELECT COUNT(*), STEPINSTANCESEQ FROM &&owner..HISTORICALASSIGNMENT GROUP BY STEPINSTANCESEQ ORDER BY 1 DESC FETCH FIRST 30 ROWS ONLY;

PRO
PRO LEASEDECORATORS
PRO ~~~~~~~~~~~~~~~
SELECT COUNT(*), workflowInstanceId FROM &&owner..LEASEDECORATORS GROUP BY workflowInstanceId ORDER BY 1 DESC FETCH FIRST 30 ROWS ONLY;

