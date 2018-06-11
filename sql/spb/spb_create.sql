DEF spb_script = 'spb_create';
----------------------------------------------------------------------------------------
--
-- File name:   spb_create.sql
--
-- Purpose:     Create a SQL Plan Baseline for given SQL_ID
--
-- Author:      Carlos Sierra
--
-- Version:     2018/05/11
--
-- Usage:       Connecting into PDB.
--
--              Enter SQL_ID when requested.
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @spb_create.sql
--
-- Notes:       Accesses AWR data thus you must have an Oracle Diagnostics Pack License.
--
--              Developed and tested on 12.1.0.2.
--
---------------------------------------------------------------------------------------
--
@@spb_internal_begin.sql
--
---------------------------------------------------------------------------------------
--
PRO
PRO EXISTING BASELINES
PRO ~~~~~~~~~~~~~~~~~~
@@spb_internal_list.sql
--
---------------------------------------------------------------------------------------
--
@@spb_internal_plans_perf.sql
--
---------------------------------------------------------------------------------------
--
PRO
PRO Select up to 3 plans:
PRO
ACC plan_hash_value_1 PROMPT '1st Plan Hash Value (req): ';
ACC plan_hash_value_2 PROMPT '2nd Plan Hash Value (opt): ';
ACC plan_hash_value_3 PROMPT '3rd Plan Hash Value (opt): ';
PRO
ACC fixed_flag PROMPT 'FIXED (opt): ';
COL fixed NEW_V fixed;
SELECT CASE WHEN UPPER('&&fixed_flag.') IN ('Y', 'YES') THEN 'YES' ELSE 'NO' END fixed FROM DUAL;
--
---------------------------------------------------------------------------------------
--
-- load SPBs from cursor
--
VAR plans NUMBER;
--
BEGIN
  :plans := 0;
  :plans := DBMS_SPM.load_plans_from_cursor_cache(
            sql_id => '&&sql_id.', 
            plan_hash_value => NVL(TO_NUMBER('&&plan_hash_value_1.'), -666), 
            fixed => '&&fixed.');
END;
/
PRO Plans created from memory for PHV &&plan_hash_value_1.
PRINT plans
--
BEGIN
  :plans := 0;
  IF '&&plan_hash_value_2.' IS NOT NULL THEN
    :plans := DBMS_SPM.load_plans_from_cursor_cache(
              sql_id => '&&sql_id.', 
              plan_hash_value => NVL(TO_NUMBER('&&plan_hash_value_2.'), -666), 
              fixed => '&&fixed.');
  END IF;
END;
/
PRO Plans created from memory for PHV &&plan_hash_value_2.
PRINT plans
--
BEGIN
  :plans := 0;
  IF '&&plan_hash_value_3.' IS NOT NULL THEN
    :plans := DBMS_SPM.load_plans_from_cursor_cache(
              sql_id => '&&sql_id.', 
              plan_hash_value => NVL(TO_NUMBER('&&plan_hash_value_3.'), -666), 
              fixed => '&&fixed.');
  END IF;
END;
/
PRO Plans created from memory for PHV &&plan_hash_value_3.
PRINT plans
--
---------------------------------------------------------------------------------------
--
-- load SPBs from awr through a sts
--
COL dbid NEW_V dbid NOPRI;
SELECT dbid FROM v$database;
--
COL begin_snap_id NEW_V begin_snap_id NOPRI;
COL end_snap_id NEW_V end_snap_id NOPRI;
--
SELECT MIN(p.snap_id) begin_snap_id, MAX(p.snap_id) end_snap_id
  FROM dba_hist_sqlstat p,
       dba_hist_snapshot s
 WHERE p.dbid = &&dbid
   AND p.sql_id = '&&sql_id.'
   AND s.snap_id = p.snap_id
   AND s.dbid = p.dbid
   AND s.instance_number = p.instance_number;
--
VAR sqlset_name VARCHAR2(30);
EXEC :sqlset_name := UPPER(REPLACE('s_&&sql_id.', ' '));
PRINT sqlset_name;
--
SET SERVEROUT ON;
VAR plans NUMBER;
DECLARE
  l_sqlset_name VARCHAR2(30);
  l_description VARCHAR2(256);
  sts_cur       SYS.DBMS_SQLTUNE.SQLSET_CURSOR;
BEGIN
  :plans := 0;
  l_sqlset_name := :sqlset_name;
  l_description := 'SQL_ID:&&sql_id.BEGIN:&&begin_snap_id.END:&&end_snap_id.';
  l_description := REPLACE(REPLACE(l_description, ' '), ',', ', ');

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

  OPEN sts_cur FOR
    SELECT VALUE(p)
      FROM TABLE(DBMS_SQLTUNE.select_workload_repository (&&begin_snap_id., &&end_snap_id.,
      q'[sql_id = '&&sql_id.' AND plan_hash_value IN (NVL(TO_NUMBER('&&plan_hash_value_1.'), -666), NVL(TO_NUMBER('&&plan_hash_value_2.'), -666), NVL(TO_NUMBER('&&plan_hash_value_3.'), -666)) AND loaded_versions > 0]',
      NULL, NULL, NULL, NULL, 1, NULL, 'ALL')) p;

  SYS.DBMS_SQLTUNE.load_sqlset (
    sqlset_name     => l_sqlset_name,
    populate_cursor => sts_cur );
  DBMS_OUTPUT.put_line('loaded sqlset: '||l_sqlset_name);

  CLOSE sts_cur;

  :plans := DBMS_SPM.load_plans_from_sqlset (
    sqlset_name  => l_sqlset_name,
    sqlset_owner => USER,
    fixed        => '&&fixed.' );
END;
/
PRO Plans created from AWR for PHVs &&plan_hash_value_1. &&plan_hash_value_2. &&plan_hash_value_3.
PRINT plans
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
             WHERE p.signature = :signature
               AND p.obj_type = 2 /* 1=profile, 2=baseline, 3=patch */
               AND p.id = 1
               AND p.other_xml IS NOT NULL
               -- plan_hash_value ignoring transient object names (must be same than plan_id)
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
      attribute_value => TRIM(i.description||' NON-FPZ ORA-13831 DISABLED='||TO_CHAR(SYSDATE, 'YYYY-MM-DD"T"HH24:MI:SS'))
    );
    l_plans_t := l_plans_t + l_plans;
  END LOOP;
  DBMS_OUTPUT.PUT_LINE('PLANS:'||l_plans_t);
END;
/
--
---------------------------------------------------------------------------------------
--
PRO
PRO RESULTING BASELINES
PRO ~~~~~~~~~~~~~~~~~~~
@@spb_internal_list.sql
--
PRO
PRO SQL PLAN BASELINES
PRO ~~~~~~~~~~~~~~~~~~
@@spb_internal_plan.sql
--
PRO
PRO RESULTING BASELINES
PRO ~~~~~~~~~~~~~~~~~~~
@@spb_internal_list.sql
--
@@spb_internal_end.sql
