SET HEA ON LIN 2490 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF LONG 240000 LONGC 2400 SERVEROUT OFF;
ALTER SESSION SET NLS_DATE_FORMAT = 'YYYY-MM-DD"T"HH24:MI:SS';
--
COL application_category FOR A4 HEA 'Type';
COL tot_times_threshold FOR 999,990.0 HEA 'AAS on DB|Violation|Factor';
COL cpu_times_threshold FOR 999,990.0 HEA 'AAS on CPU|Violation|Factor';
COL aas_tot FOR 999,990.0 HEA 'AAS|on DB';
COL aas_cpu FOR 999,990.0 HEA 'AAS|on CPU';
COL snap_time FOR A19 HEA 'Snapshot Time';
COL sql_text FOR A80 HEA 'SQL Text' TRUNC;
COL aas_tot_threshold FOR 990.0 HEA 'AAS|on DB|Threshold';
COL aas_cpu_threshold FOR 990.0 HEA 'AAS|on CPU|Threshold';
COL max_as_tot  FOR 999,990.0 HEA 'Max Sessions|on DB';
COL max_as_cpu  FOR 999,990.0 HEA 'Max Sessions|on CPU';
COL username FOR A30 HEA 'Username' TRUNC;
COL pdb_name FOR A30 HEA 'PDB Name' TRUNC;
--
BREAK ON application_category SKIP PAGE DUPL ON sql_id SKIP 1 DUPL;
--
WITH 
highaas AS (
SELECT application_category,
       tot_times_threshold,
       cpu_times_threshold,
       aas_tot,
       aas_cpu,
       snap_time,
       sql_id,
       sql_text,
       aas_tot_threshold,
       aas_cpu_threshold,
       max_as_tot,
       max_as_cpu,
       username,
       pdb_name,
       MAX(GREATEST(tot_times_threshold, cpu_times_threshold)) OVER (PARTITION BY sql_id) AS max_times_threshold,
       AVG(GREATEST(tot_times_threshold, cpu_times_threshold)) OVER (PARTITION BY sql_id) AS avg_times_threshold
  FROM C##IOD.highaas_hist
)
SELECT application_category,
       sql_id,
       snap_time,
       tot_times_threshold,
       cpu_times_threshold,
       aas_tot,
       aas_cpu,
       sql_text,
       max_as_tot,
       max_as_cpu,
       username,
       pdb_name,
       aas_tot_threshold,
       aas_cpu_threshold
  FROM highaas
 ORDER BY
       CASE application_category WHEN 'TP' THEN 1 WHEN 'RO' THEN 2 WHEN 'BG' THEN 3 WHEN 'UN' THEN 4 ELSE 5 END,
       (max_times_threshold + avg_times_threshold) DESC,
       sql_id,       
       snap_time,
       GREATEST(tot_times_threshold, cpu_times_threshold) DESC
/
