SET TERM ON HEA ON LIN 2490 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF LONG 240000 LONGC 2400 NUM 20 SERVEROUT OFF;
ALTER SESSION SET NLS_DATE_FORMAT = 'YYYY-MM-DD"T"HH24:MI:SS';
--
COL pdb_name FOR A30 TRUNC;
COL utilization_limit FOR 999 HEA 'LIMIT';
COL aas_pct FOR 999 HEA 'DEMAND';
COL snap_time FOR A19;
COL reference FOR A64 HEA 'TICKET';
COL begin_date FOR A19;
COL end_date FOR A19;
--
WITH
hist AS (
SELECT h.pdb_name, h.utilization_limit, h.aas_pct, h.snap_time, h.reference, ROW_NUMBER() OVER (PARTITION BY h.pdb_name ORDER BY h.snap_time DESC NULLS LAST) AS rn
  FROM C##IOD.rsrc_mgr_pdb_hist h
 WHERE h.pdb_name <> 'CDB$ROOT'
   AND h.pdb_name LIKE '%COMPUTE%'
   AND h.snap_time IS NOT NULL
   AND h.aas_pct > 0
   AND h.utilization_limit > 0
)
SELECT h.pdb_name, h.utilization_limit, h.aas_pct, h.snap_time, COALESCE(h.reference, c.reference) AS reference, c.begin_date, c.end_date
  FROM hist h, C##IOD.rsrc_mgr_pdb_config c
 WHERE h.rn = 1
   --AND h.aas_pct > h.utilization_limit
   AND h.aas_pct > 24 -- demand
   AND h.utilization_limit < 96 -- limit
   AND h.snap_time > SYSDATE - 7
   AND c.pdb_name(+) = h.pdb_name
 ORDER BY
       h.pdb_name
/
