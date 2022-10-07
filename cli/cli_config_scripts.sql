SET TERM ON HEA ON LIN 2490 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF LONG 240000 LONGC 2400 NUM 20 SERVEROUT OFF;
ALTER SESSION SET NLS_DATE_FORMAT = 'YYYY-MM-DD"T"HH24:MI:SS';
ALTER SESSION SET NLS_TIMESTAMP_FORMAT = 'YYYY-MM-DD"T"HH24:MI:SS.FF3';
ALTER SESSION SET NLS_TIMESTAMP_TZ_FORMAT='YYYY-MM-DD"T"HH24:MI:SS.FF3';
--
COL config_name FOR A40 TRUNC;
COL ver FOR 9990;
COL load_date FOR A19 TRUNC;
COL force FOR A5;
--
WITH
versions AS (
SELECT config_name, config_version AS ver, CASE INSTR(run_command, '${force}') WHEN 0 THEN 'NO' ELSE 'YES' END AS force, load_date, ROW_NUMBER() OVER(ORDER BY load_date DESC) AS rn
  FROM c##iod.pdb_config_scripts
)
SELECT config_name, ver, load_date, force
  FROM versions
 WHERE rn = 1
/