COL seconds FOR 999,990;
COL pdb_name FOR A30;
SELECT COUNT(*) AS seconds,
       c.name AS pdb_name
  FROM dba_hist_active_sess_history h, v$containers c
 WHERE h.event = 'enq: SQ - contention'
   AND h.sql_id = 'bwbauvpwvmn2w'
   AND sample_time > SYSDATE - 1
   AND c.con_id = h.con_id
 GROUP BY
       c.name
-- HAVING COUNT(*) > 3600
 ORDER BY
       1 DESC
/