SET HEA ON LIN 500 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF;
SET PAGES 100;
PRO
COL time_from_default NEW_V time_from_default NOPRI;
COL time_to_default NEW_V time_to_default NOPRI;
SELECT TO_CHAR(TRUNC(MIN(sample_time),'MI'),'YYYY-MM-DD"T"HH24:MI:SS') time_from_default, 
       TO_CHAR(TRUNC(MAX(sample_time),'MI')-(1/24/60/60),'YYYY-MM-DD"T"HH24:MI:SS') time_to_default 
  FROM v$active_session_history
/
COL current_time NEW_V current_time NOPRI;
SELECT TO_CHAR(SYSDATE, 'YYYY-MM-DD"T"HH24:MI:SS') current_time FROM DUAL
/
PRO
PRO Current time: &&current_time.
PRO
PRO 1. Enter time FROM (default &&time_from_default.):
COL sample_time_from NEW_V sample_time_from NOPRI;
SELECT NVL('&&1.','&&time_from_default.') sample_time_from FROM DUAL
/
PRO
PRO 2. Enter time TO (default &&time_to_default.):
COL sample_time_to NEW_V sample_time_to NOPRI;
SELECT NVL('&&2.','&&time_to_default.') sample_time_to FROM DUAL
/
PRO 3. Enter SQL_ID (optional):
DEF sql_id = '&&3.';
PRO
SELECT 'current_time: ' x, TO_CHAR(SYSDATE, 'YYYYMMDD_HH24MISS') current_time FROM DUAL;
COL x_host_name NEW_V x_host_name;
SELECT host_name x_host_name FROM v$instance;
COL x_db_name NEW_V x_db_name;
SELECT name x_db_name FROM v$database;
COL x_container NEW_V x_container;
SELECT 'NONE' x_container FROM DUAL;
SELECT SYS_CONTEXT('USERENV', 'CON_NAME') x_container FROM DUAL;
COL num_cpu_cores NEW_V num_cpu_cores;
SELECT TO_CHAR(value) num_cpu_cores FROM v$osstat WHERE stat_name = 'NUM_CPU_CORES';
PRO
COL aas_total FOR 999,990.0 HEA 'AAS|TOTAL';
COL aas_on_cpu FOR 999,990.0 HEA 'AAS|ON_CPU';
COL aas_user_io FOR 999,990.0 HEA 'AAS|USER_IO';
COL aas_system_io FOR 999,990.0 HEA 'AAS|SYSTEM_IO';
COL aas_cluster FOR 999,990.0 HEA 'AAS|CLUSTER';
COL aas_commit FOR 999,990.0 HEA 'AAS|COMMIT';
COL aas_concurrency FOR 999,990.0 HEA 'AAS|CONCURRENCY';
COL aas_application FOR 999,990.0 HEA 'AAS|APPLICATION';
COL aas_administrative FOR 999,990.0 HEA 'AAS|ADMIN';
COL aas_configuration FOR 999,990.0 HEA 'AAS|CONFIG';
COL aas_network FOR 999,990.0 HEA 'AAS|NETWORK';
COL aas_queueing FOR 999,990.0 HEA 'AAS|QUEUEING';
COL aas_scheduler FOR 999,990.0 HEA 'AAS|SCHEDULER';
COL aas_other FOR 999,990.0 HEA 'AAS|OTHER';
PRO
BREAK ON REPORT;
COMPUTE AVG LABEL 'AVERAGE' OF aas_total aas_on_cpu aas_user_io aas_system_io aas_cluster aas_commit aas_concurrency aas_application aas_administrative aas_configuration aas_network aas_queueing aas_scheduler aas_other ON REPORT;
PRO
COL output_file_name NEW_V output_file_name NOPRI;
SELECT 'ash_mem_report_'||LOWER(name)||'_'||LOWER(REPLACE(SUBSTR(host_name, 1 + INSTR(host_name, '.', 1, 2), 30), '.', '_'))||'_'||REPLACE(LOWER(SYS_CONTEXT('USERENV','CON_NAME')),'$')||'_'||(CASE WHEN '&&sql_id.' IS NOT NULL THEN '&&sql_id._' END)||TO_CHAR(SYSDATE, 'YYYYMMDD_HH24MISS') output_file_name FROM v$database, v$instance;
PRO
SPO &&output_file_name..txt;
PRO
PRO SQL>@ash_mem_report.sql "&&1." "&&2." "&&3."
PRO
PRO &&output_file_name..txt
PRO
PRO DATABASE: &&x_db_name.
PRO PDB: &&x_container.
PRO HOST: &&x_host_name.
PRO CORES: &&num_cpu_cores.
PRO SQL_ID: &&sql_id.
PRO SAMPLE_TIME_FROM: &&sample_time_from.
PRO SAMPLE_TIME_TO: &&sample_time_to.
PRO
PRO Average Active Sessions (AAS) &&x_container. &&sql_id. 
PRO ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
SELECT TO_CHAR(TRUNC(sample_time, 'MI'), 'YYYY-MM-DD"T"HH24:MI') time,
       ROUND(COUNT(*)/60,1) aas_total, -- average active sessions on the database (on cpu or waiting)
       ROUND(SUM(CASE session_state WHEN 'ON CPU'         THEN 1 ELSE 0 END)/60,1) aas_on_cpu,
       ROUND(SUM(CASE wait_class    WHEN 'User I/O'       THEN 1 ELSE 0 END)/60,1) aas_user_io,
       ROUND(SUM(CASE wait_class    WHEN 'System I/O'     THEN 1 ELSE 0 END)/60,1) aas_system_io,
       ROUND(SUM(CASE wait_class    WHEN 'Cluster'        THEN 1 ELSE 0 END)/60,1) aas_cluster,
       ROUND(SUM(CASE wait_class    WHEN 'Commit'         THEN 1 ELSE 0 END)/60,1) aas_commit,
       ROUND(SUM(CASE wait_class    WHEN 'Concurrency'    THEN 1 ELSE 0 END)/60,1) aas_concurrency,
       ROUND(SUM(CASE wait_class    WHEN 'Application'    THEN 1 ELSE 0 END)/60,1) aas_application,
       ROUND(SUM(CASE wait_class    WHEN 'Administrative' THEN 1 ELSE 0 END)/60,1) aas_administrative,
       ROUND(SUM(CASE wait_class    WHEN 'Configuration'  THEN 1 ELSE 0 END)/60,1) aas_configuration,
       ROUND(SUM(CASE wait_class    WHEN 'Network'        THEN 1 ELSE 0 END)/60,1) aas_network,
       ROUND(SUM(CASE wait_class    WHEN 'Queueing'       THEN 1 ELSE 0 END)/60,1) aas_queueing,
       ROUND(SUM(CASE wait_class    WHEN 'Scheduler'      THEN 1 ELSE 0 END)/60,1) aas_scheduler,
       ROUND(SUM(CASE wait_class    WHEN 'Other'          THEN 1 ELSE 0 END)/60,1) aas_other
  FROM v$active_session_history
 WHERE sample_time BETWEEN TO_TIMESTAMP('&&sample_time_from.', 'YYYY-MM-DD"T"HH24:MI:SS') AND TO_TIMESTAMP('&&sample_time_to.', 'YYYY-MM-DD"T"HH24:MI:SS')
   AND ('&&sql_id.' IS NULL OR sql_id = '&&sql_id.')
 GROUP BY
       TRUNC(sample_time, 'MI')
 ORDER BY
       1
/
PRO
PRO &&output_file_name..txt
PRO
SPO OFF;
UNDEF 1 2 3 sql_id
CLEAR BREAK COMPUTE COLUMNS