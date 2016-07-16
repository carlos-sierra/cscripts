PRO Lists rows larger than free space on block
PRO

ACC table_owner PROMPT 'Table Owner: '
ACC table_name PROMPT 'Table Name: '
ACC partition_name PROMPT 'Partition Name: '

DEF db_block_size = ''
COL db_block_size NEW_V db_block_size NOPRI
SELECT value db_block_size FROM v$parameter WHERE name = 'db_block_size'
/

DEF pct_free = ''
COL pct_free NEW_V pct_free NOPRI
SELECT TO_CHAR(pct_free) pct_free FROM dba_tables WHERE owner = UPPER('&&table_owner.') AND table_name = UPPER('&&table_name.')
/
SELECT TO_CHAR(pct_free) pct_free FROM dba_tab_partitions WHERE table_owner = UPPER('&&table_owner.') AND table_name = UPPER('&&table_name.') AND partition_name = UPPER('&&partition_name.')
/

DEF partition_clause = ''
COL partition_clause NEW_V partition_clause NOPRI
SELECT CASE WHEN '&&partition_name.' IS NOT NULL THEN ' PARTITION(&&partition_name.)' END partition_clause FROM DUAL
/

DEF total_count = ''
COL total_count NEW_V total_count NOPRI
SELECT TO_CHAR(COUNT(*)) total_count FROM &&table_owner..&&table_name.&&partition_clause.
/

SET FEED OFF HEA OFF NEWP NONE VER OFF ECHO OFF TIM OFF TIMI OFF SQLBL ON

SPO look_chained.sql
PRO SPO chained_rows_&&table_owner._&&table_name..txt
PRO
PRO PRO &&table_owner..&&table_name..&&partition_clause.
PRO PRO total rows: &&total_count.
PRO PRO pct_free: &&pct_free.
PRO PRO db_block_size: &&db_block_size.
PRO
PRO SELECT ROWNUM, v.row_id, v.row_length FROM (
PRO SELECT ROWID row_id, 3
SELECT '+ 1 + NVL(VSIZE('||column_name||'), 0)'
  FROM dba_tab_cols
 WHERE owner = UPPER('&&table_owner.')
   AND table_name = UPPER('&&table_name.')
 ORDER BY
       column_id
/
PRO row_length
PRO FROM &&table_owner..&&table_name.&&partition_clause.
PRO ORDER BY 2 DESC, 1 ) v
PRO WHERE v.row_length > &&db_block_size. * ( 1 - (&&pct_free. / 100) )
PRO /
PRO
PRO SPO OFF;
SPO OFF;

@look_chained.sql

PRO
PRO chained_rows_&&table_owner._&&table_name..txt was generated

CL COL