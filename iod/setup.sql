define install_user = &&1;

prompt ========================================
prompt Installing database user&&1
prompt ========================================

set feedback off;
set verify off;


whenever sqlerror exit failure;
Set serveroutput on;

DECLARE
  cnt NUMBER;
BEGIN
  SELECT COUNT(*) INTO cnt FROM dba_tablespaces WHERE tablespace_name = 'IOD';
  IF cnt = 0 THEN
    DBMS_OUTPUT.PUT_LINE('CREATE BIGFILE TABLESPACE IOD DATAFILE SIZE 8G AUTOEXTEND ON NEXT 8G MAXSIZE 128G DEFAULT ROW STORE COMPRESS ADVANCED');
    EXECUTE IMMEDIATE 'CREATE BIGFILE TABLESPACE IOD DATAFILE SIZE 8G AUTOEXTEND ON NEXT 8G MAXSIZE 128G DEFAULT ROW STORE COMPRESS ADVANCED';
  ELSE
    DBMS_OUTPUT.PUT_LINE('TABLESPACE IOD already exists');
  END IF;
END;
/

DECLARE
  cnt number := 0;
BEGIN
  select count(1)  into cnt from dba_users where username = upper(trim('&&1'));
  IF cnt = 0 THEN
    dbms_output.put_line('Creating user &&install_user');
    execute immediate 'create user &&install_user identified by "changemeplease"';
  ELSE
    dbms_output.put_line('User &&install_user already exists');
  END IF;
END;
/

alter user &&install_user. default tablespace IOD quota unlimited on IOD container=current;
alter user &&install_user identified by values 'S:5565CBA22F98CCDE79DACD2882DB60AFDFFA51656EF21CB982064AFC9AD1;T:655635182BCB8AA0BDCED8F90FCBF93F1CB036BBBF9237A648C9A67EABC651D5F0C2F6C24F91E278725A7D5AB67033CB1ED14BD95801F02A30351A15198F5EFDE92D1BFAE5AFBF230EB5D3160DBA6785';

--BEGIN
--  for r in ( select username,DEFAULT_TABLESPACE from dba_users where username = upper('&&1') ) loop
--    execute immediate 'alter user ' || r.username || ' QUOTA UNLIMITED ON ' || r.DEFAULT_TABLESPACE || ' container=current';
--  end loop;
--end;
--/

@$ORATK_HOME/bin/oracle-install/etc/iod/iod_jutil/uninstall.sql &&1
@$ORATK_HOME/bin/oracle-install/etc/iod/iod_log/setup.sql &&1
@$ORATK_HOME/bin/oracle-install/etc/iod/iod_admin/setup.sql &&1
@$ORATK_HOME/bin/oracle-install/etc/iod/iod_spm/setup.sql &&1
@$ORATK_HOME/bin/oracle-install/etc/iod/iod_amw/setup.sql &&1
@$ORATK_HOME/bin/oracle-install/etc/iod/iod_rsrc_mgr/setup.sql &&1
@$ORATK_HOME/bin/oracle-install/etc/iod/pdb_config/setup.sql &&1
@$ORATK_HOME/bin/oracle-install/etc/iod/iod_sess/setup.sql &&1
@$ORATK_HOME/bin/oracle-install/etc/iod/iod_space/setup.sql &&1
@$ORATK_HOME/bin/oracle-install/etc/iod/iod_sqlstats/setup.sql &&1
@$ORATK_HOME/bin/oracle-install/etc/iod/iod_proxy_users/setup.sql &&1

prompt ========================================
prompt Compile invalid objects
prompt ========================================
BEGIN
  FOR cur_rec IN (SELECT owner,
                         object_name,
                         object_type,
                         DECODE(object_type, 'PACKAGE', 1,
                                             'PACKAGE BODY', 2, 2) AS recompile_order
                  FROM   dba_objects
                  WHERE  object_type IN ('PACKAGE', 'PACKAGE BODY')
                  AND    owner = UPPER(TRIM('&&1.'))
                  AND    status != 'VALID'
                  ORDER BY 4)
  LOOP
    BEGIN
      IF cur_rec.object_type = 'PACKAGE' THEN
        EXECUTE IMMEDIATE 'ALTER ' || cur_rec.object_type || 
            ' "' || cur_rec.owner || '"."' || cur_rec.object_name || '" COMPILE';
      ElSE
        EXECUTE IMMEDIATE 'ALTER PACKAGE "' || cur_rec.owner || 
            '"."' || cur_rec.object_name || '" COMPILE BODY';
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        DBMS_OUTPUT.put_line(cur_rec.object_type || ' : ' || cur_rec.owner || 
                             ' : ' || cur_rec.object_name);
    END;
  END LOOP;
END;
/

prompt ========================================
prompt Installation Summary
prompt ========================================

col pdb_name for a30;
col owner for a7
col object_type for a20
col object_name for a30
col status for a10
set lin 400
set pages 100
select sys_context('USERENV','CON_NAME') PDB_name,owner,object_type,object_name,status
from dba_objects
where ( owner = upper(trim('&&1')) and substr(object_name,1,4) not in ('SYS_','BIN$'))
or ( owner = 'SYS' and object_name = 'GET_DG_IP_LIST')
order by 1,2,3,4
;

REM Return with an error if any objects are not in a valid state
whenever sqlerror exit failure
DECLARE
  invalid_count number := 0;
BEGIN
  select count(1)
  into invalid_count
  from dba_objects
  where (
  ( owner = upper(trim('&&1')) and substr(object_name,1,4) not in ('SYS_','BIN$'))
  or ( owner = 'SYS' and object_name = 'GET_DG_IP_LIST')
  )
  and upper(trim(status)) != 'VALID'
  ;

  if invalid_count > 0 THEN
     raise_application_error(-20001,'There are ' || invalid_count || ' invalid objects found after running setup scripts');
  end if;
end;
/
