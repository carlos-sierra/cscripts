----------------------------------------------------------------------------------------
--
-- File name:   cs_spbl_indexes.sql
--
-- Purpose:     List of Indexes Referenced by all SQL Plan Baselines on PDB
--
-- Author:      Carlos Sierra
--
-- Version:     2022/07/29
--
-- Usage:       Connecting into PDB.
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @cs_spbl_indexes.sql
--
-- Notes:       Developed and tested on 19c.
--
---------------------------------------------------------------------------------------
--
@@cs_internal/cs_primary.sql
@@cs_internal/cs_cdb_warn.sql
@@cs_internal/cs_set.sql
@@cs_internal/cs_def.sql
@@cs_internal/cs_file_prefix.sql
--
DEF cs_script_name = 'cs_spbl_indexes';
--
SELECT '&&cs_file_prefix._&&cs_script_name.' cs_file_name FROM DUAL;
--
@@cs_internal/cs_spool_head.sql
PRO SQL> @&&cs_script_name..sql 
@@cs_internal/cs_spool_id.sql
--
COL sql_id FOR A13;
COL signature FOR 99999999999999999999;
COL sql_handle FOR A20;
COL plan_name FOR A30;
COL plan_id FOR 9999999999;
COL plan_hash FOR 9999999999;
COL plan_hash2 FOR 9999999999;
COL plan_hash_full FOR 9999999999;
COL indexed_columns FOR A200;
COL table_owner FOR A30;
COL table_name FOR A30;
COL index_owner FOR A30;
COL index_name FOR A30;
COL sql_text FOR A100 TRUNC;
COL description FOR A100 TRUNC;
COL created FOR A23;
COL last_modified FOR A23;
COL last_executed FOR A23;
COL timestamp FOR A19;
--
-- only works from PDB. do not use CONTAINERS(table_name) since it causes ORA-00600: internal error code, arguments: [kkdolci1], [], [], [], [], [], [],
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
i AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       DISTINCT
       ic.table_owner, ic.table_name, ic.index_owner, ic.index_name, 
       LISTAGG('"'||ic.table_name||'"."'||ic.column_name||'"', ' ' ON OVERFLOW TRUNCATE) WITHIN GROUP (ORDER BY ic.column_position) AS indexed_columns
  FROM dba_ind_columns ic
 WHERE ROWNUM >= 1 /* NO_MERGE */
 GROUP BY
       ic.table_owner, ic.table_name, ic.index_owner, ic.index_name
), 
b AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       DISTINCT 
       p.signature,
       t.sql_handle,
       o.name AS plan_name,
       p.plan_id,
       TO_NUMBER(EXTRACTVALUE(XMLTYPE(p.other_xml),'/*/info[@type = "plan_hash"]')) AS plan_hash, -- normal plan_hash_value
       TO_NUMBER(EXTRACTVALUE(XMLTYPE(p.other_xml),'/*/info[@type = "plan_hash_2"]')) AS plan_hash_2, -- plan_hash_value ignoring transient object names (must be same than plan_id for a baseline to be used) 
       TO_NUMBER(EXTRACTVALUE(XMLTYPE(p.other_xml),'/*/info[@type = "plan_hash_full"]')) AS plan_hash_full, -- adaptive plan (must be different than plan_hash_2 on loaded plans) 
       DECODE(BITAND(o.flags, 1),   0, 'NO', 'YES') AS enabled,
       DECODE(BITAND(o.flags, 2),   0, 'NO', 'YES') AS accepted,
       DECODE(BITAND(o.flags, 4),   0, 'NO', 'YES') AS fixed,
       DECODE(BITAND(o.flags, 64),  0, 'YES', 'NO') AS reproduced,
       DECODE(BITAND(o.flags, 128), 0, 'NO', 'YES') AS autopurge,
       DECODE(BITAND(o.flags, 256), 0, 'NO', 'YES') AS adaptive, 
       SUBSTR(x.outline_hint, INSTR(x.outline_hint, '(', 1, 2) + 1, INSTR(x.outline_hint, '))') - INSTR(x.outline_hint, '(', 1, 2) - 1) AS indexed_columns,
       t.sql_text,
       a.description,
       a.origin,
       a.created,
       a.last_modified,
       o.last_executed,
       p.timestamp
  FROM sys.sqlobj$plan p,
       XMLTABLE('other_xml/outline_data/hint' PASSING XMLTYPE(p.other_xml) COLUMNS outline_hint VARCHAR2(500) PATH '.') x,
       sys.sqlobj$ o,
       sys.sqlobj$auxdata a,
       sys.sql$text t
 WHERE 1 = 1 -- p.signature = 12466351907564247038
   AND p.category = 'DEFAULT'
   AND p.obj_type = 2 /* 1:profile, 2:baseline, 3:patch */
   AND p.other_xml IS NOT NULL
   AND x.outline_hint LIKE 'INDEX%(%(%))'
   AND o.signature = p.signature
   AND o.category = p.category
   AND o.obj_type = p.obj_type
   AND o.plan_id = p.plan_id
   AND a.signature = o.signature
   AND a.category = o.category
   AND a.obj_type = o.obj_type
   AND a.plan_id = o.plan_id
   AND t.signature = p.signature
   AND ROWNUM >= 1 /* NO_MERGE */
),
x AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       DISTINCT
       compute_sql_id(b.sql_text) AS sql_id,
       b.sql_handle,
       b.plan_name,
       b.plan_id,
       b.plan_hash,
       b.plan_hash_2,
       b.plan_hash_full,
       b.enabled,
       b.accepted,
       b.fixed,
       b.reproduced,
       b.autopurge,
       b.adaptive,
       b.indexed_columns,
       NVL(i.table_owner, '"missing"') AS table_owner,
       NVL(i.table_name, '"missing"') AS table_name,
       NVL(i.index_owner, '"missing"') AS index_owner,
       NVL(i.index_name, '"missing"') AS index_name,
       DBMS_LOB.SUBSTR(b.sql_text, 1000) AS sql_text,
       b.description,
       b.created,
       b.last_modified,
       b.last_executed,
       b.timestamp
  FROM b, i
 WHERE i.indexed_columns(+) = b.indexed_columns
   AND ROWNUM >= 1 /* NO_MERGE */
)
SELECT /* comment out unwanted columns */
       x.sql_id,
       x.sql_text,
       -- x.sql_handle,
       x.plan_name,
       x.plan_id,
       -- x.plan_hash,
       -- x.plan_hash_2,
       -- x.plan_hash_full,
       x.enabled,
       x.accepted,
       -- x.fixed,
       -- x.reproduced,
       -- x.autopurge,
       -- x.adaptive,
       x.indexed_columns,
       x.table_owner, 
       x.table_name, 
       x.index_owner, 
       x.index_name,
       -- x.created,
       -- x.last_modified,
       -- x.last_executed,
       -- x.timestamp,
       x.description
  FROM x
 ORDER BY
       x.sql_id,
       x.plan_name,
       x.indexed_columns,
       x.table_owner, 
       x.table_name, 
       x.index_owner, 
       x.index_name
/
--
PRO
PRO SQL> @&&cs_script_name..sql 
--
@@cs_internal/cs_spool_tail.sql
@@cs_internal/cs_undef.sql
@@cs_internal/cs_reset.sql
--