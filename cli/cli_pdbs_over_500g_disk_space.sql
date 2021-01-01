DEF p_pdb_size_gb = '500';
--
-- iodcli sql_exec -y -t PRIMARY -r SEA file:/Users/csierra/git/bitbucket.oci.oraclecorp.com/dbeng/oratk/sql/cscripts/cli/cli_pdbs_over_500g_disk_space.sql hcg:HC_DATABASE > pdbs_over_500g_disk_space_2020-02-24.txt
-- cut -b 79- pdbs_over_500g_disk_space_2020-02-24.txt | sort | uniq > pdbs_over_500g_disk_space_2020-02-24.csv
--
SET HEA ON LIN 2490 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF LONG 240000 LONGC 2400 NUM 20 SERVEROUT OFF;
SET HEA OFF PAGES 0; 
--
COL line FOR A300;
--
WITH
sqf1 AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       CASE UPPER(SUBSTR(i.host_name,INSTR(i.host_name,'.',-1)+1)) -- region
         WHEN 'R1'               THEN 'OC0'
         WHEN 'US-SEATTLE-1'     THEN 'OC0'
         --
         WHEN 'R2'               THEN 'OC1'
         WHEN 'US-PHOENIX-1'     THEN 'OC1'
         WHEN 'US-ASHBURN-1'     THEN 'OC1'
         WHEN 'EU-FRANKFURT-1'   THEN 'OC1'
         WHEN 'UK-LONDON-1'      THEN 'OC1'
         WHEN 'CA-TORONTO-1'     THEN 'OC1'
         WHEN 'AP-TOKYO-1'       THEN 'OC1'
         WHEN 'AP-SEOUL-1'       THEN 'OC1'
         WHEN 'AP-MUMBAI-1'      THEN 'OC1'
         WHEN 'EU-ZURICH-1'      THEN 'OC1'
         WHEN 'SA-SAOPAULO-1'    THEN 'OC1'
         WHEN 'AP-SYDNEY-1'      THEN 'OC1'
         WHEN 'EU-AMSTERDAM-1'   THEN 'OC1'
         WHEN 'ME-JEDDAH-1'      THEN 'OC1'
         WHEN 'AP-OSAKA-1'       THEN 'OC1'
         WHEN 'AP-MELBOURNE-1'   THEN 'OC1'
         WHEN 'CA-MONTREAL-1'    THEN 'OC1'
         --
         WHEN 'US-LANGLEY-1'     THEN 'OC2'
         WHEN 'US-LUKE-1'        THEN 'OC2'
         --
         WHEN 'US-GOV-ASHBURN-1' THEN 'OC3'
         WHEN 'US-GOV-PHOENIX-1' THEN 'OC3'
         WHEN 'US-GOV-CHICAGO-1' THEN 'OC3'
         --
         WHEN 'UK-GOV-LONDON-1'  THEN 'OC4'
         --
         WHEN 'MC1'              THEN 'OC8'
         --
         ELSE 'OC9'
       END AS realm,
       UPPER(SUBSTR(i.host_name,INSTR(i.host_name,'.',-1)+1)) AS region,
       CASE
         WHEN d.name IN ('KIEV01', 'IOD01', 'IOD05') OR d.name LIKE CHR(37)||'RG' THEN 'RGN'
         WHEN UPPER(SUBSTR(i.host_name,INSTR(i.host_name,'.',-1)+1)) = 'R2' AND d.name IN ('KIEV02', 'KIEV1R2') THEN 'RGN'
         ELSE UPPER(SUBSTR(i.host_name,INSTR(i.host_name,'.',-1,2)+1,INSTR(i.host_name,'.',-1)-INSTR(i.host_name,'.',-1,2)-1))
       END AS locale,
       d.name db_name,
       c.con_id,
       cs.pdb_name,
       i.host_name,
       cs.ez_connect_string
  FROM c##iod.iod_connect_strings cs, v$database d, v$instance i, v$containers c
 WHERE 1 = 1
   AND cs.service_type = 'RW'
   AND c.name = cs.pdb_name
   AND c.open_mode = 'READ WRITE'
),
selected AS (
SELECT ROUND(SUM(t.allocated_bytes) / POWER(10,9)) AS GB,
       e.realm,
       e.region,
       e.locale,
       e.db_name,
       e.host_name,
       e.pdb_name,
       e.ez_connect_string
  FROM c##iod.dbc_tablespaces t,
       sqf1 e
 WHERE 1 = 1
   AND t.snap_time = (SELECT MAX(h.snap_time) FROM c##iod.dbc_tablespaces h)
   AND t.pdb_name <> 'CDB$ROOT'
   AND e.pdb_name = t.pdb_name
 GROUP BY 
       e.realm,
       e.region,
       e.locale,
       e.db_name,
       e.host_name,
       e.pdb_name,
       e.ez_connect_string
HAVING ROUND(SUM(t.allocated_bytes) / POWER(10,9)) > TO_NUMBER('&&p_pdb_size_gb.')
)
SELECT ' Realm, '||
       'Region,'||
       'Locale,'||
       'CDB,'||
       'Host Name,'||
       'GBs,'||
       'PDB,'||
       'Connect String' AS line
  FROM DUAL
 UNION ALL 
SELECT realm||','||
       region||','||
       locale||','||
       db_name||','||
       host_name||','||
       gb||','||
       pdb_name||','||
       ez_connect_string AS line    
  FROM selected
 ORDER BY
       1
/
