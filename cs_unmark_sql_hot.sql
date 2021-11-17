----------------------------------------------------------------------------------------
--
-- File name:   cs_unmark_sql_hot.sql
--
-- Purpose:     Use DBMS_SHARED_POOL.unmarkhot to undo cs_mark_sql_hot.sql
--
-- Author:      Carlos Sierra
--
-- Version:     2021/11/05
--
-- Usage:       Execute connected to PDB.
--
--              Enter SQL_ID when requested.
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @cs_unmark_sql_hot.sql
--
-- Notes:       Developed and tested on 19c
--
--              https://jonathanlewis.wordpress.com/2017/10/02/markhot/
--             
--              When a statement (through its “full_hash_value”) is marked as hot 
--              an extra value visible as the property column in v$db_object_cache 
--              is set to a value that seems to be dependent on the process id of the 
--              session attempting to execute the statement, and this value is used as 
--              an extra component in calculating a new full_hash_value (which leads 
--              to a new hash_value and sql_id). 
--              With a different full_hash_value the same text generates a new parent 
--              cursor which is (probably) going to be associated with a new library 
--              cache hash bucket and latch. 
--              The property value for the original parent cursor is set to “HOT”, 
--              and the extra copies become “HOTCOPY1”, “HOTCOPY2” and so on. 
--              Interestingly once an object is marked as HOT and the first HOTCOPYn 
--              has appeared the original version may disappear from v$sql while still 
--              existing in v$db_object_cache.
--
---------------------------------------------------------------------------------------
--
@@cs_internal/cs_primary.sql
@@cs_internal/cs_cdb_warn.sql
@@cs_internal/cs_set.sql
@@cs_internal/cs_def.sql
@@cs_internal/cs_file_prefix.sql
--
DEF cs_script_name = 'cs_unmark_sql_hot';
--
PRO
PRO 1. Selective SQL Text Substring: (e.g.: /* getMaxTransactionCommitID */)
DEF sql_text_substring = '&1.';
UNDEF 1;
--
SELECT '&&cs_file_prefix._&&cs_script_name.' cs_file_name FROM DUAL;
--
@@cs_internal/cs_signature.sql
--
@@cs_internal/cs_spool_head.sql
PRO SQL> @&&cs_script_name..sql "&&sql_text_substring."
@@cs_internal/cs_spool_id.sql
--
PRO SQL_TEXT_STR : "&&sql_text_substring."
--
COL hot NEW_V hot FOR 9999;
COL cold NEW_V cold FOR 9999;
COL hash_value FOR 9999999999;
COL sql_text FOR A80 TRUNC;
--
PRO
PRO BEFORE
PRO ~~~~~~
WITH
s AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       DISTINCT con_id, sql_id, hash_value, address, sql_text
  FROM v$sql
 WHERE &&cs_con_id. <> 1 -- executed on PDB and not on CDB$ROOT
   AND con_id = &&cs_con_id.
   AND '&&sql_text_substring.' IS NOT NULL
   AND sql_text LIKE '%&&sql_text_substring.%'
   AND sql_text NOT LIKE '%MATERIALIZE%' -- exclude SQL like this one!
   AND object_status = 'VALID'
   AND is_obsolete = 'N'
   AND is_shareable = 'Y'
   AND ROWNUM >= 1 /* MATERIALIZE */
)
SELECT c.full_hash_value,
       SUM(CASE WHEN c.property IS NOT NULL THEN 1 ELSE 0 END) AS hot,
       SUM(CASE WHEN c.property IS NULL THEN 1 ELSE 0 END) AS cold,
       s.sql_id, s.hash_value, s.address, s.sql_text
  FROM s, v$db_object_cache c
 WHERE c.con_id = s.con_id
   AND c.hash_value = s.hash_value
   AND c.addr = s.address
   AND c.name = s.sql_text
   AND c.namespace = 'SQL AREA'
   AND c.type = 'CURSOR'
   AND c.status = 'VALID'
 GROUP BY
       c.full_hash_value, s.sql_id, s.hash_value, s.address, s.sql_text
 ORDER BY
       c.full_hash_value, s.sql_id, s.hash_value, s.address, s.sql_text
/
--
PRO
PRO SUMMARY
PRO ~~~~~~~
WITH
s AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       DISTINCT con_id, sql_id, hash_value, address, sql_text
  FROM v$sql
 WHERE &&cs_con_id. <> 1 -- executed on PDB and not on CDB$ROOT
   AND con_id = &&cs_con_id.
   AND '&&sql_text_substring.' IS NOT NULL
   AND sql_text LIKE '%&&sql_text_substring.%'
   AND sql_text NOT LIKE '%MATERIALIZE%' -- exclude SQL like this one!
   AND object_status = 'VALID'
   AND is_obsolete = 'N'
   AND is_shareable = 'Y'
   AND ROWNUM >= 1 /* MATERIALIZE */
)
SELECT SUM(CASE WHEN c.property IS NOT NULL THEN 1 ELSE 0 END) AS hot,
       SUM(CASE WHEN c.property IS NULL THEN 1 ELSE 0 END) AS cold
  FROM s, v$db_object_cache c
 WHERE c.con_id = s.con_id
   AND c.hash_value = s.hash_value
   AND c.addr = s.address
   AND c.name = s.sql_text
   AND c.namespace = 'SQL AREA'
   AND c.type = 'CURSOR'
   AND c.status = 'VALID'
/
--
PRO
PAUSE Hit "return" to continue; or "control-c" then "return" to exit: 
--
PRO
-- PRO UNMAKE HOT (IF COLD = 0 AND HOT > 0)
PRO UNMAKE HOT (IF HOT > 0)
PRO ~~~~~~~~~~
SET SERVEROUT ON;
BEGIN
  -- IF TO_NUMBER(NVL(TRIM('&&cold.'), '0')) = 0 AND TO_NUMBER(NVL(TRIM('&&hot.'), '0')) > 0 THEN -- sql has been marked as hot
  IF TO_NUMBER(NVL(TRIM('&&hot.'), '0')) > 0 THEN -- sql has been marked as hot
    FOR i IN (
        WITH
        s AS (
        SELECT /*+ MATERIALIZE NO_MERGE */
            DISTINCT con_id, sql_id, hash_value, address, sql_text
        FROM v$sql
        WHERE &&cs_con_id. <> 1 -- executed on PDB and not on CDB$ROOT
        AND con_id = &&cs_con_id.
        AND '&&sql_text_substring.' IS NOT NULL
        AND sql_text LIKE '%&&sql_text_substring.%'
        AND sql_text NOT LIKE '%MATERIALIZE%' -- exclude SQL like this one!
        AND object_status = 'VALID'
        AND is_obsolete = 'N'
        AND is_shareable = 'Y'
        AND ROWNUM >= 1 /* MATERIALIZE */
        )
        SELECT DISTINCT full_hash_value
        FROM s, v$db_object_cache c
        WHERE c.con_id = s.con_id
        AND c.hash_value = s.hash_value
        AND c.addr = s.address
        AND c.name = s.sql_text
        AND c.namespace = 'SQL AREA'
        AND c.type = 'CURSOR'
        AND c.status = 'VALID'
        -- AND c.property IS NOT NULL -- HOT or COLD
    )
    LOOP
      DBMS_OUTPUT.put_line('UNMARKHOT:'||i.full_hash_value);
      DBMS_SHARED_POOL.unmarkhot(hash => i.full_hash_value, namespace => 0);
    END LOOP;
  END IF;
END;
/
SET SERVEROUT OFF;
--
PRO
PRO SQL> @&&cs_script_name..sql "&&sql_text_substring."
--
@@cs_internal/cs_spool_tail.sql
@@cs_internal/cs_undef.sql
@@cs_internal/cs_reset.sql
--