SET HEA ON LIN 2490 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF LONG 240000 LONGC 2400 NUM 20 SERVEROUT OFF;
PRO
PRO 1. Enter Table Name:
DEF table_name = '&1.';
UNDEF 1;
--
COL schema_name NEW_V schema_name NOPRI;
SELECT owner AS schema_name FROM dba_tables WHERE table_name = '&&table_name.';
--
VAR v_used_bytes NUMBER;
VAR v_alloc_bytes NUMBER;
DECLARE
  l_rec dba_tables%ROWTYPE;
BEGIN
  SELECT * INTO l_rec FROM dba_tables WHERE owner = '&&schema_name.' AND table_name = '&&table_name.';
  --
  IF l_rec.tablespace_name IS NULL THEN
    SELECT MAX(tablespace_name)
      INTO l_rec.tablespace_name
      FROM dba_segments
     WHERE owner = '&&schema_name.'
       AND segment_name = '&&table_name.'
       AND segment_type LIKE 'TABLE%';
  END IF;
  --
  DBMS_SPACE.create_table_cost (
    tablespace_name => l_rec.tablespace_name,
    avg_row_size    => l_rec.avg_row_len,
    row_count       => l_rec.num_rows,
    pct_free        => l_rec.pct_free,
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
EXECUTE IMMEDIATE('EXPLAIN PLAN FOR CREATE TABLE &&schema_name..&&table_name._ AS SELECT * FROM &&schema_name..&&table_name.');
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
