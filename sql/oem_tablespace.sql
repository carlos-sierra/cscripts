-- source kiev02a2_ora_35224.trc
----- Current SQL Statement for this session (sql_id=gyuxkcwdgthvp) -----
WITH max_next AS
(SELECT /*+ materialize*/  p.pdb_name,t.con_id,
t.tablespace_name,
64 Max_next_extent
FROM cdb_tablespaces t, dba_pdbs p
WHERE tablespace_name NOT LIKE 'SYS%'
AND CONTENTS='PERMANENT' and p.con_id=t.con_id
),
Extendable_space AS
(SELECT
/*+ materialize*/
d.con_id,
d.tablespace_name,
SUM(
CASE
WHEN AUTOEXTENSIBLE='YES'
/* Find exact number of next extents that fit by dividing extendable space by max_next */
THEN TRUNC((maxbytes-bytes)/1024/1024/max_next_extent)*max_next_extent
ELSE 0
END) AS Extendable_Space_MB
FROM cdb_data_files d,
max_next n
WHERE d.tablespace_name NOT LIKE 'SYS%'
AND d.tablespace_name NOT LIKE 'UNDO%'
AND d.tablespace_name=n.tablespace_name
AND d.con_id         =n.con_id
GROUP BY d.tablespace_name,
d.con_id
) ,
free_space AS
(SELECT
/*+  materialize*/
con_id,
tablespace_name,
MAX(MB) MAX_CONTIGUOUS_MB,
SUM(MB) SUM_ELIGIBLE_MB,
SUM(TRUNC(MB/Max_next_extent)) COUNT_ELIGIBLE_EXTENTS
FROM
(SELECT d.con_id,
d.tablespace_name,
BYTES    /1024/1024 MB,
MAX(BYTES/1024/1024) over (partition BY d.tablespace_name) AS max_MB,
e.Max_next_extent
FROM cdb_free_space d,
max_next e
WHERE d.tablespace_name NOT LIKE 'SYS%'
AND d.tablespace_name NOT LIKE 'UNDO%'
AND d.tablespace_name=e.tablespace_name
)
GROUP BY tablespace_name,
con_id
)
SELECT c.pdb_name,
a.tablespace_name,
NVL(a.Extendable_space_mb,0) AUTOEXTENDABLE_FREE_SPACE_MB ,
NVL(b.max_contiguous_mb,0) MAX_CONTIGUOUS_FREE_SPACE_MB ,
c.max_next_extent MAX_NEXT_MB,
NVL(a.Extendable_space_mb,0) + NVL(SUM_ELIGIBLE_MB,0) AS SPACE_AVAILABLE_MB ,
NVL(COUNT_ELIGIBLE_EXTENTS,0) CNT_ELGBL_EXTS_IN_ALLOC_SPACE,
floor((NVL(Extendable_space_mb,0) / c.max_next_extent ) ) + NVL(COUNT_ELIGIBLE_EXTENTS,0) count_possible_64m_extents,
CASE
WHEN (floor((NVL(Extendable_space_mb,0) / c.max_next_extent ) ) + NVL(COUNT_ELIGIBLE_EXTENTS,0) )< 6
AND database_role                                                                                ='PRIMARY'
THEN 'CRITICAL'
WHEN (floor((NVL(Extendable_space_mb,0) / c.max_next_extent ) ) + NVL(COUNT_ELIGIBLE_EXTENTS,0) )< 12
AND database_role                                                                                ='PRIMARY'
THEN 'WARNING'
ELSE 'OK'
END AS EXTENT_MONITOR_STATUS
FROM Extendable_space a
LEFT OUTER JOIN free_space b
ON a.tablespace_name=b.tablespace_name
AND a.con_id        =b.con_id
JOIN max_next c
ON a.tablespace_name=c.tablespace_name
AND a.con_id        =c.con_id
JOIN v$database
ON 1        =1
/

