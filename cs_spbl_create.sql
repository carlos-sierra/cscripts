----------------------------------------------------------------------------------------
--
-- File name:   cs_spbl_create.sql
--
-- Purpose:     Create a SQL Plan Baseline for given SQL_ID
--
-- Author:      Carlos Sierra
--
-- Version:     2021/07/21
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
--
@@cs_internal/cs_&&dba_or_cdb._plans_performance.sql
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
---------------------------------------------------------------------------------------
--
-- cleaup unrelated outdated sql tuning sets (created by older versions of this script)
--
BEGIN
  FOR i IN (SELECT created, owner, name FROM wri$_sqlset_definitions WHERE created < SYSDATE - 1 AND name LIKE 'S%' AND statement_count = 1 ORDER BY 1)
  LOOP
    DBMS_OUTPUT.put_line('dropping unrelated and outdated sts '||i.owner||' '||i.name||' created on '||TO_CHAR(i.created, '&&cs_datetime_full_format.'));
    DBMS_SQLTUNE.drop_sqlset(sqlset_name => i.name, sqlset_owner => i.owner);
  END LOOP;
END;
/
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
---------------------------------------------------------------------------------------
--
-- disable baselines on this sql if metadata is corrupt (ORA-13831)
--
DECLARE
  l_plans INTEGER;
  l_plans_t INTEGER := 0;
  l_description VARCHAR2(500);
BEGIN
  FOR i IN (SELECT t.sql_handle,
                   o.name plan_name,
                   a.description
              FROM sqlobj$plan p,
                   sqlobj$ o,
                   sqlobj$auxdata a,
                   sql$text t
             WHERE p.signature = :cs_signature
               AND p.obj_type = 2 /* 1=profile, 2=baseline, 3=patch */
               AND p.id = 1
               AND p.other_xml IS NOT NULL
               -- plan_hash_value ignoring transient object names (must be same than plan_id for a baseline to be used)
               AND p.plan_id <> TO_NUMBER(extractvalue(xmltype(p.other_xml),'/*/info[@type = "plan_hash_2"]')) 
               AND o.obj_type = 2 /* 1=profile, 2=baseline, 3=patch */
               AND o.signature = p.signature
               AND o.plan_id = p.plan_id
               AND BITAND(o.flags, 1) = 1 /* enabled */
               AND a.obj_type = 2 /* 1=profile, 2=baseline, 3=patch */
               AND a.signature = p.signature
               AND a.plan_id = p.plan_id
               AND a.created > TO_DATE('&&creation_time.', '&&cs_datetime_full_format.') - 1/1440
               AND t.signature = p.signature
             ORDER BY
                   t.sql_handle,
                   o.name)
  LOOP
    l_plans := DBMS_SPM.alter_sql_plan_baseline(sql_handle => i.sql_handle, plan_name => i.plan_name, attribute_name => 'ENABLED', attribute_value => 'NO');
    l_description := TRIM(i.description||' cs_spbl_create.sql ORA-13831 DISABLED='||TO_CHAR(SYSDATE, '&&cs_datetime_full_format.'));
    DBMS_OUTPUT.put_line('disable baseline since metadata is corrupt (ORA-13831): '||i.sql_handle||' '||i.plan_name||' '||l_description);
    l_plans := DBMS_SPM.alter_sql_plan_baseline(sql_handle => i.sql_handle, plan_name => i.plan_name, attribute_name => 'DESCRIPTION', attribute_value => l_description);
    l_plans_t := l_plans_t + l_plans;
  END LOOP;
END;
/
--
---------------------------------------------------------------------------------------
--
-- disable baselines on this sql if metadata is corrupt (ORA-06512)
--
DECLARE
  l_plans INTEGER; 
  l_plans_t INTEGER := 0;
  l_description VARCHAR2(500);
BEGIN 
  FOR i IN (SELECT t.sql_handle, 
                   o.name plan_name, 
                   a.description 
              FROM sys.sqlobj$ o, 
                   sys.sql$text t, 
                   sys.sqlobj$auxdata a 
             WHERE o.signature = :cs_signature
               AND o.obj_type = 2 /* 1=profile, 2=baseline, 3=patch */
               AND BITAND(o.flags, 1) = 1 /* enabled */ 
               AND t.signature = o.signature 
               AND a.obj_type = o.obj_type 
               AND a.signature = o.signature 
               AND a.plan_id = o.plan_id 
               AND a.created > TO_DATE('&&creation_time.', '&&cs_datetime_full_format.') - 1/1440
               AND NOT EXISTS  
                   ( SELECT NULL 
                       FROM sys.sqlobj$plan p 
                      WHERE p.signature = o.signature 
                        AND p.obj_type = o.obj_type 
                        AND p.plan_id = o.plan_id 
                    ) 
             ORDER BY 
                   o.plan_id) 
  LOOP 
    l_plans := DBMS_SPM.alter_sql_plan_baseline(sql_handle => i.sql_handle, plan_name => i.plan_name, attribute_name => 'ENABLED', attribute_value => 'NO'); 
    l_description := i.description||' cs_spbl_create.sql ORA-06512 DISABLED='||TO_CHAR(SYSDATE, '&&cs_datetime_full_format.');
    DBMS_OUTPUT.put_line('disable baseline since metadata is corrupt (ORA-06512): '||i.sql_handle||' '||i.plan_name||' '||l_description);
    l_plans := DBMS_SPM.alter_sql_plan_baseline(sql_handle => i.sql_handle, plan_name => i.plan_name, attribute_name => 'DESCRIPTION', attribute_value => l_description); 
    l_plans_t := l_plans_t + l_plans;
  END LOOP; 
END;
/
--
---------------------------------------------------------------------------------------
--
-- fix Corrupt Baseline (DBPERF-6822)
--
MERGE INTO sys.sqlobj$plan t
    USING (SELECT o.signature,
                  o.category,
                  o.obj_type,
                  o.plan_id,
                  1 AS id
              FROM sys.sqlobj$ o
            WHERE o.category = 'DEFAULT'
              AND o.obj_type = 2
              AND o.signature = :cs_signature
              AND NOT EXISTS (
                    SELECT NULL
                      FROM sys.sqlobj$plan p
                      WHERE p.signature = o.signature
                        AND p.category = o.category
                        AND p.obj_type = o.obj_type 
                        AND p.plan_id = o.plan_id
                        AND p.id = 1
              )
              AND NOT EXISTS (
                    SELECT NULL
                      FROM sys.sqlobj$data d
                      WHERE d.signature = o.signature
                        AND d.category = o.category
                        AND d.obj_type = o.obj_type 
                        AND d.plan_id = o.plan_id
                        AND d.comp_data IS NOT NULL
              )) s
ON (t.signature = s.signature AND t.category = s.category AND t.obj_type = s.obj_type AND t.plan_id = s.plan_id AND t.id = s.id)
WHEN NOT MATCHED THEN
  INSERT (signature, category, obj_type, plan_id, id) 
  VALUES (s.signature, s.category, s.obj_type, s.plan_id, s.id)
/
COMMIT
/
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
