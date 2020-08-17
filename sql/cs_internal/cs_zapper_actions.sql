ALTER SESSION SET container = CDB$ROOT;
PRO
PRO ZAPPER ACTIONS (&&cs_stgtab_owner..sql_plan_baseline_hist)
PRO ~~~~~~~~~~~~~~
PRO
SET HEA OFF PAGES 0 RECSEP EA;
WITH
zapper_actions AS (
SELECT snap_time, zapper_action, zapper_report,
       RANK() OVER (ORDER BY snap_time DESC) AS rank
  FROM &&cs_stgtab_owner..sql_plan_baseline_hist
 WHERE '&&cs_con_name.' IN (pdb_name, 'CDB$ROOT')
   AND sql_id = '&&cs_sql_id.'
)
SELECT zapper_report
  FROM zapper_actions
 WHERE zapper_action <> 'NULL' 
    OR rank = 1
 ORDER BY 
       snap_time
/
SET HEA ON PAGES 100 RECSEP WR;
ALTER SESSION SET CONTAINER = &&cs_con_name.;
