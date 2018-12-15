define install_user = &&1;

prompt ========================================
prompt Installing database user&&1
prompt ========================================

set feedback off;
set verify off;


whenever sqlerror exit failure;
Set serveroutput on;
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

alter user &&install_user identified by values 'S:5565CBA22F98CCDE79DACD2882DB60AFDFFA51656EF21CB982064AFC9AD1;T:655635182BCB8AA0BDCED8F90FCBF93F1CB036BBBF9237A648C9A67EABC651D5F0C2F6C24F91E278725A7D5AB67033CB1ED14BD95801F02A30351A15198F5EFDE92D1BFAE5AFBF230EB5D3160DBA6785';

BEGIN
  for r in ( select username,DEFAULT_TABLESPACE from dba_users where username = upper('&&1') ) loop
    execute immediate 'alter user ' || r.username || ' QUOTA UNLIMITED ON ' || r.DEFAULT_TABLESPACE || ' container=current';
  end loop;
end;
/

@iod/iod_spm/setup.sql &&1
@iod/iod_amw/setup.sql &&1
@iod/iod_rsrc_mgr/setup.sql &&1
@iod/iod_sess/setup.sql &&1
@iod/iod_space/setup.sql &&1
@iod/iod_sqlstats/setup.sql &&1

