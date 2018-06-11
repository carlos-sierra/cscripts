--
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
--
SET HEA ON LIN 500 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF;
SET FEED ON;
CL COL BRE
--
ALTER SESSION SET container = CDB$ROOT;
--
COL con_id_by_name FOR 999999 HEA 'CON_ID';
COL con_id_ordered FOR 999999 HEA 'CON_ID';
COL by_name FOR A30 HEA 'PDB_NAME';
COL name_by_con_id FOR A30 HEA 'PDB_NAME';
--
WITH 
pdbs AS (
SELECT name, con_id, 
ROW_NUMBER() OVER (ORDER BY con_id) rownum1,
ROW_NUMBER() OVER (ORDER BY name) rownum2
FROM v$containers WHERE open_mode = 'READ WRITE'
)
SELECT p1.name by_name, p1.con_id con_id_by_name, '|' "|", p2.con_id con_id_ordered, p2.name name_by_con_id
FROM pdbs p1, pdbs p2
WHERE p1.rownum2 = p2.rownum1
ORDER BY p1.name
/
--
PRO 1. Enter PDB_NAME:
DEF pdb_name = '&1.';
--
ALTER SESSION SET container = &pdb_name.;
UNDEF 1;