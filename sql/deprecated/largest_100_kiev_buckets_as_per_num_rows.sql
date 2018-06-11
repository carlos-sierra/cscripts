-- exit graciously if executed on standby
WHENEVER SQLERROR EXIT SUCCESS;
DECLARE
  l_open_mode VARCHAR2(20);
BEGIN
  SELECT open_mode INTO l_open_mode FROM v$database;
  IF l_open_mode <> 'READ WRITE' THEN
    raise_application_error(-20000, 'Must execute on PRIMARY');
  END IF;
END;
/
WHENEVER SQLERROR CONTINUE;

-- safe to do. as name implies, it flushes this table modifications from sga so we can report on them
EXEC DBMS_STATS.FLUSH_DATABASE_MONITORING_INFO;

COL x_host_name NEW_V x_host_name;
SELECT host_name x_host_name FROM v$instance;
COL x_db_name NEW_V x_db_name;
SELECT name x_db_name FROM v$database;
COL x_container NEW_V x_container;
SELECT 'NONE' x_container FROM DUAL;
SELECT SYS_CONTEXT('USERENV', 'CON_NAME') x_container FROM DUAL;

COL output_file_name NEW_V output_file_name NOPRI;
SELECT 'largest_kiev_buckets_'||LOWER(name)||'_'||LOWER(REPLACE(SUBSTR(host_name, 1 + INSTR(host_name, '.', 1, 2), 30), '.', '_'))||'_'||REPLACE(LOWER(SYS_CONTEXT('USERENV','CON_NAME')),'$')||'_'||TO_CHAR(SYSDATE, 'YYYYMMDD_HH24MISS') output_file_name FROM v$database, v$instance;

SET HEA ON LIN 500 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF;
ALTER SESSION SET nls_date_format = 'YYYY-MM-DD"T"HH24:MI:SS';

COL row_number FOR 99 HEA '#';
COL num_rows FOR 99,999,999,990;
COL percent FOR 9,990.0 HEA 'PERCENT|PER_DAY';
COL growth_per_day FOR 999,999,990 HEA 'GROWTH|PER_DAY';
COL inserts_per_day FOR 999,999,990 HEA 'INSERTS|PER_DAY';
COL deletes_per_day FOR 999,999,990 HEA 'DELETES|PER_DAY';
COL updates_per_day FOR 999,999,990 HEA 'UPDATES|PER_DAY';
COL blocks FOR 999,999,990;
COL pdb_name FOR A30;
COL owner FOR A30;
COL table_name FOR A30;

CLEAR BREAK COMPUTE;
BREAK ON pdb_name SKIP PAGE ON REPORT;
COMPUTE SUM LABEL 'TOTAL' OF num_rows growth_per_day inserts_per_day deletes_per_day blocks ON pdb_name;
COMPUTE SUM LABEL ' GRAND TOTAL' OF num_rows growth_per_day inserts_per_day deletes_per_day blocks ON REPORT;

SPO &&output_file_name..txt
PRO
PRO SQL> @largest_100_kiev_buckets_as_per_num_rows.sql
PRO
PRO &&output_file_name..txt
PRO

PRO DATABASE: &&x_db_name.
PRO PDB: &&x_container.
PRO HOST: &&x_host_name.
PRO

WITH
u AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       con_id,
       username owner
  FROM cdb_users
 WHERE oracle_maintained = 'N'
),
t AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       con_id,
       owner,
       table_name,
       last_analyzed,
       num_rows,
       blocks
  FROM cdb_tables
 WHERE partitioned = 'NO'
   AND table_name NOT IN ('KIEVTRANSACTIONS','KIEVTRANSACTIONKEYS')
),
m AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       con_id,
       table_owner owner,
       table_name,
       timestamp,
       inserts,
       updates,
       deletes
  FROM cdb_tab_modifications
),
c AS (
SELECT con_id,
       name pdb_name
  FROM v$containers 
 WHERE open_mode = 'READ WRITE'
),
j AS (
SELECT t.num_rows,
       ROUND((m.inserts - m.deletes) / (m.timestamp - t.last_analyzed)) growth_per_day,
       ROUND(100 * (m.inserts - m.deletes) / (m.timestamp - t.last_analyzed) / t.num_rows, 1) percent,
       c.pdb_name,
       t.owner,
       t.table_name,
       ROUND(m.inserts / (m.timestamp - t.last_analyzed)) inserts_per_day,
       ROUND(m.deletes / (m.timestamp - t.last_analyzed)) deletes_per_day,
       ROUND(m.updates / (m.timestamp - t.last_analyzed)) updates_per_day,
       t.blocks,
       t.last_analyzed,
       m.timestamp,
       ROW_NUMBER() OVER (ORDER BY t.num_rows DESC NULLS LAST) row_number
  FROM u, t, c, m
 WHERE t.con_id = u.con_id 
   AND t.owner = u.owner
   AND c.con_id = t.con_id
   AND m.con_id(+) = t.con_id 
   AND m.owner(+) = t.owner
   AND m.table_name(+) = t.table_name
)
SELECT pdb_name,
       row_number,
       num_rows,
       growth_per_day,
       percent,
       owner,
       table_name,
       inserts_per_day,
       deletes_per_day,
       --updates_per_day,
       blocks,
       last_analyzed,
       timestamp
  FROM j
 WHERE row_number <= 100
 ORDER BY
       pdb_name,
       row_number
/

PRO
PRO &&output_file_name..txt
PRO
SPO OFF;
CLEAR BREAK COMPUTE;
