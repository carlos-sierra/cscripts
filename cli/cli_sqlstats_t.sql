COL num_rows FOR 999,999,999,990;
COL blocks FOR 999,999,990;
SELECT '|'AS "|", num_rows, blocks FROM dba_tables WHERE table_name = 'IOD_SQLSTATS_T' AND owner = 'C##IOD';
