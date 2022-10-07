----------------------------------------------------------------------------------------
--
-- File name:   cs_redef_schema.sql
--
-- Purpose:     Schema Redefinition (by moving all objects into new Tablespace)
--
-- Author:      Carlos Sierra
--
-- Version:     2021/10/15
--
-- Usage:       Execute connected to PDB
--
--              Enter schema name when requested, followed by other parameters
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @cs_redef_schema.sql
--
-- Notes:       This operation requires a blackout.
--              Developed and tested on 12.1.0.2.
--
---------------------------------------------------------------------------------------
--
@@cs_internal/cs_primary.sql
@@cs_internal/cs_cdb_warn.sql
@@cs_internal/cs_set.sql
@@cs_internal/cs_def.sql
@@cs_internal/cs_blackout.sql
@@cs_internal/cs_file_prefix.sql
--
DEF cs_script_name = 'cs_redef_schema';
--
COL username FOR A30;
SELECT username
  FROM dba_users
 WHERE oracle_maintained = 'N'
   AND common = 'NO'
 ORDER BY
       username
/
PRO
PRO 1. Schema Owner:
DEF table_owner = '&1.';
UNDEF 1;
COL p_owner NEW_V p_owner FOR A30 NOPRI;
SELECT username AS p_owner 
  FROM dba_users 
 WHERE oracle_maintained = 'N'
   AND common = 'NO'
   AND username = UPPER(TRIM('&&table_owner.')) 
   AND ROWNUM = 1
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
PRO 2. Source Tablespace: 
DEF tbsname = '&2.';
UNDEF 2;
COL p_sourcetbs NEW_V p_sourcetbs FOR A30 NOPRI;
SELECT tablespace_name AS p_sourcetbs
  FROM dba_tablespaces
 WHERE contents = 'PERMANENT'
   AND tablespace_name NOT IN ('SYSTEM', 'SYSAUX')
   AND tablespace_name = UPPER(TRIM('&&tbsname.'))
/
PRO
PRO 2. Target Tablespace: 
DEF tbsname = '&3.';
UNDEF 2;
COL p_newtbs NEW_V p_newtbs FOR A30 NOPRI;
SELECT tablespace_name AS p_newtbs
  FROM dba_tablespaces
 WHERE contents = 'PERMANENT'
   AND tablespace_name NOT IN ('SYSTEM', 'SYSAUX')
   AND tablespace_name = UPPER(TRIM('&&tbsname.'))
/
PRO
PRO 3. Table OLTP Compression: [{FALSE}|TRUE]
DEF compression = '&4.';
UNDEF 3;
COL p_compression NEW_V p_compression NOPRI;
SELECT CASE WHEN SUBSTR(UPPER(TRIM('&&compression.')),1,1) IN ('T', 'Y') THEN 'TRUE' ELSE 'FALSE' END AS p_compression FROM DUAL
/
PRO
PRO 4. CLOB Compression and Deduplication: [{C}|CD|NO] C:Compression, CD:Compression and Deduplication, NO:None
DEF redeflob = '&5.';
UNDEF 4;
COL p_lobcomp NEW_V p_lobcomp NOPRI;
COL p_lobdedup NEW_V p_lobdedup NOPRI; 
COL p_redeflob NEW_V p_redeflob NOPRI;
SELECT CASE WHEN NVL(UPPER(TRIM('&&redeflob.')), 'C') IN ('CD', 'C') THEN 'TRUE' ELSE 'FALSE' END AS p_lobcomp,
       CASE WHEN NVL(UPPER(TRIM('&&redeflob.')), 'C') = 'CD' THEN 'TRUE' ELSE 'FALSE' END AS p_lobdedup,
       CASE WHEN UPPER(TRIM('&&redeflob.')) IN ('CD', 'C', 'NO') THEN UPPER(TRIM('&&redeflob.')) ELSE 'C' END AS p_redeflob
FROM DUAL
/
PRO
PRO 5. Degree of Parallelism: [{1}|2|4|8]
DEF pxdegree = '&6.';
UNDEF 5;
COL p_pxdegree NEW_V p_pxdegree NOPRI;
SELECT CASE WHEN '&&pxdegree.' IN ('1','2','4','8') THEN '&&pxdegree.' ELSE '1' END AS p_pxdegree FROM DUAL
/
--
SELECT '&&cs_file_prefix._&&cs_script_name._&&p_owner.' cs_file_name FROM DUAL;
--
@@cs_internal/cs_spool_head.sql
PRO SQL> @&&cs_script_name..sql "&&p_owner." "&&p_sourcetbs." "&&p_newtbs." "&&p_compression." "&&p_redeflob." "&&p_pxdegree."
@@cs_internal/cs_spool_id.sql
--
PRO TABLE_OWNER  : &&p_owner.
PRO TABLESPACE   : &&p_newtbs.
PRO OLTP_COMPRES : &&p_compression.
PRO LOB_COMPRES  : &&p_redeflob. [{C}|CD|NO] C:Compression, CD:Compression and Deduplication, NO:None
PRO PX_DEGREE    : &&p_pxdegree. [{1}|2|4|8]
--
@@cs_internal/&&cs_set_container_to_cdb_root.
--
PRO
PRO TABLE REDEFINITION
PRO ~~~~~~~~~~~~~~~~~~
SET SERVEROUT ON
BEGIN
  &&cs_tools_schema..IOD_SPACE.redefschemanewtbs (
      p_pdb_name      => '&&cs_con_name.'
    , p_owner         => '&&p_owner.'
    , p_pxdegree      =>  &&p_pxdegree.
    , p_sourcetbs     => '&&p_sourcetbs.'
    , p_newtbs        => '&&p_newtbs.'
    , p_compression   => &&p_compression.
    , p_lobcomp       => &&p_lobcomp.
    , p_lobdedup      => &&p_lobdedup.
  );
END;
/
SET SERVEROUT OFF;
--
@@cs_internal/&&cs_set_container_to_curr_pdb.
--
PRO
PRO SQL> @&&cs_script_name..sql "&&p_owner." "&&p_sourcetbs."  "&&p_newtbs." "&&p_compression." "&&p_redeflob." "&&p_pxdegree."
--
@@cs_internal/cs_spool_tail.sql
@@cs_internal/cs_undef.sql
@@cs_internal/cs_reset.sql
--