ACC days_of_history PROMPT 'Days of history to consider (default 7): '
ACC top_n PROMPT 'Top x (default 1): '
SET HEA ON LIN 500 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF;
COL pdb_name FOR A30;

WITH
ash_per_con_sql_phv AS (
SELECT /*+ MATERIALIZE NO_MERGE */
         con_id
       , sql_id
       , sql_plan_hash_value
       , COUNT(*) samples
  FROM dba_hist_active_sess_history
 WHERE sample_time > SYSDATE - TO_NUMBER(NVL('&&days_of_history.','7'))
 GROUP BY
          con_id
       , sql_id
       , sql_plan_hash_value
),
total AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       SUM(samples) samples
  FROM ash_per_con_sql_phv
),
ash_per_sql AS (
SELECT /*+ MATERIALIZE NO_MERGE */
         sql_id
       , SUM(samples) samples
       , ROW_NUMBER() OVER (ORDER BY SUM(samples) DESC) top
  FROM ash_per_con_sql_phv
 WHERE sql_id IS NOT NULL
 GROUP BY
       sql_id
),
top_n_sql AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       sql_id
  FROM ash_per_sql
 WHERE top = TO_NUMBER(NVL('&&top_n.', '1'))
),
plans_of_top_n_sql AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       DISTINCT sql_plan_hash_value
  FROM ash_per_con_sql_phv
 WHERE sql_id = (SELECT sql_id FROM top_n_sql)
   AND sql_plan_hash_value > 0
),
sql_family_of_top_n_sql AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       DISTINCT ash_per_con_sql_phv.sql_id
  FROM plans_of_top_n_sql, ash_per_con_sql_phv
 WHERE ash_per_con_sql_phv.sql_plan_hash_value = plans_of_top_n_sql.sql_plan_hash_value
)
SELECT   TO_CHAR(ROUND(100 * SUM(ash_per_con_sql_phv.samples) / total.samples, 2), '90.00')||' %' db_time_perc
       , ash_per_con_sql_phv.con_id
       , SUBSTR((SELECT v$pdbs.name FROM v$pdbs WHERE v$pdbs.con_id = ash_per_con_sql_phv.con_id), 1, 30) pdb_name
       , ash_per_con_sql_phv.sql_id
  FROM ash_per_con_sql_phv, sql_family_of_top_n_sql, total
 WHERE sql_family_of_top_n_sql.sql_id = ash_per_con_sql_phv.sql_id
 GROUP BY
         ash_per_con_sql_phv.con_id
       , ash_per_con_sql_phv.sql_id
       , total.samples
--HAVING ROUND(100 * SUM(ash_per_con_sql_phv.samples) / total.samples, 1) >= 0.1
 ORDER BY
       SUM(ash_per_con_sql_phv.samples) DESC
/

UNDEF days_of_history, top_n;
