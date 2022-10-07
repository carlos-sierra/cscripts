SET TERM ON HEA ON LIN 2490 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF LONG 240000 LONGC 2400 NUM 20 SERVEROUT OFF;
SET HEA OFF PAGES 0;
ALTER SESSION SET NLS_DATE_FORMAT = 'YYYY-MM-DD"T"HH24:MI:SS';
ALTER SESSION SET NLS_TIMESTAMP_FORMAT = 'YYYY-MM-DD"T"HH24:MI:SS.FF3';
--
COL ddl_statement FOR A300;
--
WITH cons AS (
   SELECT c.owner
        , c.table_name
        , c.constraint_name
        , c.r_owner
        , MAX ( CASE cc.position WHEN 1 THEN cc.column_name END ) AS cname1
        , MAX ( CASE cc.position WHEN 2 THEN cc.column_name END ) AS cname2
        , MAX ( CASE cc.position WHEN 3 THEN cc.column_name END ) AS cname3
        , MAX ( CASE cc.position WHEN 4 THEN cc.column_name END ) AS cname4
        , MAX ( CASE cc.position WHEN 5 THEN cc.column_name END ) AS cname5
        , MAX ( CASE cc.position WHEN 6 THEN cc.column_name END ) AS cname6
        , MAX ( CASE cc.position WHEN 7 THEN cc.column_name END ) AS cname7
        , MAX ( CASE cc.position WHEN 8 THEN cc.column_name END ) AS cname8
        , COUNT(*) AS col_cnt
     FROM dba_constraints c
     JOIN dba_cons_columns cc ON cc.constraint_name = c.constraint_name AND cc.owner = c.owner
    WHERE c.constraint_type = 'R'
      AND cc.owner IN (SELECT username FROM dba_users WHERE oracle_maintained = 'N' AND common = 'NO')
    GROUP BY c.table_name , c.constraint_name , c.owner , c.r_owner
) , inds AS (
   SELECT cons.owner
        , cons.table_name
        , cons.constraint_name
        , cons.r_owner
        , /*LOWER*/ ( cons.cname1 || NVL2 ( cons.cname2 , ',' || cons.cname2 , NULL )
             || NVL2 ( cons.cname3 , ',' || cons.cname3 , NULL ) || NVL2 ( cname4 , ',' || cname4 , NULL )
             || NVL2 ( cons.cname5 , ',' || cons.cname5 , NULL ) || NVL2 ( cname6 , ',' || cname6 , NULL )
             || NVL2 ( cons.cname7 , ',' || cons.cname7 , NULL ) || NVL2 ( cname8 , ',' || cname8 , NULL )
             ) AS column_list
     FROM cons
    WHERE cons.col_cnt > ALL (
         SELECT COUNT(*)
           FROM dba_ind_columns ic
          WHERE ic.table_name = cons.table_name
            AND ic.table_owner = cons.owner
            AND ic.column_name IN ( cons.cname1 , cons.cname2 , cons.cname3 , cons.cname4 , cons.cname5 , cons.cname6 , cons.cname7 , cons.cname8 )
            AND ic.column_position <= cons.col_cnt
          GROUP BY ic.index_name
         )
)
SELECT 
    --     inds.owner 
    --  ,  inds.table_name 
    --  , t.num_rows
    --  , t.blocks * 8/1024/1024 AS gb
    --  ,  inds.r_owner 
     '/* tblocks='||t.blocks||' trows='||t.num_rows||' */ CREATE INDEX ' ||  inds.owner  || '.' ||  inds.constraint_name  || ' ON ' ||  inds.owner  || '.' ||  inds.table_name   || '(' || inds.column_list ||') ONLINE;' AS ddl_statement
  FROM inds
  JOIN dba_tables t ON t.table_name = inds.table_name AND t.owner = inds.owner
 WHERE t.blocks > 5 AND NOT t.table_name LIKE 'KIEV%'
 ORDER BY t.blocks DESC, inds.owner ,  inds.table_name , inds.constraint_name
/
--
SET HEA ON PAGES 100;