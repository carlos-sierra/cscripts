----------------------------------------------------------------------------------------
--
-- File name:   cs_redef_table_tbs.sql
--
-- Purpose:     Table Redefinition and Tablespace Move
--
-- Author:      Carlos Sierra
--
-- Version:     2020/06/03
--
-- Usage:       Execute connected to PDB.
--
--              Enter table name and owner when requested.
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @cs_redef_table.sql
--
-- Notes:       Developed and tested on 12.1.0.2.
--
---------------------------------------------------------------------------------------
--
@@cs_internal/cs_primary.sql
@@cs_internal/cs_cdb_warn.sql
@@cs_internal/cs_set.sql
@@cs_internal/cs_def.sql
@@cs_internal/cs_file_prefix.sql
--
DEF cs_script_name = 'cs_redef_table';
--
DEF total_MB = '';
DEF table_MB = '';
DEF indexes_MB = '';
DEF lobs_MB = '';
--
PRO
PRO 1. Table Name:
DEF table_name = '&1.';
UNDEF 1;
COL p_table_name NEW_V p_table_name NOPRI;
SELECT table_name AS p_table_name 
  FROM dba_tables 
 WHERE table_name = UPPER(TRIM('&&table_name.')) 
   AND ROWNUM = 1
/
--
COL owner NEW_V owner FOR A30 HEA 'TABLE_OWNER';
SELECT t.owner
  FROM dba_tables t
 WHERE t.table_name = '&&p_table_name.'
 ORDER BY 1
/
PRO
PRO 2. Table Owner:
DEF p_table_owner = '&2.';
UNDEF 2;
COL p_table_owner NEW_V p_table_owner FOR A30;
SELECT owner AS p_table_owner 
  FROM dba_tables 
 WHERE table_name = '&&p_table_name.'
   AND owner = UPPER(TRIM(COALESCE('&&p_table_owner.', '&&owner.'))) 
   AND ROWNUM = 1
/
PRO
PRO 3. Tablespace:
DEF tbsname = '&3.';
COL p_tablespace_name NEW_V p_tablespace_name FOR A30 NOPRI;
SELECT tablespace_name AS p_tablespace_name
  FROM dba_tables
 WHERE owner = '&&p_table_owner.'
   AND table_name = '&&p_table_name.'
   AND tablespace_name = UPPER(TRIM('&&tbsname.'))
/
--
PRO 4. Degree of Parallelism: [{1}|0,1,2,4]
DEF p_dop = '&4.';
UNDEF 3;
COL p_dop NEW_V p_dop NOPRI;
SELECT CASE WHEN '&&p_dop.' IN ('0','1','2','4') THEN '&&p_dop.' ELSE '1' END AS p_dop FROM DUAL
/
--
SELECT '&&cs_file_prefix._&&cs_script_name._&&p_table_owner..&&p_table_name.' cs_file_name FROM DUAL;
DEF cs_file_name_p = "&&cs_file_name.";
DEF cs_script_name_p = "&&cs_script_name.";
--
@@cs_internal/cs_spool_head.sql
PRO SQL> @&&cs_script_name..sql "&&p_table_name." "&&p_table_owner."
@@cs_internal/cs_spool_id.sql
--
PRO TABLE_OWNER  : &&p_table_owner.
PRO TABLE_NAME   : &&p_table_name.
PRO TABLESPACE   : &&p_tablespace_name.
--
SPO OFF;
@@cs_table.sql "&&p_table_owner."  "&&p_table_name."
SET TIMI OFF ECHO OFF VER OFF FEED OFF;
DEF total_MB_b = "&&total_MB.";
DEF table_MB_b = "&&table_MB.";
DEF indexes_MB_b = "&&indexes_MB.";
DEF lobs_MB_b = "&&lobs_MB.";
DEF scp_b = "scp &&cs_host_name.:&&cs_file_prefix._&&cs_script_name.*.txt &&cs_local_dir."
--
SPO &&cs_file_name_p..txt APP
PRO
PRO DBMS_REDEFINITION.REDEF_TABLE
PRO ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
WHENEVER SQLERROR EXIT FAILURE;
SET TIMI ON ECHO ON VER ON FEED ON;
--
ALTER SESSION SET "_kdlxp_lobcompress" = TRUE;
ALTER SESSION SET "_kdlxp_lobcmplevel" = 2;
ALTER SESSION SET "_kdlxp_lobdeduplicate" = TRUE;
--
BEGIN
     -- SPEED UP INDEX CREATION and REDEF
   EXECUTE IMMEDIATE 'ALTER SESSION SET WORKAREA_SIZE_POLICY=MANUAL';
   EXECUTE IMMEDIATE 'ALTER SESSION SET HASH_AREA_SIZE=2100000000';
   EXECUTE IMMEDIATE 'ALTER SESSION SET SORT_AREA_SIZE=2100000000';
   IF '&&p_dop.' NOT IN ('0', '1') THEN
     EXECUTE IMMEDIATE 'ALTER SESSION SET PARALLEL_DEGREE_POLICY=auto';
     EXECUTE IMMEDIATE 'ALTER SESSION FORCE PARALLEL DDL PARALLEL &&p_dop.';
     EXECUTE IMMEDIATE 'ALTER SESSION FORCE PARALLEL DML PARALLEL &&p_dop.';
     EXECUTE IMMEDIATE 'ALTER SESSION FORCE PARALLEL QUERY PARALLEL &&p_dop.';
  END IF;
END;
/
--
ALTER SESSION SET ddl_lock_timeout = 30;
EXEC DBMS_REDEFINITION.CAN_REDEF_TABLE(uname=>'&&p_table_owner.', tname=>'&&p_table_name.');
EXEC DBMS_REDEFINITION.REDEF_TABLE(uname=>'&&p_table_owner.', tname=>'&&p_table_name.', table_part_tablespace=>'&&p_tablespace_name.', lob_compression_type=>'COMPRESS MEDIUM',index_tablespace=>'&&p_tablespace_name.',lob_tablespace=>'&&p_tablespace_name.');
--
SET TIMI OFF ECHO OFF VER OFF FEED OFF;
WHENEVER SQLERROR CONTINUE;
--
-- Disable PX
BEGIN
     -- SPEED UP INDEX CREATION and REDEF
   EXECUTE IMMEDIATE 'ALTER SESSION SET WORKAREA_SIZE_POLICY=AUTO';
   IF '&&p_dop.' NOT IN ('0', '1') THEN
     EXECUTE IMMEDIATE 'ALTER SESSION SET PARALLEL_DEGREE_POLICY=manual';
     EXECUTE IMMEDIATE 'ALTER SESSION DISABLE PARALLEL DDL';
     EXECUTE IMMEDIATE 'ALTER SESSION DISABLE PARALLEL DML';
     EXECUTE IMMEDIATE 'ALTER SESSION DISABLE PARALLEL QUERY';
  END IF;
END;
/
--
-- Remove DOP on Table and Indexes
BEGIN
   IF '&&p_dop.' NOT IN ('0', '1') THEN
      EXECUTE IMMEDIATE 'ALTER TABLE &&p_table_owner..&&p_table_name. NOPARALLEL';
      FOR i IN (SELECT owner, index_name FROM dba_indexes WHERE table_owner = '&&p_table_owner.' AND table_name = '&&p_table_name.' AND index_type <> 'LOB')
      LOOP
        EXECUTE IMMEDIATE 'ALTER INDEX '||i.owner||'.'||i.index_name||' NOPARALLEL';
      END LOOP;
   END IF;
END;
/
--
SPO OFF;
@@cs_table.sql "&&p_table_owner."  "&&p_table_name."
SET TIMI OFF ECHO OFF VER OFF FEED OFF;
DEF total_MB_a = "&&total_MB.";
DEF table_MB_a = "&&table_MB.";
DEF indexes_MB_a = "&&indexes_MB.";
DEF lobs_MB_a = "&&lobs_MB.";
DEF scp_a = "scp &&cs_host_name.:&&cs_file_prefix._&&cs_script_name.*.txt &&cs_local_dir."
--
COL type FOR A10 HEA 'OBJECT';
COL MB_before FOR 99,999,990.0;
COL MB_after FOR 99,999,990.0;
COL MB_saved FOR 99,999,990.0;
SPO &&cs_file_name_p..txt APP
PRO
PRO TABLE_OWNER  : &&p_table_owner.
PRO TABLE_NAME   : &&p_table_name.
PRO TABLESPACE   : &&p_tablespace_name.
PRO
PRO REDEF_TABLE RESULTS
PRO ~~~~~~~~~~~~~~~~~~~
SELECT 'Table:' AS type, TO_NUMBER('&&table_MB_b.') AS MB_before, TO_NUMBER('&&table_MB_a.') AS MB_after, TO_NUMBER('&&table_MB_b.') - TO_NUMBER('&&table_MB_a.') AS MB_saved FROM DUAL
 UNION ALL
SELECT 'Index(es):' AS type, TO_NUMBER('&&indexes_MB_b.') AS MB_before, TO_NUMBER('&&indexes_MB_a.') AS MB_after, TO_NUMBER('&&indexes_MB_b.') - TO_NUMBER('&&indexes_MB_a.') AS MB_saved FROM DUAL
 UNION ALL
SELECT 'Lob(s):' AS type, TO_NUMBER('&&lobs_MB_b.') AS MB_before, TO_NUMBER('&&lobs_MB_a.') AS MB_after, TO_NUMBER('&&lobs_MB_b.') - TO_NUMBER('&&lobs_MB_a.') AS MB_saved FROM DUAL
 UNION ALL
SELECT 'Total:' AS type, TO_NUMBER('&&total_MB_b.') AS MB_before, TO_NUMBER('&&total_MB_a.') AS MB_after, TO_NUMBER('&&total_MB_b.') - TO_NUMBER('&&total_MB_a.') AS MB_saved FROM DUAL
/
PRO
PRO SQL> @&&cs_script_name_p..sql "&&p_table_name." "&&p_table_owner." "&&p_tablespace_name." "&&p_dop."
--
DEF cs_script_name = "&&cs_script_name_p.";
@@cs_internal/cs_spool_tail.sql
PRO
PRO If you want before and after details on &&p_table_name. table, index(es) and lob(s):
PRO &&scp_b.
PRO &&scp_a.
@@cs_internal/cs_undef.sql
@@cs_internal/cs_reset.sql
--
