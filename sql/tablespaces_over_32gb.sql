SET HEA ON LIN 500 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF;

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
COL used_space FOR 999,999,999 HEA 'USED_SPACE|(BLOCKS)';
COL tablespace_size FOR 999,999,999 HEA 'ALLOC_SIZE|(BLOCKS)';
COL used_percent FOR 990.0 HEA 'USED|PERCENT';
COL used_space_gb FOR 999,990.000 HEA 'USED_SPACE|(GBs)';
COL tablespace_size_gb FOR 999,990.000 HEA 'ALLOC_SIZE|(GBs)';

COMP SUM LAB 'TOTAL' OF used_space tablespace_size used_space_gb tablespace_size_gb ON pdb_name;

SPO tablespace_over_32g_&&current_time..txt;
PRO HOST: &&x_host_name.
PRO DATABASE: &&x_db_name.
PRO CONTAINER: &&x_container.

SELECT ROUND(m.tablespace_size * p.block_size / POWER(2,30), 3) tablespace_size_gb,
       ROUND(m.used_space * p.block_size / POWER(2,30), 3) used_space_gb,
       ROUND(m.used_percent, 1) used_percent,
       SUBSTR(c.pdb_name, 1, 30) pdb_name,
       m.tablespace_name,
       m.tablespace_size,
       m.used_space
  FROM cdb_tablespace_usage_metrics m,
       cdb_pdbs c,
       cdb_tablespaces p
 WHERE TRUNC(m.tablespace_size * p.block_size / POWER(2,30)) > 32
   AND c.con_id = m.con_id
   AND p.con_id = m.con_id
   AND p.tablespace_name = m.tablespace_name
 ORDER BY
       m.tablespace_size * p.block_size DESC,
       c.pdb_name,
       m.tablespace_name
/

SPO OFF;
CL BRE COMP;