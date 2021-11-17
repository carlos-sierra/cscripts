BEGIN
    FOR i IN (SELECT DISTINCT d.directive_id
                FROM dba_sql_plan_directives d,
                    dba_sql_plan_dir_objects o,
                    dba_users u,
                    v$system_parameter p
                WHERE o.directive_id = d.directive_id
                AND u.username = o.owner
                AND u.oracle_maintained = 'N'
                AND p.name = 'optimizer_adaptive_statistics'
                AND p.value = 'FALSE'
    )
    LOOP
        DBMS_SPD.drop_sql_plan_directive(directive_id => i.directive_id);
    END LOOP;
END;
/
