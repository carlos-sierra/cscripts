SET TERM ON HEA ON LIN 2490 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF LONG 240000 LONGC 2400 NUM 20 SERVEROUT OFF;
SET PAGES 1000;
--
COL pdb_name FOR A30;
COL tables FOR 9,999,999;
COL indexes FOR 9,999,999;
COL matching_index FOR 9,999,999 HEA 'COMPLIANT|MATCHING|INDEX';
COL snapshot_index FOR 9,999,999 HEA 'COMPLIANT|SNAPSHOT|INDEX';
COL fat_index FOR 9,999,999 HEA 'FAT|INDEX';
COL redundant_index FOR 9,999,999 HEA 'REDUNDANT|INDEX';
COL partitioned FOR 9,999,999 HEA 'PARTITIONED';
COL deprecate_index FOR 9,999,999 HEA 'DEPRECATE|INDEX';
COL rename_index FOR 9,999,999 HEA 'RENAME|INDEX';
COL mising_index FOR 9,999,999 HEA 'MISING|INDEX';
COL extra_index FOR 9,999,999 HEA 'EXTRA|INDEX';
COL mising_columns FOR 9,999,999 HEA 'INDEX|MISING|COLUMN';
COL extra_columns FOR 9,999,999 HEA 'INDEX|WITH EXTRA|COLUMN';
COL misaligned_columns FOR 9,999,999 HEA 'INDEX|WITH MISALIGNED|COLUMN';
--
-- BREAK ON REPORT;
-- COMPUTE SUM OF tables indexes fat_index deprecate_index rename_index matching_index redundant_index partitioned snapshot_index mising_index extra_index mising_columns extra_columns misaligned_columns ON REPORT;
--
DEF cs_con_id = 1;
DEF cs_con_name = 'CDB$ROOT';
DEF cs_tools_schema = 'C##IOD';
-- 
WITH 
by_index AS (
SELECT DISTINCT
       con_id,
       UPPER(pdb_name) AS pdb_name,
       UPPER(owner) AS owner,
       UPPER(table_name) AS table_name,
       UPPER(index_name) AS index_name,
       validation,
       fat_index
  FROM &&cs_tools_schema..kiev_ind_columns_v
 WHERE 1 = 1
   AND fat_index IN ('NO', 'LITTLE')
   AND NVL(partitioned, 'NO') = 'NO'
   AND NOT (pdb_name LIKE 'KAASCANARY%' AND table_name IN ('canary_complexBucket', 'canary_simpleBucket'))
)
SELECT 
    --    pdb_name,
       '|' AS "|",
       COUNT(DISTINCT owner||'.'||table_name) AS tables,
       COUNT(DISTINCT owner||'.'||table_name||'.'||index_name) AS indexes,
       '|' AS "|",
       SUM(CASE validation WHEN 'MATCHING INDEX' THEN 1 ELSE 0 END) AS matching_index,
       SUM(CASE validation WHEN 'SNAPSHOT INDEX' THEN 1 ELSE 0 END) AS snapshot_index,
       SUM(CASE validation WHEN 'REDUNDANT INDEX' THEN 1 ELSE 0 END) AS redundant_index,
       SUM(CASE validation WHEN 'PARTITIONED' THEN 1 ELSE 0 END) AS partitioned,
       '|' AS "|",
       SUM(CASE WHEN fat_index IN ('SUPER', 'LITTLE') THEN 1 ELSE 0 END) AS fat_index,
       '|' AS "|",
       SUM(CASE validation WHEN 'DEPRECATE INDEX' THEN 1 ELSE 0 END) AS deprecate_index,
       SUM(CASE validation WHEN 'RENAME INDEX' THEN 1 ELSE 0 END) AS rename_index,
       SUM(CASE validation WHEN 'MISING INDEX' THEN 1 ELSE 0 END) AS mising_index,
       SUM(CASE validation WHEN 'EXTRA INDEX' THEN 1 ELSE 0 END) AS extra_index,
       SUM(CASE validation WHEN 'MISING COLUMN(S)' THEN 1 ELSE 0 END) AS mising_columns,
       SUM(CASE validation WHEN 'EXTRA COLUMN(S)' THEN 1 ELSE 0 END) AS extra_columns,
       SUM(CASE validation WHEN 'MISALIGNED COLUMN(S)' THEN 1 ELSE 0 END) AS misaligned_columns
  FROM by_index
 WHERE &&cs_con_id. IN (1, con_id)
   AND '&&cs_con_name.' IN ('CDB$ROOT', pdb_name)
   AND validation = 'MISING INDEX'
   HAVING COUNT(DISTINCT owner||'.'||table_name) > 0
--  GROUP BY
--        pdb_name
--  ORDER BY
--        pdb_name
/
--
-- CLEAR BREAK COMPUTE;
--
SET PAGES 100;