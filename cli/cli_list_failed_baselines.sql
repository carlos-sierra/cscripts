SET SERVEROUT ON HEA OFF PAGES 0 LIN 300;
-- list sql with plans where a baseline exists but it is ignored
DECLARE
  l_plans NUMBER;
BEGIN
  FOR i IN (WITH
            b AS (SELECT /*+ MATERIALIZE NO_MERGE OPT_PARAM('_px_cdb_view_enabled' 'FALSE') */ DISTINCT con_id, signature, sql_handle FROM cdb_sql_plan_baselines WHERE enabled = 'YES' AND accepted = 'YES' /*AND created < SYSDATE - (1/24)*/ AND con_id > 2 AND ROWNUM >= 1),
            c AS (SELECT /*+ MATERIALIZE NO_MERGE */ DISTINCT con_id, name AS pdb_name FROM v$containers WHERE con_id > 2 AND ROWNUM >= 1),
            -- p AS (SELECT /*+ MATERIALIZE NO_MERGE */ con_id, address, hash_value, sql_id, plan_hash_value, child_address, child_number FROM v$sql_plan p, 
            --       XMLTABLE('other_xml/info' PASSING XMLTYPE(p.other_xml) COLUMNS type VARCHAR2(30) PATH '@type', note VARCHAR2(4) PATH '@note', value VARCHAR2(30) PATH '.') x 
            --       WHERE p.con_id > 2 AND p.other_xml LIKE '%baseline_repro_fail%' AND x.type = 'baseline_repro_fail' AND x.value = 'yes' AND ROWNUM >= 1),
            s AS (SELECT /*+ MATERIALIZE NO_MERGE */ DISTINCT con_id, address, hash_value, sql_id, plan_hash_value, child_address, child_number, exact_matching_signature AS signature, elapsed_time, sql_text FROM v$sql 
                  WHERE con_id > 2 AND parsing_user_id > 0 AND parsing_schema_id > 0 AND exact_matching_signature > 0 AND cpu_time > 0 AND buffer_gets > executions AND object_status = 'VALID' 
                  AND is_obsolete = 'N' AND is_shareable = 'Y' AND is_bind_aware = 'N'  AND is_resolved_adaptive_plan IS NULL  AND is_reoptimizable = 'N' AND last_active_time > SYSDATE - (1/24) AND ROWNUM >= 1),
            x AS (
            SELECT  /*+ MATERIALIZE NO_MERGE */ DISTINCT s.con_id, s.sql_id, s.signature, s.elapsed_time, s.sql_text
            FROM    v$sql_plan p,
                    XMLTABLE('other_xml/info' PASSING XMLTYPE(p.other_xml) COLUMNS type VARCHAR2(30) PATH '@type', note VARCHAR2(4) PATH '@note', value VARCHAR2(30) PATH '.') x,
                    s
            WHERE   p.con_id > 2
            AND     p.plan_hash_value > 0
            AND     p.other_xml LIKE '%baseline_repro_fail%'
            AND     p.con_id = s.con_id
            AND     p.address = s.address
            AND     p.hash_value = s.hash_value
            AND     p.sql_id = s.sql_id
            AND     p.plan_hash_value = s.plan_hash_value
            AND     p.child_address = s.child_address
            AND     p.child_number = s.child_number
            AND     x.type = 'baseline_repro_fail' 
            AND     x.value = 'yes'
            AND     ROWNUM >= 1)
            SELECT  SUM(x.elapsed_time) AS elapsed_time, c.pdb_name, x.sql_id, b.sql_handle, x.sql_text
              FROM  x, c, b
             WHERE  c.con_id = x.con_id
             AND    b.con_id = x.con_id
             AND    b.signature = x.signature
            GROUP BY c.pdb_name, x.sql_id, b.sql_handle, x.sql_text
            ORDER BY 1 DESC)
  LOOP
    DBMS_OUTPUT.put_line(i.pdb_name||' '||i.sql_id||' '||i.sql_handle||' '||SUBSTR(i.sql_text, 1, 80));
  END LOOP;
END;
/

-- SELECT   p.con_id, p.sql_id, p.plan_hash_value, p.child_number
--  FROM    v$sql_plan p,
--          XMLTABLE('other_xml/info' PASSING XMLTYPE(p.other_xml) COLUMNS type VARCHAR2(30) PATH '@type', note VARCHAR2(4) PATH '@note', value VARCHAR2(30) PATH '.') x
--  WHERE   p.con_id > 2
--  AND     p.plan_hash_value > 0
--  AND     p.other_xml LIKE '%baseline_repro_fail%'
--  AND     x.type = 'baseline_repro_fail' 
--  AND     x.value = 'yes'
--  ORDER BY
--          p.con_id, p.sql_id, p.plan_hash_value, p.child_number
-- /
-- SELECT   DISTINCT p.con_id, p.sql_id, p.plan_hash_value, p.child_number
--  FROM    v$sql_plan p
--  WHERE   p.other_xml LIKE '%baseline_repro_fail%'
--  ORDER BY
--          p.con_id, p.sql_id, p.plan_hash_value, p.child_number
-- /
