----------------------------------------------------------------------------------------
--
-- File name:   cs_kiev_indexes_metadata.sql
--
-- Purpose:     Extracts and stores metadata for all KIEV Indexes from all PDBs on a CDB
--
-- Frequency:   Immediate
--
-- Author:      Carlos Sierra
--
-- Version:     2021/06/30
--
-- Usage:       Execute connected into CDB 
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @cs_kiev_indexes_metadata.sql
--
-- Notes:       Creates a script using a sppol file, then executes this script for ecah
--              kiev instance (a PDB can have zero, one or more kiev instances, defined
--              by a PDB name and a SCHEMA owner.)
--
--              former OEM IOD_IMMEDIATE_KIEV_INDEXES
--
---------------------------------------------------------------------------------------
--
--Added WHENEVER OSERROR CONTINUE as workaround for Bug 19033356 : SQLPLUS WHENEVER OSERROR FAILS REGARDLESS OF OS COMMAND RESULT
WHENEVER OSERROR CONTINUE;
-- exit graciously if executed on standby
WHENEVER SQLERROR EXIT SUCCESS;
DECLARE
  l_is_primary VARCHAR2(5);
BEGIN
  SELECT CASE WHEN open_mode = 'READ WRITE' AND database_role = 'PRIMARY' THEN 'TRUE' ELSE 'FALSE' END AS is_primary INTO l_is_primary FROM v$database;
  IF l_is_primary = 'FALSE' THEN raise_application_error(-20000, 'Not PRIMARY'); END IF;
END;
/
-- exit graciously if executed on excluded host
WHENEVER SQLERROR EXIT SUCCESS;
DECLARE
  l_host_name VARCHAR2(64);
BEGIN
  SELECT host_name INTO l_host_name FROM v$instance;
  IF LOWER(l_host_name) LIKE CHR(37)||'control-plane'||CHR(37) OR
     LOWER(l_host_name) LIKE CHR(37)||'omr'||CHR(37) OR
     LOWER(l_host_name) LIKE CHR(37)||'oem'||CHR(37) OR
     LOWER(l_host_name) LIKE CHR(37)||'casper'||CHR(37) OR
     LOWER(l_host_name) LIKE CHR(37)||'telemetry'||CHR(37)
  THEN
    raise_application_error(-20000, '*** Excluded host: "'||l_host_name||'" ***');
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
-- set parameter(s)
WHENEVER SQLERROR EXIT FAILURE;
DECLARE
  l_count NUMBER;
BEGIN
  SELECT /*+ OPT_PARAM('_px_cdb_view_enabled' 'FALSE') */ COUNT(*) INTO l_count FROM cdb_tables WHERE table_name = 'KIEVDATASTOREMETADATA' AND ROWNUM = 1;
  IF l_count = 0 THEN
    raise_application_error(-20000, '*** There are no KIEV PDBs ***');
  END IF;
END;
/
-- setup
SET TERM ON HEA ON LIN 2490 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF LONG 240000 LONGC 2400 NUM 20 SERVEROUT OFF;
DEF cs_tools_schema = 'C##IOD';
WHENEVER SQLERROR CONTINUE;
-- begin
PRO
PRO begins extraction of kiev metadata...
--
DROP TABLE &&cs_tools_schema..kiev_ind_columns
/
DROP TABLE &&cs_tools_schema..kiev_db_ind_columns
/
--
WHENEVER SQLERROR EXIT FAILURE;
-- 
CREATE TABLE &&cs_tools_schema..kiev_ind_columns (
  con_id                         NUMBER,
  pdb_name                       VARCHAR2(30),
  owner                          VARCHAR2(30), 
  table_name                     VARCHAR2(30), 
  index_name                     VARCHAR2(30), 
  index_type                     VARCHAR2(10),
  redundant_of                   VARCHAR2(30),
  source                         VARCHAR2(8),
  uniqueness                     VARCHAR2(9), 
  column_position                NUMBER, 
  column_name                    VARCHAR2(30), 
  nullable                       VARCHAR2(8), 
  data_type                      VARCHAR2(30), 
  data_length                    NUMBER, 
  data_precision                 NUMBER,
  data_scale                     NUMBER, 
  bucketid                       NUMBER,
  indexid                        NUMBER,
  ordering                       NUMBER,
  keyid                          NUMBER,
  keytype                        VARCHAR2(30),
  keyorder                       NUMBER,
  valueid                        NUMBER,
  created                        DATE,
  timestamp                      TIMESTAMP(3)
)
TABLESPACE IOD
/
--
CREATE TABLE &&cs_tools_schema..kiev_db_ind_columns (
  con_id                         NUMBER,
  pdb_name                       VARCHAR2(30),
  owner                          VARCHAR2(30), 
  table_name                     VARCHAR2(30), 
  index_name                     VARCHAR2(30), 
  rename_as                      VARCHAR2(30),
  uniqueness                     VARCHAR2(9), 
  partitioned                    VARCHAR2(11),
  visibility                     VARCHAR2(9),
  leaf_blocks                    NUMBER,
  tablespace_name                VARCHAR2(30),
  column_position                NUMBER, 
  column_name                    VARCHAR2(30), 
  nullable                       VARCHAR2(8), 
  avg_col_len                    NUMBER,
  data_type                      VARCHAR2(30), 
  data_length                    NUMBER, 
  data_precision                 NUMBER,
  data_scale                     NUMBER,
  created                        DATE,
  timestamp                      TIMESTAMP(3)
)
TABLESPACE IOD
/
--
CREATE OR REPLACE VIEW &&cs_tools_schema..kiev_ind_columns_v AS
WITH 
foj AS (
SELECT COALESCE(k.con_id, d.con_id) AS con_id,
       COALESCE(k.pdb_name, d.pdb_name) AS pdb_name,
       COALESCE(k.owner, d.owner) AS owner,
       COALESCE(k.table_name, d.table_name) AS table_name,
       COALESCE(k.index_name, d.index_name) AS index_name,
       MAX(k.redundant_of) OVER (PARTITION BY COALESCE(k.pdb_name, d.pdb_name), COALESCE(k.owner, d.owner), COALESCE(k.table_name, d.table_name), COALESCE(k.index_name, d.index_name)) AS redundant_of,
       MAX(d.rename_as) OVER (PARTITION BY COALESCE(k.pdb_name, d.pdb_name), COALESCE(k.owner, d.owner), COALESCE(k.table_name, d.table_name), COALESCE(k.index_name, d.index_name)) AS rename_as,
       COALESCE(k.uniqueness, d.uniqueness) AS uniqueness,
       k.column_position AS k_column_position,
       d.column_position AS d_column_position,
       COALESCE(k.column_name, d.column_name) AS column_name,
       COALESCE(k.nullable, d.nullable) AS nullable,
       d.avg_col_len,
       COALESCE(k.data_type, d.data_type) AS data_type,
       COALESCE(k.data_length, d.data_length) AS data_length,
       COALESCE(k.data_precision, d.data_precision) AS data_precision,
       COALESCE(k.data_scale, d.data_scale) AS data_scale,
       k.bucketid,
       k.index_type,
       k.indexid,
       k.ordering,
       k.keyid,
       k.keytype,
       k.keyorder,
       k.valueid,
       k.source,
       MAX(d.partitioned) OVER (PARTITION BY COALESCE(k.pdb_name, d.pdb_name), COALESCE(k.owner, d.owner), COALESCE(k.table_name, d.table_name), COALESCE(k.index_name, d.index_name)) AS partitioned,
       d.visibility,
       d.leaf_blocks,
       d.tablespace_name,
       k.created AS kiev_created,
       d.created AS db_created,
       SUM(COALESCE(k.data_length, d.data_length)) OVER (PARTITION BY COALESCE(k.con_id, d.con_id), COALESCE(k.pdb_name, d.pdb_name), COALESCE(k.owner, d.owner), COALESCE(k.table_name, d.table_name), COALESCE(k.index_name, d.index_name)) AS index_data_length,
       SUM(CASE WHEN k.column_position IS NULL THEN 0 ELSE 1 END) OVER (PARTITION BY COALESCE(k.con_id, d.con_id), COALESCE(k.pdb_name, d.pdb_name), COALESCE(k.owner, d.owner), COALESCE(k.table_name, d.table_name), COALESCE(k.index_name, d.index_name)) AS k_columns, -- kiev
       SUM(CASE WHEN d.column_position IS NULL THEN 0 ELSE 1 END) OVER (PARTITION BY COALESCE(k.con_id, d.con_id), COALESCE(k.pdb_name, d.pdb_name), COALESCE(k.owner, d.owner), COALESCE(k.table_name, d.table_name), COALESCE(k.index_name, d.index_name)) AS d_columns, -- database
       SUM(CASE WHEN k.column_position = d.column_position THEN 1 ELSE 0 END) OVER (PARTITION BY COALESCE(k.con_id, d.con_id), COALESCE(k.pdb_name, d.pdb_name), COALESCE(k.owner, d.owner), COALESCE(k.table_name, d.table_name), COALESCE(k.index_name, d.index_name)) AS a_columns -- aligned
  FROM &&cs_tools_schema..kiev_ind_columns k FULL OUTER JOIN &&cs_tools_schema..kiev_db_ind_columns d 
    ON  k.con_id = d.con_id
    AND UPPER(k.pdb_name) = UPPER(d.pdb_name)
    AND UPPER(k.owner) = UPPER(d.owner)
    AND UPPER(k.table_name) = UPPER(d.table_name)
    AND UPPER(k.index_name) = UPPER(d.index_name)
    AND UPPER(k.column_name) = UPPER(d.column_name)
)
SELECT con_id,
       pdb_name,
       owner,
       table_name,
       index_name,
       redundant_of,
       rename_as,
       uniqueness,
       k_column_position,
       d_column_position,
       column_name,
       nullable,
       avg_col_len,
       data_type,
       data_length,
       data_precision,
       data_scale,
       index_data_length,
       bucketid,
       index_type,
       indexid,
       ordering,
       keyid,
       keytype,
       keyorder,
       valueid,
       source,
       partitioned,
       visibility,
       leaf_blocks,
       tablespace_name,
       kiev_created,
       db_created,
       CASE
         WHEN k_columns = d_columns AND k_columns = a_columns THEN 'MATCHING INDEX'
         WHEN partitioned = 'YES' THEN 'PARTITIONED'
         --WHEN redundant_of IS NOT NULL AND k_columns > d_columns AND d_columns > 0 THEN 'EXTRA INDEX' -- 'MISING COLUMN(S)'
         --WHEN redundant_of IS NOT NULL AND d_columns = 0 THEN 'REDUNDANT INDEX' -- 'MISING INDEX'
         WHEN rename_as = 'RENAME_AS' THEN 'DEPRECATE INDEX'
         WHEN rename_as IS NOT NULL THEN 'RENAME INDEX'
         WHEN redundant_of IS NOT NULL THEN 'REDUNDANT INDEX'
         WHEN d_columns = 1 AND column_name = 'KIEVTXNID' AND index_name = table_name||'_KTI' THEN 'SNAPSHOT INDEX'
         WHEN k_columns > d_columns AND d_columns > 0 THEN 'MISING COLUMN(S)'
         WHEN k_columns < d_columns AND k_columns > 0 THEN 'EXTRA COLUMN(S)'
         WHEN k_columns <> a_columns AND k_columns > 0 AND a_columns > 0 THEN 'MISALIGNED COLUMN(S)'
         WHEN k_columns = 0 THEN 'EXTRA INDEX'
         WHEN d_columns = 0 THEN 'MISING INDEX'
       END AS validation,
       CASE
         WHEN index_data_length > 6398 THEN 'SUPER' -- index creation would fail with ORA-01450: maximum key length (6398) exceeded
         WHEN index_data_length > 3215 THEN 'LITTLE' -- index creation would fail with ORA-01450: maximum key length (3215) exceeded
         ELSE 'NO'
       END AS fat_index
  FROM foj
/
--
CREATE OR REPLACE
PROCEDURE &&cs_tools_schema..load_kiev_ind_columns (
  p_con_id          IN VARCHAR2,
  p_pdb_name        IN VARCHAR2,
  p_owner           IN VARCHAR2,
  p_table_name      IN VARCHAR2,
  p_index_name      IN VARCHAR2,
  p_index_type      IN VARCHAR2,
  p_source          IN VARCHAR2,
  p_uniqueness      IN VARCHAR2,
  p_column_position IN VARCHAR2,
  p_column_name     IN VARCHAR2,
  p_nullable        IN VARCHAR2,
  p_data_type       IN VARCHAR2,
  p_data_length     IN VARCHAR2,
  p_data_precision  IN VARCHAR2,
  p_data_scale      IN VARCHAR2,
  p_bucketid        IN VARCHAR2,
  p_indexid         IN VARCHAR2,
  p_keyid           IN VARCHAR2,
  p_keytype         IN VARCHAR2,
  p_keyorder        IN VARCHAR2,
  p_ordering        IN VARCHAR2,
  p_valueid         IN VARCHAR2,
  p_created         IN VARCHAR2
)
IS
  r &&cs_tools_schema..kiev_ind_columns%ROWTYPE;
BEGIN
  r.con_id          := p_con_id         ;
  r.pdb_name        := p_pdb_name       ;
  r.owner           := p_owner          ;
  r.table_name      := p_table_name     ;
  r.index_name      := p_index_name     ;
  r.index_type      := p_index_type     ;
  r.source          := p_source         ;
  r.uniqueness      := p_uniqueness     ;
  r.column_position := p_column_position;
  r.column_name     := p_column_name    ;
  r.nullable        := p_nullable       ;
  r.data_type       := p_data_type      ;
  r.data_length     := p_data_length    ;
  r.data_precision  := p_data_precision ;
  r.data_scale      := p_data_scale     ;
  r.bucketid        := p_bucketid       ;
  r.indexid         := p_indexid        ;
  r.ordering        := p_ordering       ;
  r.keyid           := p_keyid          ;
  r.keytype         := p_keytype        ;
  r.ordering        := p_ordering       ;
  r.valueid         := p_valueid        ;
  r.created         := TO_DATE(p_created, 'YYYY-MM-DD"T"HH24:MI:SS');
  r.timestamp       := SYSTIMESTAMP     ;
  --
  INSERT INTO &&cs_tools_schema..kiev_ind_columns VALUES r;
END;
/
-- stores script to be executed for each pdb/schema
VAR extraction_script CLOB;
BEGIN
:extraction_script := q'[
WITH
kiev_tables AS (
SELECT t.bucketid,
       t.name
  FROM kievbuckets t
),
kiev_indexes AS (
SELECT i.bucketid,
       i.indexid,
       i.indexname,
       i.isunique,
       i.whencreated
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
       k.whencreated,
       ROW_NUMBER() OVER (PARTITION BY k.bucketid ORDER BY k.keytype, k.keyorder) AS column_position
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
       c.nullable
  FROM kievbucketvalues c
),
kiev_ind_columns AS (
SELECT ic.indexid,
       ic.ordering,
       ic.valueid,
       ic.keyid,
       ROW_NUMBER() OVER (PARTITION BY ic.indexid ORDER BY ic.ordering) AS column_position
  FROM kievindexcolumns ic
),
kiev_pk_ind_columns AS (
SELECT t.bucketid,
       k.keyid,
       k.column_position,
       k.keyorder,
       t.name AS table_name,
       t.name||'_PK' AS index_name,
       'Y' AS isunique,
       k.name AS column_name,
       k.keytype,
       k.datatype,
       k.length,
       k.precision,
       k.scale,
       k.nullable,
       k.whencreated
  FROM kiev_tables t,
       kiev_keys k
 WHERE k.bucketid = t.bucketid
),
kiev_non_pk_ind_columns AS (
SELECT t.bucketid,
       i.indexid,
       ic.valueid,
       ic.keyid,
       kk.keytype,
       kk.keyorder,
       ic.column_position,
       ic.ordering,
       t.name AS table_name,
       i.indexname AS index_name,
       i.isunique,
       i.whencreated,
       CASE WHEN ic.valueid IS NOT NULL THEN tc.name WHEN ic.keyid IS NOT NULL THEN kk.name END AS column_name,
       CASE WHEN ic.valueid IS NOT NULL THEN tc.datatype WHEN ic.keyid IS NOT NULL THEN kk.datatype END AS datatype,
       CASE WHEN ic.valueid IS NOT NULL THEN tc.length WHEN ic.keyid IS NOT NULL THEN kk.length END AS length,
       CASE WHEN ic.valueid IS NOT NULL THEN tc.precision WHEN ic.keyid IS NOT NULL THEN kk.precision END AS precision,
       CASE WHEN ic.valueid IS NOT NULL THEN tc.scale WHEN ic.keyid IS NOT NULL THEN kk.scale END AS scale,
       CASE WHEN ic.valueid IS NOT NULL THEN tc.nullable WHEN ic.keyid IS NOT NULL THEN kk.nullable END AS nullable
  FROM kiev_tables t,
       kiev_indexes i,
       kiev_ind_columns ic,
       kiev_tab_columns tc,
       kiev_keys kk
 WHERE i.bucketid = t.bucketid
   AND ic.indexid = i.indexid
   AND tc.bucketid(+) = t.bucketid
   AND tc.valueid(+) = ic.valueid
   AND kk.bucketid(+) = t.bucketid
   AND kk.keyid(+) = ic.keyid
),
all_kiev_ind_columns AS (
SELECT SYS_CONTEXT('USERENV', 'CON_ID') AS con_id,
       SYS_CONTEXT('USERENV', 'CON_NAME') AS pdb_name,
       SYS_CONTEXT('USERENV', 'CURRENT_SCHEMA') AS owner,
       table_name,
       index_name,
       'PRIMARY' AS index_type,
       'METADATA' AS source,
       CASE isunique WHEN 'Y' THEN 'UNIQUE' ELSE 'NONUNIQUE' END AS uniqueness,
       column_position,
       column_name,
       nullable,
       TO_CHAR(whencreated, 'YYYY-MM-DD"T"HH24:MI:SS') AS created,
       datatype,
       length,
       precision,
       scale,
       bucketid,
       TO_NUMBER(NULL) AS indexid,
       keyid,
       keytype,
       keyorder,
       TO_NUMBER(NULL) AS ordering,
       TO_NUMBER(NULL) AS valueid
  FROM kiev_pk_ind_columns
UNION ALL
SELECT SYS_CONTEXT('USERENV', 'CON_ID') AS con_id,
       SYS_CONTEXT('USERENV', 'CON_NAME') AS pdb_name,
       SYS_CONTEXT('USERENV', 'CURRENT_SCHEMA') AS owner,
       table_name,
       index_name,
       'SECONDARY' AS index_type,
       'METADATA' AS source,
       CASE isunique WHEN 'Y' THEN 'UNIQUE' ELSE 'NONUNIQUE' END AS uniqueness,
       column_position,
       column_name,
       nullable,
       TO_CHAR(whencreated, 'YYYY-MM-DD"T"HH24:MI:SS') AS created,
       datatype,
       length,
       precision,
       scale,
       bucketid,
       indexid,
       keyid,
       keytype,
       keyorder,
       ordering,
       valueid
  FROM kiev_non_pk_ind_columns
)
SELECT 'EXEC &&cs_tools_schema..load_kiev_ind_columns('''||con_id||''','''||pdb_name||''','''||owner||''','''||table_name||''','''||index_name||''','''||index_type||''','''||source||''','''||uniqueness||''','''||column_position||''','''||column_name||''','''||nullable||''','''||datatype||''','''||length||''','''||precision||''','''||scale||''','''||bucketid||''','''||indexid||''','''||keyid||''','''||keytype||''','''||keyorder||''','''||ordering||''','''||valueid||''','''||created||''');' AS line
  FROM all_kiev_ind_columns
 ORDER BY 1
]'||CHR(47);
END;
/
SET HEA OFF PAGES 0;
SET TERM OFF;
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
 WHERE t.table_name = 'KIEVDATASTOREMETADATA'
   AND c.con_id = t.con_id
   AND c.open_mode = 'READ WRITE'
 ORDER BY
       c.name, t.owner
/
SPO OFF;
SET TERM ON;
-- 
WHENEVER SQLERROR CONTINUE;
PRO
PRO generates inserts for &&cs_tools_schema..kiev_ind_columns...
SET TERM OFF;
SPO /tmp/IOD_IMMEDIATE_KIEV_INDEXES_inserts.sql
@/tmp/IOD_IMMEDIATE_KIEV_INDEXES_driver.sql
SPO OFF;
SET TERM ON;
-- execute inserts
PRO
PRO capturing kiev metadata into staging repository...
ALTER SESSION SET container = CDB$ROOT;
@/tmp/IOD_IMMEDIATE_KIEV_INDEXES_inserts.sql
COMMIT
/
DROP PROCEDURE &&cs_tools_schema..load_kiev_ind_columns
/
SET HEA ON PAGES 100;
PRO
PRO transforming captured kiev metadata: appending to secondary non-unique indexes all columns from primary, as long as there are no duplicates...
-- SET SERVEROUT ON;
DECLARE
  l_count INTEGER;
  r &&cs_tools_schema..kiev_ind_columns%ROWTYPE;
BEGIN
  FOR i IN (SELECT con_id, pdb_name, owner, table_name, index_name, index_type, source, uniqueness, bucketid, indexid, MAX(column_position) AS max_column_position
              FROM &&cs_tools_schema..kiev_ind_columns
             WHERE index_type = 'SECONDARY'
               AND source = 'METADATA'
               AND uniqueness = 'NONUNIQUE'
             GROUP BY
                   con_id, pdb_name, owner, table_name, index_name, index_type, source, uniqueness, bucketid, indexid)
  LOOP
    l_count := 0;
    FOR j IN (SELECT 'PRIMARY' AS source, 
                     k.column_name,
                     k.nullable,
                     k.data_type,
                     k.data_length,
                     k.data_precision,
                     k.data_scale,
                     k.keyid,
                     k.keytype,
                     k.keyorder,
                     k.ordering,
                     k.valueid,
                     k.created
                FROM &&cs_tools_schema..kiev_ind_columns k
               WHERE k.index_type = 'PRIMARY'
                 AND k.uniqueness = 'UNIQUE'
                 --AND k.keytype = 'HASH'
                 AND k.indexid IS NULL
                 AND k.source = i.source
                 AND k.con_id = i.con_id
                 AND k.pdb_name = i.pdb_name
                 AND k.owner = i.owner
                 AND k.table_name = i.table_name
                 AND k.index_name <> i.index_name
                 AND k.index_type <> i.index_type
                 AND k.bucketid = i.bucketid
                 AND UPPER(k.column_name) NOT IN (SELECT UPPER(s.column_name)
                                                    FROM &&cs_tools_schema..kiev_ind_columns s
                                                   WHERE s.index_type = i.index_type
                                                     AND s.source = i.source
                                                     AND s.uniqueness = i.uniqueness
                                                     AND s.con_id = i.con_id
                                                     AND s.pdb_name = i.pdb_name
                                                     AND s.owner = i.owner
                                                     AND s.table_name = i.table_name
                                                     AND s.index_name = i.index_name
                                                     AND s.bucketid = i.bucketid
                                                     AND s.indexid = i.indexid)
                ORDER BY 
                      k.column_position)
    LOOP
      l_count := l_count + 1;
      r.con_id          := i.con_id         ;
      r.pdb_name        := i.pdb_name       ;
      r.owner           := i.owner          ;
      r.table_name      := i.table_name     ;
      r.index_name      := i.index_name     ;
      r.index_type      := i.index_type     ;
      r.source          := j.source         ;
      r.uniqueness      := i.uniqueness     ;
      r.column_position := i.max_column_position + l_count;
      r.column_name     := j.column_name    ;
      r.nullable        := j.nullable       ;
      r.data_type       := j.data_type      ;
      r.data_length     := j.data_length    ;
      r.data_precision  := j.data_precision ;
      r.data_scale      := j.data_scale     ;
      r.bucketid        := i.bucketid       ;
      r.indexid         := i.indexid        ;
      r.keyid           := j.keyid          ;
      r.keytype         := j.keytype        ;
      r.keyorder        := j.keyorder       ;
      r.ordering        := j.ordering       ;
      r.valueid         := j.valueid        ;
      r.created         := j.created        ;
      r.timestamp       := SYSTIMESTAMP     ;
      INSERT INTO &&cs_tools_schema..kiev_ind_columns VALUES r;
    END LOOP;
  END LOOP;
  COMMIT;
END;
/
PRO
PRO transforming captured kiev metadata: appending KievTxnID for MVCC to all indexes, as long as this column is not already in index...
-- SET SERVEROUT ON;
DECLARE
  l_count INTEGER;
  r &&cs_tools_schema..kiev_ind_columns%ROWTYPE;
BEGIN
  FOR i IN (SELECT con_id, pdb_name, owner, table_name, index_name, index_type, uniqueness, bucketid, indexid, MAX(column_position) AS max_column_position, MAX(created) AS max_created
              FROM &&cs_tools_schema..kiev_ind_columns
             WHERE index_type IN ('PRIMARY', 'SECONDARY')
               AND source IN ('METADATA', 'PRIMARY')
             GROUP BY
                   con_id, pdb_name, owner, table_name, index_name, index_type, uniqueness, bucketid, indexid)
  LOOP
    l_count := 0;
    FOR j IN (SELECT 'MVCC' AS source, 
                     'KievTxnID' AS column_name,
                     'N' AS nullable,
                     'INT8' data_type,
                     TO_NUMBER(NULL) AS data_length,
                     TO_NUMBER(NULL) AS data_precision,
                     TO_NUMBER(NULL) AS data_scale,
                     TO_NUMBER(NULL) AS keyid,
                     TO_CHAR(NULL) AS keytype,
                     TO_NUMBER(NULL) AS keyorder,
                     TO_NUMBER(NULL) AS ordering,
                     TO_NUMBER(NULL) AS valueid
                FROM DUAL
               WHERE NOT EXISTS (SELECT NULL
                                   FROM &&cs_tools_schema..kiev_ind_columns s
                                  WHERE s.index_type = i.index_type
                                    AND s.uniqueness = i.uniqueness
                                    AND s.con_id = i.con_id
                                    AND s.pdb_name = i.pdb_name
                                    AND s.owner = i.owner
                                    AND s.table_name = i.table_name
                                    AND s.index_name = i.index_name
                                    AND UPPER(s.column_name) = UPPER('KievTxnID')
                                    AND s.bucketid = i.bucketid))
    LOOP
      l_count := l_count + 1;
      r.con_id          := i.con_id         ;
      r.pdb_name        := i.pdb_name       ;
      r.owner           := i.owner          ;
      r.table_name      := i.table_name     ;
      r.index_name      := i.index_name     ;
      r.index_type      := i.index_type     ;
      r.source          := j.source         ;
      r.uniqueness      := i.uniqueness     ;
      r.column_position := i.max_column_position + l_count;
      r.column_name     := j.column_name    ;
      r.nullable        := j.nullable       ;
      r.data_type       := j.data_type      ;
      r.data_length     := j.data_length    ;
      r.data_precision  := j.data_precision ;
      r.data_scale      := j.data_scale     ;
      r.bucketid        := i.bucketid       ;
      r.indexid         := i.indexid        ;
      r.keyid           := j.keyid          ;
      r.keytype         := j.keytype        ;
      r.keyorder        := j.keyorder       ;
      r.ordering        := j.ordering       ;
      r.valueid         := j.valueid        ;
      r.created         := i.max_created    ;
      r.timestamp       := SYSTIMESTAMP     ;
      INSERT INTO &&cs_tools_schema..kiev_ind_columns VALUES r;
    END LOOP;
  END LOOP;
  COMMIT;
END;
/
PRO
PRO capturing db metadata into staging repository, for kiev indexes (index columns on kiev tables actually)... please wait a few minutes...
INSERT INTO &&cs_tools_schema..kiev_db_ind_columns (
  con_id         ,
  pdb_name       ,
  owner          , 
  table_name     , 
  index_name     , 
  uniqueness     ,
  partitioned    ,
  visibility     ,
  leaf_blocks    ,
  tablespace_name,
  column_position,
  column_name    , 
  nullable       ,
  avg_col_len    ,
  data_type      , 
  data_length    ,
  data_precision ,
  data_scale     ,
  created        ,
  timestamp
)
WITH 
kiev_tables AS (
SELECT /*+ MATERIALIZE NO_MERGE QB_NAME(kiev_tables) */
       DISTINCT
       con_id,
       pdb_name,
       owner,
       table_name,
       UPPER(owner) AS upper_owner,
       UPPER(table_name) AS upper_table_name
  FROM &&cs_tools_schema..kiev_ind_columns
 WHERE ROWNUM >= 1
),
db_indexes AS (
SELECT /*+ OPT_PARAM('_px_cdb_view_enabled' 'FALSE') MATERIALIZE NO_MERGE QB_NAME(db_indexes) */
       i.con_id,
       t.pdb_name,
       i.table_owner,
       i.table_name,
       i.owner,
       i.index_name,
       i.uniqueness,
       i.partitioned,
       i.visibility,
       i.leaf_blocks,
       i.tablespace_name
  FROM kiev_tables t, cdb_indexes i
 WHERE i.con_id = t.con_id 
   AND i.table_owner = t.upper_owner
   AND i.table_name = t.upper_table_name
   AND i.table_owner NOT IN ('SYS', 'XDB', 'SYSTEM', 'MDSYS', 'ORDDATA', 'WMSYS', 'CTXSYS', 'DVSYS', 'LBACSYS', 'DBSNMP', 'AUDSYS', 'OJVMSYS', 'OUTLN', 'C##IOD', 'ORDSYS')
   AND i.owner = t.upper_owner -- index and table owner shall be correct
   AND ROWNUM >= 1 /* MATERIALIZE NO_MERGE */
),
db_tables AS (
SELECT /*+ OPT_PARAM('_px_cdb_view_enabled' 'FALSE') MATERIALIZE NO_MERGE QB_NAME(db_tables) */
       dt.con_id,
       dt.owner,
       dt.table_name,
       dt.partitioned
  FROM kiev_tables t, cdb_tables dt
 WHERE dt.con_id = t.con_id 
   AND dt.owner = t.upper_owner
   AND dt.table_name = t.upper_table_name
   AND dt.owner NOT IN ('SYS', 'XDB', 'SYSTEM', 'MDSYS', 'ORDDATA', 'WMSYS', 'CTXSYS', 'DVSYS', 'LBACSYS', 'DBSNMP', 'AUDSYS', 'OJVMSYS', 'OUTLN', 'C##IOD', 'ORDSYS')
   AND ROWNUM >= 1 /* MATERIALIZE NO_MERGE */
),
db_ind_columns AS (
SELECT /*+ OPT_PARAM('_px_cdb_view_enabled' 'FALSE') MATERIALIZE NO_MERGE QB_NAME(db_ind_columns) */
       ic.con_id,
       ic.table_owner,
       ic.table_name,
       ic.index_name,
       ic.column_position,
       ic.column_name
  FROM kiev_tables t, cdb_ind_columns ic
 WHERE ic.con_id = t.con_id 
   AND ic.table_owner = t.upper_owner
   AND ic.table_name = t.upper_table_name
   AND ic.table_owner NOT IN ('SYS', 'XDB', 'SYSTEM', 'MDSYS', 'ORDDATA', 'WMSYS', 'CTXSYS', 'DVSYS', 'LBACSYS', 'DBSNMP', 'AUDSYS', 'OJVMSYS', 'OUTLN', 'C##IOD', 'ORDSYS')
   AND ic.index_owner = t.upper_owner -- index and table owner shall be correct
   AND ROWNUM >= 1 /* MATERIALIZE NO_MERGE */
),
db_tab_columns AS (
SELECT /*+ OPT_PARAM('_px_cdb_view_enabled' 'FALSE') MATERIALIZE NO_MERGE QB_NAME(db_tab_columns) */
       tc.con_id,
       tc.owner,
       tc.table_name,
       tc.column_name,
       tc.nullable,
       tc.avg_col_len,
       tc.data_type,
       tc.data_length,
       tc.data_precision,
       tc.data_scale
  FROM kiev_tables t, cdb_tab_columns tc
 WHERE tc.con_id = t.con_id 
   AND tc.owner = t.upper_owner
   AND tc.table_name = t.upper_table_name
   AND tc.owner NOT IN ('SYS', 'XDB', 'SYSTEM', 'MDSYS', 'ORDDATA', 'WMSYS', 'CTXSYS', 'DVSYS', 'LBACSYS', 'DBSNMP', 'AUDSYS', 'OJVMSYS', 'OUTLN', 'C##IOD', 'ORDSYS')
   AND ROWNUM >= 1 /* MATERIALIZE NO_MERGE */
),
db_objects AS (
SELECT /*+ OPT_PARAM('_px_cdb_view_enabled' 'FALSE') MATERIALIZE NO_MERGE QB_NAME(db_objects) */
       o.con_id,
       o.owner,
       o.object_name,
       o.created
  FROM cdb_objects o
 WHERE o.owner NOT IN ('SYS', 'XDB', 'SYSTEM', 'MDSYS', 'ORDDATA', 'WMSYS', 'CTXSYS', 'DVSYS', 'LBACSYS', 'DBSNMP', 'AUDSYS', 'OJVMSYS', 'OUTLN', 'C##IOD', 'ORDSYS')
   AND o.object_type = 'INDEX'
   AND ROWNUM >= 1 /* MATERIALIZE NO_MERGE */
)
SELECT 
  /*+ GATHER_PLAN_STATISTICS MONITOR
      BEGIN_OUTLINE_DATA
      IGNORE_OPTIM_EMBEDDED_HINTS
      OPTIMIZER_FEATURES_ENABLE('12.1.0.2')
      DB_VERSION('12.1.0.2')
      OPT_PARAM('_optimizer_extended_cursor_sharing' 'none')
      OPT_PARAM('_optimizer_extended_cursor_sharing_rel' 'none')
      OPT_PARAM('_optimizer_adaptive_cursor_sharing' 'false')
      OPT_PARAM('_px_adaptive_dist_method' 'off')
      OPT_PARAM('_optimizer_strans_adaptive_pruning' 'false')
      OPT_PARAM('_optimizer_nlj_hj_adaptive_join' 'false')
      ALL_ROWS
      OUTLINE_LEAF(@"KIEV_TABLES")
      OUTLINE_LEAF(@"SEL$1877EAF6")
      OUTLINE_LEAF(@"SEL$EFF8F9AB")
      MERGE(@"SEL$1")
      OUTLINE_LEAF(@"SEL$1877EAF5")
      OUTLINE_LEAF(@"SEL$6743A09D")
      MERGE(@"SEL$2")
      OUTLINE_LEAF(@"SEL$1877EAF4")
      OUTLINE_LEAF(@"SEL$7EAF1616")
      MERGE(@"SEL$3")
      OUTLINE_LEAF(@"SEL$1877EAF3")
      OUTLINE_LEAF(@"SEL$40974FFF")
      MERGE(@"SEL$4")
      OUTLINE_LEAF(@"SEL$2D9C9CDD")
      MERGE(@"SEL$5")
      OUTLINE_LEAF(@"SEL$456B0A2B")
      OUTLINE_LEAF(@"SEL$4F0C4B75")
      OUTLINE_LEAF(@"SEL$3A65899E")
      OUTLINE_LEAF(@"SEL$E4512C44")
      OUTLINE_LEAF(@"SEL$C9981847")
      OUTLINE_LEAF(@"SEL$6")
      OUTLINE_LEAF(@"INS$1")
      OUTLINE(@"KIEV_TABLES")
      OUTLINE(@"DB_INDEXES")
      OUTLINE(@"SEL$1")
      OUTLINE(@"DB_TABLES")
      OUTLINE(@"SEL$2")
      OUTLINE(@"DB_IND_COLUMNS")
      OUTLINE(@"SEL$3")
      OUTLINE(@"DB_TAB_COLUMNS")
      OUTLINE(@"SEL$4")
      OUTLINE(@"DB_OBJECTS")
      OUTLINE(@"SEL$5")
      OUTLINE(@"SEL$EFF8F9AB")
      MERGE(@"SEL$1")
      OUTLINE(@"SEL$6743A09D")
      MERGE(@"SEL$2")
      OUTLINE(@"SEL$7EAF1616")
      MERGE(@"SEL$3")
      OUTLINE(@"SEL$40974FFF")
      MERGE(@"SEL$4")
      OUTLINE(@"SEL$2D9C9CDD")
      MERGE(@"SEL$5")
      FULL(@"INS$1" "KIEV_DB_IND_COLUMNS"@"INS$1")
      NO_ACCESS(@"SEL$6" "I"@"SEL$6")
      NO_ACCESS(@"SEL$6" "DT"@"SEL$6")
      NO_ACCESS(@"SEL$6" "IC"@"SEL$6")
      NO_ACCESS(@"SEL$6" "TC"@"SEL$6")
      NO_ACCESS(@"SEL$6" "O"@"SEL$6")
      LEADING(@"SEL$6" "I"@"SEL$6" "DT"@"SEL$6" "IC"@"SEL$6" "TC"@"SEL$6" "O"@"SEL$6")
      USE_HASH(@"SEL$6" "DT"@"SEL$6")
      USE_HASH(@"SEL$6" "IC"@"SEL$6")
      USE_HASH(@"SEL$6" "TC"@"SEL$6")
      USE_HASH(@"SEL$6" "O"@"SEL$6")
      FULL(@"SEL$C9981847" "T1"@"SEL$C9981847")
      FULL(@"SEL$E4512C44" "T1"@"SEL$E4512C44")
      FULL(@"SEL$3A65899E" "T1"@"SEL$3A65899E")
      FULL(@"SEL$4F0C4B75" "T1"@"SEL$4F0C4B75")
      FULL(@"SEL$456B0A2B" "T1"@"SEL$456B0A2B")
      FULL(@"SEL$2D9C9CDD" "DBA_OBJECTS"@"SEL$5")
      PQ_FILTER(@"SEL$2D9C9CDD" SERIAL)
      FULL(@"SEL$40974FFF" "DBA_TAB_COLUMNS"@"SEL$4")
      NO_ACCESS(@"SEL$40974FFF" "T"@"DB_TAB_COLUMNS")
      LEADING(@"SEL$40974FFF" "DBA_TAB_COLUMNS"@"SEL$4" "T"@"DB_TAB_COLUMNS")
      USE_HASH(@"SEL$40974FFF" "T"@"DB_TAB_COLUMNS")
      PQ_FILTER(@"SEL$40974FFF" SERIAL)
      FULL(@"SEL$7EAF1616" "DBA_IND_COLUMNS"@"SEL$3")
      NO_ACCESS(@"SEL$7EAF1616" "T"@"DB_IND_COLUMNS")
      LEADING(@"SEL$7EAF1616" "DBA_IND_COLUMNS"@"SEL$3" "T"@"DB_IND_COLUMNS")
      USE_HASH(@"SEL$7EAF1616" "T"@"DB_IND_COLUMNS")
      PQ_FILTER(@"SEL$7EAF1616" SERIAL)
      FULL(@"SEL$6743A09D" "DBA_TABLES"@"SEL$2")
      NO_ACCESS(@"SEL$6743A09D" "T"@"DB_TABLES")
      LEADING(@"SEL$6743A09D" "DBA_TABLES"@"SEL$2" "T"@"DB_TABLES")
      USE_HASH(@"SEL$6743A09D" "T"@"DB_TABLES")
      PQ_FILTER(@"SEL$6743A09D" SERIAL)
      FULL(@"SEL$EFF8F9AB" "DBA_INDEXES"@"SEL$1")
      NO_ACCESS(@"SEL$EFF8F9AB" "T"@"DB_INDEXES")
      LEADING(@"SEL$EFF8F9AB" "DBA_INDEXES"@"SEL$1" "T"@"DB_INDEXES")
      USE_HASH(@"SEL$EFF8F9AB" "T"@"DB_INDEXES")
      PQ_FILTER(@"SEL$EFF8F9AB" SERIAL)
      FULL(@"KIEV_TABLES" "KIEV_IND_COLUMNS"@"KIEV_TABLES")
      USE_HASH_AGGREGATION(@"KIEV_TABLES")
      PQ_FILTER(@"KIEV_TABLES" SERIAL)
      FULL(@"SEL$1877EAF6" "T1"@"SEL$1877EAF6")
      FULL(@"SEL$1877EAF5" "T1"@"SEL$1877EAF5")
      FULL(@"SEL$1877EAF4" "T1"@"SEL$1877EAF4")
      FULL(@"SEL$1877EAF3" "T1"@"SEL$1877EAF3")
      END_OUTLINE_DATA
  */
       i.con_id,
       i.pdb_name,
       i.table_owner AS owner,
       i.table_name,
       i.index_name,
       i.uniqueness,
       CASE WHEN dt.partitioned = 'YES' OR i.partitioned = 'YES' THEN 'YES' ELSE 'NO' END AS partitioned,
       i.visibility,
       i.leaf_blocks,
       i.tablespace_name,
       ic.column_position,
       ic.column_name,
       tc.nullable,
       tc.avg_col_len,
       tc.data_type,
       tc.data_length,
       tc.data_precision,
       tc.data_scale,
       o.created,
       SYSTIMESTAMP       
  FROM db_indexes i,
       db_tables dt,
       db_ind_columns ic,
       db_tab_columns tc,
       db_objects o
 WHERE dt.con_id = i.con_id
   AND dt.owner = i.table_owner
   AND dt.table_name = i.table_name
   AND ic.con_id = i.con_id
   AND ic.table_owner = i.owner
   AND ic.index_name = i.index_name
   AND tc.con_id = ic.con_id
   AND tc.owner = ic.table_owner
   AND tc.table_name = ic.table_name
   AND tc.column_name = ic.column_name
   AND o.con_id = i.con_id
   AND o.owner = i.owner
   AND o.object_name = i.index_name
/
COMMIT
/
PRO
PRO transforming captured kiev metadata: identifying missing indexes or indexes with missing column(s) as redundant indexes...
-- SET SERVEROUT ON;
BEGIN
  FOR i IN (WITH
            all_kiev_indexes AS (
            SELECT con_id, pdb_name, owner, table_name, index_name, validation,
                   LISTAGG(column_name, ',') WITHIN GROUP (ORDER BY k_column_position NULLS LAST, d_column_position NULLS LAST) AS columns
              FROM &&cs_tools_schema..kiev_ind_columns_v
            WHERE redundant_of IS NULL
              AND rename_as IS NULL
            GROUP BY
                  con_id, pdb_name, owner, table_name, index_name, validation
            )
            SELECT m.con_id, m.pdb_name, m.owner, m.table_name, m.index_name, m.validation, m.columns AS columns_list,
                  (SELECT i.index_name
                      FROM all_kiev_indexes i
                    WHERE i.con_id = m.con_id AND UPPER(i.pdb_name) = UPPER(m.pdb_name) AND UPPER(i.owner) = UPPER(m.owner) AND UPPER(i.table_name) = UPPER(m.table_name) AND UPPER(i.index_name) <> UPPER(m.index_name) AND i.validation <> m.validation AND UPPER(i.columns) LIKE UPPER(m.columns)||CHR(37)
                    --WHERE i.con_id = m.con_id AND UPPER(i.pdb_name) = UPPER(m.pdb_name) AND UPPER(i.owner) = UPPER(m.owner) AND UPPER(i.table_name) = UPPER(m.table_name) AND UPPER(i.index_name) <> UPPER(m.index_name) AND i.validation <> m.validation AND UPPER(i.columns) = UPPER(m.columns)
                    ORDER BY
                          i.index_name
                    FETCH FIRST 1 ROW ONLY) AS redundant_of
              FROM all_kiev_indexes m
            WHERE m.validation IN ('MISING INDEX', 'MISING COLUMN(S)'))
  LOOP
    IF i.redundant_of IS NOT NULL THEN
      UPDATE &&cs_tools_schema..kiev_ind_columns SET redundant_of = i.redundant_of
      WHERE con_id = i.con_id AND UPPER(pdb_name) = UPPER(i.pdb_name) AND UPPER(owner) = UPPER(i.owner) AND UPPER(table_name) = UPPER(i.table_name) AND UPPER(index_name) = UPPER(i.index_name) AND redundant_of IS NULL;
    END IF;
  END LOOP;
  COMMIT;
END;
/
PRO
PRO transforming captured db metadata: identifying indexes that need to be renamed...
-- SET SERVEROUT ON;
BEGIN
  FOR i IN (WITH
            potential_indexes AS (
            SELECT con_id, pdb_name, owner, table_name, index_name, validation,
                   LISTAGG(column_name, ',') WITHIN GROUP (ORDER BY k_column_position NULLS LAST, d_column_position NULLS LAST) AS columns
              FROM &&cs_tools_schema..kiev_ind_columns_v
            WHERE 1 = 1
              --AND redundant_of IS NULL
              AND rename_as IS NULL
              AND validation IN ('EXTRA INDEX', 'MISING COLUMN(S)', 'REDUNDANT INDEX')
            GROUP BY
                  con_id, pdb_name, owner, table_name, index_name, validation
            )
            SELECT m.con_id, m.pdb_name, m.owner, m.table_name, m.index_name, m.validation, m.columns,
                  (SELECT i.index_name
                      FROM potential_indexes i
                    WHERE i.validation IN ('MISING COLUMN(S)', 'REDUNDANT INDEX')
                      AND i.con_id = m.con_id AND UPPER(i.pdb_name) = UPPER(m.pdb_name) AND UPPER(i.owner) = UPPER(m.owner) AND UPPER(i.table_name) = UPPER(m.table_name) AND UPPER(i.index_name) <> UPPER(m.index_name) AND i.validation <> m.validation AND UPPER(i.columns) = UPPER(m.columns)
                    ORDER BY
                          i.index_name
                    FETCH FIRST 1 ROW ONLY) AS rename_as
              FROM potential_indexes m
            WHERE m.validation = 'EXTRA INDEX')
  LOOP
    UPDATE &&cs_tools_schema..kiev_db_ind_columns SET rename_as = i.rename_as
    WHERE con_id = i.con_id AND UPPER(pdb_name) = UPPER(i.pdb_name) AND owner = UPPER(i.owner) AND table_name = UPPER(i.table_name) AND index_name = UPPER(i.index_name) AND rename_as IS NULL;
    UPDATE &&cs_tools_schema..kiev_db_ind_columns SET rename_as = 'RENAME_AS'
    WHERE con_id = i.con_id AND UPPER(pdb_name) = UPPER(i.pdb_name) AND owner = UPPER(i.owner) AND table_name = UPPER(i.table_name) AND index_name = UPPER(i.rename_as) AND rename_as IS NULL;
  END LOOP;
  COMMIT;
END;
/
--
DEF cs_con_id = 1;
DEF cs_con_name = 'CDB$ROOT';
@@cs_internal/cs_kiev_index_metadata_summary.sql
HOS rm /tmp/IOD_IMMEDIATE_KIEV_INDEXES_inserts.sql
HOS rm /tmp/IOD_IMMEDIATE_KIEV_INDEXES_extraction_script.sql
HOS rm /tmp/IOD_IMMEDIATE_KIEV_INDEXES_driver.sql
--
---------------------------------------------------------------------------------------
-- end