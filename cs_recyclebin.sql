----------------------------------------------------------------------------------------
--
-- File name:   cs_recyclebin.sql
--
-- Purpose:     Recyclebin Content
--
-- Author:      Carlos Sierra
--
-- Version:     2020/12/06
--
-- Usage:       Execute connected to CDB or PDB.
--
--              Enter if Oracle Maintained tables are included
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @cs_recyclebin.sql
--
-- Notes:       Developed and tested on 12.1.0.2.
--
---------------------------------------------------------------------------------------
--
@@cs_internal/cs_primary.sql
@@cs_internal/cs_cdb_warn.sql
@@cs_internal/cs_set.sql
@@cs_internal/cs_def.sql
@@cs_internal/cs_file_prefix.sql
--
DEF cs_script_name = 'cs_recyclebin';
--
@@cs_internal/&&cs_set_container_to_cdb_root.
--
SELECT '&&cs_file_prefix._&&cs_script_name.' cs_file_name FROM DUAL;
--
@@cs_internal/cs_spool_head.sql
PRO SQL> @&&cs_script_name..sql
@@cs_internal/cs_spool_id.sql
--
COL owner FOR A30 TRUNC;
COL object_name FOR A30 TRUNC;
COL original_name FOR A30 TRUNC;
COL ts_name FOR A30 TRUNC;
COL partition_name FOR A30 TRUNC;
COL can_undrop FOR A6 HEA 'CAN|UNDROP';
COL can_purge FOR A5 HEA 'CAN|PURGE';
COL related FOR 999999999 HEA 'PARENT|OBJECT';
COL base_object FOR 999999999 HEA 'BASE|OBJECT';
COL purge_object FOR 999999999 HEA 'PURGE|OBJECT';
COL gb FOR 999,990.000 HEA 'GB';
COL pdb_name FOR A30 TRUNC;
COL objects FOR 999,990;
--
BREAK ON REPORT;
COMPUTE SUM LABEL 'TOTAL' OF gb objects ON REPORT;
--
PRO
PRO CDB_RECYCLEBIN Details
PRO ~~~~~~~~~~~~~~~~~~~~~~
SELECT
  r.owner		
, r.object_name	
, r.original_name	
, r.operation	
, r.type		
, r.ts_name		
, r.createtime	
, r.droptime	
, r.dropscn		
, r.partition_name 
, r.can_undrop	
, r.can_purge	
, r.related		
, r.base_object	
, r.purge_object	
, r.space * t.block_size / 1e9 AS gb		
, c.name AS pdb_name 		
 FROM cdb_recyclebin r,
      cdb_tablespaces t,
      v$containers c
WHERE t.con_id = r.con_id
  AND t.tablespace_name = r.ts_name
  AND c.con_id = r.con_id
  AND c.open_mode = 'READ WRITE'
 ORDER BY
       1, 2, 3, 4, 5, 6, 7, 8
/
PRO
PRO CDB_RECYCLEBIN Summary
PRO ~~~~~~~~~~~~~~~~~~~~~~
SELECT
  r.owner		
, r.type		
, r.ts_name		
, r.can_undrop	
, r.can_purge	
, SUM(r.space) * t.block_size / 1e9 AS gb
, COUNT(*) AS objects		
, c.name AS pdb_name 		
 FROM cdb_recyclebin r,
      cdb_tablespaces t,
      v$containers c
WHERE t.con_id = r.con_id
  AND t.tablespace_name = r.ts_name
  AND c.con_id = r.con_id
  AND c.open_mode = 'READ WRITE'
GROUP BY
  r.owner		
, r.type		
, r.ts_name		
, r.can_undrop	
, r.can_purge	
, t.block_size
, c.name 		
 ORDER BY
       1, 2, 3, 4, 5
/
--
CLEAR BREAK COMPUTE COLUMNS;
--
PRO
PRO SQL> @&&cs_script_name..sql
--
@@cs_internal/cs_spool_tail.sql
--
@@cs_internal/&&cs_set_container_to_curr_pdb.
--
@@cs_internal/cs_undef.sql
@@cs_internal/cs_reset.sql
--