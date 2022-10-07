WITH relevant AS 
(SELECT z.*, ROW_NUMBER() OVER(ORDER BY log_time DESC) AS rn 
FROM &&cs_stgtab_owner..zapper_log_v z 
WHERE z.log_time BETWEEN TO_DATE('&&cs_sample_time_from.', '&&cs_datetime_full_format.') AND TO_DATE('&&cs_sample_time_to.', '&&cs_datetime_full_format.') 
AND '&&cs_con_name.' IN (z.pdb_name, 'CDB$ROOT') AND z.sql_id = NVL('&&cs_sql_id.', z.sql_id))
SELECT * 
FROM relevant 
WHERE NVL(patch_create,0) + NVL(plans_create,0) + NVL(plans_disable,0) + NVL(plans_drop,0) + NVL(baseline_repro_fail,0) > 0
OR '&&cs_null.' = 'Y' 
OR rn = 1 
ORDER BY log_time
/