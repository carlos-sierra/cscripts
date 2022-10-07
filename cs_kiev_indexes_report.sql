----------------------------------------------------------------------------------------
--
-- File name:   cs_kiev_indexes_report.sql
--
-- Purpose:     KIEV Indexes Inventory Report (show discrepancies between KIEV and DB metadata)
--
-- Author:      Carlos Sierra
--
-- Version:     2021/10/22
--
-- Usage:       Execute connected to CDB or PDB.
--
--              Specify search scope when requested.
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @cs_kiev_indexes_report.sql
--
-- Notes:       cs_kiev_indexes_metadata.sql (former OEM JOB IOD_IMMEDIATE_KIEV_INDEXES.sql) should be executed in advance
--
---------------------------------------------------------------------------------------
--
@@cs_internal/cs_primary.sql
@@cs_internal/cs_cdb_warn.sql
@@cs_internal/cs_set.sql
SET PAGES 1000;
@@cs_internal/cs_def.sql
@@cs_internal/cs_kiev_meta_warn.sql
@@cs_internal/cs_file_prefix.sql
--
@@cs_internal/&&cs_set_container_to_cdb_root.
--
SELECT DISTINCT
       table_name
  FROM &&cs_tools_schema..kiev_ind_columns
 WHERE &&cs_con_id. IN (1, con_id)
   AND '&&cs_con_name.' IN ('CDB$ROOT', pdb_name)
   AND '&&cs_con_name.' <> 'CDB$ROOT' -- list of tables would be too long for CDB level
 ORDER BY
       table_name
/
--
@@cs_internal/&&cs_set_container_to_curr_pdb.
--
PRO
PRO 1. Table Name: (opt)
DEF table_name = '&1.';
UNDEF 1;
--
@@cs_internal/&&cs_set_container_to_cdb_root.
--
SELECT DISTINCT
       index_name
  FROM &&cs_tools_schema..kiev_ind_columns
 WHERE &&cs_con_id. IN (1, con_id)
   AND '&&cs_con_name.' IN ('CDB$ROOT', pdb_name)
   AND '&&cs_con_name.' <> 'CDB$ROOT' -- list of indexes would be too long for CDB level
   AND '&&table_name.' IS NOT NULL -- list indexes only if a table was entered
   AND UPPER(table_name) = UPPER(COALESCE('&&table_name.', table_name))
   AND index_name NOT LIKE 'BIN$%'
 ORDER BY
       index_name
/
--
@@cs_internal/&&cs_set_container_to_curr_pdb.
--
PRO
PRO 2. Index Name: (opt)
DEF index_name = '&2.';
UNDEF 2;
--
PRO
PRO 3. Include KIEV/DB index compare metadata report?: [{Y}|N]
DEF include_compare = '&3.';
UNDEF 3;
COL include_compare NEW_V include_compare NOPRI;
SELECT CASE WHEN UPPER(TRIM('&&include_compare.')) IN ('Y', 'N') THEN UPPER(TRIM('&&include_compare.')) ELSE 'Y' END AS include_compare FROM DUAL
/
--
PRO
PRO 4. Include COMPLIANT indexs on compare metadata report?: [{N}|Y]
DEF include_compliant = '&4.';
UNDEF 4;
COL include_compliant NEW_V include_compliant NOPRI;
SELECT CASE WHEN UPPER(TRIM('&&include_compliant.')) IN ('Y', 'N') AND '&&include_compare.' = 'Y' THEN UPPER(TRIM('&&include_compliant.')) ELSE 'N' END AS include_compliant FROM DUAL
/
PRO
PRO 5. Include KIEV raw index metadata report?: [{N}|Y]
DEF include_kiev = '&5.';
UNDEF 5;
COL include_kiev NEW_V include_kiev NOPRI;
SELECT CASE WHEN UPPER(TRIM('&&include_kiev.')) IN ('Y', 'N') THEN UPPER(TRIM('&&include_kiev.')) ELSE 'N' END AS include_kiev FROM DUAL
/
--
PRO
PRO 6. Include DB raw index metadata report?: [{N}|Y]
DEF include_db = '&6.';
UNDEF 6;
COL include_db NEW_V include_db NOPRI;
SELECT CASE WHEN UPPER(TRIM('&&include_db.')) IN ('Y', 'N') THEN UPPER(TRIM('&&include_db.')) ELSE 'N' END AS include_db FROM DUAL
/
--
PRO
PRO 7. Include index fix DDL SQL scripts?: [{Y}|N]
DEF include_ddl = '&7.';
UNDEF 7;
COL include_ddl NEW_V include_ddl NOPRI;
SELECT CASE WHEN UPPER(TRIM('&&include_ddl.')) IN ('Y', 'N') THEN UPPER(TRIM('&&include_ddl.')) ELSE 'Y' END AS include_ddl FROM DUAL
/
--
PRO
PRO 8. Include index DROP on fix DDL SQL scripts?: [{N}|Y]
DEF include_index_drop = '&8.';
UNDEF 8;
COL include_index_drop NEW_V include_index_drop NOPRI;
SELECT CASE WHEN UPPER(TRIM('&&include_index_drop.')) IN ('Y', 'N') THEN UPPER(TRIM('&&include_index_drop.')) ELSE 'N' END AS include_index_drop FROM DUAL
/
--
PRO
PRO 9. Sleep seconds between DDL actions?: [{2}|0-10]
DEF sleep_seconds = '&9.';
UNDEF 9;
COL sleep_seconds NEW_V sleep_seconds NOPRI;
SELECT CASE WHEN TO_NUMBER('&&sleep_seconds.') BETWEEN 0 AND 10 THEN TRIM('&&sleep_seconds.') ELSE '2' END AS sleep_seconds FROM DUAL
/
--
COL cs_file_suffix NEW_V cs_file_suffix NOPRI;
SELECT CASE WHEN '&&table_name.' IS NOT NULL THEN '_&&table_name.' END||CASE WHEN '&&index_name.' IS NOT NULL THEN '_&&index_name.' END AS cs_file_suffix FROM DUAL
/
--
DEF cs_script_name = 'cs_kiev_indexes_report';
--
@@cs_internal/&&cs_set_container_to_cdb_root.
--
SELECT '&&cs_file_prefix._&&cs_script_name.&&cs_file_suffix.' cs_file_name FROM DUAL;
--
@@cs_internal/cs_spool_head.sql
PRO SQL> @&&cs_script_name..sql "&&table_name." "&&index_name." "&&include_compare." "&&include_compliant." "&&include_kiev." "&&include_db." "&&include_ddl" "&&include_index_drop." "&&sleep_seconds."
@@cs_internal/cs_spool_id.sql
--
PRO TABLE_NAME   : "&&table_name."
PRO INDEX_NAME   : "&&index_name."
PRO COMPARE_META : "&&include_compare."
PRO KIEV_META    : "&&include_kiev."
PRO DB_META      : "&&include_db."
PRO DDL_SCRIPT   : "&&include_ddl."
PRO INDEX_DROP   : "&&include_index_drop."
PRO SLEEP_SECONDS: "&&sleep_seconds."
--
PRO
PRO KIEV/DB Index Compare Summary (as of "&&kiev_metadata_date.")
PRO ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
@@cs_internal/cs_kiev_index_metadata_summary.sql
--
COL pdb_name FOR A30;
COL owner FOR A30;
COL table_name FOR A30;
COL index_name FOR A30;
COL redundant_of FOR A30;
COL rename_as FOR A30;
COL uniqueness FOR A10;
COL validation FOR A20;
COL fat_index FOR A9;
COL discrepancy FOR A11;
COL k_column_position FOR 99999999 HEA 'KIEV POS';
COL d_column_position FOR 99999999 HEA 'DB POS';
COL column_name FOR A30;
COL type_len FOR A30;
COL nullable FOR A8;
COL avg_col_len FOR 999999 HEA 'AVG_LEN';
COL data_type FOR A12;
COL data_length FOR 999999 HEA 'COL_LEN';
COL data_precision FOR 999999999 HEA 'PRECISION';
COL data_scale FOR 9999 HEA 'SCALE';
COL index_data_length FOR 999999 HEA 'IDX_LEN';
COL con_id FOR 999999;
COL bucketid FOR 99999999;
COL indexid FOR 999999;
COL ordering FOR 99999999;
COL index_type FOR A10;
COL keyid FOR 99999;
COL keytype FOR A10;
COL keyorder FOR 99999999;
COL valueid FOR 9999999;
COL source FOR A8;
COL partitioned FOR A11;
COL visibility FOR A10;
COL leaf_blocks FOR 999,999,990;
COL tablespace_name FOR A30;
COL created FOR A19;
COL kiev_created FOR A19;
COL db_created FOR A19;
COL matching_index FOR 9,999,999;
COL line FOR A300;
COL upper_table_name NOPRI;
COL upper_index_name NOPRI;
--
BREAK ON pdb_name DUPL SKIP PAGE ON upper_table_name DUPL SKIP PAGE ON upper_index_name DUPL SKIP 1;      
--
PRO
PRO KIEV/DB Index Compare Metadata (as of "&&kiev_metadata_date.")
PRO ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
SELECT pdb_name,
       owner,
       UPPER(table_name) AS upper_table_name,
       table_name,
       UPPER(index_name) AS upper_index_name,
       index_name,
       uniqueness,
       validation,
       fat_index,
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
       con_id,
       bucketid,
       indexid,
       ordering,
       index_type,
       keyid,
       keytype,
       keyorder,
       valueid,
       source,
       partitioned,
       kiev_created,
       db_created,
       visibility,
       leaf_blocks,
       tablespace_name,
       redundant_of,
       rename_as
  FROM &&cs_tools_schema..kiev_ind_columns_v
 WHERE &&cs_con_id. IN (1, con_id)
   AND '&&cs_con_name.' IN ('CDB$ROOT', pdb_name)
   AND UPPER(table_name) = UPPER(COALESCE('&&table_name.', table_name))
   AND UPPER(index_name) = UPPER(COALESCE('&&index_name.', index_name))
   AND '&&include_compare.' = 'Y'
   --AND ('&&include_compliant.' = 'Y' OR validation IN ('REDUNDANT INDEX', 'DEPRECATE INDEX', 'RENAME INDEX', 'MISING INDEX', 'EXTRA INDEX', 'MISING COLUMN(S)', 'EXTRA COLUMN(S)', 'MISALIGNED COLUMN(S)') OR fat_index IN ('SUPPER', 'LITTLE'))
   --AND ('&&include_compliant.' = 'Y' OR validation IN ('DEPRECATE INDEX', 'RENAME INDEX', 'MISING INDEX', 'EXTRA INDEX', 'MISING COLUMN(S)', 'EXTRA COLUMN(S)', 'MISALIGNED COLUMN(S)') OR fat_index IN ('SUPPER', 'LITTLE'))
   AND ('&&include_compliant.' = 'Y' OR validation IN ('DEPRECATE INDEX', 'RENAME INDEX', 'MISING INDEX', 'EXTRA INDEX', 'MISING COLUMN(S)', 'EXTRA COLUMN(S)', 'MISALIGNED COLUMN(S)') OR fat_index IN ('SUPPER'))
   AND index_name NOT LIKE 'BIN$%'
 ORDER BY
       UPPER(pdb_name),
       UPPER(owner),
       UPPER(table_name),
       UPPER(index_name),
       k_column_position NULLS LAST,
       d_column_position NULLS LAST
/
--
BREAK ON pdb_name DUPL SKIP PAGE ON upper_table_name DUPL SKIP PAGE ON upper_index_name DUPL SKIP 1; 
--
PRO
PRO KIEV Index Metadata (as of "&&kiev_metadata_date.")
PRO ~~~~~~~~~~~~~~~~~~~
SELECT pdb_name,
       owner,
       UPPER(table_name) AS upper_table_name,
       table_name,
       UPPER(index_name) AS upper_index_name,
       index_name,
       uniqueness,
       column_position,
       column_name,
       nullable,
       data_type,
       data_length,
       data_precision,
       data_scale,
       con_id,
       bucketid,
       indexid,
       ordering,
       index_type,
       keyid,
       keytype,
       keyorder,
       valueid,
       source,
       created,
       redundant_of
  FROM &&cs_tools_schema..kiev_ind_columns
 WHERE &&cs_con_id. IN (1, con_id)
   AND '&&cs_con_name.' IN ('CDB$ROOT', pdb_name)
   AND UPPER(table_name) = UPPER(COALESCE('&&table_name.', table_name))
   AND UPPER(index_name) = UPPER(COALESCE('&&index_name.', index_name))
   AND '&&include_kiev.' = 'Y'
   AND index_name NOT LIKE 'BIN$%'
 ORDER BY
       UPPER(pdb_name),
       UPPER(owner),
       UPPER(table_name),
       UPPER(index_name),
       column_position
/
--
BREAK ON pdb_name DUPL SKIP PAGE ON upper_table_name DUPL SKIP PAGE ON upper_index_name DUPL SKIP 1; 
--
PRO
PRO DB Index Metadata (as of "&&kiev_metadata_date.")
PRO ~~~~~~~~~~~~~~~~~
SELECT pdb_name,
       owner,
       UPPER(table_name) AS upper_table_name,
       table_name,
       UPPER(index_name) AS upper_index_name,
       index_name,
       uniqueness,
       column_position,
       column_name,
       nullable,
       avg_col_len,
       data_type,
       data_length,
       data_precision,
       data_scale,
       con_id,
       partitioned,
       visibility,
       leaf_blocks,
       created,
       tablespace_name,
       rename_as
  FROM &&cs_tools_schema..kiev_db_ind_columns
 WHERE &&cs_con_id. IN (1, con_id)
   AND '&&cs_con_name.' IN ('CDB$ROOT', pdb_name)
   AND UPPER(table_name) = UPPER(COALESCE('&&table_name.', table_name))
   AND UPPER(index_name) = UPPER(COALESCE('&&index_name.', index_name))
   AND '&&include_db.' = 'Y'
   AND index_name NOT LIKE 'BIN$%'
 ORDER BY
       UPPER(pdb_name),
       UPPER(owner),
       UPPER(table_name),
       UPPER(index_name),
       column_position
/
-- constants when executing as script
DEF auto_execute_script = '&&cs_file_name._DUMMY';
DEF pause_or_prompt = 'PAUSE';
DEF deprecate_index = 'Y';
DEF rename_index = 'Y';
DEF missing_index = 'Y';
DEF extra_index = 'Y';
DEF missing_colums = 'Y';
DEF extra_colums = 'Y';
DEF misaligned_colums = 'Y';
--
PRO
PRO Index fix DDL (as of "&&kiev_metadata_date.")
PRO ~~~~~~~~~~~~~
PRO see: &&cs_file_name._IMPLEMENTATION.sql
--
SET HEA OFF PAGES 0 SERVEROUT ON;
SPO &&cs_file_name._DUMMY.sql;
PRO REM I am a dummy!
SPO OFF;
PRO
PRO generating &&cs_file_name._IMPLEMENTATION.sql
PRO
SPO &&cs_file_name._IMPLEMENTATION.sql;
DECLARE
  l_created DATE;
  l_prior_pdb_name VARCHAR2(128) := '-666';
  l_statement VARCHAR2(528);
  l_count INTEGER := 0;
  l_count2 INTEGER := 0;
BEGIN
  SELECT created INTO l_created FROM dba_objects WHERE owner = UPPER('&&cs_tools_schema.') AND object_name = 'KIEV_IND_COLUMNS' AND object_type = 'TABLE';
  IF SYSDATE - l_created > 3 THEN
    raise_application_error(-20000, '*** KIEV_IND_COLUMNS is '||ROUND(SYSDATE - l_created, 1)||' days old! ***');
  END IF;
  --
  DBMS_OUTPUT.put_line('PRO 8< 8< 8< 8< 8< 8< 8< 8< 8< 8< 8< 8< 8< 8< 8< 8< 8< 8< 8< 8< 8< 8< 8< 8< 8< 8< 8< 8< 8< 8< 8< 8< 8< 8< 8< 8< 8< 8< 8< 8< 8< 8< ');
  DBMS_OUTPUT.put_line('SPO &&cs_file_name._IMPLEMENTATION.log;');
  DBMS_OUTPUT.put_line('PRO');
  --
  FOR i IN (SELECT pdb_name, owner, table_name, index_name, validation, fat_index,
                  NULLIF(MAX(uniqueness), 'NONUNIQUE') AS uniqueness,
                  MAX(rename_as) AS rename_as, 
                  MAX(visibility) AS visibility,
                  MAX(leaf_blocks) AS leaf_blocks,
                  MAX(tablespace_name) AS tablespace_name, 
                  LISTAGG(UPPER(column_name), ', ' ON OVERFLOW TRUNCATE) WITHIN GROUP (ORDER BY k_column_position) AS columns_list
              FROM &&cs_tools_schema..kiev_ind_columns_v
            WHERE &&cs_con_id. IN (1, con_id)
              AND '&&cs_con_name.' IN ('CDB$ROOT', pdb_name)
              AND UPPER(table_name) = UPPER(COALESCE('&&table_name.', table_name))
              AND UPPER(index_name) = UPPER(COALESCE('&&index_name.', index_name))
              AND '&&include_ddl.' = 'Y'
              --AND validation IN ('REDUNDANT INDEX', 'DEPRECATE INDEX', 'RENAME INDEX', 'MISING INDEX', 'EXTRA INDEX', 'MISING COLUMN(S)', 'EXTRA COLUMN(S)', 'MISALIGNED COLUMN(S)')
              AND validation IN ('DEPRECATE INDEX', 'RENAME INDEX', 'MISING INDEX', 'EXTRA INDEX', 'MISING COLUMN(S)', 'EXTRA COLUMN(S)', 'MISALIGNED COLUMN(S)')
              AND (
                      ('&&deprecate_index.' = 'Y'     AND validation  = 'DEPRECATE INDEX')      OR
                      ('&&rename_index.' = 'Y'        AND validation  = 'RENAME INDEX')         OR
                      ('&&missing_index.' = 'Y'       AND validation  = 'MISING INDEX')         OR
                      ('&&extra_index.' = 'Y'         AND validation  = 'EXTRA INDEX')          OR
                      ('&&missing_colums.' = 'Y'      AND validation  = 'MISING COLUMN(S)')     OR
                      ('&&extra_colums.' = 'Y'        AND validation  = 'EXTRA COLUMN(S)')      OR
                      ('&&misaligned_colums.' = 'Y'   AND validation  = 'MISALIGNED COLUMN(S)')
              )
              AND fat_index IN ('NO', 'LITTLE')
              AND NVL(partitioned, 'NO') = 'NO'
              AND NOT (pdb_name LIKE 'KAASCANARY%' AND table_name IN ('canary_complexBucket', 'canary_simpleBucket'))
              AND index_name NOT LIKE 'BIN$%'
            GROUP BY
                  pdb_name, owner, table_name, index_name, validation, fat_index
            ORDER BY
                  UPPER(pdb_name),
                  UPPER(owner),
                  UPPER(table_name),
                  CASE validation
                  WHEN 'EXTRA INDEX'          THEN 1
                  WHEN 'REDUNDANT INDEX'      THEN 2
                  WHEN 'DEPRECATE INDEX'      THEN 3
                  WHEN 'RENAME INDEX'         THEN 4
                  WHEN 'MISING COLUMN(S)'     THEN 5
                  WHEN 'EXTRA COLUMN(S)'      THEN 6
                  WHEN 'MISALIGNED COLUMN(S)' THEN 7
                  WHEN 'MISING INDEX'         THEN 8
                  END,
                  UPPER(index_name))
  LOOP
    l_count2 := l_count2 + 1;
    DBMS_OUTPUT.put_line('PRO');
    DBMS_OUTPUT.put_line('PRO');
    --
    IF i.pdb_name <> l_prior_pdb_name THEN
      l_count := 1;
      DBMS_OUTPUT.put_line('PRO ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~');
      DBMS_OUTPUT.put_line('PRO');
      DBMS_OUTPUT.put_line('PRO PDB NAME: '||i.pdb_name);
      DBMS_OUTPUT.put_line('PRO');
      DBMS_OUTPUT.put_line('PRO ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~');
      DBMS_OUTPUT.put_line('PRO');
      DBMS_OUTPUT.put_line('&&pause_or_prompt. hit "return" to continue');
      DBMS_OUTPUT.put_line('PRO');
      l_prior_pdb_name := i.pdb_name;
    ELSE
      l_count := l_count + 1;
      DBMS_OUTPUT.put_line('PRO sleep for &&sleep_seconds. seconds...');
      DBMS_OUTPUT.put_line('EXEC DBMS_LOCK.sleep(&&sleep_seconds.);');
    END IF;
    --
    DBMS_OUTPUT.put_line('PRO');
    DBMS_OUTPUT.put_line('PRO INDEX #'||l_count2||' (CDB). INDEX #'||l_count||' (PDB).'||i.pdb_name||' '||i.owner||' '||i.table_name||' '||i.index_name||' '||i.validation||' '||i.visibility||' BLOCKS:'||i.leaf_blocks||' FAT:'||i.fat_index||' '||i.rename_as||' ('||i.columns_list||')');
    DBMS_OUTPUT.put_line('PRO');
    DBMS_OUTPUT.put_line('ALTER SESSION SET CONTAINER = '||i.pdb_name||';');
    DBMS_OUTPUT.put_line('ALTER SESSION SET DDL_LOCK_TIMEOUT = 10;');
    DBMS_OUTPUT.put_line('SET ECHO ON FEED ON VER ON TIM ON TIMI ON SERVEROUT ON;');
    DBMS_OUTPUT.put_line('WHENEVER SQLERROR EXIT FAILURE;');
    DBMS_OUTPUT.put_line('DECLARE');
    DBMS_OUTPUT.put_line('already_indexed      EXCEPTION; PRAGMA EXCEPTION_INIT(already_indexed,      -01408); -- ORA-01408: ORA-01408: such column list already indexed'); -- expected when index is actually redundant (e.g. SEA KIEV01 IPAM idxSubnetParentId)
    DBMS_OUTPUT.put_line('table_does_not_exist EXCEPTION; PRAGMA EXCEPTION_INIT(table_does_not_exist, -00942); -- ORA-00942: table or view does not exist'); -- expected when pdb creates and drops table very often (e.g. ZRH KIEV02RG KMS_CP_SHARD1 esmpmdapyrqaa_hsmkeysKI1)
    DBMS_OUTPUT.put_line('BEGIN');
    --
    IF i.validation IN ('MISING COLUMN(S)', 'EXTRA COLUMN(S)', 'MISALIGNED COLUMN(S)', 'MISING INDEX') THEN
      IF i.fat_index = 'LITTLE' THEN DBMS_OUTPUT.put_line('--'); DBMS_OUTPUT.put_line('-- *** FAT INDEX TO BE CREATED WITH TABLE LOCK ***'); END IF;
      l_statement := 'CREATE '||i.uniqueness||' INDEX '||i.owner||'.'||SUBSTR(i.index_name, 1, 29)||'# ON '||i.owner||'.'||i.table_name||'('||i.columns_list||') ';
      IF i.tablespace_name IS NOT NULL THEN l_statement := l_statement||'TABLESPACE '||i.tablespace_name; END IF;
      IF NOT i.fat_index = 'LITTLE' THEN l_statement := l_statement||' ONLINE'; END IF;
      DBMS_OUTPUT.put_line('EXECUTE IMMEDIATE '''||l_statement||''';'); -- create new as <index_name>#
    END IF;
    --
    IF i.validation IN ('MISING COLUMN(S)', 'EXTRA COLUMN(S)', 'MISALIGNED COLUMN(S)') THEN
      l_statement := 'ALTER INDEX '||i.owner||'.'||i.index_name||' RENAME TO '||SUBSTR(i.index_name, 1, 29)||'$'; -- rename old to <index_name>$
      DBMS_OUTPUT.put_line('EXECUTE IMMEDIATE '''||l_statement||''';');
      IF i.uniqueness = 'UNIQUE' AND i.index_name LIKE '%PK' THEN
        l_statement := 'ALTER TABLE '||i.owner||'.'||i.table_name||' DROP PRIMARY KEY';
        DBMS_OUTPUT.put_line('EXECUTE IMMEDIATE '''||l_statement||''';');
      END IF;
    END IF;
    --
    IF i.validation IN ('MISING COLUMN(S)', 'EXTRA COLUMN(S)', 'MISALIGNED COLUMN(S)', 'MISING INDEX') THEN
      l_statement := 'ALTER INDEX '||i.owner||'.'||SUBSTR(i.index_name, 1, 29)||'#'||' RENAME TO '||i.index_name; -- rename new from <index_name># to <index_name>
      DBMS_OUTPUT.put_line('EXECUTE IMMEDIATE '''||l_statement||''';');
      IF i.uniqueness = 'UNIQUE' AND i.index_name LIKE '%PK' THEN
        l_statement := 'ALTER TABLE '||i.owner||'.'||i.table_name||' ADD PRIMARY KEY ('||i.columns_list||') USING INDEX '||i.owner||'.'||i.index_name;
        DBMS_OUTPUT.put_line('EXECUTE IMMEDIATE '''||l_statement||''';');
      END IF;
    END IF;
    --
    IF i.validation IN ('MISING COLUMN(S)', 'EXTRA COLUMN(S)', 'MISALIGNED COLUMN(S)') THEN
      IF '&&include_index_drop.' = 'Y' THEN
        l_statement := 'DROP INDEX '||i.owner||'.'||SUBSTR(i.index_name, 1, 29)||'$'; -- drop old <index_name>$
        DBMS_OUTPUT.put_line('EXECUTE IMMEDIATE '''||l_statement||''';');
      ELSE
        IF i.visibility = 'VISIBLE' THEN
          l_statement := 'ALTER INDEX '||i.owner||'.'||SUBSTR(i.index_name, 1, 29)||'$ INVISIBLE'; -- invisible old <index_name>$
          DBMS_OUTPUT.put_line('EXECUTE IMMEDIATE '''||l_statement||''';');
        END IF;
      END IF;
    END IF;
    --
    IF i.validation = 'RENAME INDEX' THEN
      l_statement := 'ALTER INDEX '||i.owner||'.'||i.index_name||' RENAME TO '||i.rename_as;
      DBMS_OUTPUT.put_line('EXECUTE IMMEDIATE '''||l_statement||''';');
      IF i.visibility = 'INVISIBLE' THEN
        l_statement := 'ALTER INDEX '||i.owner||'.'||i.rename_as||' VISIBLE';
        DBMS_OUTPUT.put_line('EXECUTE IMMEDIATE '''||l_statement||''';');
      END IF;
    END IF;
    --
    IF i.validation IN ('REDUNDANT INDEX', 'DEPRECATE INDEX', 'EXTRA INDEX') THEN
      IF '&&include_index_drop.' = 'Y' THEN
        l_statement := 'DROP INDEX '||i.owner||'.'||i.index_name;
        DBMS_OUTPUT.put_line('EXECUTE IMMEDIATE '''||l_statement||''';');
      ELSE
        IF i.visibility = 'VISIBLE' THEN
          l_statement := 'ALTER INDEX '||i.owner||'.'||i.index_name||' INVISIBLE';
          DBMS_OUTPUT.put_line('EXECUTE IMMEDIATE '''||l_statement||''';');
        END IF;
        l_statement := 'ALTER INDEX '||i.owner||'.'||i.index_name||' RENAME TO '||SUBSTR(i.index_name, 1, 29)||'_';
        DBMS_OUTPUT.put_line('EXECUTE IMMEDIATE '''||l_statement||''';');
      END IF;
    END IF;
    --
    DBMS_OUTPUT.put_line('EXCEPTION');
    DBMS_OUTPUT.put_line('WHEN already_indexed OR table_does_not_exist THEN DBMS_OUTPUT.put_line(SQLERRM);');
    DBMS_OUTPUT.put_line('END;');
    DBMS_OUTPUT.put_line('/');
    DBMS_OUTPUT.put_line('WHENEVER SQLERROR CONTINUE;');
  END LOOP;
  --
  DBMS_OUTPUT.put_line('PRO');
  DBMS_OUTPUT.put_line('PRO log: &&cs_file_name._IMPLEMENTATION.log');
  DBMS_OUTPUT.put_line('SPO OFF;');
  --
  IF '&&cs_con_name.' = 'CDB$ROOT' THEN
    DBMS_OUTPUT.put_line('@@cs_internal/&&cs_set_container_to_cdb_root.');
  END IF;
  --
  DBMS_OUTPUT.put_line('PRO');
  DBMS_OUTPUT.put_line('PRO Done!');
  DBMS_OUTPUT.put_line('PRO');
  DBMS_OUTPUT.put_line('PRO 8< 8< 8< 8< 8< 8< 8< 8< 8< 8< 8< 8< 8< 8< 8< 8< 8< 8< 8< 8< 8< 8< 8< 8< 8< 8< 8< 8< 8< 8< 8< 8< 8< 8< 8< 8< 8< 8< 8< 8< 8< 8< ');
END;
/
SPO OFF;
SET HEA ON PAGES 100 SERVEROUT OFF;
SPO &&cs_file_name..txt APP;
--
PRO
PRO SQL> @&&cs_script_name..sql "&&table_name." "&&index_name." "&&include_compare." "&&include_compliant." "&&include_kiev." "&&include_db." "&&include_ddl" "&&include_index_drop." "&&sleep_seconds."
--
PRO
PRO *****************************************
PRO *
PRO * To fix indexes:
PRO * 1. Verify there are no long pending transactions: cs_sessions.sql
PRO * 2. Begin a blackout: cs_blackout_begin.sql
PRO * 3. Clean interrupted Table Redefinition: cs_drop_redef_table.sql
PRO * 4. Verify and implement fixes for known WF Execution Plans: cs_sprf_verify_wf_flash.sql and cs_sprf_implement_wf.sql
PRO * 5. Implement indexes changes &&cs_file_name._IMPLEMENTATION.sql
PRO *
PRO *****************************************
PRO
--
@@cs_internal/cs_spool_tail.sql
--
@@cs_internal/&&cs_set_container_to_curr_pdb.
--
@@cs_internal/cs_undef.sql
@@cs_internal/cs_reset.sql
--
@@cs_internal/cs_kiev_meta_warn.sql
--
@@&&auto_execute_script..sql
--