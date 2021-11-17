COL owner FOR A30 TRUNC;
COL table_name FOR A30 TRUNC;
COL tablespace_name FOR A30 TRUNC;
COL column_name FOR A30 TRUNC;
COL segment_name FOR A30 TRUNC;
COL index_name FOR A30 TRUNC;
COL encrypt FOR A8;
COL compression FOR A12;
COL deduplication FOR A14;
COL in_row FOR A7;
COL partitioned FOR A12;
COL securefile FOR A11;
--
SELECT l.owner,
       l.table_name,
       l.tablespace_name,
       l.column_name,
       l.segment_name,
       l.index_name,
       l.cache,
       l.encrypt,
       l.compression,
       l.deduplication,
       l.in_row,
       l.partitioned,
       l.securefile
  FROM dba_lobs l
 WHERE l.table_name = COALESCE('&&specific_table.', l.table_name)
 ORDER BY
       l.owner,
       l.table_name,
       l.tablespace_name,
       l.column_name
/

