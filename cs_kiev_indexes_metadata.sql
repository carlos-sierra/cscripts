----------------------------------------------------------------------------------------
--
-- File name:   cs_kiev_indexes_metadata.sql
--
-- Purpose:     Extracts and stores metadata for all KIEV Indexes from all PDBs
--
-- Frequency:   Immediate
--
-- Author:      Carlos Sierra
--
-- Version:     2020/12/25
--
-- Usage:       Execute connected into CDB 
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @cs_kiev_indexes_metadata.sql
--
-- Notes:       Creates a script using a sppol file, then executes this script for ecah
--              kiev instance (a PDB can have zero, one or more kiev instances, defined
--              by a PDB name and a SCHEMA owner.
--
--              former OEM IOD_IMMEDIATE_KIEV_INDEXES
--
---------------------------------------------------------------------------------------
--
-- exit graciously if executed on standby
WHENEVER SQLERROR EXIT SUCCESS;
DECLARE
  l_open_mode VARCHAR2(20);
BEGIN
  SELECT open_mode INTO l_open_mode FROM v$database;
  IF l_open_mode <> 'READ WRITE' THEN
    raise_application_error(-20000, 'Not PRIMARY');
  END IF;
END;
/
-- exit graciously if executed on excluded host
WHENEVER SQLERROR EXIT SUCCESS;
DECLARE
  l_host_name VARCHAR2(64);
BEGIN
  SELECT host_name INTO l_host_name FROM v$instance;
  IF LOWER(l_host_name) LIKE CHR(37)||'casper'||CHR(37) OR 
     LOWER(l_host_name) LIKE CHR(37)||'control-plane'||CHR(37) OR 
     LOWER(l_host_name) LIKE CHR(37)||'omr'||CHR(37) OR 
     LOWER(l_host_name) LIKE CHR(37)||'oem'||CHR(37) OR 
     LOWER(l_host_name) LIKE CHR(37)||'telemetry'||CHR(37)
  THEN
    raise_application_error(-20000, '*** Excluded host: "'||l_host_name||'" ***');
  END IF;
END;
/
-- exit graciously if executed on unapproved database
WHENEVER SQLERROR EXIT SUCCESS;
DECLARE
  l_db_name VARCHAR2(9);
  l_region VARCHAR2(64);
BEGIN
  SELECT name INTO l_db_name FROM v$database;
  SELECT UPPER(SUBSTR(host_name,INSTR(host_name,'.',-1)+1)) AS region INTO l_region FROM v$instance;
  IF UPPER(l_db_name) LIKE 'DBE'||CHR(37) OR 
     UPPER(l_db_name) LIKE 'IOD'||CHR(37) OR 
     UPPER(l_db_name) LIKE 'KIEV'||CHR(37) OR 
     UPPER(l_db_name) LIKE 'LCS'||CHR(37) OR
     UPPER(l_db_name) LIKE 'CAT'||CHR(37)
  THEN
    NULL;
  ELSE
    raise_application_error(-20000, '*** Unapproved database: "'||l_db_name||'" ***');
  END IF;
END;
/
-- exit graciously if there are no KIEV PDBs
WHENEVER SQLERROR EXIT SUCCESS;
DECLARE
  l_count NUMBER;
BEGIN
  SELECT COUNT(*) INTO l_count FROM cdb_tables WHERE table_name = 'KIEVBUCKETS' AND ROWNUM = 1;
  IF l_count = 0 THEN
    raise_application_error(-20000, '*** There are no KIEV PDBs ***');
  END IF;
END;
/
-- exit graciously if executed on a PDB
WHENEVER SQLERROR EXIT SUCCESS;
BEGIN
  IF SYS_CONTEXT('USERENV', 'CON_NAME') <> 'CDB$ROOT' THEN
    raise_application_error(-20000, '*** Within PDB "'||SYS_CONTEXT('USERENV', 'CON_NAME')||'" ***');
  END IF;
END;
/
-- exit not graciously if any error
WHENEVER SQLERROR EXIT FAILURE;
-- creates repository if it does not exist, or tuncates it if it exists
DECLARE
  l_exists NUMBER;
  l_sql_statement VARCHAR2(32767) := q'[
CREATE TABLE &&cs_tools_schema..kiev_ind_columns (
  pdb_name                       VARCHAR2(30),
  owner                          VARCHAR2(30), 
  table_name                     VARCHAR2(30), 
  index_name                     VARCHAR2(30), 
  uniqueness                     VARCHAR2(9), 
  column_position                NUMBER, 
  column_name                    VARCHAR2(30), 
  data_type                      VARCHAR2(30), 
  data_length                    NUMBER, 
  data_precision                 NUMBER,
  data_scale                     NUMBER, 
  nullable                       VARCHAR2(8), 
  con_id                         NUMBER
)
TABLESPACE IOD
]';
BEGIN
  SELECT COUNT(*) INTO l_exists FROM dba_tables WHERE owner = '&&cs_tools_schema.' AND table_name = 'KIEV_IND_COLUMNS';
  IF l_exists = 0 THEN
    EXECUTE IMMEDIATE l_sql_statement;
  ELSE
    EXECUTE IMMEDIATE 'TRUNCATE TABLE &&cs_tools_schema..kiev_ind_columns';
  END IF;
END;
/
-- stores script to be executed for each pdb/schema
VAR extraction_script CLOB;
BEGIN
:extraction_script := q'[WITH
kiev_tables AS (
SELECT SYS_CONTEXT('USERENV', 'CURRENT_SCHEMA') owner,
       t.name,
       t.bucketid 
  FROM kievbuckets t
),
kiev_indexes AS (
SELECT i.bucketid,
       i.indexid,
       i.indexname,
       i.isunique
  FROM kievindexes i
),
kiev_keys AS (
SELECT k.bucketid,
       k.keyid,
       k.keyorder,
       k.name,
       k.keytype,
       k.datatype,
       k.length,
       k.precision,
       k.scale,
       k.nullable,
       ROW_NUMBER() OVER (PARTITION BY k.bucketid ORDER BY CASE k.keytype WHEN 'HASH' THEN 1 ELSE 2 END, k.keyorder, k.keyid) column_position
  FROM kievbucketkeys k
),
kiev_tab_columns AS (
SELECT c.bucketid,
       c.valueid,
       c.valueorder,
       c.name,
       c.datatype,
       c.length,
       c.precision,
       c.scale,
       c.nullable,
       ROW_NUMBER() OVER (PARTITION BY c.bucketid ORDER BY c.valueorder DESC NULLS LAST) valueorder_desc
  FROM kievbucketvalues c
),
kiev_ind_columns AS (
SELECT ic.indexid,
       ic.ordering,
       ic.valueid,
       ic.keyid,
       COUNT(*) OVER (PARTITION BY ic.indexid) column_count
  FROM kievindexcolumns ic
),
kiev_pk_indexes AS (
SELECT t.bucketid,
       t.owner,
       t.name table_name,
       t.name||'_PK' index_name,
       k.column_position,
       k.name column_name,
       k.datatype,
       k.length,
       k.precision,
       k.scale,
       k.nullable,
       COUNT(*) OVER (PARTITION BY t.owner, t.name) column_count
  FROM kiev_tables t,
       kiev_keys k
 WHERE k.bucketid = t.bucketid
),
kiev_pk AS (
SELECT p.owner,
       p.table_name,
       p.index_name,
       'UNIQUE' uniqueness,
       p.column_position,
       p.column_name,
       p.datatype,
       p.length,
       p.precision,
       p.scale,
       p.nullable
  FROM kiev_pk_indexes p
),
kiev_pk_txn AS (
SELECT p.owner,
       p.table_name,
       p.index_name,
       'UNIQUE' uniqueness,
       p.column_position + 1 column_position,
       'KievTxnID' column_name,
       tc.datatype,
       tc.length,
       tc.precision,
       tc.scale,
       tc.nullable
  FROM kiev_pk_indexes p,
       kiev_tab_columns tc
 WHERE p.column_count = p.column_position
   AND tc.bucketid = p.bucketid
   AND tc.valueorder_desc = 1
   AND NOT EXISTS (SELECT NULL FROM kiev_pk k WHERE k.owner = p.owner AND k.table_name = p.table_name AND k.index_name = p.index_name AND k.column_name = 'KievTxnID')
),
kiev_non_pk AS (
SELECT t.owner,
       t.name table_name,
       i.indexname index_name,
       CASE i.isunique WHEN 'Y' THEN 'UNIQUE' ELSE 'NONUNIQUE' END uniqueness,
       ic.ordering column_position,
       COALESCE(k.name, tc.name) column_name,
       COALESCE(k.datatype, tc.datatype) datatype,
       COALESCE(k.length, tc.length) length,
       COALESCE(k.precision, tc.precision) precision,
       COALESCE(k.scale, tc.scale) scale,
       COALESCE(k.nullable, tc.nullable) nullable
  FROM kiev_tables t,
       kiev_indexes i,
       kiev_ind_columns ic,
       kiev_keys k,
       kiev_tab_columns tc
 WHERE i.bucketid = t.bucketid
   AND ic.indexid = i.indexid
   AND k.bucketid(+) = t.bucketid
   AND k.keyid(+) = ic.keyid
   AND tc.bucketid(+) = t.bucketid
   AND tc.valueid(+) = ic.valueid
),
kiev_non_pk_txn AS (
SELECT t.owner,
       t.name table_name,
       i.indexname index_name,
       CASE i.isunique WHEN 'Y' THEN 'UNIQUE' ELSE 'NONUNIQUE' END uniqueness,
       ic.ordering + 1 column_position,
       'KievTxnID' column_name,
       tc.datatype,
       tc.length,
       tc.precision,
       tc.scale,
       tc.nullable
  FROM kiev_tables t,
       kiev_indexes i,
       kiev_ind_columns ic,
       kiev_tab_columns tc
 WHERE i.bucketid = t.bucketid
   AND ic.indexid = i.indexid
   AND ic.column_count = ic.ordering
   AND tc.bucketid = t.bucketid
   AND tc.valueorder_desc = 1
   AND NOT EXISTS (SELECT NULL FROM kiev_non_pk k WHERE k.owner = t.owner AND k.table_name = t.name AND k.index_name = i.indexname AND k.column_name = 'KievTxnID')
),
kiev_union AS (
SELECT owner,
       table_name,
       index_name,
       uniqueness,
       column_position,
       column_name,
       datatype,
       length,
       precision,
       scale,
       nullable
  FROM kiev_pk
 UNION ALL
SELECT owner,
       table_name,
       index_name,
       uniqueness,
       column_position,
       column_name,
       datatype,
       length,
       precision,
       scale,
       nullable
  FROM kiev_pk_txn
 UNION ALL
SELECT owner,
       table_name,
       index_name,
       uniqueness,
       column_position,
       column_name,
       datatype,
       length,
       precision,
       scale,
       nullable
  FROM kiev_non_pk
 UNION ALL
SELECT owner,
       table_name,
       index_name,
       uniqueness,
       column_position,
       column_name,
       datatype,
       length,
       precision,
       scale,
       nullable
  FROM kiev_non_pk_txn
)
SELECT 'INSERT INTO &&cs_tools_schema..kiev_ind_columns (pdb_name, owner, table_name, index_name, uniqueness, column_position, column_name, data_type, data_length, data_precision, data_scale, nullable, con_id) '||
       'VALUES ('''||SYS_CONTEXT('USERENV', 'CON_NAME')||''', '''||owner||''', '''||table_name||''', '''||index_name||''', '''||uniqueness||''', '||column_position||
       ', '''||column_name||''', '''||datatype||''', TO_NUMBER('''||length||'''), TO_NUMBER('''||precision||'''), TO_NUMBER('''||scale||'''), '''||nullable||''', '''||SYS_CONTEXT('USERENV', 'CON_ID')||''');' line
  FROM kiev_union
 ORDER BY
       owner, table_name, index_name, column_position
]'||CHR(47);
END;
/
SET HEA ON LIN 2490 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF LONG 240000 LONGC 2400 SERVEROUT OFF;
SET HEA OFF PAGES 500;
SPO /tmp/IOD_IMMEDIATE_KIEV_INDEXES_extraction_script.sql;
PRINT extraction_script;
SPO OFF;
-- driver script
SPO /tmp/IOD_IMMEDIATE_KIEV_INDEXES_driver.sql
SELECT 'ALTER SESSION SET container = '||c.name||';'||CHR(10)||
       'ALTER SESSION SET current_schema = '||t.owner||';'||CHR(10)||
       '@/tmp/IOD_IMMEDIATE_KIEV_INDEXES_extraction_script.sql;' line
  FROM cdb_tables t,
       v$containers c
 WHERE t.table_name = 'KIEVBUCKETS'
   AND c.con_id = t.con_id
   AND c.open_mode = 'READ WRITE'
 ORDER BY
       c.name, t.owner
/
SPO OFF;
-- continue if any error
WHENEVER SQLERROR CONTINUE;
-- generates inserts
SPO /tmp/IOD_IMMEDIATE_KIEV_INDEXES_inserts.sql
@/tmp/IOD_IMMEDIATE_KIEV_INDEXES_driver.sql
SPO OFF;
-- execute inserts
ALTER SESSION SET container = CDB$ROOT;
DELETE &&cs_tools_schema..kiev_ind_columns;
@/tmp/IOD_IMMEDIATE_KIEV_INDEXES_inserts.sql
COMMIT;
-- list result
SET HEA ON PAGES 100;
COL nullable FOR A8;
BREAK ON pdb_name ON owner ON table_name SKIP PAGE ON index_name SKIP 1;
--
SPO /tmp/IOD_IMMEDIATE_KIEV_INDEXES_kiev_indexes.txt
PRO Kiev Indexes  
PRO ~~~~~~~~~~~~
SELECT pdb_name,
       owner,
       table_name,
       index_name,
       uniqueness,
       column_position,
       column_name,
       data_type,
       data_length,
       data_precision,
       data_scale,
       nullable
  FROM &&cs_tools_schema..kiev_ind_columns
 ORDER BY
       1,2,3,4,6
/
SPO OFF;
--
---------------------------------------------------------------------------------------
