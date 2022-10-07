@@cs_set_container_to_cdb_root.sql
--
COL dynamic_script NEW_V dynamic_script NOPRI;
SELECT CASE WHEN COUNT(*) = 0 THEN 'cs_null.sql' ELSE 'cs_zapper_sprf_export_warn.sql' END AS dynamic_script 
  FROM &&cs_tools_schema..zapper_sprf_export_implement i
 WHERE UPPER(:cs_sql_text) LIKE UPPER('%'||i.sql_text_string||'%')
  AND i.sprf_export_version = (SELECt MAX(sprf_export_version) FROM &&cs_tools_schema..zapper_sprf_export_implement)
/
--
@@cs_set_container_to_curr_pdb.sql
--
@@&&dynamic_script.
--
