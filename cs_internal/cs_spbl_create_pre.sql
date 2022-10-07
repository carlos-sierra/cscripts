---------------------------------------------------------------------------------------
--
-- cleaup unrelated outdated sql tuning sets (created by older versions of this script)
--
BEGIN
  FOR i IN (SELECT created, owner, name FROM wri$_sqlset_definitions WHERE created < SYSDATE - 1 AND name LIKE 'S%' AND statement_count = 1 ORDER BY 1)
  LOOP
    DBMS_OUTPUT.put_line('dropping unrelated and outdated sts '||i.owner||' '||i.name||' created on '||TO_CHAR(i.created, '&&cs_datetime_full_format.'));
    DBMS_SQLTUNE.drop_sqlset(sqlset_name => i.name, sqlset_owner => i.owner);
  END LOOP;
END;
/
--
-- Oracle Support Document 1276524.1 (ORA-13757: Can't drop SQL Tuning Set) can be found at: https://support.oracle.com/epmos/faces/DocumentDisplay?id=1276524.1
-- in case of ORA-13757: "SQL Tuning Set" "SQL_DETAIL_1491025646579" owned by user "SYS" is active.
-- select description, created, owner from DBA_SQLSET_REFERENCES where sqlset_name = 'SQL_DETAIL_1491025646579';
-- exec DBMS_SQLTUNE.DROP_TUNING_TASK('SQL_TUNING_1491025649684'); -- take value from description (e.g.: "created by: SQL Tuning Advisor - task: SQL_TUNING_1491025649684")
-- exec dbms_sqltune.drop_sqlset('SQL_DETAIL_1491025646579','SYS');
--
