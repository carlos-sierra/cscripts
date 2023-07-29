----------------------------------------------------------------------------------------
--
-- File name:   cs_top_bloated_indexes.sql
--
-- Purpose:     Top bloated indexes on a PDB (text report)
--
-- Author:      Carlos Sierra
--
-- Version:     2020/12/09
--
-- Usage:       Execute connected to PDB
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @cs_top_bloated_indexes.sql
--
-- Notes:       Developed and tested on 12.1.0.2.
--
---------------------------------------------------------------------------------------
--
SET HEA ON LIN 2490 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF LONG 240000 LONGC 2400 NUM 20 SERVEROUT OFF;
SET SERVEROUT ON;
DEF top_n = '20';
DEF debug = 'N';
--
COL owner FOR A30;
COL table_name FOR A30;
COL index_name FOR A30;
COL partitioned FOR A4 HEA 'PART';
COL current_gb FOR 9,990.000 HEA 'CURRENT|GB';
COL estimated_gb FOR 9,990.000 HEA 'ESTIMATED|GB';
COL wasted_gb FOR 9,990.000 HEA 'WASTED|GB';
COL wated_perc FOR 990.0 HEA 'WASTED|PERC%';
COL estimated_bytes_function FOR 999 HEA 'FUNC';
--
BREAK ON REPORT;
COMPUTE SUM LABEL "TOTAL" OF current_gb estimated_gb wasted_gb ON REPORT;
--
WITH
FUNCTION get_estimated_index_size1 (p_owner IN VARCHAR2, p_index_name IN VARCHAR2, p_current_bytes IN NUMBER)
RETURN NUMBER
IS
  l_used_bytes NUMBER;
  l_alloc_bytes NUMBER;
BEGIN
  DBMS_SPACE.create_index_cost (
    ddl             => DBMS_METADATA.get_ddl('INDEX', p_index_name, p_owner),
    used_bytes      => l_used_bytes,
    alloc_bytes     => l_alloc_bytes
  );
  IF '&&debug.' = 'Y' THEN
    DBMS_OUTPUT.put_line(CHR(10)||'1 '||p_owner||'.'||p_index_name||' '||p_current_bytes||' '||l_alloc_bytes);
  END IF;
  RETURN l_alloc_bytes;
EXCEPTION
  WHEN OTHERS THEN
    IF '&&debug.' = 'Y' THEN
      DBMS_OUTPUT.put_line(CHR(10)||p_owner||'.'||p_index_name);
      DBMS_OUTPUT.put_line(SQLERRM);
    END IF;
    RETURN -1;
END get_estimated_index_size1;
/****************************************************************************************/
FUNCTION get_estimated_index_size2 (p_owner IN VARCHAR2, p_index_name IN VARCHAR2, p_current_bytes IN NUMBER)
RETURN NUMBER
IS
  l_alloc_bytes NUMBER;
BEGIN
  SELECT ROUND(
           ( -- https://stackoverflow.com/questions/827123/how-can-i-estimate-the-size-of-an-oracle-index
             SUM((t.num_rows - tc.num_nulls) * (tc.avg_col_len + 1)) + -- data payload
             i.num_rows * 18 + -- rowid
             i.num_rows * 2 -- index row header
           ) * 1.125 -- for pctfree of 10 and an overhead factor
         )
    INTO l_alloc_bytes
    FROM dba_ind_columns ic,
         dba_tab_columns tc,
         dba_tables t,
         dba_indexes i
   WHERE ic.index_owner = p_owner
     AND ic.index_name = p_index_name
     AND tc.owner = ic.table_owner
     AND tc.table_name = ic.table_name
     AND tc.column_name = ic.column_name
     AND t.owner = ic.table_owner
     AND t.table_name = ic.table_name
     AND i.owner = ic.index_owner
     AND i.index_name = ic.index_name
   GROUP BY
         t.num_rows,
         i.num_rows;
  IF '&&debug.' = 'Y' THEN
    DBMS_OUTPUT.put_line(CHR(10)||'2 '||p_owner||'.'||p_index_name||' '||p_current_bytes||' '||l_alloc_bytes);
  END IF;
  RETURN l_alloc_bytes;
EXCEPTION
  WHEN OTHERS THEN
    IF '&&debug.' = 'Y' THEN
      DBMS_OUTPUT.put_line(CHR(10)||p_owner||'.'||p_index_name);
      DBMS_OUTPUT.put_line(SQLERRM);
    END IF;
    RETURN -1;
END get_estimated_index_size2;
/****************************************************************************************/
all_application_indexes AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       i.owner, i.table_name, i.index_name, i.partitioned,
       SUM(bytes) AS current_bytes
  FROM dba_segments s,
       dba_users u,
       dba_indexes i
 WHERE s.segment_type LIKE 'INDEX%'
   AND s.segment_name NOT LIKE 'SYS_IL%'
   AND u.username = s.owner
   AND u.oracle_maintained = 'N'
   AND i.owner = s.owner
   AND i.index_name = s.segment_name
 GROUP BY
       i.owner, i.table_name, i.index_name, i.partitioned
),
all_application_indexes_trans1 AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       owner, table_name, index_name, partitioned,
       current_bytes,
       get_estimated_index_size1(owner, index_name, current_bytes) AS estimated_bytes1,
       get_estimated_index_size2(owner, index_name, current_bytes) AS estimated_bytes2
  FROM all_application_indexes
),
all_application_indexes_trans2 AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       owner, table_name, index_name, partitioned,
       current_bytes,
       CASE estimated_bytes1 WHEN -1 THEN (CASE estimated_bytes2 WHEN -1 THEN NULL ELSE estimated_bytes2 END) ELSE estimated_bytes1 END AS estimated_bytes,
       CASE estimated_bytes1 WHEN -1 THEN (CASE estimated_bytes2 WHEN -1 THEN -1 ELSE 2 END) ELSE 1 END AS estimated_bytes_function
  FROM all_application_indexes_trans1
),
all_bloated_appl_indexes AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       owner, table_name, index_name, partitioned,
       current_bytes, estimated_bytes, 
       current_bytes - estimated_bytes AS wasted_bytes,
       estimated_bytes_function,
       ROW_NUMBER() OVER (ORDER BY current_bytes - estimated_bytes DESC) AS rn
  FROM all_application_indexes_trans2
 WHERE current_bytes > estimated_bytes
)
SELECT owner, table_name, index_name, partitioned,
       ROUND(current_bytes / POWER(10,9), 3) AS current_gb,
       ROUND(estimated_bytes / POWER(10,9), 3) AS estimated_gb,
       ROUND(wasted_bytes / POWER(10,9), 3) AS wasted_gb,
       ROUND(100 * wasted_bytes / current_bytes, 1) AS wated_perc,
       estimated_bytes_function
  FROM all_bloated_appl_indexes
 WHERE rn <= &&top_n.
 ORDER BY
       rn
/
--
SET SERVEROUT OFF;