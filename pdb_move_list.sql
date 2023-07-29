-- pdb_move_list.sql - List all PDBs and highligh as "MOVE" the 1/3 at the middle in terms of CPU
@@set.sql
ALTER SESSION SET container = CDB$ROOT;
--
COL pdb_name FOR A30 HEA 'PDB Name' PRI;
COL con_id FOR 990 HEA 'CON|ID' PRI;
COL cpus FOR 9,990.000 HEA 'CPUs' PRI;
COL cpus_perc FOR 990.0 HEA 'CPUs|Perc%' PRI;
COL cpus_rank FOR 990 HEA 'CPUs|Rank' PRI;
COL position FOR 990 HEA 'Pos' PRI;
COL space_gb FOR 99,990.000 HEA 'Space|GBs' PRI;
COL space_perc FOR 990.0 HEA 'Space|Perc%' PRI;
COL space_rank FOR 990 HEA 'Space|Rank' PRI;
COL iops FOR 9,999,990.000 HEA 'IOPS' PRI;
COL iops_perc FOR 990.0 HEA 'IOPS|Perc%' PRI;
COL iops_rank FOR 990 HEA 'IOPS|Rank' PRI;
COL mbps FOR 999,990.000 HEA 'MBPS' PRI;
COL mbps_perc FOR 990.0 HEA 'MBPS|Perc%' PRI;
COL mbps_rank FOR 990 HEA 'MBPS|Rank' PRI;
COL move_pdb FOR A12 HEA 'MOVE PDB' PRI;
--
BREAK ON REPORT;
COMPUTE SUM OF cpus cpus_perc space_gb space_perc iops iops_perc mbps mbps_perc ON REPORT;
--
PRO
PRO All PDBs
PRO ~~~~~~~~
WITH
rsrcmgrmetric AS (
SELECT r.con_id,
       c.name AS pdb_name,
       (SUM(r.cpu_consumed_time) / 1000) / (MAX(r.intsize_csec) / 100) AS cpus,
       MAX(c.total_size) / POWER(2,30) AS space_gb,
       SUM(r.io_requests) / (MAX(r.intsize_csec) / 100) AS iops,
       SUM(r.io_megabytes) / (MAX(r.intsize_csec) / 100) AS mbps
  FROM v$rsrcmgrmetric r,
       v$containers c
 WHERE r.con_id > 2 -- exclude CDB$ROOT
   AND r.intsize_csec > 0
   AND c.con_id = r.con_id
 GROUP BY
       r.con_id, -- needed since there are multiple consumer groups (usually 3) per time slice
       c.name
),
rsrcmgrmetric_ext AS (
SELECT con_id,
       pdb_name,
       cpus,
       100 * cpus / NULLIF(SUM(cpus) OVER(), 0) AS cpus_perc,
       RANK() OVER(ORDER BY cpus DESC) AS cpus_rank,
       100 * ROW_NUMBER() OVER(ORDER BY cpus DESC)/COUNT(*) OVER() AS position,
       space_gb,
       100 * space_gb / NULLIF(SUM(space_gb) OVER(), 0) AS space_perc,
       RANK() OVER(ORDER BY space_gb DESC) AS space_rank,
       iops,
       100 * iops / NULLIF(SUM(iops) OVER(), 0) AS iops_perc,
       RANK() OVER(ORDER BY iops DESC) AS iops_rank,
       mbps,
       100 * mbps / NULLIF(SUM(mbps) OVER(), 0) AS mbps_perc,
       RANK() OVER(ORDER BY mbps DESC) AS mbps_rank
  FROM rsrcmgrmetric
)
SELECT r.cpus,
       r.cpus_perc,
       r.cpus_rank,
      --  r.position,
       r.space_gb,
       r.space_perc,
       r.space_rank,
       r.iops,
       r.iops_perc,
       r.iops_rank,
       r.mbps,
       r.mbps_perc,
       r.mbps_rank,
       r.pdb_name,
       r.con_id,
       CASE WHEN r.position BETWEEN 33 AND 66 THEN '*** MOVE ***' END AS move_pdb
  FROM rsrcmgrmetric_ext r
--  WHERE (r.cpus_perc > 1 OR r.space_perc > 1 OR r.iops_perc > 1 OR r.mbps_perc > 1) 
--    AND (r.cpus > 0.1 OR r.space_gb > 0.1 OR r.iops > 0.001 OR r.mbps > 0.001)
ORDER BY
      r.cpus_perc DESC,
      r.space_perc DESC,
      r.iops_perc DESC,
      r.mbps_perc DESC
/
--
CLEAR BREAK COLUMNS COMPUTE;
