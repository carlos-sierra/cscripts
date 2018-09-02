PRO
PRO &&cs_file_name..txt
PRO /* ---------------------------------------------------------------------------------------------- */
SPO OFF;
PRO
DEF cs_reference;
DEF cs_local_dir;
PRO
PRO If you want to preserve script output, execute scp command below, from a TERM session running on your Mac/PC:
PRO scp &&cs_host_name.:&&cs_file_name..txt &&cs_local_dir.
PRO scp &&cs_host_name.:&&cs_file_prefix._*_&&cs_reference_sanitized._*.* &&cs_local_dir.
--
