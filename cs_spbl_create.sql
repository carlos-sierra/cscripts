----------------------------------------------------------------------------------------
--
-- File name:   cs_spbl_create.sql
--
-- Purpose:     Create a SQL Plan Baseline for given SQL_ID
--
-- Author:      Carlos Sierra
--
-- Version:     2020/12/20
--
-- Usage:       Connecting into PDB.
--
--              Enter SQL_ID when requested.
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @cs_spbl_create.sql
--
-- Notes:        *** Requires Oracle Diagnostics Pack License ***
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
SELECT '&&cs_file_prefix._&&cs_script_name._&&cs_sql_id.' cs_file_name FROM DUAL;
--
@@cs_internal/cs_signature.sql
--
@@cs_internal/cs_&&dba_or_cdb._plans_performance.sql
@@cs_internal/cs_spbl_internal_list.sql
--
PRO
PRO Select up to 3 plans:
PRO
PRO 2. 1st Plan Hash Value (req):
DEF plan_hash_value_1 = "&2.";
UNDEF 2;
PRO
PRO 3. 2nd Plan Hash Value (opt):
DEF plan_hash_value_2 = "&3.";
UNDEF 3;
PRO
PRO 4. 3rd Plan Hash Value (opt):
DEF plan_hash_value_3 = "&4.";
UNDEF 4;
PRO
PRO 5. Value for FIXED flag (opt) [{NO}|YES|N|Y]:
DEF fixed_flag = "&5.";
UNDEF 5;
--
COL fixed NEW_V fixed NOPRI;
SELECT CASE WHEN UPPER('&&fixed_flag.') IN ('Y', 'YES') THEN 'YES' ELSE 'NO' END fixed FROM DUAL;
--
@@cs_internal/cs_spool_head.sql
PRO SQL> @&&cs_script_name..sql "&&cs_sql_id." "&&plan_hash_value_1." "&&plan_hash_value_2." "&&plan_hash_value_3." "&&fixed."
@@cs_internal/cs_spool_id.sql
--
PRO SQL_ID       : &&cs_sql_id.
PRO SIGNATURE    : &&cs_signature.
PRO SQL_HANDLE   : &&cs_sql_handle.
PRO APPLICATION  : &&cs_application_category.
PRO PLAN_HASH_VAL: &&plan_hash_value_1. &&plan_hash_value_2. &&plan_hash_value_3.
PRO FIXED        : &&fixed.
--
SET HEA OFF;
PRINT :cs_sql_text
SET HEA ON;
--
---------------------------------------------------------------------------------------
--
-- validate requested plan(s) are not yet on repository
--
WHENEVER SQLERROR EXIT SUCCESS;
DECLARE
  l_spb_exists NUMBER := 0;
BEGIN
  SELECT COUNT(*)
    INTO l_spb_exists
    FROM sqlobj$plan p
   WHERE p.obj_type = 2 /* 1:profile, 2:baseline, 3:patch */
     AND p.id = 1
     AND p.other_xml IS NOT NULL
     AND p.signature = :cs_signature
     AND TO_NUMBER(extractvalue(xmltype(p.other_xml),'/*/info[@type = "plan_hash"]')) = TO_NUMBER('&&plan_hash_value_1.');
  IF l_spb_exists > 0 THEN
    raise_application_error(-20001, 'Plan &&plan_hash_value_1. already exists on SPM');
  END IF;
  SELECT COUNT(*)
    INTO l_spb_exists
    FROM sqlobj$plan p
   WHERE p.obj_type = 2 /* 1:profile, 2:baseline, 3:patch */
     AND p.id = 1
     AND p.other_xml IS NOT NULL
     AND p.signature = :cs_signature
     AND TO_NUMBER(extractvalue(xmltype(p.other_xml),'/*/info[@type = "plan_hash"]')) = TO_NUMBER('&&plan_hash_value_2.');
  IF l_spb_exists > 0 THEN
    raise_application_error(-20002, 'Plan &&plan_hash_value_2. already exists on SPM');
  END IF;
  SELECT COUNT(*)
    INTO l_spb_exists
    FROM sqlobj$plan p
   WHERE p.obj_type = 2 /* 1:profile, 2:baseline, 3:patch */
     AND p.id = 1
     AND p.other_xml IS NOT NULL
     AND p.signature = :cs_signature
     AND TO_NUMBER(extractvalue(xmltype(p.other_xml),'/*/info[@type = "plan_hash"]')) = TO_NUMBER('&&plan_hash_value_3.');
  IF l_spb_exists > 0 THEN
    raise_application_error(-20003, 'Plan &&plan_hash_value_3. already exists on SPM');
  END IF;
END;
/
WHENEVER SQLERROR CONTINUE;
--
---------------------------------------------------------------------------------------
--
-- load SPBs from cursor
--
VAR plans1 NUMBER;
VAR plans2 NUMBER;
VAR plans3 NUMBER;
VAR plans0 NUMBER;
--
BEGIN
  :plans1 := 0;
  :plans1 := DBMS_SPM.load_plans_from_cursor_cache(
            sql_id => '&&cs_sql_id.', 
            plan_hash_value => NVL(TO_NUMBER('&&plan_hash_value_1.'), -666), 
            fixed => '&&fixed.');
  FOR i IN (SELECT sql_handle, plan_name FROM dba_sql_plan_baselines WHERE :plans1 > 0 AND signature = :cs_signature AND created > SYSDATE - 1/1440 AND description IS NULL AND origin LIKE 'MANUAL-LOAD%') /* on 19c it transformed from MANUAL-LOAD into MANUAL-LOAD-FROM-CURSOR-CACHE */
  LOOP
    :plans0 :=
    DBMS_SPM.ALTER_SQL_PLAN_BASELINE (
      sql_handle      => i.sql_handle,
      plan_name       => i.plan_name,
      attribute_name  => 'DESCRIPTION',
      attribute_value => 'cs_spbl_create.sql SRC=MEM SQL_ID=&&cs_sql_id. PHV=&&plan_hash_value_1. &&cs_reference_sanitized. CREATED='||TO_CHAR(SYSDATE, 'YYYY-MM-DD"T"HH24:MI:SS')
    );
  END LOOP;
END;
/
PRO Plans created from memory for PHV1 "&&plan_hash_value_1."
PRINT plans1
--
BEGIN
  :plans2 := 0;
  IF '&&plan_hash_value_2.' IS NOT NULL THEN
    :plans2 := DBMS_SPM.load_plans_from_cursor_cache(
              sql_id => '&&cs_sql_id.', 
              plan_hash_value => NVL(TO_NUMBER('&&plan_hash_value_2.'), -666), 
              fixed => '&&fixed.');
    FOR i IN (SELECT sql_handle, plan_name FROM dba_sql_plan_baselines WHERE :plans2 > 0 AND signature = :cs_signature AND created > SYSDATE - 1/1440 AND description IS NULL AND origin LIKE 'MANUAL-LOAD%') /* on 19c it transformed from MANUAL-LOAD into MANUAL-LOAD-FROM-CURSOR-CACHE */
    LOOP
      :plans0 :=
      DBMS_SPM.ALTER_SQL_PLAN_BASELINE (
        sql_handle      => i.sql_handle,
        plan_name       => i.plan_name,
        attribute_name  => 'DESCRIPTION',
        attribute_value => 'cs_spbl_create.sql SRC=MEM SQL_ID=&&cs_sql_id. PHV=&&plan_hash_value_2. &&cs_reference_sanitized. CREATED='||TO_CHAR(SYSDATE, 'YYYY-MM-DD"T"HH24:MI:SS')
      );
    END LOOP;
  END IF;
END;
/
PRO Plans created from memory for PHV2 "&&plan_hash_value_2."
PRINT plans2
--
BEGIN
  :plans3 := 0;
  IF '&&plan_hash_value_3.' IS NOT NULL THEN
    :plans3 := DBMS_SPM.load_plans_from_cursor_cache(
              sql_id => '&&cs_sql_id.', 
              plan_hash_value => NVL(TO_NUMBER('&&plan_hash_value_3.'), -666), 
              fixed => '&&fixed.');
    FOR i IN (SELECT sql_handle, plan_name FROM dba_sql_plan_baselines WHERE :plans3 > 0 AND signature = :cs_signature AND created > SYSDATE - 1/1440 AND description IS NULL AND origin LIKE 'MANUAL-LOAD%') /* on 19c it transformed from MANUAL-LOAD into MANUAL-LOAD-FROM-CURSOR-CACHE */
    LOOP
      :plans0 :=
      DBMS_SPM.ALTER_SQL_PLAN_BASELINE (
        sql_handle      => i.sql_handle,
        plan_name       => i.plan_name,
        attribute_name  => 'DESCRIPTION',
        attribute_value => 'cs_spbl_create.sql SRC=MEM SQL_ID=&&cs_sql_id. PHV=&&plan_hash_value_3. &&cs_reference_sanitized. CREATED='||TO_CHAR(SYSDATE, 'YYYY-MM-DD"T"HH24:MI:SS')
      );
    END LOOP;
  END IF;
END;
/
PRO Plans created from memory for PHV3 "&&plan_hash_value_3."
PRINT plans3
--
@@cs_internal/cs_signature.sql
--
DEF plan_hash_value_1_awr = '';
DEF plan_hash_value_2_awr = '';
DEF plan_hash_value_3_awr = '';
COL plan_hash_value_1_awr NEW_V plan_hash_value_1_awr FOR A10 HEA 'PHV1';
COL plan_hash_value_2_awr NEW_V plan_hash_value_2_awr FOR A10 HEA 'PHV1';
COL plan_hash_value_3_awr NEW_V plan_hash_value_3_awr FOR A10 HEA 'PHV1';
-- only consider awr plans that were not available on cursor cache
SELECT CASE :plans1 WHEN 0 THEN '&&plan_hash_value_1.' END plan_hash_value_1_awr FROM DUAL;
SELECT CASE :plans2 WHEN 0 THEN '&&plan_hash_value_2.' END plan_hash_value_2_awr FROM DUAL;
SELECT CASE :plans3 WHEN 0 THEN '&&plan_hash_value_3.' END plan_hash_value_3_awr FROM DUAL;
-- get dbid
COL dbid NEW_V dbid;
SELECT dbid FROM v$database;
-- only consider awr plans created during past 6 months
COL timestamp FOR A19;
SELECT plan_hash_value, TO_CHAR(MAX(timestamp), 'YYYY-MM-DD"T"HH24:MI:SS') timestamp
  FROM dba_hist_sql_plan
 WHERE dbid = &&dbid. AND sql_id = '&&cs_sql_id.' 
   AND plan_hash_value IN ('&&plan_hash_value_1_awr.','&&plan_hash_value_2_awr.','&&plan_hash_value_3_awr.')
 GROUP BY
       plan_hash_value
 ORDER BY
       plan_hash_value;
SELECT CASE WHEN MAX(timestamp) > SYSDATE - 180 THEN '&&plan_hash_value_1_awr.' END plan_hash_value_1_awr
  FROM dba_hist_sql_plan
 WHERE dbid = &&dbid. AND sql_id = '&&cs_sql_id.' AND plan_hash_value = '&&plan_hash_value_1_awr.';
SELECT CASE WHEN MAX(timestamp) > SYSDATE - 180 THEN '&&plan_hash_value_2_awr.' END plan_hash_value_2_awr
  FROM dba_hist_sql_plan
 WHERE dbid = &&dbid. AND sql_id = '&&cs_sql_id.' AND plan_hash_value = '&&plan_hash_value_2_awr.';
SELECT CASE WHEN MAX(timestamp) > SYSDATE - 180 THEN '&&plan_hash_value_3_awr.' END plan_hash_value_3_awr
  FROM dba_hist_sql_plan
 WHERE dbid = &&dbid. AND sql_id = '&&cs_sql_id.' AND plan_hash_value = '&&plan_hash_value_3_awr.';
PRO Plans requested: "&&plan_hash_value_1." "&&plan_hash_value_2." "&&plan_hash_value_3."
PRO Recent plans from AWR: "&&plan_hash_value_1_awr." "&&plan_hash_value_2_awr." "&&plan_hash_value_3_awr."
--
---------------------------------------------------------------------------------------
--
-- load SPBs from awr through a sts (only if we could not load any plans from memory)
--
COL begin_snap_id NEW_V begin_snap_id NOPRI;
COL end_snap_id NEW_V end_snap_id NOPRI;
--
SELECT NVL(MIN(p.snap_id), 0) begin_snap_id, NVL(MAX(p.snap_id), 999999999999) end_snap_id
  FROM dba_hist_sqlstat p,
       dba_hist_snapshot s
 WHERE '&&plan_hash_value_1_awr.&&plan_hash_value_2_awr.&&plan_hash_value_3_awr.' IS NOT NULL
   AND p.dbid = &&dbid
   AND p.sql_id = '&&cs_sql_id.'
   AND s.snap_id = p.snap_id
   AND s.dbid = p.dbid
   AND s.instance_number = p.instance_number;
--
VAR sqlset_name VARCHAR2(30);
EXEC :sqlset_name := UPPER(REPLACE('s_&&cs_sql_id.', ' '));
PRINT sqlset_name;
--
SET SERVEROUT ON;
VAR plans NUMBER;
DECLARE
  l_sqlset_name VARCHAR2(30);
  l_description VARCHAR2(256);
  sts_cur       SYS.DBMS_SQLTUNE.SQLSET_CURSOR;
BEGIN
  IF '&&plan_hash_value_1_awr.&&plan_hash_value_2_awr.&&plan_hash_value_3_awr.' IS NOT NULL THEN
    --
    :plans := 0;
    l_sqlset_name := :sqlset_name;
    l_description := 'SQL_ID:&&cs_sql_id.BEGIN:&&begin_snap_id.END:&&end_snap_id.';
    l_description := REPLACE(REPLACE(l_description, ' '), ',', ', ');
    --
    BEGIN
      DBMS_OUTPUT.put_line('dropping sqlset: '||l_sqlset_name);
      SYS.DBMS_SQLTUNE.drop_sqlset (
        sqlset_name  => l_sqlset_name,
        sqlset_owner => USER );
    EXCEPTION
      WHEN OTHERS THEN
        DBMS_OUTPUT.put_line(SQLERRM||' while trying to drop STS: '||l_sqlset_name||' (safe to ignore)');
    END;
    --
    l_sqlset_name :=
    SYS.DBMS_SQLTUNE.create_sqlset (
      sqlset_name  => l_sqlset_name,
      description  => l_description,
      sqlset_owner => USER );
    DBMS_OUTPUT.put_line('created sqlset: '||l_sqlset_name);
    --
    OPEN sts_cur FOR
      SELECT VALUE(p)
        FROM TABLE(DBMS_SQLTUNE.select_workload_repository (&&begin_snap_id., &&end_snap_id.,
        q'[sql_id = '&&cs_sql_id.' AND plan_hash_value IN (NVL(TO_NUMBER('&&plan_hash_value_1_awr.'), -666), NVL(TO_NUMBER('&&plan_hash_value_2_awr.'), -666), NVL(TO_NUMBER('&&plan_hash_value_3_awr.'), -666)) AND loaded_versions > 0]',
        NULL, NULL, NULL, NULL, 1, NULL, 'ALL')) p;
    --
    SYS.DBMS_SQLTUNE.load_sqlset (
      sqlset_name     => l_sqlset_name,
      populate_cursor => sts_cur );
    DBMS_OUTPUT.put_line('loaded sqlset: '||l_sqlset_name);
    --
    CLOSE sts_cur;
    --
    :plans := DBMS_SPM.load_plans_from_sqlset (
      sqlset_name  => l_sqlset_name,
      sqlset_owner => USER,
      fixed        => '&&fixed.' );
    --
    FOR i IN (SELECT sql_handle, plan_name FROM dba_sql_plan_baselines WHERE :plans > 0 AND signature = :cs_signature AND created > SYSDATE - 1/1440 AND description IS NULL)
    LOOP
      :plans0 :=
      DBMS_SPM.ALTER_SQL_PLAN_BASELINE (
        sql_handle      => i.sql_handle,
        plan_name       => i.plan_name,
        attribute_name  => 'DESCRIPTION',
        attribute_value => 'cs_spbl_create.sql SRC=MEM SQL_ID=&&cs_sql_id. PHV='||TRIM('&&plan_hash_value_1_awr. &&plan_hash_value_2_awr. &&plan_hash_value_3_awr.')||' &&cs_reference_sanitized. CREATED='||TO_CHAR(SYSDATE, 'YYYY-MM-DD"T"HH24:MI:SS')
      );
    END LOOP;
    --
  END IF;
END;
/
PRO Plans created from AWR for PHV(s): &&plan_hash_value_1_awr. &&plan_hash_value_2_awr. &&plan_hash_value_3_awr.
PRINT plans
--
@@cs_internal/cs_signature.sql
--
---------------------------------------------------------------------------------------
--
-- disable baselines on this sql if metadata is corrupt
--
DECLARE
  l_plans INTEGER;
  l_plans_t INTEGER := 0;
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
               AND t.signature = p.signature
             ORDER BY
                   t.sql_handle,
                   o.name)
  LOOP
    l_plans :=
    DBMS_SPM.ALTER_SQL_PLAN_BASELINE (
      sql_handle      => i.sql_handle,
      plan_name       => i.plan_name,
      attribute_name  => 'ENABLED',
      attribute_value => 'NO'
    );
    l_plans :=
    DBMS_SPM.ALTER_SQL_PLAN_BASELINE (
      sql_handle      => i.sql_handle,
      plan_name       => i.plan_name,
      attribute_name  => 'DESCRIPTION',
      attribute_value => TRIM(i.description||' cs_spbl_create.sql ORA-13831 DISABLED='||TO_CHAR(SYSDATE, 'YYYY-MM-DD"T"HH24:MI:SS'))
    );
    l_plans_t := l_plans_t + l_plans;
  END LOOP;
  DBMS_OUTPUT.PUT_LINE('PLANS:'||l_plans_t);
END;
/
--
---------------------------------------------------------------------------------------
--
@@cs_internal/cs_spbl_internal_list.sql
@@cs_internal/cs_spbl_internal_plan.sql
@@cs_internal/cs_spbl_internal_list.sql
--
PRO
PRO SQL> @&&cs_script_name..sql "&&cs_sql_id." "&&plan_hash_value_1." "&&plan_hash_value_2." "&&plan_hash_value_3." "&&fixed."
--
@@cs_internal/cs_spool_tail.sql
@@cs_internal/cs_undef.sql
@@cs_internal/cs_reset.sql
--
