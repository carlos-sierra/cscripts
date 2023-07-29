SELECT TO_CHAR(b.created, '&&cs_timestamp_full_format.') AS created,
       TO_CHAR(b.last_modified, '&&cs_datetime_full_format.') AS last_modified, 
       b.plan_name,
       b.enabled,
       b.accepted,
       b.fixed,
       b.reproduced,
       b.autopurge,
       b.adaptive, 
       b.origin AS ori, 
       b.description
  FROM dba_sql_plan_baselines b
 WHERE b.signature = :cs_signature
 ORDER BY
       b.created, b.last_modified, b.plan_name
/