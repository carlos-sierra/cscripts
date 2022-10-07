DEF 1 = 'C##IOD';
VAR plans_to_refresh_limit NUMBER;
EXEC :plans_to_refresh_limit := 1000;
--
WITH
candidate_sql AS (
SELECT  /*+ MATERIALIZE NO_MERGE */
        DISTINCT s.con_id, s.exact_matching_signature AS signature, s.sql_id, s.plan_hash_value, s.sql_plan_baseline AS plan_name, s.sql_text
FROM    v$sql s
WHERE   s.sql_plan_baseline IS NOT NULL -- a baseline exists and it is in use
AND     s.parsing_user_id > 0 -- exclude SYS
AND     s.parsing_schema_id > 0 -- exclude SYS
AND     s.parsing_schema_name NOT IN ('SYS', 'SYSTEM', 'MDSYS', 'ORDDATA', 'CTXSYS', 'WMSYS', 'DVSYS', 'XDB', 'LBACSYS', 'DBSNMP', 'GSMADMIN_INTERNAL') -- to reduce selection
AND     s.parsing_schema_name NOT LIKE 'C##%' -- to reduce selection
AND     s.parsing_schema_name NOT LIKE 'APEX%' -- to reduce selection
AND     s.plan_hash_value > 0 -- e.g.: PL/SQL has 0 on PHV
AND     s.exact_matching_signature > 0 -- INSERT from values has 0 on signature
AND     s.executions > 0
AND     s.cpu_time > 0
AND     s.buffer_gets > 0
AND     s.buffer_gets > s.executions
AND     s.object_status = 'VALID'
AND     s.is_obsolete = 'N'
AND     s.is_shareable = 'Y'
AND     s.is_bind_aware = 'N' -- to ignore cursors using adaptive cursor sharing ACS as per CHANGE-190522
AND     s.is_resolved_adaptive_plan IS NULL -- to ignore adaptive plans which cause trouble when combined with SPM
AND     s.is_reoptimizable = 'N' -- to ignore cursors which require adjustments as per cardinality feedback  
AND     s.last_active_time > SYSDATE - (3/24) -- cursors has been executed within the last few hours
-- AND     NOT EXISTS (SELECT NULL FROM &&1..zapper_ignore_sql_text i WHERE UPPER(s.sql_text) LIKE UPPER('%'||i.sql_text||'%'))
AND     ROWNUM >= 1 /* MATERIALIZE NO_MERGE */
),
candidate_baselines AS (
SELECT /*+ MATERIALIZE NO_MERGE OPT_PARAM('_px_cdb_view_enabled' 'FALSE') */
       DISTINCT
       b.con_id,
       b.created, 
       b.last_modified,
       b.signature,
       b.plan_name,
       b.description
  FROM cdb_sql_plan_baselines b
 WHERE b.enabled = 'YES'
   AND b.accepted = 'YES'
   AND b.created < SYSDATE - 30 -- only consider refreshing baselines older than these many days
   AND b.parsing_schema_name NOT IN ('SYS', 'SYSTEM', 'MDSYS', 'ORDDATA', 'CTXSYS', 'WMSYS', 'DVSYS', 'XDB', 'LBACSYS', 'DBSNMP', 'GSMADMIN_INTERNAL') -- to reduce selection
   AND b.parsing_schema_name NOT LIKE 'C##%' -- to reduce selection
   AND b.parsing_schema_name NOT LIKE 'APEX%' -- to reduce selection
   AND  ROWNUM >= 1 /* MATERIALIZE NO_MERGE */
)
SELECT s.sql_id,
       c.name AS pdb_name,
       s.signature,
       s.plan_hash_value,
       s.plan_name,
       s.sql_text,
       b.created, 
       b.last_modified,
       b.description
  FROM candidate_sql s,
       candidate_baselines b,
       v$containers c
 WHERE b.con_id = s.con_id
   AND b.signature = s.signature
   AND b.plan_name = s.plan_name
   AND c.con_id = s.con_id
 ORDER BY
       b.created,
       b.last_modified
 FETCH FIRST :plans_to_refresh_limit ROWS ONLY
/

