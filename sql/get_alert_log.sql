COL alert_log NEW_V alert_log;
SELECT value||'/alert_*.log' alert_log FROM v$diag_info WHERE name = 'Diag Trace';
!cp &&alert_log. .
!chmod 777 alert_*.log

COL locale NEW_V locale;
SELECT LOWER(REPLACE(SUBSTR(LOWER(host_name), 1 + INSTR(LOWER(host_name), '.', 1, 2), 30), '.', '_')) locale FROM v$instance
/

COL db_name NEW_V db_name;
SELECT LOWER(name) db_name FROM v$database
/

COL con_name NEW_V con_name;
SELECT 'NONE' con_name FROM DUAL;
SELECT LOWER(SYS_CONTEXT('USERENV', 'CON_NAME')) con_name FROM DUAL
/

COL output_file_name NEW_V output_file_name;
SELECT 'alert_&&locale._&&db_name._'||REPLACE('&&con_name.','$') output_file_name FROM DUAL
/

COL output_file_name NEW_V output_file_name;
SELECT 'alert_&&locale._&&db_name._'||TO_CHAR(SYSDATE, 'YYYYMMDD"T"HH24MISS') output_file_name FROM DUAL
/

!rename alert &&output_file_name. alert_*.log