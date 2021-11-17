-- warn if there is a blackout
SET TAB OFF FEED OFF ECHO OFF VER OFF;
ALTER SESSION SET container = CDB$ROOT;
--
COL blackout_end_time NEW_V blackout_end_time NOPRI;
COL dynamic_script NEW_V dynamic_script NOPRI;
SELECT CASE WHEN SYSDATE BETWEEN begin_time AND end_time THEN TO_CHAR(end_time, '&&cs_datetime_full_format.') END AS blackout_end_time, CASE WHEN SYSDATE BETWEEN begin_time AND end_time THEN 'cs_blackout_warn.sql' ELSE 'cs_null.sql' END AS dynamic_script FROM &&cs_tools_schema..blackout WHERE id = 1
/
--
ALTER SESSION SET CONTAINER = &&cs_con_name.;
--
@@&&dynamic_script.
