SET HEA ON LIN 500 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF;

COL dbid NEW_V dbid;
COL db_name NEW_V db_name;
SELECT dbid, LOWER(name) db_name FROM v$database
/

COL instance_number NEW_V instance_number;
COL host_name NEW_V host_name;
SELECT instance_number, LOWER(host_name) host_name FROM v$instance
/

COL con_name NEW_V con_name;
SELECT 'NONE' con_name FROM DUAL;
SELECT LOWER(SYS_CONTEXT('USERENV', 'CON_NAME')) con_name FROM DUAL
/

COL locale NEW_V locale;
SELECT LOWER(REPLACE(SUBSTR('&&host_name.', 1 + INSTR('&&host_name.', '.', 1, 2), 30), '.', '_')) locale FROM DUAL
/

HOS rm autotask_windows_*.txt;

COL zip_file_name NEW_V zip_file_name;
SELECT 'autotask_windows_&&locale._&&db_name._'||REPLACE('&&con_name.','$')||'_'||TO_CHAR(SYSDATE, 'YYYYMMDD"T"HH24MMSS') zip_file_name FROM DUAL
/

SPO autotask_windows_dynamic.sql

SELECT 'ALTER SESSION SET container = '||pdb_name||';'||CHR(10)||
       '@@autotask_windows.sql'||CHR(10)||
       'HOS zip -m &&zip_file_name..zip autotask_windows_*.txt'
  FROM cdb_pdbs
 ORDER BY 
       pdb_name
/

SPO OFF;

@autotask_windows_dynamic.sql
HOS rm autotask_windows_dynamic.sql

ALTER SESSION SET container = CDB$ROOT;

HOS unzip -l &&zip_file_name..zip

