PRO cli_replace_baseline_with_sql_patch4.sql
SET LIN 600 SERVEROUT ON;
DECLARE
  l_signature NUMBER := 18428452374179711003; -- 8hsfgrf1n66vu /* performScanQuery(JOB,HashRangeIndex) */ NETWORK_CONTROL_PLANE
  l_cs_reference VARCHAR2(30) := 'IOD-31530';
  --l_cbo_hints VARCHAR2(500) := q'[GATHER_PLAN_STATISTICS FIRST_ROWS(1) OPT_PARAM('_fix_control' '5922070:OFF')]';
  l_cbo_hints VARCHAR2(500) := q'[FIRST_ROWS(1) OPT_PARAM('_fix_control' '5922070:OFF')]';
  l_plans INTEGER := -1;
  l_name VARCHAR2(64);
BEGIN
  FOR i IN (
    SELECT sql_handle, plan_name, sql_text, description, 
    SUBSTR(description, INSTR(description, 'SQL_ID=') + 7, 13) AS sql_id, 
    REPLACE(TRIM(SUBSTR(description, INSTR(description, 'PHV=') + 4, 10)), ' ') AS phv
      FROM dba_sql_plan_baselines 
     WHERE signature = l_signature
     ORDER BY
           sql_handle, plan_name
  )
  LOOP
    DBMS_OUTPUT.put_line('drop baseline: '||i.sql_handle||' '||i.plan_name||' '||i.sql_id||' '||i.phv||' '||i.description);
    IF l_plans = -1 THEN -- do once (expect multiple plans on baseline)
      FOR j IN (SELECT name FROM dba_sql_patches WHERE signature = l_signature)
      LOOP
        DBMS_SQLDIAG.drop_sql_patch(name => j.name); -- drop any pre-existing sql patch
      END LOOP;
      DBMS_OUTPUT.put_line('create patch: '||l_cbo_hints);
      $IF DBMS_DB_VERSION.ver_le_12_1
      $THEN
        DBMS_SQLDIAG_INTERNAL.i_create_patch(sql_text => i.sql_text, hint_text => l_cbo_hints, name => 'spch_'||COALESCE(i.sql_id, TO_CHAR(l_signature)), description => l_cbo_hints||' '||l_cs_reference); -- 12c
      $ELSE
        l_name := DBMS_SQLDIAG.create_sql_patch(sql_text => i.sql_text, hint_text => l_cbo_hints, name => 'spch_'||COALESCE(i.sql_id, TO_CHAR(l_signature)), description => l_cbo_hints||' '||l_cs_reference); -- 19c
      $END
    END IF;
    l_plans := DBMS_SPM.drop_sql_plan_baseline(sql_handle => i.sql_handle, plan_name => i.plan_name); -- drop all plans on baseline (one by one)
  END LOOP;
END;
/
