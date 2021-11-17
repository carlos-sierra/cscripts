----------------------------------------------------------------------------------------
--
-- File name:   cs_spbl_drop.sql
--
-- Purpose:     Drop one or all SQL Plan Baselines for given SQL_ID
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
--              SQL> @cs_spbl_drop.sql
--
-- Notes:       Accesses AWR data thus you must have an Oracle Diagnostics Pack License.
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
DEF cs_script_name = 'cs_spbl_drop';
--
PRO 1. SQL_ID: 
DEF cs_sql_id = '&1.';
UNDEF 1;
--
SELECT '&&cs_file_prefix._&&cs_script_name._&&cs_sql_id.' cs_file_name FROM DUAL;
--
@@cs_internal/cs_signature.sql
--
@@cs_internal/cs_dba_plans_performance.sql
@@cs_internal/cs_spbl_internal_list.sql
--
PRO
PRO 2. PLAN_NAME (opt):
DEF cs_plan_name = '&2.';
UNDEF 2;
--
DEF cs_plan_id = '';
COL cs_plan_id NEW_V cs_plan_id NOPRI;
SELECT TO_CHAR(plan_id) cs_plan_id
  FROM sys.sqlobj$
 WHERE obj_type = 2 /* 1:profile, 2:baseline, 3:patch */
   AND signature = TO_NUMBER('&&cs_signature.')
   AND name = '&&cs_plan_name.'
/
PRO
--
@@cs_internal/cs_spool_head.sql
PRO SQL> @&&cs_script_name..sql "&&cs_sql_id." "&&cs_plan_name."
@@cs_internal/cs_spool_id.sql
--
PRO SQL_ID       : &&cs_sql_id.
PRO SQLHV        : &&cs_sqlid.
PRO SIGNATURE    : &&cs_signature.
PRO SQL_HANDLE   : &&cs_sql_handle.
PRO PLAN_NAME    : "&&cs_plan_name."
PRO PLAN_ID      : "&&cs_plan_id."
--
SET HEA OFF;
PRINT :cs_sql_text
SET HEA ON;
--
@@cs_internal/cs_dba_plans_performance.sql
@@cs_internal/cs_spbl_internal_list.sql
--
@@cs_internal/cs_spbl_internal_stgtab.sql
@@cs_internal/cs_spbl_internal_pack.sql
--
SET SERVEROUT ON;
PRO
PRO Validate plan: "&&cs_plan_name."
WHENEVER SQLERROR EXIT FAILURE;
DECLARE
  l_plans INTEGER;
BEGIN
  FOR i IN (SELECT o.signature,
                  o.category,
                  o.obj_type,
                  o.plan_id,
                  o.name AS plan_name,
                  TO_CHAR(a.created, '&&cs_timestamp_full_format.') AS created,
                  TO_CHAR(a.last_modified, '&&cs_datetime_full_format.') AS last_modified, 
                  DECODE(BITAND(o.flags, 1),   0, 'NO', 'YES') AS enabled,
                  DECODE(BITAND(o.flags, 2),   0, 'NO', 'YES') AS accepted,
                  DECODE(BITAND(o.flags, 4),   0, 'NO', 'YES') AS fixed,
                  DECODE(BITAND(o.flags, 64),  0, 'YES', 'NO') AS reproduced,
                  DECODE(BITAND(o.flags, 128), 0, 'NO', 'YES') AS autopurge,
                  DECODE(BITAND(o.flags, 256), 0, 'NO', 'YES') AS adaptive, 
                  a.origin AS ori, 
                  t.sql_handle,
                  t.sql_text,
                  a.description
              FROM sys.sqlobj$ o,
                  sys.sqlobj$auxdata a,
                  sys.sql$text t
            WHERE o.signature = :cs_signature
              AND o.category = 'DEFAULT'
              AND o.obj_type = 2 /* 1:profile, 2:baseline, 3:patch */
              AND a.signature = o.signature
              AND a.category = o.category
              AND a.obj_type = o.obj_type
              AND a.plan_id = o.plan_id
              AND t.signature = o.signature
              AND NOT EXISTS (
                    SELECT NULL
                      FROM sys.sqlobj$plan p
                      WHERE p.signature = o.signature
                        AND p.category = o.category
                        AND p.obj_type = o.obj_type 
                        AND p.plan_id = o.plan_id
                        AND p.id = 1
                        AND ROWNUM = 1
              )
              AND NOT EXISTS (
                    SELECT NULL
                      FROM sys.sqlobj$data d
                      WHERE d.signature = o.signature
                        AND d.category = o.category
                        AND d.obj_type = o.obj_type 
                        AND d.plan_id = o.plan_id
                        AND d.comp_data IS NOT NULL
                        AND ROWNUM = 1
              )
            ORDER BY
                  o.signature, o.category, o.obj_type, o.plan_id)
  LOOP
    IF i.enabled = 'YES' THEN
      DBMS_OUTPUT.put_line('Disable Plan: '||i.plan_name);
      l_plans := DBMS_SPM.alter_sql_plan_baseline(sql_handle => i.sql_handle, plan_name => i.plan_name, attribute_name => 'ENABLED', attribute_value => 'NO');
    END IF;
    DBMS_OUTPUT.put_line('Fixing Corrupt Plan: '||i.plan_name);
    DELETE sys.sqlobj$plan WHERE signature = i.signature AND category = i.category AND obj_type = i.obj_type AND plan_id = i.plan_id AND id = 1;
    INSERT INTO sys.sqlobj$plan (signature, category, obj_type, plan_id, id) VALUES (i.signature, i.category, i.obj_type, i.plan_id, 1);
  END LOOP;
  COMMIT;
END;
/
PRO
PRO Drop plan: "&&cs_plan_name."
DECLARE
  l_plans INTEGER := 0;
BEGIN
  IF '&&cs_sql_handle.' IS NOT NULL OR '&&cs_plan_name.' IS NOT NULL THEN
    l_plans := DBMS_SPM.drop_sql_plan_baseline(sql_handle => '&&cs_sql_handle.', plan_name => '&&cs_plan_name.');
  END IF;
  DBMS_OUTPUT.put_line('Plans Dropped:'||l_plans);
END;
/
WHENEVER SQLERROR CONTINUE;
SET SERVEROUT OFF;
--
@@cs_internal/cs_spbl_internal_list.sql
--
PRO
PRO SQL> @&&cs_script_name..sql "&&cs_sql_id." "&&cs_plan_name."
--
@@cs_internal/cs_spool_tail.sql
@@cs_internal/cs_undef.sql
@@cs_internal/cs_reset.sql
--
