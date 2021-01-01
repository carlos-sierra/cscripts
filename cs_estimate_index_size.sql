----------------------------------------------------------------------------------------
--
-- File name:   cs_estimate_index_size.sql
--
-- Purpose:     Estimate Index Size
--
-- Author:      Carlos Sierra
--
-- Version:     2020/12/06
--
-- Usage:       Execute connected to PDB.
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @cs_estimate_index_size.sql
--
-- Notes:       Developed and tested on 12.1.0.2.
--
---------------------------------------------------------------------------------------
--
SET HEA ON LIN 2490 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF LONG 240000 LONGC 2400 NUM 20 SERVEROUT OFF;
PRO
PRO 1. Enter Index Name:
DEF index_name = '&1.';
UNDEF 1;
--
COL schema_name NEW_V schema_name NOPRI;
SELECT owner AS schema_name FROM dba_indexes WHERE index_name = '&&index_name.';
--
VAR v_used_bytes NUMBER;
VAR v_alloc_bytes NUMBER;
BEGIN
  DBMS_SPACE.create_index_cost (
    ddl             => DBMS_METADATA.get_ddl('INDEX', '&&index_name.', '&&schema_name.'),
    used_bytes      => :v_used_bytes,
    alloc_bytes     => :v_alloc_bytes
  );
END;
/
COL used_gb FOR 999,990.000;
COL alloc_gb FOR 999,990.000;
SELECT :v_used_bytes/1e9 AS used_gb, :v_alloc_bytes/1e9 AS alloc_gb FROM DUAL;
--
ROLLBACK;
DELETE plan_table;
BEGIN
EXECUTE IMMEDIATE('EXPLAIN PLAN FOR '||DBMS_METADATA.get_ddl('INDEX', '&&index_name.', '&&schema_name.'));
END;
/
COMMIT;
SET HEA ON PAGES 0;
PRO
SELECT plan_table_output FROM 
TABLE(DBMS_XPLAN.DISPLAY('PLAN_TABLE', NULL, 'ADVANCED'))
/
SET HEA ON PAGES 100;
CLEAR COLUMNS;
