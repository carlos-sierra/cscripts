----------------------------------------------------------------------------------------
--
-- File name:   cs_redef_table.sql
--
-- Purpose:     Table Redefinition
--
-- Author:      Carlos Sierra
--
-- Version:     2020/12/25
--
-- Usage:       Execute connected to PDB
--
--              Enter table owner and name when requested, followed by other parameters
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
COL username FOR A30;
SELECT username
  FROM dba_users
 WHERE oracle_maintained = 'N'
   AND username NOT LIKE 'C##%'
 ORDER BY
       username
/
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
COL table_name FOR A30;
SELECT table_name, blocks
  FROM dba_tables
 WHERE owner = '&&p_owner.'
 ORDER BY
       table_name
/
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
COL tablespace_name_d NEW_V tablespace_name_d NOPRI;
SELECT tablespace_name AS tablespace_name_d
  FROM dba_segments
 WHERE owner = '&&p_owner.'
   AND segment_name = '&&p_table_name.'
   AND segment_type LIKE 'TABLE%'
 ORDER BY 
       segment_type
FETCH FIRST ROW ONLY
/
--
COL tablespace_name FOR A30;
SELECT tablespace_name
  FROM dba_tablespaces
 WHERE contents = 'PERMANENT'
   AND tablespace_name NOT IN ('SYSTEM', 'SYSAUX')
 ORDER BY 
       tablespace_name
/
PRO
PRO 3. Target Tablespace: [{&&tablespace_name_d.}|<TABLESPACE_NAME>]
DEF tbsname = '&3.';
UNDEF 3;
COL p_newtbs NEW_V p_newtbs FOR A30 NOPRI;
SELECT tablespace_name AS p_newtbs
  FROM dba_tablespaces
 WHERE contents = 'PERMANENT'
   AND tablespace_name NOT IN ('SYSTEM', 'SYSAUX')
   AND tablespace_name = UPPER(TRIM(NVL('&&tbsname.', '&&tablespace_name_d.')))
/
PRO
PRO 4. Table OLTP Compression: [{FALSE}|TRUE]
DEF compression = '&4.';
UNDEF 4;
COL p_compression NEW_V p_compression NOPRI;
SELECT CASE WHEN SUBSTR(UPPER(TRIM('&&compression.')),1,1) IN ('T', 'Y') THEN 'TRUE' ELSE 'FALSE' END AS p_compression FROM DUAL
/
PRO
PRO 5. CLOB Compression and Deduplication: [{CD}|C|NO] CD:Compression and Deduplication, C:Compression, NO:None
DEF redeflob = '&5.';
UNDEF 5;
COL api_name NEW_V api_name NOPRI;
COL p_redeflob NEW_V p_redeflob NOPRI;
SELECT CASE UPPER(TRIM('&&redeflob.')) WHEN 'CD' THEN 'REDEFLOBCD' WHEN 'C' THEN 'REDEFLOBC' WHEN 'NO' THEN 'REDEFNOLOBCD' ELSE 'REDEFLOBCD' END AS api_name,
       CASE WHEN UPPER(TRIM('&&redeflob.')) IN ('CD', 'C', 'NO') THEN UPPER(TRIM('&&redeflob.')) ELSE 'CD' END AS p_redeflob
FROM DUAL
/
PRO
PRO 6. Degree of Parallelism: [{1}|2|4|8]
DEF pxdegree = '&6.';
UNDEF 6;
COL p_pxdegree NEW_V p_pxdegree NOPRI;
SELECT CASE WHEN '&&pxdegree.' IN ('1','2','4','8') THEN '&&pxdegree.' ELSE '1' END AS p_pxdegree FROM DUAL
/
--
SELECT '&&cs_file_prefix._&&cs_script_name._&&p_owner..&&p_table_name.' cs_file_name FROM DUAL;
--
@@cs_internal/cs_spool_head.sql
PRO SQL> @&&cs_script_name..sql "&&p_owner." "&&p_table_name." "&&p_newtbs." "&&p_compression." "&&p_redeflob." "&&p_pxdegree."
@@cs_internal/cs_spool_id.sql
--
PRO TABLE_OWNER  : &&p_owner.
PRO TABLE_NAME   : &&p_table_name.
PRO TABLESPACE   : &&p_newtbs.
PRO OLTP_COMPRES : &&p_compression.
PRO LOB_COMPRES  : &&p_redeflob.
PRO PX_DEGREE    : &&p_pxdegree.
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
--
ALTER SESSION SET container = CDB$ROOT;
--
PRO
PRO TABLE REDEFINITION
PRO ~~~~~~~~~~~~~~~~~~
SET SERVEROUT ON
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
PRO SQL> @&&cs_script_name..sql "&&p_owner." "&&p_table_name." "&&p_newtbs." "&&p_compression." "&&p_redeflob." "&&p_pxdegree."
--
@@cs_internal/cs_spool_tail.sql
@@cs_internal/cs_undef.sql
@@cs_internal/cs_reset.sql
--