COL cs_sample_time_from NEW_V cs_sample_time_from NOPRI;
COL cs_sample_time_to NEW_V cs_sample_time_to NOPRI;
SELECT TO_CHAR(SYSDATE - 7, '&&cs_datetime_full_format.') AS cs_sample_time_from, TO_CHAR(SYSDATE, '&&cs_datetime_full_format.') AS cs_sample_time_to FROM DUAL
/
@@&&cs_set_container_to_cdb_root.
PRO
PRO ZAPPER-19 ENTRIES (&&cs_stgtab_owner..zapper_log)
PRO ~~~~~~~~~~~~~~~~~
PRO
DEF cs_null = 'Y';
@@cs_internal/cs_zapper_log_entries.sql
PRO
PRO ZAPPER-19 ACTIONS (&&cs_stgtab_owner..zapper_log)
PRO ~~~~~~~~~~~~~~~~~
PRO
SET HEA OFF PAGES 0;
DEF cs_null = 'N';
@@cs_pr_internal.sql "cs_internal/cs_zapper_log_actions.sql"
SET HEA ON PAGES 100;
@@&&cs_set_container_to_curr_pdb.
