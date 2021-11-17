SELECT pdb_name, count(*)
  FROM C##IOD.iod_connect_strings
 WHERE service_type = 'RW'
   AND svc_ok = 'Y'
   AND dns_ok = 'Y'
 GROUP BY
       pdb_name
 HAVING COUNT(*) > 1
/
