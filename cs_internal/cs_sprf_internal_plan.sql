PRO
PRO SQL PROFILE - DISPLAY (dbms_xplan.display_sql_profile_plan)
PRO ~~~~~~~~~~~~~~~~~~~~~
-- only works from PDB.
SET HEA OFF PAGES 0;
SELECT * FROM TABLE(DBMS_XPLAN.display_sql_profile_plan((SELECT name FROM dba_sql_profiles WHERE signature = :cs_signature AND category = 'DEFAULT' AND ROWNUM = 1), 'ADVANCED'));
SET HEA ON PAGES 100;
