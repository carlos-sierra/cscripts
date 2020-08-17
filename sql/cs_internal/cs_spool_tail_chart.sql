SPO OFF;
HOS chmod 644 &&cs_file_name..html
PRO
DEF cs_reference;
DEF cs_local_dir;
PRO
PRO If you want to preserve script output, execute corresponding scp command below, from a TERM session running on your Mac/PC:
PRO scp &&cs_host_name.:&&cs_file_prefix._&&cs_script_name.*.* &&cs_local_dir.
PRO scp &&cs_host_name.:&&cs_file_dir.&&cs_reference_sanitized._*.* &&cs_local_dir.
--