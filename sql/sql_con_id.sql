WITH
ash AS (
SELECT con_id, COUNT(*) samples
  FROM dba_hist_active_sess_history
 WHERE sql_id = '&&sql_id'
 GROUP BY
       con_id
)
SELECT a.samples, a.con_id, p.name container
  FROM v$pdbs p, ash a
 WHERE p.con_id = a.con_id
 ORDER BY
       a.samples DESC
/
