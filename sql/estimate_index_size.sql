----------------------------------------------------------------------------------------
--
-- File name:   estimate_index_size.sql
--
-- Purpose:     Reports Indexes with an Actual size > Estimated size for over 1 MB
--
-- Author:      Carlos Sierra
--
-- Version:     2014/07/18
--
-- Description: Script to very quickly and cheaply estimate the size of an index if it 
--              were to be rebuilt. It uses EXPLAIN PLAN FOR CREATE INDEX technique.
--              It can be used on a single index, or all the indexes on a table, or
--              a particular application schema, or all application schemas. It does not
--              lock indexes and only updates the plan_table, which is usually a global
--              temporary table.
-- 
-- Usage:       Connect to SQL*Plus as SYS or DBA account and execute without parameters.
--              It will ask for optional schema owner, table name and index name. If all
--              3 are given null values then it acts on all application schemas. It
--              generates a simple text report with the indexes having an estimated size
--              of at least 1 MB over their actual size.
--
-- Example:     @estimate_index_size.sql
--
-- Notes:       Developed and tested on 11.2.0.3.
--
--              Inspired on blog posts from Richard Foote and Connor MacDonald:
--              http://richardfoote.wordpress.com/2014/04/24/estimate-index-size-with-explain-plan-i-cant-explain/#comment-116966
--              http://connormcdonald.wordpress.com/2012/05/30/index-size/
--
--              If considering index rebuilds based on the output of this script, read
--              first Richard Foote's numerous blog postings about this topic. Bottom
--              line: there are only a few cases where you actually need to manually
--              rebuild an index.
--
--              This method to estimated size of an index is far from perfect, please
--              scrutinize this script before using it. You may also want to read
--              Oracle MOS notes: 989093.1 and 989186.1 on this topic.
--
---------------------------------------------------------------------------------------
--
SPO estimate_index_size.txt;
UNDEF owner table_name index_name exclusion_list exclusion_list2;
DEF exclusion_list = "('ANONYMOUS','APEX_030200','APEX_040000','APEX_SSO','APPQOSSYS','CTXSYS','DBSNMP','DIP','EXFSYS','FLOWS_FILES','MDSYS','OLAPSYS','ORACLE_OCM','ORDDATA','ORDPLUGINS','ORDSYS','OUTLN','OWBSYS')";
DEF exclusion_list2 = "('SI_INFORMTN_SCHEMA','SQLTXADMIN','SQLTXPLAIN','SYS','SYSMAN','SYSTEM','TRCANLZR','WMSYS','XDB','XS$NULL')";
VAR random1 VARCHAR2(30);
VAR random2 VARCHAR2(30);
EXEC :random1 := DBMS_RANDOM.string('A', 30);
EXEC :random2 := DBMS_RANDOM.string('X', 30);
DELETE plan_table WHERE statement_id IN (:random1, :random2);

SET SERVEROUT ON;
DECLARE
  sql_text CLOB;
BEGIN
  FOR i IN (SELECT idx.owner, idx.index_name
              FROM dba_indexes idx,
                   dba_tables tbl
             WHERE idx.owner = NVL(UPPER(TRIM('&&owner.')), idx.owner) -- optional schema owner name
               AND idx.table_name = NVL(UPPER(TRIM('&&table_name.')), idx.table_name) -- optional table name
               AND idx.index_name = NVL(UPPER(TRIM('&&index_name.')), idx.index_name) -- optional index name
               AND idx.owner NOT IN &&exclusion_list. -- exclude non-application schemas
               AND idx.owner NOT IN &&exclusion_list2. -- exclude more non-application schemas
               AND idx.index_type IN ('NORMAL', 'FUNCTION-BASED NORMAL', 'BITMAP', 'NORMAL/REV') -- exclude domain and lob
               AND idx.status != 'UNUSABLE' -- only valid indexes
               AND idx.temporary = 'N'
               AND tbl.owner = idx.table_owner
               AND tbl.table_name = idx.table_name
               AND tbl.last_analyzed IS NOT NULL -- only tables with statistics
               AND tbl.num_rows > 0 -- only tables with rows as per statistics
               AND tbl.blocks > 128 -- skip small tables
               AND tbl.temporary = 'N')
  LOOP
    BEGIN
      sql_text := 'EXPLAIN PLAN SET STATEMENT_ID = '''||:random1||''' FOR '||REPLACE(DBMS_METADATA.get_ddl('INDEX', i.index_name, i.owner), CHR(10), ' ');
      -- cbo estimates index size based on explain plan for create index ddl
      EXECUTE IMMEDIATE sql_text;
      -- index owner and name do not fit on statement_id, thus using object_owner and object_name, using statement_id as processing state
      DELETE plan_table WHERE statement_id = :random1 AND (other_xml IS NULL OR NVL(DBMS_LOB.instr(other_xml, 'index_size'), 0) = 0);
      UPDATE plan_table SET object_owner = i.owner, object_name = i.index_name, statement_id = :random2 WHERE statement_id = :random1;
    EXCEPTION
      WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE(i.owner||'.'||i.index_name||': '||SQLERRM);
        DBMS_OUTPUT.PUT_LINE(DBMS_LOB.substr(sql_text));
    END;
  END LOOP;
END;
/
SET SERVEROUT OFF;

WITH 
indexes AS (
SELECT pt.object_owner, 
       pt.object_name,
       TO_NUMBER(EXTRACTVALUE(VALUE(d), '/info')) estimated_bytes
  FROM plan_table pt,
       TABLE(XMLSEQUENCE(EXTRACT(XMLTYPE(pt.other_xml), '/other_xml/info'))) d
 WHERE pt.statement_id = :random2
   AND pt.other_xml IS NOT NULL -- redundant
   AND DBMS_LOB.instr(pt.other_xml, 'index_size') > 0 -- redundant
   AND EXTRACTVALUE(VALUE(d), '/info/@type') = 'index_size' -- grab index_size type
),
segments AS (
SELECT owner, segment_name, SUM(bytes) actual_bytes
  FROM dba_segments
 WHERE owner = NVL(UPPER(TRIM('&&owner.')), owner) -- optional schema owner name
   AND segment_name = NVL(UPPER(TRIM('&&index_name.')), segment_name) -- optional index name
   AND owner NOT IN &&exclusion_list. -- exclude non-application schemas
   AND owner NOT IN &&exclusion_list2. -- exclude more non-application schemas
   AND segment_type LIKE 'INDEX%'
HAVING SUM(bytes) > POWER(10,6) -- only indexes with actual size > 1 MB
 GROUP BY
       owner,
       segment_name
),
list_bytes AS (
SELECT (s.actual_bytes - i.estimated_bytes) actual_minus_estimated,
       s.actual_bytes,
       i.estimated_bytes,
       i.object_owner,
       i.object_name
  FROM indexes i,
       segments s
 WHERE i.estimated_bytes > POWER(10,6) -- only indexes with estimated size > 1 MB
   AND s.owner = i.object_owner
   AND s.segment_name = i.object_name
)
SELECT ROUND(actual_minus_estimated / POWER(10,6)) actual_minus_estimated,
       ROUND(actual_bytes / POWER(10,6)) actual_mb,
       ROUND(estimated_bytes / POWER(10,6)) estimated_mb,
       object_owner owner,
       object_name index_name
  FROM list_bytes
 WHERE actual_minus_estimated > POWER(10,6) -- only differences > 1 MB
 ORDER BY
       1 DESC,
       object_owner,
       object_name
/

DELETE plan_table WHERE statement_id IN (:random1, :random2);
UNDEF owner table_name index_name exclusion_list exclusion_list2;
SPO OFF;
