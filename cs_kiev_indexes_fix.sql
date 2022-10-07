----------------------------------------------------------------------------------------
--
-- File name:   cs_kiev_indexes_fix.sql
--
-- Purpose:     KIEV Indexes Inventory Fix Script
--
-- Author:      Carlos Sierra
--
-- Version:     2021/09/17
--
-- Usage:       Execute connected to CDB or PDB.
--
--              Specify search scope when requested.
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @cs_kiev_indexes_fix.sql
--
-- Notes:       cs_kiev_indexes_metadata.sql (former OEM JOB IOD_IMMEDIATE_KIEV_INDEXES.sql) should be executed in advance
--
---------------------------------------------------------------------------------------
--
WHENEVER OSERROR CONTINUE;
WHENEVER SQLERROR EXIT FAILURE;
--
COL cs_con_name NEW_V cs_con_name FOR A30 NOPRI;
COL cs_con_id NEW_V cs_con_id FOR A4 NOPRI;
SELECT SYS_CONTEXT('USERENV', 'CON_NAME') AS cs_con_name, SYS_CONTEXT('USERENV', 'CON_ID') AS cs_con_id FROM DUAL
/
-- constants
DEF cs_tools_schema = 'C##IOD';
DEF cs_file_name = '/tmp/cs_kiev_indexes_fix';
DEF table_name = '';
DEF index_name = '';
DEF include_ddl = 'Y';
DEF include_index_drop = 'Y';
-- constants when executing as script
DEF sleep_seconds = '2';
DEF auto_execute_script = '&&cs_file_name._DUMMY';
DEF pause_or_prompt = 'PAUSE';
DEF deprecate_index = 'Y';
DEF rename_index = 'Y';
DEF missing_index = 'Y';
DEF extra_index = 'Y';
DEF missing_colums = 'Y';
DEF extra_colums = 'Y';
DEF misaligned_colums = 'Y';
-- constants when executing as job, uncomment this section below
-- DEF sleep_seconds = '5';
-- DEF auto_execute_script = '&&cs_file_name._IMPLEMENTATION';
-- DEF pause_or_prompt = 'PROMPT';
-- DEF deprecate_index = 'N';
-- DEF rename_index = 'N';
-- DEF extra_index = 'N';
-- DEF missing_colums = 'N';
-- DEF extra_colums = 'N';
-- DEF misaligned_colums = 'N';
--
@@cs_internal/&&cs_set_container_to_cdb_root.
--
SET TERM ON HEA ON LIN 2490 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF LONG 240000 LONGC 2400 NUM 20 SERVEROUT OFF;
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
PRO
PRO Review and Execute: &&cs_file_name._IMPLEMENTATION.sql
PRO 
@@cs_internal/&&cs_set_container_to_curr_pdb.
--
@@&&auto_execute_script..sql
--