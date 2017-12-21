SET HEA ON LIN 500 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF;

COL current_time NEW_V current_time FOR A15;
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
COL num_cpus NEW_V num_cpus;
SELECT TO_CHAR(value) num_cpus FROM v$osstat WHERE stat_name = 'NUM_CPUS';

CL BREAK
COL sql_text_100_only FOR A100 HEA 'SQL Text';
COL sample_date_time FOR A20 HEA 'Sample Date and Time';
COL samples FOR 9999,999 HEA 'Sessions';
COL on_cpu_or_wait_class FOR A14 HEA 'ON CPU or|Wait Class';
COL on_cpu_or_wait_event FOR A50 HEA 'ON CPU or Timed Event';
COL session_serial FOR A16 HEA 'Session,Serial';
COL machine FOR A60 HEA 'Application Server';
COL con_id FOR 999999;
COL plans FOR 99999 HEA 'Plans';
COL sessions FOR 9999,999 HEA 'Sessions|this SQL';

SPO ash_awr_and_mem_spikes_&&current_time..txt;
PRO HOST: &&x_host_name.
PRO NUM_CPU_CORES: &&num_cpu_cores.
PRO NUM_CPUS: &&num_cpus.
PRO DATABASE: &&x_db_name.
PRO CONTAINER: &&x_container.

PRO
PRO ASH AWR spikes by sample time and top SQL (spikes higher than &&num_cpus. cpus)
PRO ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

WITH 
ash_by_sample_and_sql AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       h.sample_time,
       h.sql_id,
       h.con_id,
       COUNT(*) samples,
       COUNT(DISTINCT h.sql_plan_hash_value) plans,
       ROW_NUMBER () OVER (PARTITION BY h.sample_time ORDER BY COUNT(*) DESC NULLS LAST, h.sql_id) row_number
  FROM dba_hist_active_sess_history h
 GROUP BY
       h.sample_time,
       h.sql_id,
       h.con_id
)
SELECT TO_CHAR(CAST(h.sample_time AS DATE), 'YYYY-MM-DD"T"HH24:MI:SS') sample_date_time,
       SUM(h.samples) samples,
       MAX(CASE h.row_number WHEN 1 THEN h.sql_id END) sql_id,
       SUM(CASE h.row_number WHEN 1 THEN h.samples ELSE 0 END) sessions,
       MAX(CASE WHEN h.row_number = 1 AND h.sql_id IS NOT NULL THEN h.plans END) plans,
       MAX(CASE h.row_number WHEN 1 THEN h.con_id END) con_id,       
       MAX(CASE WHEN h.row_number = 1 AND h.sql_id IS NOT NULL THEN (SELECT SUBSTR(q.sql_text, 1, 100) FROM v$sql q WHERE q.sql_id = h.sql_id AND ROWNUM = 1) END) sql_text_100_only
  FROM ash_by_sample_and_sql h
 GROUP BY
       h.sample_time
HAVING SUM(h.samples) >= &&num_cpus.
 ORDER BY
       h.sample_time
/

PRO
PRO ASH MEM spikes by sample time and top SQL (spikes higher than &&num_cpus. cpus)
PRO ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

WITH 
ash_by_sample_and_sql AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       h.sample_time,
       h.sql_id,
       h.con_id,
       COUNT(*) samples,
       COUNT(DISTINCT h.sql_plan_hash_value) plans,
       ROW_NUMBER () OVER (PARTITION BY h.sample_time ORDER BY COUNT(*) DESC NULLS LAST, h.sql_id) row_number
  FROM gv$active_session_history h
 GROUP BY
       h.sample_time,
       h.sql_id,
       h.con_id
)
SELECT TO_CHAR(CAST(h.sample_time AS DATE), 'YYYY-MM-DD"T"HH24:MI:SS') sample_date_time,
       SUM(h.samples) samples,
       MAX(CASE h.row_number WHEN 1 THEN h.sql_id END) sql_id,
       SUM(CASE h.row_number WHEN 1 THEN h.samples ELSE 0 END) sessions,
       MAX(CASE WHEN h.row_number = 1 AND h.sql_id IS NOT NULL THEN h.plans END) plans,
       MAX(CASE h.row_number WHEN 1 THEN h.con_id END) con_id,       
       MAX(CASE WHEN h.row_number = 1 AND h.sql_id IS NOT NULL THEN (SELECT SUBSTR(q.sql_text, 1, 100) FROM v$sql q WHERE q.sql_id = h.sql_id AND ROWNUM = 1) END) sql_text_100_only
  FROM ash_by_sample_and_sql h
 GROUP BY
       h.sample_time
HAVING SUM(h.samples) >= &&num_cpus.
 ORDER BY
       h.sample_time
/

SPO OFF;
