SELECT
        /*+ first_rows */
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
ORDER BY 1,2
/
