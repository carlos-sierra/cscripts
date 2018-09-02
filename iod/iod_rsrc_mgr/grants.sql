GRANT INHERIT PRIVILEGES ON USER sys TO &&1.;
--
BEGIN
  DBMS_RESOURCE_MANAGER_PRIVS.grant_system_privilege (
    grantee_name   => '&&1.', 
    privilege_name => 'ADMINISTER_RESOURCE_MANAGER', 
    admin_option   => TRUE
  );
END;
/
