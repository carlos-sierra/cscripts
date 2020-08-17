--DEF sql_id = '71q8v33pkskus';
DEF sql_id = '3hahc9c3zmc6d';
--DEF sql_id = 'cbum4h6kxwpqy';
--
DEF sql_text_piece = '';
COL sql_text_piece NEW_V sql_text_piece FOR A100;
SELECT SUBSTR(sql_text, 1, INSTR(sql_text, '*/') + 1) AS sql_text_piece
  FROM v$sql
 WHERE sql_id = '&&sql_id.'
   AND sql_text LIKE '/*%*/%'
   AND ROWNUM = 1
/
--
-- list all hot cursors
SELECT name,
       property AS hot_flag,
       status,
       lock_mode,
       pin_mode,
       hash_value,
       full_hash_value,
       kept,
       COUNT(*) AS cnt,
       COUNT(DISTINCT addr) AS addresses,
       SUM(sharable_mem) AS sharable_mem,
       SUM(loads) AS loads,
       SUM(executions) AS executions,
       SUM(locks) AS locks,
       SUM(pins) AS pins,
       SUM(child_latch) AS latches,
       SUM(invalidations) AS invalidations,
       SUM(locked_total) AS locked_total,
       SUM(pinned_total) AS pinned_total,
       MIN(timestamp) AS min_timestamp,
       MAX(timestamp) AS max_timestamp,
       COUNT(DISTINCT con_id) AS pdbs,
       MIN(con_id) AS min_con_id,
       MAX(con_id) AS max_con_id
  FROM v$db_object_cache
 WHERE property IS NOT NULL
   AND namespace = 'SQL AREA'
   AND type = 'CURSOR'
 GROUP BY
       name,
       property,
       status,
       lock_mode,
       pin_mode,
       hash_value,
       full_hash_value,
       kept
 ORDER BY
       name,
       property,
       status,
       lock_mode,
       pin_mode,
       hash_value,
       full_hash_value,
       kept
/
@pr
--
-- list object cache for selected sql_id
SELECT name,
       property AS hot_flag,
       status,
       lock_mode,
       pin_mode,
       hash_value,
       full_hash_value,
       kept,
       COUNT(*) AS cnt,
       COUNT(DISTINCT addr) AS addresses,
       SUM(sharable_mem) AS sharable_mem,
       SUM(loads) AS loads,
       SUM(executions) AS executions,
       SUM(locks) AS locks,
       SUM(pins) AS pins,
       SUM(child_latch) AS latches,
       SUM(invalidations) AS invalidations,
       SUM(locked_total) AS locked_total,
       SUM(pinned_total) AS pinned_total,
       MIN(timestamp) AS min_timestamp,
       MAX(timestamp) AS max_timestamp,
       COUNT(DISTINCT con_id) AS pdbs,
       MIN(con_id) AS min_con_id,
       MAX(con_id) AS max_con_id
  FROM v$db_object_cache
 WHERE '&&sql_text_piece.' IS NOT NULL
   AND name LIKE '&&sql_text_piece.%'
   AND namespace = 'SQL AREA'
   AND type = 'CURSOR'
 GROUP BY
       name,
       property,
       status,
       lock_mode,
       pin_mode,
       hash_value,
       full_hash_value,
       kept
 ORDER BY
       name,
       property,
       status,
       lock_mode,
       pin_mode,
       hash_value,
       full_hash_value,
       kept
/
@pr
--
-- determine if this sql has already been marked as hot
DEF hottie_count = '';
COL hottie_count NEW_V hottie_count FOR A12;
SELECT TO_CHAR(COUNT(*)) AS hottie_count
  FROM v$db_object_cache
 WHERE '&&sql_text_piece.' IS NOT NULL
   AND name LIKE '&&sql_text_piece.%'
   AND namespace = 'SQL AREA'
   AND type = 'CURSOR'
   AND property IS NOT NULL -- already hot!
/
--
-- get hash onlly if sql has not been marked as hot
DEF full_hash_value = '';
COL full_hash_value NEW_V full_hash_value FOR A64;
SELECT DISTINCT TO_CHAR(full_hash_value) AS full_hash_value
  FROM v$db_object_cache
 WHERE '&&sql_text_piece.' IS NOT NULL
   AND name LIKE '&&sql_text_piece.%'
   AND namespace = 'SQL AREA'
   AND type = 'CURSOR'
   AND property IS NULL -- not hot!
   AND TO_NUMBER('&&hottie_count.') = 0 -- to be sure there are no cursors hot and some not hot
/
--
-- mark cursor hot
-- note: regardless if you execute this on PDB, the mark goes to CDB level. thus, if same sql is executed from several PDBs, all get the cursor marked as hot
SET SERVEROUT ON;
BEGIN
  IF TO_NUMBER('&&hottie_count.') = 0 AND LENGTH('&&full_hash_value.') = 32 THEN
    FOR i IN (
      SELECT DISTINCT TO_CHAR(full_hash_value) AS full_hash_value
        FROM v$db_object_cache
       WHERE '&&sql_text_piece.' IS NOT NULL
         AND name LIKE '&&sql_text_piece.%'
         AND namespace = 'SQL AREA'
         AND type = 'CURSOR'
         AND property IS NULL -- not hot!
         AND TO_NUMBER('&&hottie_count.') = 0 -- to be sure there are no cursors hot and some not hot    
    )
    LOOP -- there could be more than one full_hash_value
      DBMS_OUTPUT.put_line('*** MarkHot: '||i.full_hash_value);
      DBMS_SHARED_POOL.markhot(hash => i.full_hash_value, namespace => 0);
    END LOOP;
  END IF;
END;
/
SET SERVEROUT OFF;
--
EXEC DBMS_LOCK.sleep(60);
--
--
-- list object cache for selected sql_id
SELECT name,
       property AS hot_flag,
       status,
       lock_mode,
       pin_mode,
       hash_value,
       full_hash_value,
       kept,
       COUNT(*) AS cnt,
       COUNT(DISTINCT addr) AS addresses,
       SUM(sharable_mem) AS sharable_mem,
       SUM(loads) AS loads,
       SUM(executions) AS executions,
       SUM(locks) AS locks,
       SUM(pins) AS pins,
       SUM(child_latch) AS latches,
       SUM(invalidations) AS invalidations,
       SUM(locked_total) AS locked_total,
       SUM(pinned_total) AS pinned_total,
       MIN(timestamp) AS min_timestamp,
       MAX(timestamp) AS max_timestamp,
       COUNT(DISTINCT con_id) AS pdbs,
       MIN(con_id) AS min_con_id,
       MAX(con_id) AS max_con_id
  FROM v$db_object_cache
 WHERE '&&sql_text_piece.' IS NOT NULL
   AND name LIKE '&&sql_text_piece.%'
   AND namespace = 'SQL AREA'
   AND type = 'CURSOR'
 GROUP BY
       name,
       property,
       status,
       lock_mode,
       pin_mode,
       hash_value,
       full_hash_value,
       kept
 ORDER BY
       name,
       property,
       status,
       lock_mode,
       pin_mode,
       hash_value,
       full_hash_value,
       kept
/
@pr
--
-- list all hot cursors
SELECT name,
       property AS hot_flag,
       status,
       lock_mode,
       pin_mode,
       hash_value,
       full_hash_value,
       kept,
       COUNT(*) AS cnt,
       COUNT(DISTINCT addr) AS addresses,
       SUM(sharable_mem) AS sharable_mem,
       SUM(loads) AS loads,
       SUM(executions) AS executions,
       SUM(locks) AS locks,
       SUM(pins) AS pins,
       SUM(child_latch) AS latches,
       SUM(invalidations) AS invalidations,
       SUM(locked_total) AS locked_total,
       SUM(pinned_total) AS pinned_total,
       MIN(timestamp) AS min_timestamp,
       MAX(timestamp) AS max_timestamp,
       COUNT(DISTINCT con_id) AS pdbs,
       MIN(con_id) AS min_con_id,
       MAX(con_id) AS max_con_id
  FROM v$db_object_cache
 WHERE property IS NOT NULL
   AND namespace = 'SQL AREA'
   AND type = 'CURSOR'
 GROUP BY
       name,
       property,
       status,
       lock_mode,
       pin_mode,
       hash_value,
       full_hash_value,
       kept
 ORDER BY
       name,
       property,
       status,
       lock_mode,
       pin_mode,
       hash_value,
       full_hash_value,
       kept
/
@pr
--
