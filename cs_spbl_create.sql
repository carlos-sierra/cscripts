----------------------------------------------------------------------------------------
--
-- File name:   cs_spbl_create.sql
--
-- Purpose:     Create a SQL Plan Baseline for given SQL_ID
--
-- Author:      Carlos Sierra
--
-- Version:     2022/08/10
--
-- Usage:       Connecting into PDB.
--
--              Enter SQL_ID when requested.
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @cs_spbl_create.sql
--
-- Notes:       *** Requires Oracle Diagnostics Pack License ***
--
--              Developed and tested on 12.1.0.2.
--
---------------------------------------------------------------------------------------
--
@@cs_internal/cs_primary.sql
@@cs_internal/cs_cdb_warn.sql
@@cs_internal/cs_set.sql
@@cs_internal/cs_def.sql
@@cs_internal/cs_file_prefix.sql
--
DEF cs_script_name = 'cs_spbl_create';
--
PRO 1. SQL_ID: 
DEF cs_sql_id = '&1.';
UNDEF 1;
--
@@cs_internal/cs_signature.sql
@@cs_internal/&&cs_zapper_sprf_export.
--
-- @@cs_internal/cs_&&dba_or_cdb._plans_performance.sql (deprecated)
@@cs_internal/cs_plans_performance.sql 
--@@cs_internal/cs_spbl_internal_list.sql
--
PRO
PRO 2. Plan Hash Value:
DEF cs_plan_hash_value = "&2.";
UNDEF 2;
--
SELECT '&&cs_file_prefix._&&cs_script_name._&&cs_sql_id._&&cs_plan_hash_value.' cs_file_name FROM DUAL;
--
-- preserves curren time since new baselines will have more recent creation than this:
COL creation_time NEW_V creation_time NOPRI;
SELECT TO_CHAR(SYSDATE, '&&cs_datetime_full_format.') AS creation_time FROM DUAL;
--
@@cs_internal/cs_spool_head.sql
PRO SQL> @&&cs_script_name..sql "&&cs_sql_id." "&&cs_plan_hash_value." 
@@cs_internal/cs_spool_id.sql
--
PRO SQL_ID       : &&cs_sql_id.
PRO SQLHV        : &&cs_sqlid.
PRO SIGNATURE    : &&cs_signature.
PRO SQL_HANDLE   : &&cs_sql_handle.
PRO APPLICATION  : &&cs_application_category.
PRO PLAN_HASH_VAL: &&cs_plan_hash_value. 
--
SET HEA OFF;
PRINT :cs_sql_text
SET HEA ON;
SET SERVEROUT ON;
--
@@cs_internal/&&cs_spbl_create_pre.
--
---------------------------------------------------------------------------------------
--
-- tries to load plan from cursor
--
DECLARE
  l_signature NUMBER := :cs_signature; -- avoid PLS-00110: bind variable 'CS' not allowed in this context
  l_created_plans INTEGER;
  l_modified_plans INTEGER;
  l_description VARCHAR2(500);
BEGIN
  IF TO_NUMBER('&&cs_plan_hash_value.') > 0 THEN
    l_created_plans := DBMS_SPM.load_plans_from_cursor_cache(sql_id => '&&cs_sql_id.', plan_hash_value => TO_NUMBER('&&cs_plan_hash_value.'));
    DBMS_OUTPUT.put_line('Plans loaded from cursor cache:'||l_created_plans);
    FOR i IN (SELECT /* 1 */ sql_handle, plan_name FROM dba_sql_plan_baselines WHERE l_created_plans > 0 AND signature = l_signature AND created > TO_DATE('&&creation_time.', '&&cs_datetime_full_format.') - 1/1440 AND description IS NULL AND origin LIKE 'MANUAL-LOAD%') /* on 19c it transformed from MANUAL-LOAD into MANUAL-LOAD-FROM-CURSOR-CACHE */
    LOOP
      l_description := 'cs_spbl_create.sql SRC=MEM SQL_ID=&&cs_sql_id. PHV=&&cs_plan_hash_value. &&cs_reference_sanitized. CREATED=&&creation_time.';
      l_modified_plans := DBMS_SPM.alter_sql_plan_baseline(sql_handle => i.sql_handle, plan_name => i.plan_name, attribute_name => 'DESCRIPTION', attribute_value => l_description);
      DBMS_OUTPUT.put_line('plan loaded from cursor cache: '||i.sql_handle||' '||i.plan_name||' '||l_description);
    END LOOP;
  END IF;
END;
/
--
---------------------------------------------------------------------------------------
--
-- tries to load plan from AWR (through a STS on 12c), but only if we could not load any plans from memory
--
DECLARE
  l_signature NUMBER := :cs_signature; -- avoid PLS-00110: bind variable 'CS' not allowed in this context
  l_created_plans INTEGER;
  l_modified_plans INTEGER;
  l_sqlset_name VARCHAR2(30);
  l_description VARCHAR2(500);
  l_begin_snap INTEGER := TO_NUMBER('&&cs_min_snap_id.');
  l_end_snap INTEGER := TO_NUMBER('&&cs_max_snap_id.');
  sts_cur DBMS_SQLTUNE.sqlset_cursor;
BEGIN
  -- only load plan from awr if none was loaded from cursor cache
  SELECT COUNT(*) INTO l_created_plans FROM dba_sql_plan_baselines WHERE signature = l_signature AND created > TO_DATE('&&creation_time.', '&&cs_datetime_full_format.') - 1/1440 AND description IS NOT NULL AND origin LIKE 'MANUAL-LOAD%'; /* on 19c it transformed from MANUAL-LOAD into MANUAL-LOAD-FROM-CURSOR-CACHE */
  IF l_created_plans = 0 THEN
    SELECT MIN(snap_id), MAX(snap_id) INTO l_begin_snap, l_end_snap FROM dba_hist_sqlstat WHERE sql_id = '&&cs_sql_id.' AND plan_hash_value = TO_NUMBER('&&cs_plan_hash_value.') AND dbid = TO_NUMBER('&&cs_dbid.') AND instance_number = TO_NUMBER('&&cs_instance_number.'); -- maybe an overkill
    DBMS_OUTPUT.put_line('begin_snap:'||l_begin_snap||' end_snap:'||l_end_snap);
    IF l_end_snap > l_begin_snap THEN
      --
      -- 19c DBMS_SPM.load_plans_from_awr fails with ORA-13769: Snapshots 94482 and 96578 do not exist.
      -- $IF DBMS_DB_VERSION.ver_le_12_1
      -- $THEN
        l_sqlset_name := 'S&&cs_sql_id._&&cs_file_timestamp.';
        l_description := 'SQL_ID=&&cs_sql_id. PHV=&&cs_plan_hash_value. CREATED=&&cs_file_timestamp.';
        l_sqlset_name := DBMS_SQLTUNE.create_sqlset(sqlset_name => l_sqlset_name, description => l_description);
        DBMS_OUTPUT.put_line('created staging sts: '||l_sqlset_name);
        --
        OPEN sts_cur FOR SELECT VALUE(p) FROM TABLE(DBMS_SQLTUNE.select_workload_repository(begin_snap => l_begin_snap, end_snap => l_end_snap, basic_filter => q'[sql_id = '&&cs_sql_id.' AND plan_hash_value = TO_NUMBER('&&cs_plan_hash_value.')]')) p;
        DBMS_SQLTUNE.load_sqlset(sqlset_name => l_sqlset_name, populate_cursor => sts_cur);
        DBMS_OUTPUT.put_line('loaded sts: '||l_sqlset_name);
        CLOSE sts_cur;
        --
        l_created_plans := DBMS_SPM.load_plans_from_sqlset(sqlset_name => l_sqlset_name);
        DBMS_OUTPUT.put_line('Plans loaded from sql tuning set:'||l_created_plans);
        --
        IF l_created_plans > 0 THEN
          DBMS_SQLTUNE.drop_sqlset(sqlset_name => l_sqlset_name);
          DBMS_OUTPUT.put_line('dropped staging sts: '||l_sqlset_name);
          --
          FOR i IN (SELECT /* 2 */ sql_handle, plan_name FROM dba_sql_plan_baselines WHERE l_created_plans > 0 AND signature = l_signature AND created > TO_DATE('&&creation_time.', '&&cs_datetime_full_format.') - 1/1440 AND description IS NULL AND origin LIKE 'MANUAL-LOAD%') /* on 19c it transformed from MANUAL-LOAD into MANUAL-LOAD-FROM-CURSOR-CACHE */
          LOOP
            l_description := 'cs_spbl_create.sql SRC=STS SQL_ID=&&cs_sql_id. PHV=&&cs_plan_hash_value. &&cs_reference_sanitized. CREATED=&&creation_time.';
            l_modified_plans := DBMS_SPM.alter_sql_plan_baseline(sql_handle => i.sql_handle, plan_name => i.plan_name, attribute_name  => 'DESCRIPTION', attribute_value => l_description);
            DBMS_OUTPUT.put_line('plan loaded from awr using a sts: '||i.sql_handle||' '||i.plan_name||' '||l_description);
          END LOOP;
        END IF;
      -- 19c DBMS_SPM.load_plans_from_awr fails with ORA-13769: Snapshots 94482 and 96578 do not exist.
      -- $ELSE
      --   l_created_plans := DBMS_SPM.load_plans_from_awr(begin_snap => l_begin_snap, end_snap => l_end_snap, basic_filter => q'[sql_id = '&&cs_sql_id.' AND plan_hash_value = TO_NUMBER('&&cs_plan_hash_value.')]');
      --   DBMS_OUTPUT.put_line('Plans loaded from awr:'||l_created_plans);
      --   FOR i IN (SELECT /* 3 */ sql_handle, plan_name FROM dba_sql_plan_baselines WHERE l_created_plans > 0 AND signature = l_signature AND created > TO_DATE('&&creation_time.', '&&cs_datetime_full_format.') - 1/1440 AND description IS NULL AND origin LIKE 'MANUAL-LOAD%') /* on 19c it transformed from MANUAL-LOAD into MANUAL-LOAD-FROM-CURSOR-CACHE */
      --   LOOP
      --     l_description := 'cs_spbl_create.sql SRC=AWR SQL_ID=&&cs_sql_id. PHV=&&cs_plan_hash_value. &&cs_reference_sanitized. CREATED=&&creation_time.';
      --     l_modified_plans := DBMS_SPM.alter_sql_plan_baseline(sql_handle => i.sql_handle, plan_name => i.plan_name, attribute_name  => 'DESCRIPTION', attribute_value => l_description);
      --     DBMS_OUTPUT.put_line('plan loaded from awr: '||i.sql_handle||' '||i.plan_name||' '||l_description);
      --   END LOOP;
      -- $END
    END IF;
  END IF;
END;
/
--
@@cs_internal/&&cs_spbl_create_post.
--
---------------------------------------------------------------------------------------
--
SET SERVEROUT OFF;
@@cs_internal/cs_spbl_internal_list.sql
--
PRO
PRO SQL> @&&cs_script_name..sql "&&cs_sql_id." "&&cs_plan_hash_value." 
--
@@cs_internal/cs_spool_tail.sql
@@cs_internal/cs_undef.sql
@@cs_internal/cs_reset.sql
--
