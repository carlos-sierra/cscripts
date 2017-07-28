----------------------------------------------------------------------------------------
--
-- File name:   indexes_2b_shrunk.sql
--
-- Purpose:     List of candidate indexes to be shrunk (rebuild online), if:
--              1. they are larger than a certain MB threshold; and
--              2. space savings is larger than a certain % threshold
--
-- Author:      Carlos Sierra
--
-- Version:     2017/07/20
--
-- Usage:       Execute on PDB
--
-- Example:     @indexes_2b_shrunk.sql
--
-- Notes:       Execute connected into a PDB.
--              Consider then:
--              ALTER INDEX [schema.]index REBUILD ONLINE;
--
---------------------------------------------------------------------------------------

-- select only those indexes with an estimated space saving percent greater than 25%
VAR savings_percent NUMBER;
EXEC :savings_percent := 25;
-- select only those indexes with current size (as per cbo stats) greater then 10MB
VAR minimum_size_mb NUMBER;
EXEC :minimum_size_mb := 10;

SET SERVEROUT ON ECHO OFF FEED OFF VER OFF TAB OFF LINES 300;

COL report_date NEW_V report_date;
SELECT TO_CHAR(SYSDATE, 'YYYY-MM-DD"T"HH24-MI-SS') report_date FROM DUAL;
SPO /tmp/indexes_2b_shrunk_&&report_date..txt;

DECLARE
  l_used_bytes  NUMBER;
  l_alloc_bytes NUMBER;
  l_percent     NUMBER;
BEGIN
  DBMS_OUTPUT.PUT_LINE('PDB: '||SYS_CONTEXT('USERENV', 'CON_NAME'));
  DBMS_OUTPUT.PUT_LINE('---');
  DBMS_OUTPUT.PUT_LINE(
    RPAD('TABLE_NAME', 30)||' '||
    RPAD('OWNER.INDEX_NAME', 35)||' '||
    LPAD('SAVING %', 10)||' '||
    LPAD('CURRENT SIZE', 20)||' '||
    LPAD('ESTIMATED SIZE', 20)||'  '||
    RPAD('COMMAND', 75));
  DBMS_OUTPUT.PUT_LINE(
    RPAD('-', 30, '-')||' '||
    RPAD('-', 35, '-')||' '||
    LPAD('-', 10, '-')||' '||
    LPAD('-', 20, '-')||' '||
    LPAD('-', 20, '-')||'  '||
    RPAD('-', 75, '-'));
  FOR i IN (SELECT x.table_name, x.owner, x.index_name, SUM(s.leaf_blocks) * TO_NUMBER(p.value) index_size,
                   REPLACE(DBMS_METADATA.GET_DDL('INDEX',x.index_name,x.owner),CHR(10),CHR(32)) ddl
              FROM dba_ind_statistics s, dba_indexes x, dba_users u, v$parameter p
             WHERE u.oracle_maintained = 'N'
               AND x.owner = u.username
               AND x.tablespace_name NOT IN ('SYSTEM','SYSAUX')
               AND x.index_type LIKE '%NORMAL%'
               AND x.table_type = 'TABLE'
               AND x.status = 'VALID'
               AND x.temporary = 'N'
               AND x.dropped = 'NO'
               AND x.visibility = 'VISIBLE'
               AND x.segment_created = 'YES'
               AND x.orphaned_entries = 'NO'
               AND p.name = 'db_block_size'
               AND s.owner = x.owner
               AND s.index_name = x.index_name
             GROUP BY
                   x.table_name, x.owner, x.index_name, p.value
             HAVING
                   SUM(s.leaf_blocks) * TO_NUMBER(p.value) > :minimum_size_mb * POWER(2,20)
             ORDER BY
                   index_size DESC)
  LOOP
    DBMS_SPACE.CREATE_INDEX_COST(i.ddl,l_used_bytes,l_alloc_bytes);
    IF i.index_size * (100 - :savings_percent) / 100 > l_alloc_bytes THEN 
      l_percent := 100 * (i.index_size - l_alloc_bytes) / i.index_size;
      DBMS_OUTPUT.PUT_LINE(
        RPAD(i.table_name, 30)||' '||
        RPAD(i.owner||'.'||i.index_name, 35)||' '||
        LPAD(TO_CHAR(ROUND(l_percent, 1), '990.0')||' % ', 10)||' '||
        LPAD(TO_CHAR(ROUND(i.index_size / POWER(2,20), 1), '999,999,990.0')||' MB', 20)||' '||
        LPAD(TO_CHAR(ROUND(l_alloc_bytes / POWER(2,20), 1), '999,999,990.0')||' MB', 20)||'  '||
        RPAD('ALTER INDEX '||LOWER(i.owner||'.'||i.index_name)||' REBUILD ONLINE;', 75));
    END IF;
  END LOOP;
END;
/

SPO OFF;