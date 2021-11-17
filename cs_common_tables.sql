COL owner FOR A30 TRUNC;
COL table_name FOR A30 TRUNC;
--
SELECT t.owner, t.table_name, num_rows
  FROM dba_users u, dba_tables t
 WHERE u.common = 'YES'
   AND u.oracle_maintained = 'N'
   AND t.owner = u.username
 ORDER BY
       t.owner, t.table_name
/