SET HEA ON LIN 2490 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF LONG 240000 LONGC 2400 NUM 20 SERVEROUT OFF;
ALTER SESSION SET NLS_DATE_FORMAT = 'YYYY-MM-DD"T"HH24:MI:SS';
--
COL pdb_name FOR A30 TRUNC;
COL realm FOR A5;
COL region_acronym FOR A3 HEA 'RGN';
COL locale FOR A6;
COL db_name FOR A9;
COL avg_running_sessions FOR 999,990.000000000;
COL total_size_gbs FOR 999,999,990.000000000;
COL sessions FOR 999,999,990;
COL ez_connect_string FOR A110;
COL host_name FOR A52;
COL created FOR A19;
--
BREAK ON REPORT;
COMPUTE SUM OF avg_running_sessions total_size_gbs sessions ON REPORT;
--
SPO /tmp/iod_fleet_pdb_inventory.txt;
PRO
PRO IOD Fleet - PDB Inventory
PRO ~~~~~~~~~~~~~~~~~~~~~~~~~
WITH
by_ez_connect_string AS (
SELECT    version
        , pdb_name
        , realm
        , region_acronym
        , locale
        , db_name
        , avg_running_sessions
        , total_size_bytes/ POWER(10, 9) AS total_size_gbs
        , sessions
        , ez_connect_string
        , host_name
        , realm_type_order_by
        , region_order_by
        , locale_order_by
        , ROW_NUMBER() OVER (PARTITION BY ez_connect_string ORDER BY version DESC) AS rn
FROM    C##IOD.pdb_attributes
)
SELECT    pdb_name
        , realm
        , region_acronym
        , locale
        , db_name
        , avg_running_sessions
        , total_size_gbs
        , sessions
        , ez_connect_string
        , host_name
FROM    by_ez_connect_string
WHERE   rn = 1
ORDER BY
          pdb_name
        , realm_type_order_by
        , region_order_by
        , locale_order_by
        , db_name
/
CLEAR BREAK COMPUTE;
SPO OFF;
HOS hostname
HOS ls -lt /tmp/iod_fleet_pdb_inventory.txt
