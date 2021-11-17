  WITH /*+ IOD_SESS.purge_hvc */ -- fake hint so it shows in shared pool queries
  hvc AS (
  SELECT /*+ MATERIALIZE NO_MERGE */
         SUM(loaded_versions) loaded_versions_sum, 
         SUM(DISTINCT version_count) version_count_sum, 
         ROUND(SUM(sharable_mem + persistent_mem + runtime_mem)/POWER(2,20)) mem_mbs_sum,
         COUNT(*) pdb_count, 
         sql_id, address, hash_value, sql_text,
         ROW_NUMBER () OVER (ORDER BY SUM(loaded_versions) DESC) rank_loaded_versions,
         ROW_NUMBER () OVER (ORDER BY SUM(DISTINCT version_count) DESC) rank_version_count
    FROM v$sqlarea
   WHERE loaded_versions > 0
     AND version_count > 0
   GROUP BY 
         sql_id, address, hash_value, sql_text
  )
  SELECT rank_loaded_versions, rank_version_count,
         loaded_versions_sum, version_count_sum, mem_mbs_sum, pdb_count,
         sql_id, address, hash_value, sql_text
    FROM hvc
   WHERE loaded_versions_sum > 2048
      OR version_count_sum > 1024
   ORDER BY
         CASE
           WHEN loaded_versions_sum > 2048 THEN 1
           WHEN version_count_sum > 1024 THEN 2
         END,
         CASE
           WHEN loaded_versions_sum > 2048 THEN rank_loaded_versions
           WHEN version_count_sum > 1024 THEN rank_version_count
         END
   FETCH FIRST 300 ROWS ONLY;