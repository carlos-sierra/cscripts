-- pdb_spfile.sql - PDB SPFILE Parameters (from CDB)
SET HEA ON LIN 2490 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF LONG 240000 LONGC 2400 SERVEROUT OFF;
--
COL pdb_name FOR A30 TRUNC;
COL parameter FOR A40;
COL value$ FOR A30 HEA 'sys.pdb_spfile$';
COL value FOR A30 HEA 'v$system_parameter';
--
BREAK ON pdb_name SKIP PAGE DUPL ON parameter SKIP 1 DUPL;
--
SELECT c.name pdb_name,
       p.name parameter,
       p.db_uniq_name,
       p.value$,
       s.value
  FROM sys.pdb_spfile$ p,
       v$containers c,
       v$system_parameter s
 WHERE p.pdb_uid > 1
   AND c.con_uid = p.pdb_uid
   AND s.con_id = c.con_id
   AND s.name = p.name
   AND s.value <> p.value$
 ORDER BY
       c.name,
       p.name,
       p.db_uniq_name
/
