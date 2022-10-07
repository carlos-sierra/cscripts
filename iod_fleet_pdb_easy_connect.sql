SET HEA ON LIN 2490 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF LONG 240000 LONGC 2400 NUM 20 SERVEROUT OFF;
ALTER SESSION SET NLS_DATE_FORMAT = 'YYYY-MM-DD"T"HH24:MI:SS';
--
COL customer FOR A50 TRUNC;
COL pdb_name FOR A30 TRUNC;
COL pdbs FOR 9,990;
COL realm FOR A5;
COL region_acronym FOR A3 HEA 'RGN';
COL locale FOR A6;
COL db_name FOR A9;
COL avg_running_sessions FOR 999,990.000 HEA 'AVERAGE RUNNING|SESSIONS PDB';
COL avg_running_sessions_cdb FOR 999,990.000 HEA 'AVERAGE RUNNING|SESSIONS CDB';
COL total_size_gbs FOR 9,999,990.000;
COL sessions FOR 999,999,990;
COL ez_connect_string FOR A110;
COL host_name FOR A52;
COL created FOR A19;
--
BREAK ON REPORT;
COMPUTE SUM OF avg_running_sessions total_size_gbs sessions ON REPORT;
--
SPO /tmp/iod_fleet_pdb_easy_connect.txt;
PRO
PRO IOD Fleet - Easy Connect
PRO ~~~~~~~~~~~~~~~~~~~~~~~~
WITH
fleet AS (
SELECT    pdb_name
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
        , ROW_NUMBER() OVER (PARTITION BY ez_connect_string ORDER BY version DESC NULLS LAST) AS rn
FROM    C##IOD.pdb_attributes
--WHERE   avg_running_sessions > 0
)
SELECT    pdb_name
        , COUNT(*) OVER (PARTITION BY realm, region_acronym, locale, db_name) AS pdbs
        , realm
        , region_acronym
        , locale
        , db_name
        , avg_running_sessions
        , SUM(avg_running_sessions) OVER (PARTITION BY realm, region_acronym, locale, db_name) AS avg_running_sessions_cdb
        , sessions
        , total_size_gbs
        , ez_connect_string
        , host_name
FROM    fleet
WHERE   rn = 1
ORDER BY
          pdb_name
        , realm_type_order_by
        , region_order_by
        , locale_order_by
        , db_name
/
SPO OFF;
--
SPO /tmp/iod_fleet_pdb_top_avg_running_sessions.txt;
PRO
PRO IOD Fleet - Top Average Running Sessions
PRO ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
WITH
fleet AS (
SELECT    pdb_name
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
        , ROW_NUMBER() OVER (PARTITION BY ez_connect_string ORDER BY version DESC NULLS LAST) AS rn
        , ROW_NUMBER() OVER (ORDER BY avg_running_sessions DESC NULLS LAST) AS topn
FROM    C##IOD.pdb_attributes
)
SELECT    pdb_name
        , COUNT(*) OVER (PARTITION BY realm, region_acronym, locale, db_name) AS pdbs
        , realm
        , region_acronym
        , locale
        , db_name
        , avg_running_sessions
        , SUM(avg_running_sessions) OVER (PARTITION BY realm, region_acronym, locale, db_name) AS avg_running_sessions_cdb
        , total_size_gbs
        , sessions
        , ez_connect_string
        , host_name
FROM    fleet
WHERE   rn = 1
ORDER BY
          topn
        , pdb_name
FETCH FIRST 1000 ROWS ONLY
/
SPO OFF;
--
SPO /tmp/iod_fleet_pdb_top_total_size_gbs.txt;
PRO
PRO IOD Fleet - Top Total Size GBs
PRO ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
WITH
fleet AS (
SELECT    pdb_name
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
        , ROW_NUMBER() OVER (PARTITION BY ez_connect_string ORDER BY version DESC NULLS LAST) AS rn
        , ROW_NUMBER() OVER (ORDER BY total_size_bytes DESC NULLS LAST) AS topn
FROM    C##IOD.pdb_attributes
)
SELECT    pdb_name
        , COUNT(*) OVER (PARTITION BY realm, region_acronym, locale, db_name) AS pdbs
        , realm
        , region_acronym
        , locale
        , db_name
        , avg_running_sessions
        , SUM(avg_running_sessions) OVER (PARTITION BY realm, region_acronym, locale, db_name) AS avg_running_sessions_cdb
        , total_size_gbs
        , sessions
        , ez_connect_string
        , host_name
FROM    fleet
WHERE   rn = 1
ORDER BY
          topn
        , pdb_name
FETCH FIRST 1000 ROWS ONLY
/
SPO OFF;
--
SPO /tmp/iod_fleet_pdb_top_avg_running_sessions_NO_CASPER.txt;
PRO
PRO IOD Fleet - Top Average Running Sessions
PRO ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
WITH
fleet AS (
SELECT    pdb_name
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
        , ROW_NUMBER() OVER (PARTITION BY ez_connect_string ORDER BY version DESC NULLS LAST) AS rn
        , ROW_NUMBER() OVER (ORDER BY avg_running_sessions DESC NULLS LAST) AS topn
FROM    C##IOD.pdb_attributes
-- WHERE   kiev_or_wf = 'K'
WHERE pdb_name NOT LIKE '%CASPER%'
)
SELECT    pdb_name
        , COUNT(*) OVER (PARTITION BY realm, region_acronym, locale, db_name) AS pdbs
        , realm
        , region_acronym
        , locale
        , db_name
        , avg_running_sessions
        , SUM(avg_running_sessions) OVER (PARTITION BY realm, region_acronym, locale, db_name) AS avg_running_sessions_cdb
        , total_size_gbs
        , sessions
        , ez_connect_string
        , host_name
FROM    fleet
WHERE   rn = 1
ORDER BY
          topn
        , pdb_name
FETCH FIRST 1000 ROWS ONLY
/
SPO OFF;
--
SPO /tmp/iod_fleet_pdb_top_total_size_gbs_NO_CASPER.txt;
PRO
PRO IOD Fleet - Top Total Size GBs
PRO ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
WITH
fleet AS (
SELECT    pdb_name
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
        , ROW_NUMBER() OVER (PARTITION BY ez_connect_string ORDER BY version DESC NULLS LAST) AS rn
        , ROW_NUMBER() OVER (ORDER BY total_size_bytes DESC NULLS LAST) AS topn
FROM    C##IOD.pdb_attributes
-- WHERE   kiev_or_wf = 'K'
WHERE pdb_name NOT LIKE '%CASPER%'
)
SELECT    pdb_name
        , COUNT(*) OVER (PARTITION BY realm, region_acronym, locale, db_name) AS pdbs
        , realm
        , region_acronym
        , locale
        , db_name
        , avg_running_sessions
        , SUM(avg_running_sessions) OVER (PARTITION BY realm, region_acronym, locale, db_name) AS avg_running_sessions_cdb
        , total_size_gbs
        , sessions
        , ez_connect_string
        , host_name
FROM    fleet
WHERE   rn = 1
ORDER BY
          topn
        , pdb_name
FETCH FIRST 1000 ROWS ONLY
/
SPO OFF;
--
SPO /tmp/iod_fleet_pdb_top_avg_running_sessions_KIEV.txt;
PRO
PRO IOD Fleet - Top Average Running Sessions
PRO ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
WITH
fleet AS (
SELECT    pdb_name
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
        , ROW_NUMBER() OVER (PARTITION BY ez_connect_string ORDER BY version DESC NULLS LAST) AS rn
        , ROW_NUMBER() OVER (ORDER BY avg_running_sessions DESC NULLS LAST) AS topn
FROM    C##IOD.pdb_attributes
WHERE   kiev_or_wf = 'K'
-- WHERE pdb_name NOT LIKE '%CASPER%'
)
SELECT    pdb_name
        , COUNT(*) OVER (PARTITION BY realm, region_acronym, locale, db_name) AS pdbs
        , realm
        , region_acronym
        , locale
        , db_name
        , avg_running_sessions
        , SUM(avg_running_sessions) OVER (PARTITION BY realm, region_acronym, locale, db_name) AS avg_running_sessions_cdb
        , total_size_gbs
        , sessions
        , ez_connect_string
        , host_name
FROM    fleet
WHERE   rn = 1
ORDER BY
          topn
        , pdb_name
FETCH FIRST 1000 ROWS ONLY
/
SPO OFF;
--
SPO /tmp/iod_fleet_pdb_top_total_size_gbs_KIEV.txt;
PRO
PRO IOD Fleet - Top Total Size GBs
PRO ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
WITH
fleet AS (
SELECT    pdb_name
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
        , ROW_NUMBER() OVER (PARTITION BY ez_connect_string ORDER BY version DESC NULLS LAST) AS rn
        , ROW_NUMBER() OVER (ORDER BY total_size_bytes DESC NULLS LAST) AS topn
FROM    C##IOD.pdb_attributes
WHERE   kiev_or_wf = 'K'
-- WHERE pdb_name NOT LIKE '%CASPER%'
)
SELECT    pdb_name
        , COUNT(*) OVER (PARTITION BY realm, region_acronym, locale, db_name) AS pdbs
        , realm
        , region_acronym
        , locale
        , db_name
        , avg_running_sessions
        , SUM(avg_running_sessions) OVER (PARTITION BY realm, region_acronym, locale, db_name) AS avg_running_sessions_cdb
        , total_size_gbs
        , sessions
        , ez_connect_string
        , host_name
FROM    fleet
WHERE   rn = 1
ORDER BY
          topn
        , pdb_name
FETCH FIRST 1000 ROWS ONLY
/
SPO OFF;
--
SET HEA OFF
PRO
SELECT 'scp '||host_name||':/tmp/iod_fleet_pdb* .' FROM v$instance
/
SET HEA ON
