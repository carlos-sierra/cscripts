SET SERVEROUT ON;
ACC index_name PROMPT 'Index Name: ';
DECLARE
  l_db_block_size NUMBER;
  l_owner dba_indexes.owner%TYPE;
  l_index_name dba_indexes.index_name%TYPE;
  l_leaf_blocks NUMBER;
  l_used_bytes NUMBER;
  l_alloc_bytes NUMBER;
BEGIN
  SELECT owner, index_name, leaf_blocks INTO l_owner, l_index_name, l_leaf_blocks FROM dba_indexes WHERE index_name LIKE UPPER(TRIM('&index_name.'));    
  SELECT TO_NUMBER(value) INTO l_db_block_size FROM v$parameter WHERE name = 'db_block_size';
  DBMS_SPACE.CREATE_INDEX_COST(REPLACE(DBMS_METADATA.GET_DDL('INDEX',l_index_name,l_owner),CHR(10),CHR(32)),l_used_bytes,l_alloc_bytes);
  DBMS_OUTPUT.PUT_LINE('| '||TO_CHAR(ROUND(l_leaf_blocks * l_db_block_size / POWER(2,20),1), '9,999,990.0')||' MB (current)');
  DBMS_OUTPUT.PUT_LINE('| '||TO_CHAR(ROUND(l_alloc_bytes / POWER(2,20),1), '9,999,990.0')||' MB (if rebuilt)');
  DBMS_OUTPUT.PUT_LINE('| '||TO_CHAR(ROUND(((l_leaf_blocks * l_db_block_size) - l_alloc_bytes) / POWER(2,20),1), '9,999,990.0')||' MB (overhead)');
END;
/
