SET HEA ON LIN 500 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF;

COL owner FOR A30;
SELECT username owner
  FROM dba_users 
 WHERE oracle_maintained = 'N' 
   AND username NOT LIKE 'C##%'
 ORDER BY
       username
/

PRO
PRO 1. Owner
DEF owner = '&1.';

COL table_name FOR A30;
SELECT table_name, blocks, num_rows
  FROM dba_tables
 WHERE owner = UPPER(TRIM('&&owner.'))
 ORDER BY
       table_name
/

PRO
PRO 2. Table Name
DEF table_name = '&2.';

COL tablespace_name NEW_V tablespace_name FOR A30;
SELECT tablespace_name
  FROM dba_tables
 WHERE owner = UPPER(TRIM('&&owner.'))
   AND table_name = UPPER(TRIM('&&table_name.'))
/

PRO redef_table.sql
PRO
PRO Owner: &&owner.
PRO Table Name: &&table_name.
PRO Tablespace: &&tablespace_name.

COL size_mbs FOR 999,990.000
PRO
PRO Table Size MBs (before)
PRO ~~~~~~~~~~~~~~
SELECT ROUND(bytes / POWER(2,20), 3) size_mbs
  FROM dba_segments
 WHERE owner = UPPER(TRIM('&&owner.'))
   AND segment_name = UPPER(TRIM('&&table_name.'))
   AND segment_type = 'TABLE'
/

PRO
PRO Index Size MBs (before)
PRO ~~~~~~~~~~~~~~
COL index_name FOR A30;
SELECT i.index_name,
       ROUND(bytes / POWER(2,20), 3) size_mbs
  FROM dba_indexes i,
       dba_segments s
 WHERE i.table_owner = UPPER(TRIM('&&owner.'))
   AND i.table_name = UPPER(TRIM('&&table_name.'))
   AND s.owner = i.owner
   AND s.segment_name = i.index_name
   AND s.segment_type = 'INDEX'
 ORDER BY
       i.index_name
/

SET timi ON;
PRO
PRO DBMS_REDEFINITION.REDEF_TABLE
PRO ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
EXEC DBMS_REDEFINITION.REDEF_TABLE(uname=>UPPER(TRIM('&&owner.')), tname=>UPPER(TRIM('&&table_name.')), table_part_tablespace=>UPPER(TRIM('&&tablespace_name.')));
SET timi OFF;

PRO
PRO Table Size MBs (after)
PRO ~~~~~~~~~~~~~~
SELECT ROUND(bytes / POWER(2,20), 3) size_mbs
  FROM dba_segments
 WHERE owner = UPPER(TRIM('&&owner.'))
   AND segment_name = UPPER(TRIM('&&table_name.'))
   AND segment_type = 'TABLE'
/

PRO
PRO Index Size MBs (after)
PRO ~~~~~~~~~~~~~~
SELECT i.index_name,
       ROUND(bytes / POWER(2,20), 3) size_mbs
  FROM dba_indexes i,
       dba_segments s
 WHERE i.table_owner = UPPER(TRIM('&&owner.'))
   AND i.table_name = UPPER(TRIM('&&table_name.'))
   AND s.owner = i.owner
   AND s.segment_name = i.index_name
   AND s.segment_type = 'INDEX'
 ORDER BY
       i.index_name
/

UNDEF 1 2 owner table_name tablespace_name