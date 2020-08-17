SET HEA ON LIN 2490 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF LONG 240000 LONGC 2400 NUM 20 SERVEROUT OFF;
SET SERVEROUT ON;
--
DECLARE
    l_plans INTEGER;
    l_signature_count INTEGER := 0;
    l_plan_name_count INTEGER := 0;
BEGIN
    FOR i IN (SELECT signature, origin, description FROM dba_sql_plan_baselines WHERE origin LIKE 'MANUAL-LOAD%' AND description LIKE 'CLONE_SC%' AND sql_text LIKE '/* %(%,%)% [%] */%')
    LOOP
        l_signature_count := l_signature_count + 1;
        DBMS_OUTPUT.put_line(i.signature||' '||i.origin||' '||i.description);
        FOR j IN (SELECT sql_handle, plan_name FROM dba_sql_plan_baselines WHERE signature = i.signature)
        LOOP
            DBMS_OUTPUT.put_line(j.sql_handle||' '||j.plan_name);
            l_plans := DBMS_SPM.drop_sql_plan_baseline(j.sql_handle, j.plan_name);
            l_plan_name_count := l_plan_name_count + l_plans;
        END LOOP;
    END LOOP;
    DBMS_OUTPUT.put_line('Dropped '||l_plan_name_count||' SQL Plan Baselines from '||l_signature_count||' distinct Signatures');
END;
/
