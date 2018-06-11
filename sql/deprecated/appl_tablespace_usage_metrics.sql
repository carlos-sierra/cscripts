SET HEA ON LIN 500 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF;

COL current_time NEW_V current_time FOR A15;
SELECT 'current_time: ' x, TO_CHAR(SYSDATE, 'YYYYMMDD_HH24MISS') current_time FROM DUAL;
COL x_host_name NEW_V x_host_name;
SELECT host_name x_host_name FROM v$instance;
COL x_db_name NEW_V x_db_name;
SELECT name x_db_name FROM v$database;
COL x_container NEW_V x_container;
SELECT 'NONE' x_container FROM DUAL;
SELECT SYS_CONTEXT('USERENV', 'CON_NAME') x_container FROM DUAL;

COL pdb_name FOR A30;
COL used_space FOR 999,999,999,999 HEA 'USED_SPACE|(BLOCKS)';
COL tablespace_size FOR 999,999,999,999 HEA 'ALLOC_SIZE|(BLOCKS)';
COL used_percent FOR 990.0 HEA 'USED|PERCENT';
COL used_space_gb FOR 999,990.000 HEA 'USED_SPACE|(GBs)';
COL tablespace_size_gb FOR 999,990.000 HEA 'ALLOC_SIZE|(GBs)';

COL dummy_nopri NOPRI;
CL BRE;
BRE ON dummy_nopri;
COMP SUM LAB 'TOTAL' OF used_space tablespace_size used_space_gb tablespace_size_gb ON dummy_nopri;

SPO appl_tablespace_usage_metrics_&&current_time..txt;
PRO HOST: &&x_host_name.
PRO DATABASE: &&x_db_name.
PRO CONTAINER: &&x_container.

PRO
PRO **********************************************************************************************************************************
PRO
PRO oem
PRO ~~~

WITH
oem_tablespaces_query AS (
-- this is OEM SQL_ID cudu43xrkjnd2 captured from R1 RGN (replaced hints and added con_id)
SELECT  /*+ MATERIALIZE NO_MERGE */ -- added these hints 
        /* + first_rows */ -- removed hint first_rows
        ts.con_id                               , -- added this column to projection
        pdb.name                                ,
        ts.tablespace_name                      ,
        NVL(t.bytes/1024/1024,0) allocated_space,
        NVL(DECODE(un.bytes,NULL,DECODE(ts.contents,'TEMPORARY', DECODE(ts.extent_management,'LOCAL',u.bytes,t.bytes - NVL(u.bytes, 0)), t.bytes - NVL(u.bytes, 0)), un.bytes)/1024/1024,0) used_space
FROM    cdb_tablespaces ts,
        v$containers pdb  ,
        (
                SELECT  con_id         ,
                        tablespace_name,
                        SUM(bytes) bytes
                FROM    cdb_free_space
                GROUP BY con_id,
                        tablespace_name
                UNION ALL
                SELECT  con_id         ,
                        tablespace_name,
                        NVL(SUM(bytes_used), 0)
                FROM    gv$temp_extent_pool
                GROUP BY con_id,
                        tablespace_name
        )
        u,
        (
                SELECT  con_id         ,
                        tablespace_name,
                        SUM(NVL(bytes, 0)) bytes
                FROM    cdb_data_files
                GROUP BY con_id,
                        tablespace_name
                UNION ALL
                SELECT  con_id         ,
                        tablespace_name,
                        SUM(NVL(bytes, 0)) bytes
                FROM    cdb_temp_files
                GROUP BY con_id,
                        tablespace_name
        )
        t,
        (
                SELECT  ts.con_id         ,
                        ts.tablespace_name,
                        NVL(um.used_space*ts.block_size, 0) bytes
                FROM    cdb_tablespaces ts,
                        cdb_tablespace_usage_metrics um
                WHERE   ts.tablespace_name = um.tablespace_name(+)
                        AND ts.con_id      = um.con_id(+)
                        AND ts.contents    ='UNDO'
        )
        un
WHERE   ts.tablespace_name     = t.tablespace_name(+)
        AND ts.tablespace_name = u.tablespace_name(+)
        AND ts.tablespace_name = un.tablespace_name(+)
        AND ts.con_id          = pdb.con_id
        AND ts.con_id          = u.con_id(+)
        AND ts.con_id          = t.con_id(+)
        AND ts.con_id          = un.con_id(+)
)
SELECT --con_id,
       1 dummy_nopri,
       ROUND(100 * used_space / allocated_space, 1) used_percent,
       ROUND(allocated_space/1024, 3) tablespace_size_gb,
       ROUND(used_space/1024, 3) used_space_gb,
       name pdb_name,
       tablespace_name
  FROM oem_tablespaces_query
 WHERE 1 = 1
   AND tablespace_name NOT IN ('SYSAUX', 'SYSTEM', 'TEMP', 'UNDOTBS1', 'USERS')
 ORDER BY
       used_space / allocated_space DESC,
       allocated_space DESC,
       used_space DESC,
       name,
       tablespace_name
/

PRO
PRO **********************************************************************************************************************************
PRO
PRO cdb_tablespace_usage_metrics
PRO ~~~~~~~~~~~~~~~~~~~~~~~~~~~~

SELECT 1 dummy_nopri,
       ROUND(m.used_percent, 1) used_percent,
       ROUND(m.tablespace_size * p.block_size / POWER(2,30), 3) tablespace_size_gb,
       ROUND(m.used_space * p.block_size / POWER(2,30), 3) used_space_gb,
       SUBSTR(c.pdb_name, 1, 30) pdb_name,
       m.tablespace_name,
       m.tablespace_size,
       m.used_space
  FROM cdb_tablespace_usage_metrics m,
       cdb_pdbs c,
       cdb_tablespaces p
 WHERE 1 = 1
   AND m.tablespace_name NOT IN ('SYSAUX', 'SYSTEM', 'TEMP', 'UNDOTBS1', 'USERS')
   AND c.con_id = m.con_id
   AND p.con_id = m.con_id
   AND p.tablespace_name = m.tablespace_name
 ORDER BY
       m.used_percent DESC,
       m.tablespace_size * p.block_size DESC,
       m.used_space * p.block_size DESC,
       c.pdb_name,
       m.tablespace_name
/

PRO
PRO **********************************************************************************************************************************

SPO OFF;
CL BRE COMP;