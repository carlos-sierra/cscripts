SET HEA ON LIN 2490 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF LONG 240000 LONGC 2400 NUM 20 SERVEROUT OFF;
SET HEA OFF PAGES 0;
ALTER SESSION SET NLS_DATE_FORMAT = 'YYYY-MM-DD'; 
/*
iodcli sql_exec -y -t PRIMARY file:/Users/csierra/git/bitbucket.oci.oraclecorp.com/dbeng/cscripts/cli/cli_get_cdb_attributes.sql hcg:HC_DATABASE > cdb_attributes.txt
cut -b 79- cdb_attributes.txt | sort | uniq > cdb_attributes.sql
*/    
/* ------------------------------------------------------------------------------------ */
--
VAR u02_size NUMBER;
VAR u02_used NUMBER;
VAR u02_available NUMBER;
VAR disk_config VARCHAR2(16);
VAR host_shape VARCHAR2(64);
VAR host_class VARCHAR2(64);
DECLARE
  l_exists NUMBER;
BEGIN
  SELECT COUNT(*) INTO l_exists FROM dba_tables WHERE owner = 'C##IOD' AND table_name = 'DBC_SYSTEM';
  IF l_exists > 0 THEN
    EXECUTE IMMEDIATE q'[
      SELECT  u02_size, u02_used, u02_available, disk_config, host_shape, host_class 
      FROM    c##iod.dbc_system 
      ORDER BY timestamp DESC 
      FETCH FIRST 1 ROW ONLY
    ]'
    INTO :u02_size, :u02_used, :u02_available, :disk_config, :host_shape, :host_class;
  ELSE
    :u02_size := 0;
    :u02_used := 0;
    :u02_available := 0;
    :disk_config := 'unknown';
    :host_shape := 'unknown';
    :host_class := 'UNKNOWN';
  END IF;
END;
/
--
/* ------------------------------------------------------------------------------------ */
--
VAR u02_size_1m NUMBER;
VAR u02_used_1m NUMBER;
VAR u02_available_1m NUMBER;
BEGIN
  SELECT u02_size, u02_used, u02_available 
    INTO :u02_size_1m, :u02_used_1m, :u02_available_1m
    FROM c##iod.dbc_system 
   WHERE timestamp < SYSDATE - (30)
   ORDER BY timestamp DESC
   FETCH FIRST 1 ROW ONLY;
EXCEPTION
  WHEN OTHERS THEN
    :u02_size_1m := 0;
    :u02_used_1m := 0;
    :u02_available_1m := 0;
END;
/
--
/* ------------------------------------------------------------------------------------ */
--
VAR aas_on_cpu_avg NUMBER;
VAR aas_on_cpu_p90 NUMBER;
VAR aas_on_cpu_p95 NUMBER;
VAR aas_on_cpu_p99 NUMBER;
BEGIN
SELECT ROUND(AVG(v.samples), 3) AS aas_on_cpu_avg,
       PERCENTILE_DISC(0.90) WITHIN GROUP (ORDER BY v.samples) AS aas_on_cpu_p90,
       PERCENTILE_DISC(0.95) WITHIN GROUP (ORDER BY v.samples) AS aas_on_cpu_p95,
       PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY v.samples) AS aas_on_cpu_p99
INTO :aas_on_cpu_avg, :aas_on_cpu_p90, :aas_on_cpu_p95, :aas_on_cpu_p99
FROM (
SELECT h.sample_time, COUNT(*) AS samples
  FROM dba_hist_active_sess_history h
 WHERE h.sample_time > SYSDATE - 7
   AND h.session_state = 'ON CPU'
 GROUP BY h.sample_time
) v;
END;
/
--
/* ------------------------------------------------------------------------------------ */
--
VAR load_avg NUMBER;
VAR load_p90 NUMBER;
VAR load_p95 NUMBER;
VAR load_p99 NUMBER;
BEGIN
SELECT ROUND(AVG(v.value), 3) AS load_avg,
       ROUND(PERCENTILE_DISC(0.90) WITHIN GROUP (ORDER BY v.value), 3) AS load_p90,
       ROUND(PERCENTILE_DISC(0.95) WITHIN GROUP (ORDER BY v.value), 3) AS load_p95,
       ROUND(PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY v.value), 3) AS load_p99
INTO :load_avg, :load_p90, :load_p95, :load_p99
FROM (
SELECT o.value
  FROM dba_hist_osstat o, dba_hist_snapshot s
 WHERE o.stat_name = 'LOAD'
   AND s.snap_id = o.snap_id
   AND s.dbid = o.dbid
   AND s.instance_number = o.instance_number
   AND s.end_interval_time > SYSDATE - 7
) v;
END;
/
--
/* ------------------------------------------------------------------------------------ */
--
VAR cdb_weight NUMBER;
EXEC :cdb_weight := c##iod.iod_rsrc_mgr.get_cdb_weight();
--
/* ------------------------------------------------------------------------------------ */
--
VAR pdb_count NUMBER;
EXEC :pdb_count := NVL(c##iod.iod_rsrc_mgr.pdb_count(), 0);
--
/* ------------------------------------------------------------------------------------ */
--
COL line FOR A500 TRUNC;
WITH
u02_util AS (
  SELECT NVL(c##iod.iod_rsrc_mgr.fs_u02_util_perc(), 0) AS perc FROM DUAL
),
all_u02 AS (
          SELECT 80 AS util_perc, CASE WHEN perc BETWEEN 65 AND 79 THEN TRUNC(c##iod.iod_rsrc_mgr.u02_util_forecast_date(80, 07)) END AS forecast_date FROM u02_util
UNION ALL SELECT 80 AS util_perc, CASE WHEN perc BETWEEN 65 AND 79 THEN TRUNC(c##iod.iod_rsrc_mgr.u02_util_forecast_date(80, 14)) END AS forecast_date FROM u02_util
UNION ALL SELECT 80 AS util_perc, CASE WHEN perc BETWEEN 65 AND 79 THEN TRUNC(c##iod.iod_rsrc_mgr.u02_util_forecast_date(80, 21)) END AS forecast_date FROM u02_util
UNION ALL SELECT 80 AS util_perc, CASE WHEN perc BETWEEN 65 AND 79 THEN TRUNC(c##iod.iod_rsrc_mgr.u02_util_forecast_date(80, 28)) END AS forecast_date FROM u02_util
UNION ALL SELECT 90 AS util_perc, CASE WHEN perc BETWEEN 65 AND 89 THEN TRUNC(c##iod.iod_rsrc_mgr.u02_util_forecast_date(90, 07)) END AS forecast_date FROM u02_util
UNION ALL SELECT 90 AS util_perc, CASE WHEN perc BETWEEN 65 AND 89 THEN TRUNC(c##iod.iod_rsrc_mgr.u02_util_forecast_date(90, 14)) END AS forecast_date FROM u02_util
UNION ALL SELECT 90 AS util_perc, CASE WHEN perc BETWEEN 65 AND 89 THEN TRUNC(c##iod.iod_rsrc_mgr.u02_util_forecast_date(90, 21)) END AS forecast_date FROM u02_util
UNION ALL SELECT 90 AS util_perc, CASE WHEN perc BETWEEN 65 AND 89 THEN TRUNC(c##iod.iod_rsrc_mgr.u02_util_forecast_date(90, 28)) END AS forecast_date FROM u02_util
UNION ALL SELECT 95 AS util_perc, CASE WHEN perc BETWEEN 65 AND 94 THEN TRUNC(c##iod.iod_rsrc_mgr.u02_util_forecast_date(95, 07)) END AS forecast_date FROM u02_util
UNION ALL SELECT 95 AS util_perc, CASE WHEN perc BETWEEN 65 AND 94 THEN TRUNC(c##iod.iod_rsrc_mgr.u02_util_forecast_date(95, 14)) END AS forecast_date FROM u02_util
UNION ALL SELECT 95 AS util_perc, CASE WHEN perc BETWEEN 65 AND 94 THEN TRUNC(c##iod.iod_rsrc_mgr.u02_util_forecast_date(95, 21)) END AS forecast_date FROM u02_util
UNION ALL SELECT 95 AS util_perc, CASE WHEN perc BETWEEN 65 AND 94 THEN TRUNC(c##iod.iod_rsrc_mgr.u02_util_forecast_date(95, 28)) END AS forecast_date FROM u02_util
),
u02_norm AS (
SELECT util_perc,
       MIN(forecast_date) AS forecast_date
  FROM all_u02
 WHERE forecast_date BETWEEN SYSDATE AND SYSDATE + 365
 GROUP BY
       util_perc
),
u02 AS (
SELECT perc AS fs_u02_util_perc,
       (SELECT forecast_date FROM u02_norm WHERE util_perc = 80) AS fs_u02_at_80p,
       (SELECT forecast_date FROM u02_norm WHERE util_perc = 90) AS fs_u02_at_90p,
       (SELECT forecast_date FROM u02_norm WHERE util_perc = 95) AS fs_u02_at_95p
  FROM u02_util
),
cdb_attributes AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       i.host_name, 
       p1.value AS db_domain,
       :disk_config AS disk_config,
       :host_shape AS host_shape,
       :host_class AS host_class,
       TO_NUMBER((SELECT value FROM v$osstat WHERE stat_name = 'NUM_CPU_CORES')) AS cpu_cores,
       TO_NUMBER((SELECT value FROM v$osstat WHERE stat_name = 'NUM_CPUS')) AS cpu_threads,
       CASE WHEN :cdb_weight IS NULL THEN 1 ELSE 0 END AS maxed_out,
       :cdb_weight AS cdb_weight,
       :load_avg AS load_avg, 
       :load_p90 AS load_p90, 
       :load_p95 AS load_p95, 
       :load_p99 AS load_p99,
       :aas_on_cpu_avg AS aas_on_cpu_avg, 
       :aas_on_cpu_p90 AS aas_on_cpu_p90, 
       :aas_on_cpu_p95 AS aas_on_cpu_p95, 
       :aas_on_cpu_p99 AS aas_on_cpu_p99,
       :u02_size_1m AS u02_size_1m,
       :u02_used_1m AS u02_used_1m,
       :u02_available_1m AS u02_available_1m,
       :u02_size AS u02_size,
       :u02_used AS u02_used,
       :u02_available AS u02_available,
       d.name AS db_name,
       (SELECT COUNT(*) FROM v$dataguard_config) AS dg_members,
       :pdb_count AS pdbs,
       (SELECT COUNT(DISTINCT con_id) FROM cdb_tables WHERE table_name = 'KIEVBUCKETS') AS kiev_pdbs,
       (SELECT COUNT(DISTINCT con_id) FROM cdb_tables WHERE table_name = 'STEPINSTANCES') AS wf_pdbs,
       (SELECT SUM(CASE WHEN UPPER(c.name) LIKE '%CASPER%' OR UPPER(c.name) LIKE '%TENANT%' OR LOWER(i.host_name) LIKE '%casper%' THEN 1 ELSE 0 END) FROM v$containers c WHERE con_id > 2) AS casper_pdbs
  FROM v$instance i, v$database d, v$parameter p1
 WHERE p1.name = 'db_domain'
)
SELECT 'EXEC c##iod.merge_cdb_attributes('||
       ''''||TO_CHAR(SYSDATE, 'YYYY-MM-DD')||''','||
       ''''||a.host_name||''','||
       ''''||a.db_domain||''','||
       ''''||a.disk_config||''','||
       ''''||a.host_shape||''','||
       ''''||a.host_class||''','||
       a.cpu_cores||','||
       a.cpu_threads||','||
       a.maxed_out||','||
       'TO_NUMBER('''||a.cdb_weight||'''),'|| -- cdb_weight could be NULL
       a.load_avg||','||
       a.load_p90||','||
       a.load_p95||','||
       a.load_p99||','||
       a.aas_on_cpu_avg||','||
       a.aas_on_cpu_p90||','||
       a.aas_on_cpu_p95||','||
       a.aas_on_cpu_p99||','||
       a.u02_size_1m||','||
       a.u02_used_1m||','||
       a.u02_available_1m||','||
       a.u02_size||','||
       a.u02_used||','||
       a.u02_available||','||
       u.fs_u02_util_perc||','||
       ''''||TO_CHAR(u.fs_u02_at_80p, 'YYYY-MM-DD')||''','||
       ''''||TO_CHAR(u.fs_u02_at_90p, 'YYYY-MM-DD')||''','||
       ''''||TO_CHAR(u.fs_u02_at_95p, 'YYYY-MM-DD')||''','||
       ''''||a.db_name||''','||
       a.dg_members||','||
       a.pdbs||','||
       a.kiev_pdbs||','||
       a.wf_pdbs||','||
       a.casper_pdbs||');' AS line
  FROM cdb_attributes a, u02 u
/