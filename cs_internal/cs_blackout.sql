-- warn if there is a blackout
SET TAB OFF FEED OFF ECHO OFF VER OFF;
@@&&cs_set_container_to_cdb_root.
--
COL blackout_end_time NEW_V blackout_end_time NOPRI;
COL dynamic_script NEW_V dynamic_script NOPRI;
SELECT CASE WHEN SYSDATE BETWEEN begin_time AND end_time THEN TO_CHAR(end_time, '&&cs_datetime_full_format.') END AS blackout_end_time, CASE WHEN SYSDATE BETWEEN begin_time AND end_time THEN 'cs_blackout_warn.sql' ELSE 'cs_null.sql' END AS dynamic_script FROM &&cs_tools_schema..blackout WHERE id = 1
/
--
@@&&cs_set_container_to_curr_pdb.
--
@@&&dynamic_script.
