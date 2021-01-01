----------------------------------------------------------------------------------------
--
-- File name:   drop_redef_table_pdb.sql
--
-- Purpose:     Generate commands to drop stale objects from failed Table Redefinitions for PDB
--
-- Author:      Carlos Sierra
--
-- Version:     2020/12/06
--
-- Usage:       Execute connected to PDB
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @drop_redef_table_pdb.sql
--
-- Notes:       Developed and tested on 12.1.0.2.
--
--              Comands listed by this script must be executed manually inside corresponding PDB
--
---------------------------------------------------------------------------------------
--
SET HEA ON LIN 500 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF;
ALTER SESSION SET "_px_cdb_view_enabled" = FALSE;
--
COL drop_commands FOR A120;
--
WITH 
users AS (
SELECT /*+ MATERIALIZE NO_MERGE */ username FROM dba_users WHERE oracle_maintained = 'N'
)
SELECT 'DROP MATERIALIZED VIEW LOG ON "'||log_owner||'"."'||master||'";' drop_commands
  FROM dba_mview_logs
 WHERE log_table LIKE 'MLOG$\_'||CHR(37) ESCAPE '\'
   AND log_owner IN (SELECT u.username FROM users u)
 UNION ALL
SELECT 'DROP MATERIALIZED VIEW "'||owner||'"."'||mview_name||'";' drop_commands
  FROM dba_mviews
 WHERE mview_name LIKE 'REDEF$\_T'||CHR(37) ESCAPE '\'
   AND owner IN (SELECT u.username FROM users u)
 UNION ALL
SELECT 'DROP TABLE "'||owner||'"."'||table_name||'";' drop_commands
  FROM dba_tables
 WHERE table_name LIKE 'REDEF$\_T'||CHR(37) ESCAPE '\'
   AND owner IN (SELECT u.username FROM users u)
/
PRO
PRO Comands listed by this script must be executed manually inside corresponding PDB