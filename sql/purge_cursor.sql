DECLARE
  name varchar2(50);
BEGIN
  select address||','||hash_value into name
  from v$sqlarea 
  where sql_id like '&sql_id';
  sys.dbms_shared_pool.purge(name,'C',1);
END;
/

