PRO
PRO Pack plan: "&&cs_plan_name."
DECLARE
  l_plans INTEGER;
BEGIN
  FOR i IN (SELECT sql_handle, plan_name 
              FROM dba_sql_plan_baselines 
             WHERE signature = &&cs_signature.
               AND plan_name = COALESCE('&&cs_plan_name.', plan_name)
             ORDER BY signature, plan_name)
  LOOP
    l_plans := DBMS_SPM.pack_stgtab_baseline(table_name => '&&cs_stgtab_prefix._stgtab_baseline', table_owner => '&&cs_stgtab_owner.', sql_handle => i.sql_handle, plan_name => i.plan_name);
  END LOOP;
END;
/
