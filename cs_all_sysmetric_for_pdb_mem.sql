----------------------------------------------------------------------------------------
--
-- File name:   cs_all_sysmetric_for_pdb_mem.sql
--
-- Purpose:     All System Metrics as per V$CON_SYSMETRIC Views for a PDB (text report)
--
-- Author:      Carlos Sierra
--
-- Version:     2021/04/06
--
-- Usage:       Execute connected to CDB or PDB
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @cs_all_sysmetric_for_pdb_mem.sql
--
-- Notes:       Developed and tested on 19c.
--
---------------------------------------------------------------------------------------
--
DEF view_name_prefix = 'v$con_sysmetric';
DEF common_predicate = "con_id = SYS_CONTEXT('USERENV', 'CON_ID')";
DEF script_name = 'cs_all_sysmetric_for_pdb_mem';
--
COL cs_date NEW_V cs_date NOPRI;
COL cs_host NEW_V cs_host NOPRI;
COL cs_db NEW_V cs_db NOPRI;
COL cs_con NEW_V cs_con NOPRI;
SELECT TO_CHAR(SYSDATE, 'YYYY-MM-DD"T"HH24:MI:SS') AS cs_date, SYS_CONTEXT('USERENV','HOST') AS cs_host, UPPER(name) AS cs_db, SYS_CONTEXT('USERENV', 'CON_NAME') AS cs_con FROM v$database;
--
SET TERM ON HEA ON LIN 2490 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF LONG 240000 LONGC 2400 NUM 20 SERVEROUT OFF;
ALTER SESSION SET NLS_DATE_FORMAT = 'YYYY-MM-DD"T"HH24:MI:SS';
COL report_date_time NEW_V report_date_time NOPRI;
SELECT TO_CHAR(SYSDATE, 'YYYY-MM-DD"T"HH24.MI.SS"Z"') AS report_date_time FROM DUAL;
--
SPO /tmp/&&script_name._&&report_date_time..txt
PRO /tmp/&&script_name._&&report_date_time..txt
PRO
PRO Date     : &&cs_date.
PRO Host     : &&cs_host.
PRO Database : &&cs_db.
PRO Container: &&cs_con.
--
COL metric_name FOR A45 TRUN;
COL metric_unit FOR A41 TRUN;
COL seconds FOR 9,900.00;
--
PRO
PRO System Metrics by Name (&&view_name_prefix. and &&view_name_prefix._summary)
PRO ~~~~~~~~~~~~~~~~~~~~~~
SELECT metric_name,
       intsize_csec/100 AS seconds,
       begin_time,
       end_time,
       value AS average,
       TO_NUMBER(NULL) AS maxval,
       metric_unit
  FROM &&view_name_prefix.
 WHERE &&common_predicate.
 UNION ALL
SELECT metric_name,
       intsize_csec/100 AS seconds,
       begin_time,
       end_time,
       average,
       maxval,
       metric_unit
  FROM &&view_name_prefix._summary
 WHERE &&common_predicate.
 ORDER BY
       1, 2
/
--
PRO
PRO System Metrics by Unit and Name (&&view_name_prefix. and &&view_name_prefix._summary)
PRO ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
SELECT metric_unit,
       metric_name,
       intsize_csec/100 AS seconds,
       begin_time,
       end_time,
       value AS average,
       TO_NUMBER(NULL) AS maxval
  FROM &&view_name_prefix.
 WHERE &&common_predicate.
 UNION ALL
SELECT metric_unit,
       metric_name,
       intsize_csec/100 AS seconds,
       begin_time,
       end_time,
       average,
       maxval
  FROM &&view_name_prefix._summary
 WHERE &&common_predicate.
 ORDER BY
       1, 2, 3
/
--
PRO
PRO SQL> @&&script_name..sql 
SPO OFF;
PRO
PRO /tmp/&&script_name._&&report_date_time..txt
--