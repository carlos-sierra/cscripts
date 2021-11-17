-- iod_fleet_all.sql - Execute iod_fleet_summary.sql, iod_fleet_inventory.sql and iod_fleet_busy.sql
SET HEA ON LIN 2490 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF LONG 240000 LONGC 2400 NUM 20 SERVEROUT OFF;
SET HEA OFF PAGES 0;
--
COL version NEW_V version;
SELECT version, COUNT(*) FROM c##iod.cdb_attributes GROUP BY version ORDER BY version
/
PRO
PRO 1. Enter version:
DEF cs_version_all = '&1.';
UNDEF 1;
COL cs_version_all NEW_V cs_version_all NOPRI;
SELECT COALESCE('&&cs_version_all.', '&&version.') AS cs_version_all FROM DUAL
/
--
SET HEA ON PAGES 100;
SPO /tmp/iod_fleet_summary_&&cs_version_all..txt
@@iod_fleet_summary.sql "&&cs_version_all."
SPO OFF;
SET HEA OFF PAGES 0;
--
SPO /tmp/iod_fleet_inventory_&&cs_version_all..csv
@@iod_fleet_inventory.sql "&&cs_version_all."
SPO OFF;
--
SPO /tmp/iod_fleet_busy_&&cs_version_all..csv
@@iod_fleet_busy.sql "&&cs_version_all."
SPO OFF;
--
COL host_name NEW_V host_name NOPRI;
SELECT host_name FROM v$instance
/
--
PRO
PRO scp &&host_name.:/tmp/iod_fleet_*_&&cs_version_all..* .