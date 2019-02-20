PRO
PRO &&cs_file_name..txt
PRO /* ---------------------------------------------------------------------------------------------- */
SPO OFF;
HOS chmod 644 &&cs_file_name..txt
PRO
DEF cs_reference;
--DEF cs_local_dir;
PRO
PRO If you want to preserve script output, execute scp command below, from a TERM session running on your Mac/PC:
--PRO scp &&cs_host_name.:&&cs_file_name..txt &&cs_local_dir.
PRO scp &&cs_host_name.:&&cs_file_prefix.*&&cs_file_date_time.*&&cs_reference_sanitized.*&&cs_script_name.*.txt &&cs_local_dir.
PRO scp &&cs_host_name.:&&cs_file_prefix.*&&cs_reference_sanitized.*.* &&cs_local_dir.
--
