BREAK ON REPORT;
COMPUTE SUM LABEL 'TOTAL' OF size_gbs size_tbs ON REPORT;

SELECT con_id,
       blocks * 8 / POWER(2, 20) size_gbs,
       blocks * 8 / POWER(2, 30) size_tbs
  FROM cdb_segments
 WHERE segment_name = 'KIEVTRANSACTIONS_AK2'
 ORDER BY
       1
/