SELECT REPLACE('&&cs_file_name.', '$') AS cs_file_name FROM DUAL;
--
EXEC :cs_begin_elapsed_time := DBMS_UTILITY.get_time;
--
SPO &&cs_file_name..txt
PRO /* ---------------------------------------------------------------------------------------------- */
PRO &&cs_file_name..txt
PRO
--