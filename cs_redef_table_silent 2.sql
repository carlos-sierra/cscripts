----------------------------------------------------------------------------------------
--
-- File name:   cs_redef_table_silent.sql
--
-- Purpose:     Table Redefinition - Silent
--
-- Author:      Carlos Sierra
--
-- Version:     2021/11/02
--
-- Usage:       Execute connected to PDB
--
--              Enter: table owner, table name, and ticket number (e.g.: CHANGE-123456)
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @cs_redef_table_silent.sql
--
-- Notes:       Developed and tested on 12.1.0.2.
--
---------------------------------------------------------------------------------------
--
DEF cs_reference = 'cs_redef_table_silent.sql';
DEF p_compression = 'FALSE';
DEF api_name = 'REDEFLOBC';
DEF p_redeflob = 'C';
DEF p_pxdegree = '1';
--
@@cs_internal/cs_primary.sql
@@cs_internal/cs_cdb_warn.sql
@@cs_internal/cs_set.sql
@@cs_internal/cs_def.sql
@@cs_internal/cs_blackout.sql
@@cs_internal/cs_file_prefix.sql
--
DEF cs_script_name = 'cs_redef_table_silent';
--
PRO
PRO 1. Table Owner:
DEF table_owner = '&1.';
UNDEF 1;
COL p_owner NEW_V p_owner FOR A30 NOPRI;
SELECT username AS p_owner 
  FROM dba_users 
 WHERE oracle_maintained = 'N'
   AND username NOT LIKE 'C##%'
   AND username = UPPER(TRIM('&&table_owner.')) 
   AND ROWNUM = 1
/
--
PRO
PRO 2. Table Name:
DEF table_name = '&2.';
UNDEF 2;
COL p_table_name NEW_V p_table_name NOPRI;
SELECT table_name AS p_table_name 
  FROM dba_tables 
 WHERE owner = '&&p_owner.'
   AND table_name = UPPER(TRIM('&&table_name.')) 
   AND ROWNUM = 1
/
--
COL p_newtbs NEW_V p_newtbs NOPRI;
SELECT tablespace_name AS p_newtbs
  FROM dba_segments
 WHERE owner = '&&p_owner.'
   AND segment_name = '&&p_table_name.'
   AND segment_type LIKE 'TABLE%'
 ORDER BY 
       segment_type
FETCH FIRST ROW ONLY
/
--
PRO
PRO 3. Ticket: (e.g: CHANGE-123456)
SELECT NVL(UPPER(TRIM('&3.')), '&&cs_reference.') AS cs_reference FROM DUAL
/
UNDEF 3;
--
SELECT '&&cs_file_prefix._&&cs_script_name._&&p_owner..&&p_table_name.' cs_file_name FROM DUAL;
--
@@cs_internal/cs_spool_head.sql
PRO SQL> @&&cs_script_name..sql "&&p_owner." "&&p_table_name." "&&cs_reference."
@@cs_internal/cs_spool_id.sql
--
PRO TABLE_OWNER  : &&p_owner.
PRO TABLE_NAME   : &&p_table_name.
PRO TICKET       : &&cs_reference.
PRO TABLESPACE   : &&p_newtbs. 
PRO OLTP_COMPRES : &&p_compression. [{FALSE}|TRUE]
PRO LOB_COMPRES  : &&p_redeflob. [{C}|CD|NO] C:Compression, CD:Compression and Deduplication, NO:None
PRO PX_DEGREE    : &&p_pxdegree. [{1}|2|4|8]
--
DEF specific_table = '&&p_table_name.';
DEF order_by = 't.pdb_name, t.owner, t.table_name';
DEF fetch_first_N_rows = '1';
DEF total_MB = '';
DEF table_MB = '';
DEF indexes_MB = '';
DEF lobs_MB = '';
--
PRO
PRO BEFORE
PRO ~~~~~~
@@cs_internal/cs_tables_internal.sql
DEF total_MB_b = "&&total_MB.";
DEF table_MB_b = "&&table_MB.";
DEF indexes_MB_b = "&&indexes_MB.";
DEF lobs_MB_b = "&&lobs_MB.";
@@cs_internal/cs_lobs_internal.sql
--
ALTER SESSION SET container = CDB$ROOT;
--
PRO
PRO TABLE REDEFINITION
PRO ~~~~~~~~~~~~~~~~~~
SET SERVEROUT ON
ALTER SESSION SET DDL_LOCK_TIMEOUT = 10;
BEGIN
  &&cs_tools_schema..IOD_SPACE.&&api_name.(
      p_pdb_name      => '&&cs_con_name.'
    , p_owner         => '&&p_owner.'
    , p_table_name    => '&&p_table_name.'
    , p_pxdegree      =>  &&p_pxdegree.
    , p_newtbs        => '&&p_newtbs.'
    , p_compression   => &&p_compression.
  );
END;
/
SET SERVEROUT OFF;
--
ALTER SESSION SET CONTAINER = &&cs_con_name.;
--
PRO
PRO AFTER
PRO ~~~~~
@@cs_internal/cs_tables_internal.sql
DEF total_MB_a = "&&total_MB.";
DEF table_MB_a = "&&table_MB.";
DEF indexes_MB_a = "&&indexes_MB.";
DEF lobs_MB_a = "&&lobs_MB.";
@@cs_internal/cs_lobs_internal.sql
--
COL type FOR A10 HEA 'OBJECT';
COL MB_before FOR 99,999,990.0;
COL MB_after FOR 99,999,990.0;
COL MB_saved FOR 99,999,990.0;
PRO
PRO TABLE REDEFINITION EFFICIENCY
PRO ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
SELECT 'Table:' AS type, TO_NUMBER('&&table_MB_b.') AS MB_before, TO_NUMBER('&&table_MB_a.') AS MB_after, TO_NUMBER('&&table_MB_b.') - TO_NUMBER('&&table_MB_a.') AS MB_saved FROM DUAL
 UNION ALL
SELECT 'Index(es):' AS type, TO_NUMBER('&&indexes_MB_b.') AS MB_before, TO_NUMBER('&&indexes_MB_a.') AS MB_after, TO_NUMBER('&&indexes_MB_b.') - TO_NUMBER('&&indexes_MB_a.') AS MB_saved FROM DUAL
 UNION ALL
SELECT 'Lob(s):' AS type, TO_NUMBER('&&lobs_MB_b.') AS MB_before, TO_NUMBER('&&lobs_MB_a.') AS MB_after, TO_NUMBER('&&lobs_MB_b.') - TO_NUMBER('&&lobs_MB_a.') AS MB_saved FROM DUAL
 UNION ALL
SELECT 'Total:' AS type, TO_NUMBER('&&total_MB_b.') AS MB_before, TO_NUMBER('&&total_MB_a.') AS MB_after, TO_NUMBER('&&total_MB_b.') - TO_NUMBER('&&total_MB_a.') AS MB_saved FROM DUAL
/
--
PRO
PRO SQL> @&&cs_script_name..sql "&&p_owner." "&&p_table_name." "&&cs_reference."
--
@@cs_internal/cs_spool_tail.sql
@@cs_internal/cs_undef.sql
@@cs_internal/cs_reset.sql
--