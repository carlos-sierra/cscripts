WHENEVER SQLERROR EXIT FAILURE;

/* ------------------------------------------------------------------------------------ */

DECLARE
  l_exists NUMBER;
  l_sql_statement VARCHAR2(32767) := q'[
CREATE TABLE &&1..sqlstats_snapshot (
  -- soft PK
  snap_id                        NUMBER,
  snap_time                      DATE,
  -- columns
  instance_startup_age_secs      NUMBER,
  last_awr_snapshot_age_secs     NUMBER,
  rows_count                     NUMBER
)
PARTITION BY RANGE (snap_time)
INTERVAL (NUMTOYMINTERVAL(1,'MONTH'))
(
PARTITION before_2018_08_01 VALUES LESS THAN (TO_DATE('2018-08-01', 'YYYY-MM-DD'))
)
ROW STORE COMPRESS ADVANCED
TABLESPACE IOD
]';
BEGIN
  SELECT COUNT(*) INTO l_exists FROM dba_tables WHERE owner = UPPER(TRIM('&&1.')) AND table_name = UPPER('sqlstats_snapshot');
  IF l_exists = 0 THEN
    EXECUTE IMMEDIATE l_sql_statement;
  END IF;
END;
/

/* ------------------------------------------------------------------------------------ */

-- sqlstats_hist
-- create repository, partitioned and compressed
-- code preserves 12 months of data
DECLARE
  l_exists NUMBER;
  l_sql_statement VARCHAR2(32767) := q'[
CREATE TABLE &&1..sqlstats_hist (
  -- soft PK
  con_id                         NUMBER,
  sql_id                         VARCHAR2(13),
  snap_id                        NUMBER,
  snap_time                      DATE,
  -- columns
  last_active_time               DATE,
  plan_hash_value                NUMBER,
  disk_reads                     NUMBER,
  buffer_gets                    NUMBER,
  rows_processed                 NUMBER,
  fetches                        NUMBER,
  executions                     NUMBER,
  end_of_fetch_count             NUMBER,
  loads                          NUMBER,
  version_count                  NUMBER,
  invalidations                  NUMBER,
  cpu_time                       NUMBER,
  elapsed_time                   NUMBER,
  application_wait_time          NUMBER,
  concurrency_wait_time          NUMBER,
  user_io_wait_time              NUMBER,
  sharable_mem                   NUMBER,
  exact_matching_signature       NUMBER,
  delta_disk_reads               NUMBER,
  delta_buffer_gets              NUMBER,
  delta_rows_processed           NUMBER,
  delta_fetch_count              NUMBER,
  delta_execution_count          NUMBER,
  delta_end_of_fetch_count       NUMBER,
  delta_cpu_time                 NUMBER,
  delta_elapsed_time             NUMBER,
  delta_application_wait_time    NUMBER,
  delta_concurrency_time         NUMBER,
  delta_user_io_wait_time        NUMBER,
  delta_loads                    NUMBER,
  delta_invalidations            NUMBER,
  -- extension
  pdb_name                       VARCHAR2(128),
  parsing_schema_name            VARCHAR2(30),
  instance_startup_age_secs      NUMBER,
  last_awr_snapshot_age_secs     NUMBER
)
PARTITION BY RANGE (snap_time)
INTERVAL (NUMTOYMINTERVAL(1,'MONTH'))
(
PARTITION before_2018_08_01 VALUES LESS THAN (TO_DATE('2018-08-01', 'YYYY-MM-DD'))
)
ROW STORE COMPRESS ADVANCED
TABLESPACE IOD
]';
BEGIN
  SELECT COUNT(*) INTO l_exists FROM dba_tables WHERE owner = UPPER(TRIM('&&1.')) AND table_name = UPPER('sqlstats_hist');
  IF l_exists = 0 THEN
    EXECUTE IMMEDIATE l_sql_statement;
  END IF;
END;
/

/* ------------------------------------------------------------------------------------ */

-- active_session_hist
-- create repository, partitioned and compressed
-- code preserves 12 months of data
DECLARE
  l_exists NUMBER;
  l_sql_statement VARCHAR2(32767) := q'[
CREATE TABLE &&1..active_session_hist (
  -- soft PK
  con_id                         NUMBER,
  sql_id                         VARCHAR2(13),
  snap_id                        NUMBER,
  snap_time                      DATE,
  -- columns
  aas_total                      NUMBER, 
  aas_on_cpu                     NUMBER,
  aas_user_io                    NUMBER,
  aas_system_io                  NUMBER,
  aas_cluster                    NUMBER,
  aas_commit                     NUMBER,
  aas_concurrency                NUMBER,
  aas_application                NUMBER,
  aas_administrative             NUMBER,
  aas_configuration              NUMBER,
  aas_network                    NUMBER,
  aas_queueing                   NUMBER,
  aas_scheduler                  NUMBER,
  aas_other                      NUMBER,
  -- extension
  pdb_name                       VARCHAR2(128),
  username                       VARCHAR2(128)
)
PARTITION BY RANGE (snap_time)
INTERVAL (NUMTOYMINTERVAL(1,'MONTH'))
(
PARTITION before_2018_08_01 VALUES LESS THAN (TO_DATE('2018-08-01', 'YYYY-MM-DD'))
)
ROW STORE COMPRESS ADVANCED
TABLESPACE IOD
]';
BEGIN
  SELECT COUNT(*) INTO l_exists FROM dba_tables WHERE owner = UPPER(TRIM('&&1.')) AND table_name = UPPER('active_session_hist');
  IF l_exists = 0 THEN
    EXECUTE IMMEDIATE l_sql_statement;
  END IF;
END;
/

/* ------------------------------------------------------------------------------------ */

DECLARE
  l_exists NUMBER;
  l_sql_statement VARCHAR2(32767) := q'[
CREATE TABLE &&1..sqlstats_config (
  regression_threshold           NUMBER, -- N times regression of DB Time, CPU Time and Buffer Gets to capture sql (2x)
  db_aas_threshold               NUMBER, -- minimum average active sessions as per elapsed time from last awr to capture sql (0.002 DB AAS) 
  db_us_exe_threshold            NUMBER, -- minimum microseconds of database time per execution from last awr to capture sql (1000 us = 1 ms)
  last_awr_snapshot_age_secs     NUMBER, -- minimum age of awr metrics to capture sql (1 sec)
  instance_startup_age_secs      NUMBER, -- minimum age of instance to capture sql (60 secs = 1 minute)
  flags_percent_threshold        NUMBER  -- percent of flags needed in order to consider sql at fault (e.g. 66% -> 2/3)
)
TABLESPACE IOD
]';
BEGIN
  SELECT COUNT(*) INTO l_exists FROM dba_tables WHERE owner = UPPER(TRIM('&&1.')) AND table_name = UPPER('sqlstats_config');
  IF l_exists = 0 THEN
    EXECUTE IMMEDIATE l_sql_statement;
  END IF;
END;
/

INSERT INTO &&1..sqlstats_config (
  regression_threshold,
  db_aas_threshold,
  db_us_exe_threshold,
  last_awr_snapshot_age_secs,
  instance_startup_age_secs,
  flags_percent_threshold
)
SELECT 2, -- regression_threshold >= gk_regression_threshold
       0.002, -- db_aas_threshold >= gk_db_aas_threshold
       1000, -- db_us_exe_threshold >= gk_db_us_exe_threshold
       1, -- last_awr_snapshot_age_secs >= gk_last_awr_snapshot_age_secs
       60, -- instance_startup_age_secs >= gk_instance_startup_age_secs
       66 -- percent of flags needed to consider sql at fault
  FROM DUAL WHERE NOT EXISTS (SELECT NULL FROM &&1..sqlstats_config);

COMMIT;

/* ------------------------------------------------------------------------------------ */

CREATE OR REPLACE VIEW &&1..sqlstats_hist_v AS
WITH 
sqlstats_hist_extended AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       -- soft pk
       h.con_id                         ,
       h.sql_id                         ,
       h.snap_id                        ,
       h.snap_time                      ,
       -- columns
       h.last_active_time               ,
       h.plan_hash_value                ,
       h.disk_reads                     ,
       h.buffer_gets                    ,
       h.rows_processed                 ,
       h.fetches                        ,
       h.executions                     ,
       h.end_of_fetch_count             ,
       h.loads                          ,
       h.version_count                  ,
       h.invalidations                  ,
       h.cpu_time                       ,
       h.elapsed_time                   ,
       h.application_wait_time          ,
       h.concurrency_wait_time          ,
       h.user_io_wait_time              ,
       h.sharable_mem                   ,
       h.exact_matching_signature       ,
       h.delta_disk_reads               ,
       h.delta_buffer_gets              ,
       h.delta_rows_processed           ,
       h.delta_fetch_count              ,
       h.delta_execution_count          ,
       h.delta_end_of_fetch_count       ,
       h.delta_cpu_time                 ,
       h.delta_elapsed_time             ,
       h.delta_application_wait_time    ,
       h.delta_concurrency_time         ,
       h.delta_user_io_wait_time        ,
       h.delta_loads                    ,
       h.delta_invalidations            ,
       -- extension
       h.pdb_name                       ,
       h.parsing_schema_name            ,
       h.instance_startup_age_secs      ,
       h.last_awr_snapshot_age_secs     ,
       -- staging computed metrics (et per exe)
       h.elapsed_time       / GREATEST(h.executions, 1)            hist_avg_et_us_exe,
       h.delta_elapsed_time / GREATEST(h.delta_execution_count, 1) curr_avg_et_us_exe,
       -- staging computed metrics (cpu per exe)
       h.cpu_time           / GREATEST(h.executions, 1)            hist_avg_cpu_us_exe,
       h.delta_cpu_time     / GREATEST(h.delta_execution_count, 1) curr_avg_cpu_us_exe,
       -- staging computed metrics (bg per exe)
       h.buffer_gets        / GREATEST(h.executions, 1)            hist_avg_bg_exe,
       h.delta_buffer_gets  / GREATEST(h.delta_execution_count, 1) curr_avg_bg_exe,
       --
       -- staging computed metrics (et per row)
       CASE WHEN h.rows_processed >= h.executions THEN
       h.elapsed_time       / GREATEST(h.rows_processed, 1)
       END                                                         hist_avg_et_us_row,
       CASE WHEN h.delta_rows_processed >= h.delta_execution_count THEN
       h.delta_elapsed_time / GREATEST(h.delta_rows_processed, 1)  
       END                                                         curr_avg_et_us_row,
       -- staging computed metrics (cpu per row)
       CASE WHEN h.rows_processed >= h.executions THEN
       h.cpu_time           / GREATEST(h.rows_processed, 1)        
       END                                                         hist_avg_cpu_us_row,
       CASE WHEN h.delta_rows_processed >= h.delta_execution_count THEN
       h.delta_cpu_time     / GREATEST(h.delta_rows_processed, 1)  
       END                                                         curr_avg_cpu_us_row,
       -- staging computed metrics (bg per row)
       CASE WHEN h.rows_processed >= h.executions THEN
       h.buffer_gets        / GREATEST(h.rows_processed, 1)        
       END                                                         hist_avg_bg_row,
       CASE WHEN h.delta_rows_processed >= h.delta_execution_count THEN
       h.delta_buffer_gets  / GREATEST(h.delta_rows_processed, 1)  
       END                                                         curr_avg_bg_row,
       -- rows per exe
       h.rows_processed / GREATEST(h.executions, 1)                  hist_rows_per_exe,
       h.delta_rows_processed / GREATEST(h.delta_execution_count, 1) curr_rows_per_exe,
       -- db aas
       h.delta_elapsed_time / 1e6 / h.last_awr_snapshot_age_secs     db_aas,
       -- flags per exe
       CASE WHEN h.delta_elapsed_time / GREATEST(h.delta_execution_count, 1) > c.regression_threshold * h.elapsed_time / GREATEST(h.executions, 1)     THEN 1 ELSE 0 END flag_et_exe,
       CASE WHEN h.delta_cpu_time     / GREATEST(h.delta_execution_count, 1) > c.regression_threshold * h.cpu_time     / GREATEST(h.executions, 1)     THEN 1 ELSE 0 END flag_cpu_exe,
       CASE WHEN h.delta_buffer_gets  / GREATEST(h.delta_execution_count, 1) > c.regression_threshold * h.buffer_gets  / GREATEST(h.executions, 1)     THEN 1 ELSE 0 END flag_bg_exe,
       -- flags per row
       CASE WHEN h.delta_elapsed_time / GREATEST(h.delta_rows_processed, 1)  > c.regression_threshold * h.elapsed_time / GREATEST(h.rows_processed, 1) AND h.rows_processed >= h.executions AND h.delta_rows_processed >= h.delta_execution_count THEN 1 ELSE 0 END flag_et_row,
       CASE WHEN h.delta_cpu_time     / GREATEST(h.delta_rows_processed, 1)  > c.regression_threshold * h.cpu_time     / GREATEST(h.rows_processed, 1) AND h.rows_processed >= h.executions AND h.delta_rows_processed >= h.delta_execution_count THEN 1 ELSE 0 END flag_cpu_row,
       CASE WHEN h.delta_buffer_gets  / GREATEST(h.delta_rows_processed, 1)  > c.regression_threshold * h.buffer_gets  / GREATEST(h.rows_processed, 1) AND h.rows_processed >= h.executions AND h.delta_rows_processed >= h.delta_execution_count THEN 1 ELSE 0 END flag_bg_row
       --
  FROM &&1..sqlstats_hist h,
       &&1..sqlstats_config c
 WHERE h.executions > 0 -- since instance starup
   AND h.delta_elapsed_time / GREATEST(h.delta_execution_count, 1) > c.db_us_exe_threshold -- minimum microseconds of database time per execution from last awr (1000 us = 1 ms)
   AND h.delta_elapsed_time / 1e6 / h.last_awr_snapshot_age_secs > c.db_aas_threshold -- minimum average active sessions as per elapsed time from last awr (0.002 DB AAS) 
   AND h.instance_startup_age_secs > c.instance_startup_age_secs
   AND h.last_awr_snapshot_age_secs > c.last_awr_snapshot_age_secs
   AND h.parsing_schema_name NOT LIKE 'C##%'
)
SELECT -- sql text
       s.sql_text                       ,
       s.sql_fulltext                   ,
       -- soft pk
       h.con_id                         ,
       h.sql_id                         ,
       h.snap_id                        ,
       h.snap_time                      ,
       -- columns
       h.last_active_time               ,
       h.plan_hash_value                ,
       h.disk_reads                     ,
       h.buffer_gets                    ,
       h.rows_processed                 ,
       h.fetches                        ,
       h.executions                     ,
       h.end_of_fetch_count             ,
       h.loads                          ,
       h.version_count                  ,
       h.invalidations                  ,
       h.cpu_time                       ,
       h.elapsed_time                   ,
       h.application_wait_time          ,
       h.concurrency_wait_time          ,
       h.user_io_wait_time              ,
       h.sharable_mem                   ,
       h.exact_matching_signature       ,
       h.delta_disk_reads               ,
       h.delta_buffer_gets              ,
       h.delta_rows_processed           ,
       h.delta_fetch_count              ,
       h.delta_execution_count          ,
       h.delta_end_of_fetch_count       ,
       h.delta_cpu_time                 ,
       h.delta_elapsed_time             ,
       h.delta_application_wait_time    ,
       h.delta_concurrency_time         ,
       h.delta_user_io_wait_time        ,
       h.delta_loads                    ,
       h.delta_invalidations            ,
       -- extension
       h.pdb_name                       ,
       h.parsing_schema_name            ,
       h.instance_startup_age_secs      ,
       h.last_awr_snapshot_age_secs     ,
       -- derived metrics
       h.hist_avg_et_us_exe             ,
       h.curr_avg_et_us_exe             ,
       h.hist_avg_cpu_us_exe            ,
       h.curr_avg_cpu_us_exe            ,
       h.hist_avg_bg_exe                ,
       h.curr_avg_bg_exe                ,
       h.hist_avg_et_us_row             ,
       h.curr_avg_et_us_row             ,
       h.hist_avg_cpu_us_row            ,
       h.curr_avg_cpu_us_row            ,
       h.hist_avg_bg_row                ,
       h.curr_avg_bg_row                ,
       h.hist_rows_per_exe              ,
       h.curr_rows_per_exe              ,
       h.db_aas                         ,
       -- flags
       h.flag_et_exe                    ,
       h.flag_cpu_exe                   ,
       h.flag_bg_exe                    ,
       h.flag_et_row                    ,
       h.flag_cpu_row                   ,
       h.flag_bg_row                    ,
       (h.flag_et_exe + h.flag_cpu_exe + h.flag_bg_exe + h.flag_et_row + h.flag_cpu_row + h.flag_bg_row) flag_count,
       CASE
         WHEN h.rows_processed >= h.executions AND h.delta_rows_processed >= h.delta_execution_count THEN 6
         ELSE 3 
       END flag_total                   ,
       c.flags_percent_threshold        ,
       -- regression
       CASE 
         WHEN
         100 *
         (h.flag_et_exe + h.flag_cpu_exe + h.flag_bg_exe + h.flag_et_row + h.flag_cpu_row + h.flag_bg_row) /
         CASE
           WHEN h.rows_processed >= h.executions AND h.delta_rows_processed >= h.delta_execution_count THEN 6
           ELSE 3 
         END
         >= c.flags_percent_threshold
         AND h.flag_et_exe = 1 -- most have a regression on elapsed time per execution!
         THEN 'Y'
         ELSE 'N'
       END regressing,
       --CASE WHEN (h.flag_et_exe + h.flag_cpu_exe + h.flag_bg_exe + h.flag_et_row + h.flag_cpu_row + h.flag_bg_row) >= c.flags_count_threshold THEN 'Y' ELSE 'N' END regressing,
       c.regression_threshold           ,
       CASE h.flag_et_exe  WHEN 1 THEN curr_avg_et_us_exe  / hist_avg_et_us_exe  END et_exe_regr,
       CASE h.flag_cpu_exe WHEN 1 THEN curr_avg_cpu_us_exe / hist_avg_cpu_us_exe END cpu_exe_regr,
       CASE h.flag_bg_exe  WHEN 1 THEN curr_avg_bg_exe     / hist_avg_bg_exe     END bg_exe_regr,
       CASE h.flag_et_row  WHEN 1 THEN curr_avg_et_us_row  / hist_avg_et_us_row  END et_row_regr,
       CASE h.flag_cpu_row WHEN 1 THEN curr_avg_cpu_us_row / hist_avg_cpu_us_row END cpu_row_regr,
       CASE h.flag_bg_row  WHEN 1 THEN curr_avg_bg_row     / hist_avg_bg_row     END bg_row_regr
  FROM sqlstats_hist_extended h,
       &&1..sqlstats_config c,
       v$sqlstats s
 WHERE s.con_id = h.con_id
   AND s.sql_id = h.sql_id
/

/* ------------------------------------------------------------------------------------ */


