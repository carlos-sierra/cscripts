SELECT '&&cs_file_dir.'||LOWER('&&cs_region._&&cs_locale._&&cs_db_name._'||TRANSLATE('&&cs_con_name.', '*@#$"''', '_____')) cs_file_prefix FROM DUAL;
--
