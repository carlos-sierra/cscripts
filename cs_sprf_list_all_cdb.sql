----------------------------------------------------------------------------------------
--
-- File name:   cs_sprf_list_all_cdb.sql
--
-- Purpose:     List all SQL Profiles for some SQL Text string on CDB
--
-- Author:      Carlos Sierra
--
-- Version:     2023/03/27
--
-- Usage:       Connecting into PDB.
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @cs_sprf_list_all_cdb.sql
--
-- Notes:       Developed and tested on 19c
--
---------------------------------------------------------------------------------------
--
@@cs_internal/cs_primary.sql
-- @@cs_internal/cs_cdb_warn.sql
@@cs_internal/cs_set.sql
@@cs_internal/cs_def.sql
@@cs_internal/cs_file_prefix.sql
--
DEF cs_script_name = 'cs_sprf_list_all_cdb';
--
PRO 1. SQL Text piece (e.g.: ScanQuery, getValues, TableName, IndexName):
DEF cs2_sql_text_piece = '&1.';
UNDEF 1;
--
SELECT '&&cs_file_prefix._&&cs_script_name.' cs_file_name FROM DUAL;
--
@@cs_internal/cs_spool_head.sql
PRO SQL> @&&cs_script_name..sql "&&cs2_sql_text_piece."
@@cs_internal/cs_spool_id.sql
--
PRO SQL_TEXT     : &&cs2_sql_text_piece.
--
COL created FOR A23;
COL sql_id FOR A13;
COL sql_text FOR A80 TRUNC;
COL name FOR A30;
COL child_cursors FOR 99999 HEA 'Child|Cursors';
COL category FOR A30;
COL status FOR A8;
COL last_modified FOR A19;
COL description FOR A200;
COL pdb_name FOR A30 HEA 'PDB Name';
--
SET FEED ON;
--
PRO
PRO SQL PROFILES - LIST (cdb_sql_profiles)
PRO ~~~~~~~~~~~~~~~~~~~
WITH
FUNCTION compute_sql_id (sql_text IN CLOB)
RETURN VARCHAR2 IS
 BASE_32 CONSTANT VARCHAR2(32) := '0123456789abcdfghjkmnpqrstuvwxyz';
 l_raw_128 RAW(128);
 l_hex_32 VARCHAR2(32);
 l_low_16 VARCHAR(16);
 l_q3 VARCHAR2(8);
 l_q4 VARCHAR2(8);
 l_low_16_m VARCHAR(16);
 l_number NUMBER;
 l_idx INTEGER;
 l_sql_id VARCHAR2(13);
 function_returned_an_error EXCEPTION;
 PRAGMA EXCEPTION_INIT(function_returned_an_error, -28817); -- ORA-28817: PL/SQL function returned an error.
BEGIN
 l_raw_128 := /* use md5 algorithm on sql_text and produce 128 bit hash */
 SYS.DBMS_CRYPTO.hash(TRIM(CHR(0) FROM sql_text)||CHR(0), SYS.DBMS_CRYPTO.hash_md5);
 l_hex_32 := RAWTOHEX(l_raw_128); /* 32 hex characters */
 l_low_16 := SUBSTR(l_hex_32, 17, 16); /* we only need lower 16 */
 l_q3 := SUBSTR(l_low_16, 1, 8); /* 3rd quarter (8 hex characters) */
 l_q4 := SUBSTR(l_low_16, 9, 8); /* 4th quarter (8 hex characters) */
 /* need to reverse order of each of the 4 pairs of hex characters */
 l_q3 := SUBSTR(l_q3, 7, 2)||SUBSTR(l_q3, 5, 2)||SUBSTR(l_q3, 3, 2)||SUBSTR(l_q3, 1, 2);
 l_q4 := SUBSTR(l_q4, 7, 2)||SUBSTR(l_q4, 5, 2)||SUBSTR(l_q4, 3, 2)||SUBSTR(l_q4, 1, 2);
 /* assembly back lower 16 after reversing order on each quarter */
 l_low_16_m := l_q3||l_q4;
 /* convert to number */
 SELECT TO_NUMBER(l_low_16_m, 'xxxxxxxxxxxxxxxx') INTO l_number FROM DUAL;
 /* 13 pieces base-32 (5 bits each) make 65 bits. we do have 64 bits */
 FOR i IN 1 .. 13
 LOOP
 l_idx := TRUNC(l_number / POWER(32, (13 - i))); /* index on BASE_32 */
 l_sql_id := l_sql_id||SUBSTR(BASE_32, (l_idx + 1), 1); /* stitch 13 characters */
 l_number := l_number - (l_idx * POWER(32, (13 - i))); /* for next piece */
 END LOOP;
 RETURN l_sql_id;
EXCEPTION
  WHEN function_returned_an_error THEN
    RETURN 'ORA-28817';
END compute_sql_id;
used_profiles AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       con_id, sql_profile, COUNT(*) AS child_cursors
  FROM v$sql
 WHERE sql_profile IS NOT NULL
   AND ROWNUM >= 1
 GROUP BY
       con_id, sql_profile
)
SELECT TO_CHAR(s.created, '&&cs_datetime_full_format.') AS created, 
       TO_CHAR(s.last_modified, '&&cs_datetime_full_format.') AS last_modified, 
       compute_sql_id(s.sql_text) AS sql_id,
       DBMS_LOB.substr(s.sql_text, 1000) AS sql_text,
       s.name,
       p.child_cursors,
       s.category,
       s.status,
       s.description,
       c.name AS pdb_name
  FROM cdb_sql_profiles s,
       used_profiles p,
       v$containers c
 WHERE ('&&cs2_sql_text_piece.' IS NULL OR UPPER(s.sql_text) LIKE '%'||UPPER(TRIM('&&cs2_sql_text_piece.'))||'%')
   AND p.sql_profile(+) = s.name
   AND p.con_id(+) = s.con_id
   AND c.con_id = s.con_id
 ORDER BY
       s.created, s.last_modified
/
--
PRO
PRO SQL> @&&cs_script_name..sql "&&cs2_sql_text_piece."
--
@@cs_internal/cs_spool_tail.sql
@@cs_internal/cs_undef.sql
@@cs_internal/cs_reset.sql
--