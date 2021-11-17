WITH
x AS (
SELECT pdb_name, service_type, ez_connect_string,
       COUNT(*) OVER (PARTITION BY pdb_name, service_type) AS cnt
  FROM C##IOD.iod_connect_strings
)
SELECT pdb_name, service_type, ez_connect_string 
FROM x WHERE cnt > 1
ORDER BY 1, 2, 3
/
