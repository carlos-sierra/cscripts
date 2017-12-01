SET LIN 300 PAGES 100 TAB OFF VER OFF FEED OFF ECHO OFF TRIMS ON;
UNDEF sql_text_piece
PRO &&sql_text_piece.

COL current_time NEW_V current_time FOR A15;
SELECT 'current_time: ' x, TO_CHAR(SYSDATE, 'YYYYMMDD_HH24MISS') current_time FROM DUAL;
COL x_host_name NEW_V x_host_name;
SELECT host_name x_host_name FROM v$instance;
COL x_db_name NEW_V x_db_name;
SELECT name x_db_name FROM v$database;
COL x_container NEW_V x_container;
SELECT 'NONE' x_container FROM DUAL;
SELECT SYS_CONTEXT('USERENV', 'CON_NAME') x_container FROM DUAL;

COL cursors FOR 9999999;
COL spb FOR 999;
COL sql_id NEW_V sql_id FOR A13;
COL sql_text_100 FOR A100;
COL pdb_name FOR A30;
COL plns FOR 9999;

SPO fs_&&current_time..txt;
PRO HOST: &&x_host_name.
PRO DATABASE: &&x_db_name.
PRO CONTAINER: &&x_container.
PRO SQL_TEXT_PIECE: &&sql_text_piece.

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
HAVING SUM(s.executions) > 0 AND SUM(s.elapsed_time) > 0
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

SPO OFF;
SET LIN 80 PAGES 14 VER ON FEED ON ECHO ON;

