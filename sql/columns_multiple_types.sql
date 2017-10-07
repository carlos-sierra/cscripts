SPO columns_multiple_types.txt;

WITH 
columns AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       column_name, COUNT(*) typ_cnt, data_type,  
       MIN(owner||'.'||table_name) min_table_name, 
       MAX(owner||'.'||table_name) max_table_name
  FROM dba_tab_columns
 WHERE owner NOT IN ('ANONYMOUS','APEX_030200','APEX_040000','APEX_SSO','APPQOSSYS','CTXSYS','DBSNMP','DIP','EXFSYS','FLOWS_FILES','MDSYS','OLAPSYS','ORACLE_OCM','ORDDATA','ORDPLUGINS','ORDSYS','OUTLN','OWBSYS')
   AND owner NOT IN ('SI_INFORMTN_SCHEMA','SQLTXADMIN','SQLTXPLAIN','SYS','SYSMAN','SYSTEM','TRCANLZR','WMSYS','XDB','XS$NULL','PERFSTAT','STDBYPERF')
   AND data_type != 'UNDEFINED'
 GROUP BY
       column_name, data_type
),
more_than_one_type AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       column_name, SUM(typ_cnt) col_cnt
  FROM columns
 GROUP BY
       column_name
HAVING COUNT(*) > 1
)
SELECT /*+ NO_MERGE */
       m.col_cnt, c.*
  FROM columns c,
       more_than_one_type m
 WHERE m.column_name = c.column_name
 ORDER BY
       m.col_cnt DESC,
       c.column_name,
       c.typ_cnt DESC,
       c.data_type
/

SPO OFF;