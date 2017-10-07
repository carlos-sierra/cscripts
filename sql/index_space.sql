VAR index_size_before NUMBER;
VAR index_ddl CLOB;
BEGIN
SELECT i.leaf_blocks * TO_NUMBER(p.value),
       REPLACE(DBMS_METADATA.GET_DDL('INDEX', i.index_name, i.owner), CHR(10), CHR(32)) 
  INTO :index_size_before, :index_ddl
  FROM dba_indexes i, v$parameter p
 WHERE i.index_name = UPPER('&&index_name.') AND p.name = 'db_block_size';
END;
/
VAR l_used_bytes NUMBER;
VAR l_alloc_bytes NUMBER;
EXEC DBMS_SPACE.CREATE_INDEX_COST(:index_ddl, :l_used_bytes, :l_alloc_bytes);
SELECT :index_size_before size_before, :l_alloc_bytes size_after, 
TO_CHAR(ROUND(100 * (:index_size_before - :l_alloc_bytes) / :index_size_before, 1), '990.0')||'% ' savings
FROM dual
/
