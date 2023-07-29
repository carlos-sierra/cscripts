SET HEA OFF PAGES 0;
CLEAR COLUMNS;
SPO /tmp/cs_driver_&&cs_mysid..sql;
--
PRO PRO
PRO PRO TOP_SECONDARY_KEYS when table has less than &&cs_num_rows_limit_display. rows (using approximate counts after 10M rows)
PRO PRO ~~~~~~~~~~~~~~~~~~
--
SELECT /* cs_top_secondary_keys_table.sql kiev */
       'PRO'||CHR(10)||
       'PRO TABLE  : '||i.table_owner||'.'||i.table_name||CHR(10)||
       'PRO INDEX  : '||i.owner||'.'||i.index_name||CHR(10)||
       'PRO COLUMNS: ('||LISTAGG(c.column_name, ', ' ON OVERFLOW TRUNCATE) WITHIN GROUP (ORDER BY c.column_position)||')'||CHR(10)||
       'PRO ~~~~~~~'||CHR(10)||
       'WITH top AS (SELECT '||CASE WHEN t.num_rows > 1e9 THEN '1000' WHEN t.num_rows > 1e8 THEN '100' WHEN t.num_rows > 1e7 THEN '10' ELSE '1' END||' * COUNT(*) AS VERSIONS, ROUND(100 * COUNT(*) / SUM(COUNT(*)) OVER (), 6) AS ROWS_PERCENT,'||CHR(10)||
       'SUM(CASE t.KIEVLIVE WHEN ''Y'' THEN '||CASE WHEN t.num_rows > 1e9 THEN '1000' WHEN t.num_rows > 1e8 THEN '100' WHEN t.num_rows > 1e7 THEN '10' ELSE '1' END||' ELSE 0 END) AS KIEVLIVE_Y, SUM(CASE t.KIEVLIVE WHEN ''N'' THEN '||CASE WHEN t.num_rows > 1e9 THEN '1000' WHEN t.num_rows > 1e8 THEN '100' WHEN t.num_rows > 1e7 THEN '10' ELSE '1' END||' ELSE 0 END) AS KIEVLIVE_N, '||CHR(10)||
       'MIN(t.KIEVTXNID) AS MIN_KIEVTXNID, MAX(t.KIEVTXNID) AS MAX_KIEVTXNID, '||CHR(10)||
       LISTAGG('''"'||LOWER(c.column_name)||'": "''||t.'||LOWER(c.column_name), '||''",''||CHR(10)||' ON OVERFLOW TRUNCATE) WITHIN GROUP (ORDER BY c.column_position)||'||''"'' AS KEY_VALUE '||CHR(10)||
       'FROM '||i.table_owner||'.'||i.table_name||CHR(10)||
       CASE WHEN t.num_rows > 1e9 THEN ' SAMPLE BLOCK (0.1) ' WHEN t.num_rows > 1e8 THEN ' SAMPLE BLOCK (1) ' WHEN t.num_rows > 1e7 THEN ' SAMPLE BLOCK (10) ' END||' t GROUP BY '||CHR(10)||
       LISTAGG('t.'||c.column_name, ', ' ON OVERFLOW TRUNCATE) WITHIN GROUP (ORDER BY c.column_position)||CHR(10)||
       'ORDER BY 1 DESC, 2 DESC, 3 DESC, 4 DESC, 5, 6, '||LISTAGG('t.'||c.column_name, ', ' ON OVERFLOW TRUNCATE) WITHIN GROUP (ORDER BY c.column_position)||' FETCH FIRST 20 ROWS ONLY)'||CHR(10)||
       'SELECT t.VERSIONS, t.ROWS_PERCENT, t.KIEVLIVE_Y, t.KIEVLIVE_N, t.MIN_KIEVTXNID, t.MAX_KIEVTXNID,'||CHR(10)||
       '(SELECT MIN(k.BEGINTIME) FROM '||i.owner||'.KIEVTRANSACTIONS k WHERE k.COMMITTRANSACTIONID = t.MIN_KIEVTXNID) AS MIN_BEGINTIME,'||CHR(10)||
       '(SELECT MAX(k.BEGINTIME) FROM '||i.owner||'.KIEVTRANSACTIONS k WHERE k.COMMITTRANSACTIONID = t.MAX_KIEVTXNID) AS MAX_BEGINTIME,'||CHR(10)||
      --  '(SELECT MAX(k.BEGINTIME) FROM '||i.owner||'.KIEVTRANSACTIONS k WHERE k.COMMITTRANSACTIONID = t.MAX_KIEVTXNID) - (SELECT MIN(k.BEGINTIME) FROM '||i.owner||'.KIEVTRANSACTIONS k WHERE k.COMMITTRANSACTIONID = t.MIN_KIEVTXNID) AS TIME_INTERVAL,'||CHR(10)||
      --  'TRIM(TRIM(LEADING ''0'' FROM REGEXP_SUBSTR((SELECT MAX(k.BEGINTIME) FROM '||i.owner||'.KIEVTRANSACTIONS k WHERE k.COMMITTRANSACTIONID = t.MAX_KIEVTXNID) - (SELECT MIN(k.BEGINTIME) FROM '||i.owner||'.KIEVTRANSACTIONS k WHERE k.COMMITTRANSACTIONID = t.MIN_KIEVTXNID), ''\d+ \d{2}\:\d{2}\:\d{2}\.\d{3}''))) AS TIME_INTERVAL,'||CHR(10)||
       'REGEXP_REPLACE(REGEXP_REPLACE((SELECT MAX(k.BEGINTIME) FROM '||i.owner||'.KIEVTRANSACTIONS k WHERE k.COMMITTRANSACTIONID = t.MAX_KIEVTXNID) - (SELECT MIN(k.BEGINTIME) FROM '||i.owner||'.KIEVTRANSACTIONS k WHERE k.COMMITTRANSACTIONID = t.MIN_KIEVTXNID), ''\+0{1,8}'', ''+''), ''000'') AS TIME_INTERVAL,'||CHR(10)||
       't.KEY_VALUE, ORA_HASH(SUBSTR(t.KEY_VALUE, 1, 4000)) AS KEY_HASH'||CHR(10)||
       'FROM top t;'
       AS dynamic_sql
  FROM dba_tables t,
       dba_users u,
       dba_indexes i,
       dba_ind_columns c
 WHERE '&&cs_kiev_version.' <> 'NOT_KIEV' -- this script ONLY executes on KIEV databases
   AND t.owner = '&&table_owner.'
   AND t.table_name = '&&table_name.'
   AND t.table_name NOT LIKE 'KIEV%' -- excludes KIEV internal tables
   AND t.num_rows < &&cs_num_rows_limit_number.
   AND u.username = t.owner
   AND u.oracle_maintained = 'N'
   AND u.common = 'NO'
   AND i.table_owner = t.owner
   AND i.table_name = t.table_name
   AND i.index_type = 'NORMAL'
   AND NOT (i.uniqueness = 'UNIQUE' AND i.index_name LIKE '%PK%') -- excludes PK since it is reported under cs_top_primary_keys_table.sql
   AND i.owner = t.owner
   AND c.table_owner = i.table_owner
   AND c.table_name = i.table_name
   AND c.index_owner = i.owner
   AND c.index_name = i.index_name
   AND c.column_name <> 'KIEVTXNID'
   AND c.column_name <> 'KIEVLIVE'
 GROUP BY
       i.table_owner,
       i.table_name,
       t.num_rows,
       i.owner,
       i.index_name
 ORDER BY
       i.table_owner,
       i.table_name,
       i.owner,
       i.index_name
/
--
SELECT /* cs_top_secondary_keys_table.sql nonkiev */
       'PRO'||CHR(10)||
       'PRO TABLE  : '||i.table_owner||'.'||i.table_name||CHR(10)||
       'PRO INDEX  : '||i.owner||'.'||i.index_name||CHR(10)||
       'PRO COLUMNS: ('||LISTAGG(c.column_name, ', ' ON OVERFLOW TRUNCATE) WITHIN GROUP (ORDER BY c.column_position)||')'||CHR(10)||
       'PRO ~~~~~~~'||CHR(10)||
       'WITH top AS (SELECT '||CASE WHEN t.num_rows > 1e9 THEN '1000' WHEN t.num_rows > 1e8 THEN '100' WHEN t.num_rows > 1e7 THEN '10' ELSE '1' END||' * COUNT(*) AS NUM_ROWS, ROUND(100 * COUNT(*) / SUM(COUNT(*)) OVER (), 6) AS ROWS_PERCENT,'||CHR(10)||
       LISTAGG('''"'||LOWER(c.column_name)||'": "''||t.'||LOWER(c.column_name), '||''",''||CHR(10)||' ON OVERFLOW TRUNCATE) WITHIN GROUP (ORDER BY c.column_position)||'||''"'' AS KEY_VALUE '||CHR(10)||
       'FROM '||i.table_owner||'.'||i.table_name||CHR(10)||
       CASE WHEN t.num_rows > 1e9 THEN ' SAMPLE BLOCK (0.1) ' WHEN t.num_rows > 1e8 THEN ' SAMPLE BLOCK (1) ' WHEN t.num_rows > 1e7 THEN ' SAMPLE BLOCK (10) ' END||' t GROUP BY '||CHR(10)||
       LISTAGG('t.'||c.column_name, ', ' ON OVERFLOW TRUNCATE) WITHIN GROUP (ORDER BY c.column_position)||CHR(10)||
       'ORDER BY 1 DESC, 2 DESC, '||LISTAGG('t.'||c.column_name, ', ' ON OVERFLOW TRUNCATE) WITHIN GROUP (ORDER BY c.column_position)||' FETCH FIRST 20 ROWS ONLY)'||CHR(10)||
       'SELECT t.NUM_ROWS, t.ROWS_PERCENT, '||CHR(10)||
       't.KEY_VALUE, ORA_HASH(SUBSTR(t.KEY_VALUE, 1, 4000)) AS KEY_HASH'||CHR(10)||
       'FROM top t;'
       AS dynamic_sql
  FROM dba_tables t,
       dba_indexes i,
       dba_ind_columns c
 WHERE '&&cs_kiev_version.' = 'NOT_KIEV' -- this script ONLY executes on NONKIEV databases
   AND t.owner = '&&table_owner.'
   AND t.table_name = '&&table_name.'
   AND i.table_owner = t.owner
   AND i.table_name = t.table_name
   AND i.index_type = 'NORMAL'
   AND i.uniqueness = 'NONUNIQUE' 
   AND i.owner = t.owner
   AND c.table_owner = i.table_owner
   AND c.table_name = i.table_name
   AND c.index_owner = i.owner
   AND c.index_name = i.index_name
 GROUP BY
       i.table_owner,
       i.table_name,
       t.num_rows,
       i.owner,
       i.index_name
 ORDER BY
       i.table_owner,
       i.table_name,
       i.owner,
       i.index_name
/
--
SPO OFF;
SET HEA ON PAGES 100;
--
COL VERSIONS FOR 999,999,990;
COL NUM_ROWS FOR 999,999,990;
COL ROWS_PERCENT FOR 990.000000;
COL KIEVLIVE_Y FOR 999,999,990;
COL KIEVLIVE_N FOR 999,999,990;
COL MIN_KIEVTXNID FOR 99999999999990;
COL MAX_KIEVTXNID FOR 99999999999990;
COL MIN_BEGINTIME FOR A26;
COL MAX_BEGINTIME FOR A26;
COL TIME_INTERVAL FOR A20;
COL KEY_VALUE FOR A200;
COL KEY_HASH FOR 0000000000;
--
BREAK ON REPORT;
COMPUTE SUM OF VERSIONS NUM_ROWS ROWS_PERCENT KIEVLIVE_Y KIEVLIVE_N ON REPORT;
--
SPO &&cs_file_name..txt APP
@/tmp/cs_driver_&&cs_mysid..sql;
--
CLEAR BREAK COMPUTE COLUMNS;