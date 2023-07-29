-- @@cs_internal/&&cs_set_container_to_cdb_root.
ALTER SESSION SET container = CDB$ROOT;
--
UNDEF 1 2 3 4 5 6 7 8 9 10 11 12;
@@set.sql
CLEAR BREAK COLUMNS COMPUTE;
--