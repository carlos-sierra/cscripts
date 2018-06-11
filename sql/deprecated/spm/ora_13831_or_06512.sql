SET PAGES 100 LIN 300 FEED ON HEA ON;
COL signature FOR 99999999999999999999;
COL plans FOR 99999;
COL active FOR 999999;
COL fixed FOR 99999;
COL min_created FOR A19;
COL max_created FOR A19;
COL last_executed FOR A19;
WITH all_baselines AS (
SELECT TO_CHAR(MIN(created), 'YYYY-MM-DD"T"HH24:MI:SS') min_created,
       TO_CHAR(MAX(created), 'YYYY-MM-DD"T"HH24:MI:SS') max_created,
       TO_CHAR(MAX(last_executed), 'YYYY-MM-DD"T"HH24:MI:SS') last_executed,
       signature,
       COUNT(*) plans,
       SUM(CASE WHEN enabled = 'YES' AND accepted = 'YES' AND reproduced = 'YES' THEN 1 ELSE 0 END) active,
       SUM(CASE WHEN enabled = 'YES' AND accepted = 'YES' AND reproduced = 'YES' AND fixed = 'YES' THEN 1 ELSE 0 END) fixed,
       SUM(CASE WHEN description LIKE '%13831%' THEN 1 ELSE 0 END) ora_13831,
       SUM(CASE WHEN description LIKE '%06512%' THEN 1 ELSE 0 END) ora_06512,
       SUM(CASE WHEN description LIKE '%13831%' OR description LIKE '%06512%' THEN 1 ELSE 0 END) ora_both
  FROM cdb_sql_plan_baselines
 GROUP BY
       signature
)
SELECT *
  FROM all_baselines
 WHERE ora_13831 > 0 OR ora_06512 > 0
 ORDER BY
       min_created
/
