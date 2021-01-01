-- spfile.sql - SPFILE Parameters (from PDB or CDB)
SET HEA ON LIN 500 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF;
COL sid FOR A12;
COL name FOR A45;
COL type FOR A11;
COL ordinal FOR 999 HEA 'ORD';
COL value FOR A45;
COL display_value FOR A45;
COL pdbs FOR 9999;
COL min_con_id FOR 999999 HEA 'MIN|CON_ID';
COL max_con_id FOR 999999 HEA 'MAX|CON_ID';

SELECT sid,
       name,
       type,
       ordinal,
       value,
       display_value,
       COUNT(*) pdbs,
       MIN(con_id) min_con_id,
       MAX(con_id) max_con_id
  FROM v$spparameter
 WHERE isspecified = 'TRUE'
 GROUP BY
       sid,
       name,
       type,
       ordinal,
       value,
       display_value
 ORDER BY
       sid,
       name,
       type,
       ordinal,
       value,
       display_value
/

