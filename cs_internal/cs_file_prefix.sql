SELECT '&&cs_file_dir.'||'&&cs_reference_sanitized._&&cs_file_date_time.Z_'||UPPER('&&cs_rgn._')||UPPER('&&cs_locale._')||UPPER('&&cs_db_name._')||UPPER(TRANSLATE('&&cs_con_name.', '*@#$"''', '_____')) cs_file_prefix FROM DUAL;
--
