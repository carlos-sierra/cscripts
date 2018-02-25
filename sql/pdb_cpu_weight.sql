SET HEA ON LIN 500 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF;

VAR dbid NUMBER;
VAR instance_number NUMBER;
VAR num_cpu_cores NUMBER;
VAR num_cpu_cores_adjusted NUMBER;
VAR num_cpu_cores_reserved NUMBER;
EXEC :num_cpu_cores_reserved := 2;
BEGIN
  SELECT dbid INTO :dbid FROM v$database;
  SELECT instance_number INTO :instance_number FROM v$instance;
  SELECT value INTO :num_cpu_cores FROM v$osstat WHERE stat_name = 'NUM_CPU_CORES';
END;
/
EXEC :num_cpu_cores_adjusted := :num_cpu_cores - :num_cpu_cores_reserved;

VAR pdb_age_days NUMBER;
EXEC :pdb_age_days := 7;
VAR date_format VARCHAR2(30);
EXEC :date_format := 'YYYY-MM-DD"T"HH24:MI:SS';

VAR shares_low NUMBER;
VAR shares_high NUMBER;
VAR shares_default NUMBER;
EXEC :shares_low := 1;
EXEC :shares_high := 10;
EXEC :shares_default := ROUND((:shares_low + :shares_high) / 2);

VAR utilization_limit_low NUMBER;
VAR utilization_limit_high NUMBER;
VAR utilization_limit_default NUMBER;
EXEC :utilization_limit_low := 10;
EXEC :utilization_limit_high := 50;
EXEC :utilization_limit_default := ROUND((:utilization_limit_low + :utilization_limit_high) / 2);

COL con_id FOR 999999;
COL pdb_name FOR A30;
COL min_sample_date FOR A19;
COL creation_date FOR A19;
COL data_points FOR 999,999,990;
COL aas_p90 FOR 999,990 HEA 'AAS|90th';
COL aas_p95 FOR 999,990 HEA 'AAS|95th';
COL aas_p97 FOR 999,990 HEA 'AAS|97th';
COL aas_p99 FOR 999,990 HEA 'AAS|99th';
COL aas_p999 FOR 999,990 HEA 'AAS|99.9th';
COL aas_p9999 FOR 999,990 HEA 'AAS|99.99th';
COL shares FOR 999990;
COL utilization_limit FOR 99990 HEA 'UTIL|LIMIT'

WITH
    pdbs AS (
    SELECT /*+ MATERIALIZE NO_MERGE GATHER_PLAN_STATISTICS QB_NAME(pdbs) */ -- disjoint for perf reasons
           con_id,
           name pdb_name
      FROM v$pdbs
     WHERE open_mode = 'READ WRITE'
    ),
    pdbs_hist AS (
    SELECT /*+ MATERIALIZE NO_MERGE GATHER_PLAN_STATISTICS QB_NAME(pdbs_hist) */ -- disjoint for perf reasons
           con_id,
           op_timestamp creation_date
      FROM cdb_pdb_history 
     WHERE operation = 'CREATE'
    ),
    ash AS (
    SELECT /*+ MATERIALIZE NO_MERGE GATHER_PLAN_STATISTICS QB_NAME(ash) */ -- disjoint for perf reasons
           con_id,
           sample_id,
           CAST(MIN(sample_time) AS DATE) min_sample_date,
           SUM(CASE WHEN session_state = 'ON CPU' OR wait_class = 'Scheduler' THEN 1 ELSE 0 END) aas_on_cpu
      FROM dba_hist_active_sess_history
     WHERE dbid = :dbid
       AND instance_number = :instance_number
       AND con_id > 2
     GROUP BY
           con_id,
           sample_id
    ),
    aas_on_cpu AS (
    SELECT /*+ MATERIALIZE NO_MERGE GATHER_PLAN_STATISTICS QB_NAME(ash_on_spu) */ -- disjoint for perf reasons
           con_id,
           MIN(min_sample_date) min_sample_date,
           COUNT(*) data_points,
           ROUND(AVG(aas_on_cpu), 3) aas_avg,
           MEDIAN(aas_on_cpu) aas_median,
           PERCENTILE_DISC(0.9) WITHIN GROUP (ORDER BY aas_on_cpu) aas_p90,
           PERCENTILE_DISC(0.95) WITHIN GROUP (ORDER BY aas_on_cpu) aas_p95,
           PERCENTILE_DISC(0.97) WITHIN GROUP (ORDER BY aas_on_cpu) aas_p97,
           PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY aas_on_cpu) aas_p99,
           PERCENTILE_DISC(0.999) WITHIN GROUP (ORDER BY aas_on_cpu) aas_p999,
           PERCENTILE_DISC(0.9999) WITHIN GROUP (ORDER BY aas_on_cpu) aas_p9999,
           MAX(aas_on_cpu) aas_max
      FROM ash
     GROUP BY
            con_id
    )
    SELECT p.con_id,
           p.pdb_name,
           TO_CHAR(h.creation_date, :date_format) creation_date,
           TO_CHAR(a.min_sample_date, :date_format) min_sample_date,
           a.data_points,
           a.aas_p95,
           a.aas_p99,
           CASE 
             WHEN SYSDATE - h.creation_date < :pdb_age_days THEN :shares_default
             WHEN SYSDATE - a.min_sample_date < :pdb_age_days THEN :shares_default
             WHEN a.aas_p95 IS NULL THEN :shares_default
             WHEN a.aas_p95 >= :num_cpu_cores_adjusted THEN :shares_high
             WHEN a.aas_p95 <= 1 THEN :shares_low
             ELSE :shares_low + ROUND((:shares_high - :shares_low) * a.aas_p95 / :num_cpu_cores_adjusted)
           END shares,
           CASE
             WHEN SYSDATE - h.creation_date < :pdb_age_days THEN :utilization_limit_default
             WHEN SYSDATE - a.min_sample_date < :pdb_age_days THEN :utilization_limit_default
             WHEN a.aas_p99 IS NULL THEN :utilization_limit_default
             WHEN a.aas_p99 >= :num_cpu_cores_adjusted THEN :utilization_limit_high
             WHEN a.aas_p99 <= 1 THEN :utilization_limit_low
             ELSE :utilization_limit_low + ROUND((:utilization_limit_high - :utilization_limit_low) * a.aas_p99 * 2 / :num_cpu_cores_adjusted, -1) / 2
           END  utilization_limit
      FROM pdbs p,
           pdbs_hist h,
           aas_on_cpu a
     WHERE h.con_id = p.con_id
       AND a.con_id(+) = p.con_id
     ORDER BY
           con_id
/
