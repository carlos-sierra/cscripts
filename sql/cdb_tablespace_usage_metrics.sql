SET HEA ON LIN 500 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF;
SET RECSEP OFF;
--
CLEAR BREAK COMPUTE;
COL pdb_tablespace_name1 FOR A35 HEA 'PDB|TABLESPACE_NAME';
COL pdb_tablespace_name2 FOR A35 HEA 'PDB|TABLESPACE_NAME';
COL used_space_gbs1 FOR 999,990.000 HEA 'USED_SPACE|(GBs)';
COL used_space_gbs2 FOR 999,990.000 HEA 'USED_SPACE|(GBs)';
COL max_size_gbs1 FOR 999,990.000 HEA 'MAX_SIZE|(GBs)';
COL max_size_gbs2 FOR 999,990.000 HEA 'MAX_SIZE|(GBs)';
COL used_percent1 FOR 990.000 HEA 'USED|PERCENT';
COL used_percent2 FOR 990.000 HEA 'USED|PERCENT';
--
BREAK ON REPORT;
COMPUTE SUM LABEL 'TOTAL' OF used_space_gbs1 max_size_gbs1 used_space_gbs2 max_size_gbs2 ON REPORT; 
--
COL output_file_name NEW_V output_file_name NOPRI;
SELECT 'cdb_tablespace_usage_metrics_'||LOWER(name)||'_'||LOWER(REPLACE(SUBSTR(host_name, 1 + INSTR(host_name, '.', 1, 2), 30), '.', '_'))||'_'||TO_CHAR(SYSDATE, 'yyyymmdd"T"hh24miss') output_file_name FROM v$database, v$instance;
--
SPO &&output_file_name..txt;
PRO
PRO SQL> @cdb_tablespace_usage_metrics.sql
PRO
PRO &&output_file_name..txt;
PRO
WITH 
t AS (
SELECT c.name||'('||c.con_id||')' pdb,
       m.tablespace_name,
       ROUND(m.used_percent, 3) used_percent, -- as per maximum size (considering auto extend)
       ROUND(m.used_space * t.block_size / POWER(2, 30), 3) used_space_gbs,
       ROUND(m.tablespace_size * t.block_size / POWER(2, 30), 3) max_size_gbs,
       ROW_NUMBER() OVER (ORDER BY c.name, m.tablespace_name) row_number1,
       ROW_NUMBER() OVER (ORDER BY m.used_percent DESC, m.used_space * t.block_size DESC, m.tablespace_size * t.block_size DESC) row_number2
  FROM cdb_tablespace_usage_metrics m,
       cdb_tablespaces t,
       v$containers c
 WHERE t.con_id = m.con_id
   AND t.tablespace_name = m.tablespace_name
   AND t.status = 'ONLINE'
   AND t.contents = 'PERMANENT'
   AND t.tablespace_name NOT IN ('SYSTEM', 'SYSAUX')
   AND c.con_id = m.con_id
   AND c.open_mode = 'READ WRITE'
)
SELECT t1.pdb||CHR(10)||'   '||
       t1.tablespace_name pdb_tablespace_name1,
       t1.used_percent used_percent1,
       t1.used_space_gbs used_space_gbs1,
       t1.max_size_gbs max_size_gbs1,
       '|'||CHR(10)||'|' "|",
       t2.used_percent used_percent2,
       t2.used_space_gbs used_space_gbs2,
       t2.max_size_gbs max_size_gbs2,
       t2.pdb||CHR(10)||'   '||
       t2.tablespace_name pdb_tablespace_name2
  FROM t t1, t t2
 WHERE t1.row_number1 = t2.row_number2
 ORDER BY
       t1.row_number1
/
PRO
PRO &&output_file_name..txt;
PRO
SPO OFF;
--
CLEAR BREAK COMPUTE;
