SET TERM ON HEA ON LIN 2490 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF LONG 240000 LONGC 2400 NUM 20 SERVEROUT OFF;
--
COL comments FOR A100;
COL pluggable_database FOR A30;
COL shares FOR 999990;
COL utilization_limit FOR 9,990 HEA 'CPU%'
--
--BREAK ON REPORT;
--COMPUTE SUM LABEL 'TOTAL' OF utilization_limit ON REPORT;
--
SELECT utilization_limit,
       shares, 
       pluggable_database, 
       comments
  FROM dba_cdb_rsrc_plan_directives
 WHERE plan = 'IOD_CDB_PLAN'
   AND mandatory = 'NO'
   AND directive_type = 'PDB'
   AND utilization_limit > 8
   AND (pluggable_database LIKE '%DEV%' OR pluggable_database LIKE '%TEST%')
  --  AND NVL(comments, '-666') NOT LIKE '%NEW%'
 ORDER BY 
       pluggable_database
/
