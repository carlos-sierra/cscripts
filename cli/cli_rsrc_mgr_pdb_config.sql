SET TERM ON HEA ON LIN 2490 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF
ALTER SESSION SET NLS_DATE_FORMAT = 'YYYY-MM-DD"T"HH24:MI:SS';
COL pdb_name FOR A30;
COL end_date FOR A19;
COL utilization_limit FOR 999 HEA 'UTIL';
COL reference FOR A30;
SELECT pdb_name, utilization_limit, end_date, reference
  FROM c##iod.rsrc_mgr_pdb_config
 ORDER BY pdb_name
/
