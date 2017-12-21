-- IOD_CS_BROWSE_FLEET
WHENEVER SQLERROR EXIT SUCCESS;
PRO
PRO An error "ORA-01476: divisor is equal to zero" just means v$database.open_mode is not "READ WRITE"
SELECT CASE open_mode WHEN 'READ WRITE' THEN open_mode ELSE TO_CHAR(1/0) END open_mode FROM v$database;
--WHENEVER SQLERROR EXIT FAILURE;

SET HEA ON LIN 500 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF;

COL current_time NEW_V current_time FOR A15;
SELECT 'current_time: ' x, TO_CHAR(SYSDATE, 'YYYY-MM-DD"T"HH24:MI:SS') current_time FROM DUAL;
COL x_host_name NEW_V x_host_name;
SELECT host_name x_host_name FROM v$instance;
COL x_db_name NEW_V x_db_name;
SELECT name x_db_name FROM v$database;
COL x_container NEW_V x_container;
SELECT 'NONE' x_container FROM DUAL;
SELECT SYS_CONTEXT('USERENV', 'CON_NAME') x_container FROM DUAL;

PRO HOST: &&x_host_name.
PRO DATABASE: &&x_db_name.
PRO CONTAINER: &&x_container.
PRO DATE: &&current_time.

PRO
PRO Top 10 consumers of Sharable Memory
PRO ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
COL sql_text FOR A100
SELECT * FROM (
SELECT ROUND(SUM(sharable_mem)/POWER(2,20)) sharable_mem_mb,
       con_id,
       sql_id,
       COUNT(*) cursors,
       sql_text
  FROM v$sql
 GROUP BY
       con_id,
       sql_id,
       sql_text
HAVING SUM(sharable_mem)/POWER(2,20) > 10
 ORDER BY 1 DESC
) 
WHERE ROWNUM < 11
/

PRO
PRO Kept pinned SQL
PRO ~~~~~~~~~~~~~~~
SELECT sql_id, sql_text
  FROM v$sql
 WHERE kept_versions > 0
/

PRO
PRO Owners of Table QueuedRawEvents
PRO ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
COL owner FOR A30
COL table_name FOR A30
SELECT con_id, owner, table_name, num_rows, blocks, last_analyzed
  FROM cdb_tables
 WHERE table_name IN ('QUEUEDRAWEVENTS', 'LEASES')
/

PRO
PRO PDBs
PRO ~~~~
SHO pdbs;

