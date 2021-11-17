COL con_id FOR 999999;
COL sql_text FOR A65 TRUNC;
SELECT DISTINCT con_id, sql_text FROM v$sql WHERE sql_text LIKE '/* performScanQuery(leaseDecorators,ae_timestamp_index) %' ORDER BY 1, 2;