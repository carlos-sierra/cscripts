SET lin 300;
UNDEF sql_id
UNDEF sql_text_piece
COL cursors FOR 9999999;
COL spb FOR 999;
COL sql_id NEW_V sql_id FOR A13;
COL sql_text_100 FOR A100;
COL pdb_name FOR A30;
COL plns FOR 9999;
SELECT ROUND(SUM(s.elapsed_time)/1e6) elapsed_seconds,
       ROUND(SUM(s.cpu_time)/1e6) cpu_seconds,
       SUM(s.executions) executions, 
       CASE WHEN SUM(s.executions) > 0 THEN ROUND(SUM(s.elapsed_time)/SUM(s.executions)/1e6, 6) END secs_per_exec,
       MIN(s.plan_hash_value) min_phv,
       COUNT(DISTINCT s.plan_hash_value) plns,
       MAX(s.plan_hash_value) max_phv,
       (SELECT p.name FROM v$pdbs p WHERE p.con_id = s.con_id) pdb_name, 
       s.sql_id, 
       COUNT(*) cursors,
       SUM(CASE WHEN s.sql_plan_baseline IS NULL THEN 0 ELSE 1 END) spb,
       SUBSTR(s.sql_text, 1, 100) sql_text_100
  FROM v$sql s
 WHERE ((UPPER(s.sql_text) LIKE UPPER('%&&sql_text_piece.%') AND UPPER(s.sql_text) NOT LIKE '%SQL_ID%') OR s.sql_id = '&&sql_text_piece.')
 GROUP BY
       s.con_id, s.sql_id, 
       SUBSTR(s.sql_text, 1, 100)
HAVING SUM(s.executions) > 1 AND SUM(s.elapsed_time)/1e6 > 1
 ORDER BY
       1 DESC, 2 DESC, 3 DESC, 4 DESC
/

SELECT (SELECT p.name FROM v$pdbs p WHERE p.con_id = h.con_id) pdb_name, h.con_id,
        h.sql_id, DBMS_LOB.SUBSTR(h.sql_text, 100) sql_text_100
  FROM dba_hist_sqltext h
 WHERE ((UPPER(DBMS_LOB.SUBSTR(h.sql_text, 4000)) LIKE UPPER('%&&sql_text_piece.%') AND UPPER(DBMS_LOB.SUBSTR(h.sql_text, 4000)) NOT LIKE '%SQL_ID%') OR h.sql_id = '&&sql_text_piece.')
   AND h.con_id > 2
 ORDER BY 1, 2
/

