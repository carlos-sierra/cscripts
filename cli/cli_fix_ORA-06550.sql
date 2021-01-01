SELECT 'FIX' FROM C##IOD.iod_api_version 
WHERE api_name = 'IOD_SPM.ZAPPER_19' 
AND api_version = 8
AND sql_statement_4 IS NOT NULL
/

UPDATE C##IOD.iod_api_version 
SET sql_statement_4 = NULL 
WHERE api_name = 'IOD_SPM.ZAPPER_19' 
AND api_version = 8
AND sql_statement_4 IS NOT NULL
/

COMMIT
/