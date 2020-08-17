COL con_id FOR 999 HEA 'Con|ID';
COL pdb_name FOR A30 HEA 'PDB Name' FOR A30 TRUNC;
COL timestamp FOR A19 HEA 'Timestamp';
COL plan_hash_value FOR 9999999999 HEA 'Plan|Hash Value';
--
PRO
PRO PLANS IN AWR (dba_hist_sql_plan)
PRO ~~~~~~~~~~~~
SELECT TO_CHAR(h.timestamp, '&&cs_datetime_full_format.') timestamp, 
       h.con_id, c.name AS pdb_name,
       plan_hash_value
  FROM cdb_hist_sql_plan h,
       v$containers c
 WHERE h.sql_id = '&&cs_sql_id.'
   AND ('&&cs_plan_hash_value.' IS NULL OR h.plan_hash_value = TO_NUMBER('&&cs_plan_hash_value.'))
   AND h.id = 0
   AND c.con_id = h.con_id
 ORDER BY
       h.timestamp,
       h.con_id
/
