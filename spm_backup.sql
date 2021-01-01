-- spm_backup.sql - Create DATAPUMP backup of SQL Plan Management (SPM) Repository for one PDB
SET HEA ON LIN 500 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF;
ALTER SESSION SET container = CDB$ROOT;
SELECT name pdb_name FROM v$containers WHERE open_mode = 'READ WRITE' ORDER BY 1;
PRO 1. Enter PDB_NAME failing with ORA-13831:
DEF pdb_name = '&1.';
UNDEF 1;
PRO
HOS echo $ORACLE_HOME
PRO 2. Enter directory path ($ORACLE_HOME):
DEF directory_path = '&2.';
UNDEF 2;
PRO
PRO 3. Enter connect string such as: kiev-wfs-tenant-b-preprod.svc.ad2.r1/s_wfs_tenant_b_preprod.ad2.r1
DEF connect_string = '&3'
UNDEF 3;
PRO
PRO 4. Enter sys password
DEF sys_pwd = '&4.';
UNDEF 4;
PRO
SET FEED ON ECHO ON VER ON TI ON TIMI ON;
-- connect to pdb
ALTER SESSION SET container = &&pdb_name.;
--
CREATE OR REPLACE DIRECTORY CS_TEMP AS '&&directory_path.';
-- prepares backup owner
DEF repo_owner = 'C##IOD';
COL default_tablespace NEW_V default_tablespace NOPRI;
SELECT default_tablespace FROM dba_users WHERE username = UPPER('&&repo_owner.');
ALTER USER &&repo_owner. QUOTA UNLIMITED ON &&default_tablespace.;
-- backup SPM metadata (for subsequent datapump)
COL backup_timestamp NEW_V backup_timestamp NOPRI;
SELECT TO_CHAR(SYSDATE, 'YYYYMMDD_HH24MISS') backup_timestamp FROM DUAL;
CREATE TABLE &&repo_owner..sqllog$_&&backup_timestamp. AS SELECT * FROM sys.sqllog$;
CREATE TABLE &&repo_owner..smb$config_&&backup_timestamp. AS SELECT * FROM sys.smb$config;
CREATE TABLE &&repo_owner..sql$_&&backup_timestamp. AS SELECT * FROM sys.sql$;
CREATE TABLE &&repo_owner..sql$text_&&backup_timestamp. AS SELECT * FROM sys.sql$text;
CREATE TABLE &&repo_owner..sqlobj$_&&backup_timestamp. AS SELECT * FROM sys.sqlobj$;
CREATE TABLE &&repo_owner..sqlobj$data_&&backup_timestamp. AS SELECT * FROM sys.sqlobj$data;
CREATE TABLE &&repo_owner..sqlobj$auxdata_&&backup_timestamp. AS SELECT * FROM sys.sqlobj$auxdata;
--CREATE TABLE &&repo_owner..sqlobj$plan_&&backup_timestamp. AS SELECT * FROM sys.sqlobj$plan;
-- needed to avoid ORA-00997: illegal use of LONG datatype on column "other"
CREATE TABLE &&repo_owner..sqlobj$plan_&&backup_timestamp. AS SELECT 
 signature
,category
,obj_type
,plan_id
,statement_id
,xpl_plan_id
,timestamp
,remarks
,operation
,options
,object_node
,object_owner
,object_name
,object_alias
,object_instance
,object_type
,optimizer
,search_columns
,id
,parent_id
,depth
,position
,cost
,cardinality
,bytes
,other_tag
,partition_start
,partition_stop
,partition_id
,TO_LOB(other) other -- TO_LOB() needed to avoid ORA-00997: illegal use of LONG datatype
,distribution
,cpu_cost
,io_cost
,temp_space
,access_predicates
,filter_predicates
,projection
,time
,qblock_name
,other_xml
FROM sys.sqlobj$plan;
--
COL table_list NEW_V table_list;
select LISTAGG(owner||'.'||replace(object_name,chr(36), chr(92)||chr(36) ),',') WITHIN GROUP (order by 1) as table_list 
from dba_objects where owner='C##IOD' and object_type='TABLE' AND object_name LIKE '%_&&backup_timestamp.';
--
PRO
HOS expdp \"sys/&&sys_pwd.@&&connect_string. as sysdba\" file=SPM_&&backup_timestamp..dmp logfile=SPM_&&backup_timestamp..log DIRECTORY=CS_TEMP tables=&&table_list.
PRO
HOS cp &&directory_path./SPM_&&backup_timestamp..* .
HOS chmod 777 SPM_&&backup_timestamp..*
HOS ls -lat SPM_&&backup_timestamp..*
