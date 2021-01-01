PRO
PRO CPU LOAD between &&cs_begin_date_from. and &&cs_end_date_to. (greater than 0.001)
PRO ~~~~~~~~
SET TERM OFF;
DEF cs_order_by = 's.cpu_aas DESC NULLS LAST';
GET cs_internal/&&cs_script_name._internal.sql NOLIST
.
666666 SELECT      s.sql_id,
666666             s.plan_hash_value,
666666             s.has_baseline,
666666             s.has_profile,
666666             s.has_patch,
666666             '|' AS sp1,
666666             s.cpu_aas,
666666             s.db_aas,
666666             s.io_aas,
666666             s.ap_aas,
666666             s.cc_aas,
666666             '|' AS sp2,
666666             s.cpu_ms_pe,
666666             s.db_ms_pe,
666666             '|' AS sp3,
666666             s.rows_processed_pe,
666666             s.buffer_gets_pe,
666666             '|' AS sp4,
666666             s.cpu_ms_prp,
666666             s.db_ms_prp,
666666             s.buffer_gets_prp,
666666             '|' AS sp5,
666666             s.executions_ps,
666666             '|' AS sp9,
666666             s.sql_type,
666666             s.sql_text,
666666             &&skip_module. s.module,
666666             &&skip_parsing_schema_name. s.parsing_schema_name,
666666             s.pdb_name
666666   FROM sqlstat3 s
666666  WHERE s.cpu_aas > 0.001;
SET TERM ON;
/