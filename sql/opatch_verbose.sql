SET HEA ON LIN 5000 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF;
SET LONG 80000;
COL bundle_data FOR A200;
COL patch_descriptor FOR A200;
COL comp_id FOR A8;
COL comp_name FOR A35;
COL version FOR A10;
COL schema FOR A30;
COL status FOR A10;
COL control FOR A8;
COL other_schemas FOR A80;
COL modified FOR A20;
COL namespace FOR A10;
COL action_time FOR A30;
COL description FOR A80;
COL bundle_series FOR A14;
COL logfile NOPRI;
COL patch_directory NOPRI;
--COL patch_descriptor NOPRI;
--COL bundle_data NOPRI;
COL comments FOR A80;
SPO opatch_verbose.txt;
PRO
PRO dba_registry
PRO ~~~~~~~~~~~~
SELECT * FROM dba_registry;
PRO
PRO dba_registry_sqlpatch
PRO ~~~~~~~~~~~~~~~~~~~~~
SELECT * FROM dba_registry_sqlpatch;
PRO
PRO dba_registry_history
PRO ~~~~~~~~~~~~~~~~~~~~
SELECT * FROM dba_registry_history;
SPO OFF;