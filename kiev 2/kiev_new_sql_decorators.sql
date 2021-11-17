REM kiev_new_sql_decorators.sql - Find new SQL Decorators not yet in IOD_SPM.application_category
SET HEA ON LIN 2490 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF LONG 240000 LONGC 2400 NUM 20 SERVEROUT OFF;
ALTER SESSION SET "_px_cdb_view_enabled" = FALSE;
COL decoration FOR A100;
WITH
kiev_buckets AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       DISTINCT con_id
  FROM cdb_tables
 WHERE table_name = 'KIEVDATASTOREMETADATA'
   AND con_id > 2
 GROUP BY
       con_id
),
decorations AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       DISTINCT con_id, SUBSTR(sql_text, 1, INSTR(sql_text, '*/') + 1) AS decoration
  FROM v$sql
 WHERE sql_id IS NOT NULL
   AND parsing_user_id > 0
   AND parsing_schema_id > 0
   AND sql_text LIKE '/*%*/%'
),
application AS (
SELECT C##IOD.IOD_SPM.application_category(d.decoration) AS appl,
       CASE 
         WHEN INSTR(d.decoration, ')') > INSTR(d.decoration, '(') + 1 THEN SUBSTR(d.decoration, 1, INSTR(d.decoration, '('))||SUBSTR(d.decoration, INSTR(d.decoration, ')'))
         ELSE d.decoration
       END AS decoration
  FROM decorations d, kiev_buckets k
 WHERE d.con_id = k.con_id
)
SELECT DISTINCT decoration
  FROM application
 WHERE appl = 'UN'
 ORDER BY
       decoration
/
