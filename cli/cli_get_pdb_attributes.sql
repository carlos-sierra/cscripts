SET HEA ON LIN 2490 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF LONG 240000 LONGC 2400 NUM 20 SERVEROUT OFF;
SET HEA OFF PAGES 0;
ALTER SESSION SET NLS_DATE_FORMAT = 'YYYY-MM-DD"T"HH24:MI:SS';
COL line FOR A2000;
--
WITH
pdbs1 AS (
SELECT  p.*, ROW_NUMBER() OVER (PARTITION BY p.db_domain, p.db_name, p.pdb_name ORDER BY p.timestamp DESC) AS rn
FROM    C##IOD.dbc_pdbs p
WHERE   p.timestamp > SYSDATE - 7
),
pdbs2 AS (
SELECT  pdb_name, MAX(total_size_bytes) AS total_size_bytes, MAX(sessions) AS sessions, ROUND(AVG(avg_running_sessions), 3) AS avg_running_sessions
  FROM  pdbs1
 WHERE  total_size_bytes >= 0
   AND  sessions >= 0
--    AND  avg_running_sessions >= 0 -- resource manager needs to be executing
 GROUP BY
        pdb_name
),
pdbs3 AS (
SELECT    TO_CHAR(SYSDATE, 'YYYY-MM-DD') AS version
        , curr.timestamp
        , curr.db_domain                       
        , curr.db_name                         
        , curr.pdb_name                        
        , curr.host_name                       
        , curr.realm_type                      
        , curr.realm_type_order_by             
        , curr.realm                           
        , curr.realm_order_by                  
        , curr.region                          
        , curr.region_acronym                  
        , curr.region_order_by                 
        , curr.locale                          
        , curr.locale_order_by                 
        , curr.kiev_or_wf                      
        , curr.ez_connect_string               
        , aggr.total_size_bytes                
        , aggr.sessions                        
        , aggr.avg_running_sessions            
        , curr.created                         
        , curr.open_time                       
FROM    pdbs1 curr, pdbs2 aggr
WHERE   curr.rn = 1
AND     aggr.pdb_name = curr.pdb_name
)
SELECT  'EXEC c##iod.merge_pdb_attributes('||
        ''''||version||''','||
        ''''||timestamp||''','||
        ''''||db_domain||''','||
        ''''||db_name||''','||
        ''''||pdb_name||''','||
        ''''||host_name||''','||
        ''''||realm_type||''','||
        ''''||realm_type_order_by||''','||
        ''''||realm||''','||
        ''''||realm_order_by||''','||
        ''''||region||''','||
        ''''||region_acronym||''','||
        ''''||region_order_by||''','||
        ''''||locale||''','||
        ''''||locale_order_by||''','||
        ''''||kiev_or_wf||''','||
        ''''||ez_connect_string||''','||
        ''''||total_size_bytes||''','||
        ''''||sessions||''','||
        ''''||avg_running_sessions||''','||
        ''''||created||''','||
        ''''||open_time||''');' AS line
FROM    pdbs3
ORDER BY
        pdb_name
/
