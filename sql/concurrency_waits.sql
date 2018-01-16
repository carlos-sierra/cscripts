SET HEA ON LIN 500 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF;

WHENEVER SQLERROR EXIT SUCCESS;
PRO
PRO Error "ORA-01476: divisor is equal to zero" just means v$database.open_mode is not "READ WRITE"
SELECT CASE open_mode WHEN 'READ WRITE' THEN open_mode ELSE TO_CHAR(1/0) END open_mode FROM v$database;

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
COL output_file_name NEW_V output_file_name;
SELECT 'concurrency_waits_'||LOWER(name)||'_'||LOWER(REPLACE(SUBSTR(host_name, 1 + INSTR(host_name, '.', 1, 2), 30), '.', '_'))||'_'||TO_CHAR(SYSDATE, 'YYYYMMDD_HH24MISS') output_file_name FROM v$database, v$instance;
BRE ON sample_date SKIP 1;

COL total_samples HEA 'TOTAL|SAMPLES';
COL library_cache_lock HEA 'LIBRARY|CACHE|LOCK';
COL library_cache_mutex_x HEA 'LIBRARY|CACHE|MUTEX';
COL cursor_pin_S_wait_on_X HEA 'CURSOR|PIN S|WAIT ON X';
COL cursor_mutex_X HEA 'CURSOR|MUTEX X';
COL cursor_pin_S HEA 'CURSOR|PIN S';
COL cursor_mutex_S HEA 'CURSOR|MUTEX S';
COL buffer_busy_waits HEA 'BUFFER|BUSY|WAITS';
COL resmgr_internal_state_change HEA 'RESMGR|INTERNAL|STATE CHANGE';
COL enq_TX_index_contention HEA 'ENQ|TX INDEX|CONTENTION';
COL latch_shared_pool HEA 'LATCH|SHARED POOL';
COL latch_row_cache_objects HEA 'LATCH|ROW CACHE|OBJECTS';
COL total_samples_sql_id HEA 'TOTAL SAMPLES|FOR SQL_ID';
COL pdb_name FOR A30;

SPO &&output_file_name..txt;
PRO HOST: &&x_host_name.
PRO NUM_CPU_CORES: &&num_cpu_cores.
PRO NUM_CPUS: &&num_cpus.
PRO DATABASE: &&x_db_name.
PRO CONTAINER: &&x_container.

PRO
PRO dba_hist_active_sess_history (spikes higher than &&num_cpu_cores. cores)
PRO ~~~~~~~~~~~~~~~~~~~~~~~~~~~~
WITH 
pdbs AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       con_id,
       pdb_name
  FROM dba_pdbs
),
ash_by_sample_and_sql AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       sample_time sample_date_time,
       sql_id,
       con_id,
       COUNT(*) total_samples,
       ROW_NUMBER () OVER (PARTITION BY sample_time ORDER BY COUNT(*) DESC NULLS LAST, sql_id) row_number,
       SUM(CASE event WHEN 'library cache lock' THEN 1 ELSE 0 END) library_cache_lock,
       SUM(CASE event WHEN 'library cache: mutex X' THEN 1 ELSE 0 END) library_cache_mutex_x,
       SUM(CASE event WHEN 'cursor: pin S wait on X' THEN 1 ELSE 0 END) cursor_pin_S_wait_on_X,
       SUM(CASE event WHEN 'cursor: mutex X' THEN 1 ELSE 0 END) cursor_mutex_X,
       SUM(CASE event WHEN 'cursor: pin S' THEN 1 ELSE 0 END) cursor_pin_S,
       SUM(CASE event WHEN 'cursor: mutex S' THEN 1 ELSE 0 END) cursor_mutex_S,
       SUM(CASE event WHEN 'buffer busy waits' THEN 1 ELSE 0 END) buffer_busy_waits,
       SUM(CASE event WHEN 'resmgr:internal state change' THEN 1 ELSE 0 END) resmgr_internal_state_change,
       SUM(CASE event WHEN 'enq: TX - index contention' THEN 1 ELSE 0 END) enq_TX_index_contention,
       SUM(CASE event WHEN 'latch: shared pool' THEN 1 ELSE 0 END) latch_shared_pool,
       SUM(CASE event WHEN 'latch: row cache objects' THEN 1 ELSE 0 END) latch_row_cache_objects
  FROM dba_hist_active_sess_history
 WHERE wait_class = 'Concurrency'
 GROUP BY
       sample_time,
       sql_id,
       con_id
),
outliers AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       sample_date_time,
       TO_CHAR(sample_date_time, 'YYYY-MM-DD') sample_date,
       TO_CHAR(sample_date_time, 'HH24:MI:SS') sample_time,
       SUM(total_samples) total_samples,
       SUM(library_cache_lock) library_cache_lock,
       SUM(library_cache_mutex_x) library_cache_mutex_x,
       SUM(cursor_pin_S_wait_on_X) cursor_pin_S_wait_on_X,
       SUM(cursor_mutex_X) cursor_mutex_X,
       SUM(cursor_pin_S) cursor_pin_S,
       SUM(cursor_mutex_S) cursor_mutex_S,
       SUM(buffer_busy_waits) buffer_busy_waits,
       SUM(resmgr_internal_state_change) resmgr_internal_state_change,
       SUM(enq_TX_index_contention) enq_TX_index_contention,
       SUM(latch_shared_pool) latch_shared_pool,
       SUM(latch_row_cache_objects) latch_row_cache_objects,
       MAX(CASE row_number WHEN 1 THEN con_id END) con_id,       
       MAX(CASE row_number WHEN 1 THEN sql_id END) sql_id,
       SUM(CASE row_number WHEN 1 THEN total_samples ELSE 0 END) total_samples_sql_id
  FROM ash_by_sample_and_sql
 GROUP BY
       sample_date_time
HAVING SUM(total_samples) > &&num_cpu_cores.
)
SELECT o.sample_date,
       o.sample_time,
       o.total_samples,
       o.library_cache_lock,
       o.library_cache_mutex_x,
       o.cursor_pin_S_wait_on_X,
       o.cursor_mutex_X,
       o.cursor_pin_S,
       o.cursor_mutex_S,
       o.buffer_busy_waits,
       o.resmgr_internal_state_change,
       o.enq_TX_index_contention,
       o.latch_shared_pool,
       o.latch_row_cache_objects,
       o.con_id,   
       p.pdb_name,    
       o.sql_id,
       o.total_samples_sql_id
  FROM outliers o, 
       pdbs p
 WHERE p.con_id = o.con_id
 ORDER BY
       o.sample_date_time
/

PRO
PRO v$active_session_history (spikes higher than &&num_cpu_cores. cores)
PRO ~~~~~~~~~~~~~~~~~~~~~~~~
WITH 
pdbs AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       con_id,
       pdb_name
  FROM dba_pdbs
),
ash_by_sample_and_sql AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       sample_time sample_date_time,
       sql_id,
       con_id,
       COUNT(*) total_samples,
       ROW_NUMBER () OVER (PARTITION BY sample_time ORDER BY COUNT(*) DESC NULLS LAST, sql_id) row_number,
       SUM(CASE event WHEN 'library cache lock' THEN 1 ELSE 0 END) library_cache_lock,
       SUM(CASE event WHEN 'library cache: mutex X' THEN 1 ELSE 0 END) library_cache_mutex_x,
       SUM(CASE event WHEN 'cursor: pin S wait on X' THEN 1 ELSE 0 END) cursor_pin_S_wait_on_X,
       SUM(CASE event WHEN 'cursor: mutex X' THEN 1 ELSE 0 END) cursor_mutex_X,
       SUM(CASE event WHEN 'cursor: pin S' THEN 1 ELSE 0 END) cursor_pin_S,
       SUM(CASE event WHEN 'cursor: mutex S' THEN 1 ELSE 0 END) cursor_mutex_S,
       SUM(CASE event WHEN 'buffer busy waits' THEN 1 ELSE 0 END) buffer_busy_waits,
       SUM(CASE event WHEN 'resmgr:internal state change' THEN 1 ELSE 0 END) resmgr_internal_state_change,
       SUM(CASE event WHEN 'enq: TX - index contention' THEN 1 ELSE 0 END) enq_TX_index_contention,
       SUM(CASE event WHEN 'latch: shared pool' THEN 1 ELSE 0 END) latch_shared_pool,
       SUM(CASE event WHEN 'latch: row cache objects' THEN 1 ELSE 0 END) latch_row_cache_objects
  FROM v$active_session_history
 WHERE wait_class = 'Concurrency'
 GROUP BY
       sample_time,
       sql_id,
       con_id
),
outliers AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       sample_date_time,
       TO_CHAR(sample_date_time, 'YYYY-MM-DD') sample_date,
       TO_CHAR(sample_date_time, 'HH24:MI:SS') sample_time,
       SUM(total_samples) total_samples,
       SUM(library_cache_lock) library_cache_lock,
       SUM(library_cache_mutex_x) library_cache_mutex_x,
       SUM(cursor_pin_S_wait_on_X) cursor_pin_S_wait_on_X,
       SUM(cursor_mutex_X) cursor_mutex_X,
       SUM(cursor_pin_S) cursor_pin_S,
       SUM(cursor_mutex_S) cursor_mutex_S,
       SUM(buffer_busy_waits) buffer_busy_waits,
       SUM(resmgr_internal_state_change) resmgr_internal_state_change,
       SUM(enq_TX_index_contention) enq_TX_index_contention,
       SUM(latch_shared_pool) latch_shared_pool,
       SUM(latch_row_cache_objects) latch_row_cache_objects,
       MAX(CASE row_number WHEN 1 THEN con_id END) con_id,       
       MAX(CASE row_number WHEN 1 THEN sql_id END) sql_id,
       SUM(CASE row_number WHEN 1 THEN total_samples ELSE 0 END) total_samples_sql_id
  FROM ash_by_sample_and_sql
 GROUP BY
       sample_date_time
HAVING SUM(total_samples) > &&num_cpu_cores.
)
SELECT o.sample_date,
       o.sample_time,
       o.total_samples,
       o.library_cache_lock,
       o.library_cache_mutex_x,
       o.cursor_pin_S_wait_on_X,
       o.cursor_mutex_X,
       o.cursor_pin_S,
       o.cursor_mutex_S,
       o.buffer_busy_waits,
       o.resmgr_internal_state_change,
       o.enq_TX_index_contention,
       o.latch_shared_pool,
       o.latch_row_cache_objects,
       o.con_id,   
       p.pdb_name,    
       o.sql_id,
       o.total_samples_sql_id
  FROM outliers o, 
       pdbs p
 WHERE p.con_id = o.con_id
 ORDER BY
       o.sample_date_time
/

SPO OFF;