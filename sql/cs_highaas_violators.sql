SET HEA ON LIN 2490 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF LONG 240000 LONGC 2400 SERVEROUT OFF;
SET FEED ON;
--
SELECT horizon_minutes_monitor, threshold_violation_factor FROM C##IOD.highaas_config
/
UPDATE C##IOD.highaas_config SET horizon_minutes_monitor = 1440, threshold_violation_factor = 1
/
--
COL threshold_violation_factor FOR 999,990.0 HEA 'Violation|Factor';
COL value FOR 999,990 HEA 'Elapsed|Seconds';
COL key_value FOR A200 HEA 'pdb:PDB Name, typ:SQL Type, sql:SQL_ID, aas_db:Average Active Session on DB, aas_cpu:Average Active Session on CPU, tim:Capture Time, txt:SQL Text' TRUNC;
--
PRO
PRO Captured last 24h, Violation Factor of 1
PRO ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
SELECT threshold_violation_factor,
       value,
       key_value
  FROM C##IOD.highaas_hist_v
 ORDER BY
       threshold_violation_factor DESC
/
--
ROLLBACK
/
--
PRO
PRO Captured last 30m, Violation Factor of 2 (default values)
PRO ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
SELECT threshold_violation_factor,
       value,
       key_value
  FROM C##IOD.highaas_hist_v
 ORDER BY
       threshold_violation_factor DESC
/
--
