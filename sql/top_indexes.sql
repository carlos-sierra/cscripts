SET ECHO OFF FEED OFF VER OFF TAB OFF LINES 300 PAGES 28;

COL current_time NEW_V current_time FOR A15;
SELECT 'current_time: ' x, TO_CHAR(SYSDATE, 'YYYYMMDD_HH24MISS') current_time FROM DUAL;
COL x_host_name NEW_V x_host_name;
SELECT host_name x_host_name FROM v$instance;
COL x_db_name NEW_V x_db_name;
SELECT name x_db_name FROM v$database;
COL x_container NEW_V x_container;
SELECT 'NONE' x_container FROM DUAL;
SELECT SYS_CONTEXT('USERENV', 'CON_NAME') x_container FROM DUAL;

COL pdb_name FOR A30;
COL owner FOR A30;
COL index_name FOR A30;
COL table_owner FOR A30;
COL table_name FOR A30;

SPO top_indexes_&&current_time..txt;
PRO HOST: &&x_host_name.
PRO DATABASE: &&x_db_name.
PRO CONTAINER: &&x_container.

WITH 
indexes AS (
SELECT s.con_id,
       s.owner,
       s.index_name,
       s.table_owner,
       s.table_name,
       SUM(s.leaf_blocks) leaf_blocks,
       RANK() OVER (ORDER BY SUM(s.leaf_blocks) DESC NULLS LAST) rank
  FROM cdb_ind_statistics s,
       cdb_users u
 WHERE s.con_id > 2
   AND u.username = s.owner
   AND u.con_id = s.con_id
   AND u.oracle_maintained = 'N'
 GROUP BY
       s.con_id,
       s.owner,
       s.index_name,
       s.table_owner,
       s.table_name
)
SELECT i.rank,
       ROUND(i.leaf_blocks * TO_NUMBER(p.value) / POWER(2,20), 0) mb,
       pdb.name pdb_name,
       i.owner,
       i.index_name,
       i.table_owner,
       i.table_name
  FROM indexes i,
       v$parameter p,
       v$pdbs pdb
 WHERE (i.rank < 26 OR (i.leaf_blocks * TO_NUMBER(p.value) / POWER(2,20)) > 100 /* MB */ )
   AND p.name = 'db_block_size'
   AND pdb.con_id = i.con_id
 ORDER BY
       i.rank,
       pdb.name,
       i.owner,
       i.index_name
/

SPO OFF;
