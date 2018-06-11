SET PAGES 100 LIN 300 FEED ON HEA ON;
COL signature FOR 99999999999999999999;
COL plans FOR 99999;
COL active FOR 999999;
COL fixed FOR 99999;
COL min_created FOR A19;
COL max_created FOR A19;
COL last_executed FOR A19;
SELECT TO_CHAR(MIN(created), 'YYYY-MM-DD"T"HH24:MI:SS') min_created,
       TO_CHAR(MAX(created), 'YYYY-MM-DD"T"HH24:MI:SS') max_created,
       TO_CHAR(MAX(last_executed), 'YYYY-MM-DD"T"HH24:MI:SS') last_executed,
       signature,
       COUNT(*) plans,
       SUM(CASE WHEN enabled = 'YES' AND accepted = 'YES' AND reproduced = 'YES' THEN 1 ELSE 0 END) active,
       SUM(CASE WHEN enabled = 'YES' AND accepted = 'YES' AND reproduced = 'YES' AND fixed = 'YES' THEN 1 ELSE 0 END) fixed
  FROM cdb_sql_plan_baselines
 WHERE description LIKE '%13831%'
    --OR description LIKE '%06512%'
 GROUP BY
       signature
 ORDER BY
       MIN(created)
/
