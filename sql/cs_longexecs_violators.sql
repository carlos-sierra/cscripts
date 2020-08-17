SET HEA ON LIN 2490 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF LONG 240000 LONGC 2400 SERVEROUT OFF;
SET FEED ON;
--
SELECT horizon_minutes_monitor, last_update_horizon_minutes, threshold_violation_factor FROM C##IOD.longexecs_config
/
UPDATE C##IOD.longexecs_config SET horizon_minutes_monitor = 1440, last_update_horizon_minutes = 1440, threshold_violation_factor = 1
/
--
COL threshold_violation_factor FOR 999,990.0 HEA 'Violation|Factor';
COL value FOR 999,990 HEA 'Elapsed|Seconds';
COL key_value FOR A200 HEA 'pdb:PDB Name, typ:SQL Type, sql:SQL_ID, phv:Plan Hash Value, src:Source, sta:Start Time, sid:Session ID and Sesioan Serial#, txt:SQL Text' TRUNC;
--
PRO
PRO Started last 24h, Updated last 3h, Violation Factor of 1
PRO ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
SELECT threshold_violation_factor,
       value,
       key_value
  FROM C##IOD.longexecs_hist_v2
 ORDER BY
       threshold_violation_factor DESC
/
--
ROLLBACK
/
--
PRO
PRO Started last 2h, Updated last 15m, Violation Factor of 2 (default values)
PRO ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
SELECT threshold_violation_factor,
       value,
       key_value
  FROM C##IOD.longexecs_hist_v2
 ORDER BY
       threshold_violation_factor DESC
/
--
