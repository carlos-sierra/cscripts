-- warn if executed not on MOUNTED or READ ONLY
SET TAB OFF FEED OFF ECHO OFF VER OFF;
COL open_mode NEW_V open_mode NOPRI;
COL dynamic_script NEW_V dynamic_script NOPRI;
SELECT open_mode, CASE open_mode WHEN 'READ WRITE' THEN 'cs_null.sql' ELSE 'cs_primary_warn.sql' END AS dynamic_script FROM v$database
/
@@&&dynamic_script.