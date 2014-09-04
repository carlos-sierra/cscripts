----------------------------------------------------------------------------------------
--
-- File name:   data_files_usage.sql
--
-- Purpose:     Reports Datafiles and Tablespaces usage
--
-- Author:      Carlos Sierra
--
-- Version:     2014/02/12
--
-- Usage:       This script reads DBA_DATA_FILES and DBA_FREE_SPACE
--
-- Example:     @data_files_usage.sql
--
--  Notes:      Developed and tested on 11.2.0.3 
--             
---------------------------------------------------------------------------------------
--
SPO data_files_usage.txt;
SET NEWP NONE PAGES 50 LINES 32767 TRIMS ON;

COL tablespace_name FOR A30;
COL datafiles FOR 999,999,999;
COL alloc_gb FOR 999,999;
COL used_gb FOR 999,999;
COL free_gb FOR 999,999;

DEF sq_fact_hints = 'MATERIALIZE';

WITH
alloc AS (
SELECT /*+ &&sq_fact_hints. */
       tablespace_name,
       COUNT(*) datafiles,
       ROUND(SUM(bytes)/1024/1024/1024) gb
  FROM dba_data_files
 GROUP BY
       tablespace_name
),
free AS (
SELECT /*+ &&sq_fact_hints. */
       tablespace_name,
       ROUND(SUM(bytes)/1024/1024/1024) gb
  FROM dba_free_space
 GROUP BY
       tablespace_name
),
tablespaces AS (
SELECT /*+ &&sq_fact_hints. */
       a.tablespace_name,
       a.datafiles,
       a.gb alloc_gb,
       (a.gb - f.gb) used_gb,
       f.gb free_gb
  FROM alloc a, free f
 WHERE a.tablespace_name = f.tablespace_name
 ORDER BY
       a.tablespace_name
),
total AS (
SELECT /*+ &&sq_fact_hints. */
       SUM(alloc_gb) alloc_gb,
       SUM(used_gb) used_gb,
       SUM(free_gb) free_gb
  FROM tablespaces
)
SELECT v.tablespace_name,
       v.datafiles,
       v.alloc_gb,
       v.used_gb,
       CASE WHEN v.alloc_gb > 0 THEN
       LPAD(TRIM(TO_CHAR(ROUND(100 * v.used_gb / v.alloc_gb, 1), '990.000')), 8)
       END pct_used,
       v.free_gb,
       CASE WHEN v.alloc_gb > 0 THEN
       LPAD(TRIM(TO_CHAR(ROUND(100 * v.free_gb / v.alloc_gb, 1), '990.000')), 8)
       END pct_free
  FROM (
SELECT tablespace_name,
       datafiles,
       alloc_gb,
       used_gb,
       free_gb
  FROM tablespaces
 UNION ALL
SELECT 'Total' tablespace_name,
       TO_NUMBER(NULL) datafiles,
       alloc_gb,
       used_gb,
       free_gb
  FROM total
) v
/

SET NEWP 1 PAGES 14 LINES 80 TRIMS OFF;
SPO OFF; 
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
