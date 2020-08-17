SET HEA ON LIN 2490 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF LONG 240000 LONGC 2400 NUM 20 SERVEROUT OFF;
SET SERVEROUT ON;
ALTER SESSION SET CONTAINER = CDB$ROOT;
-- ends blackout if still in progress
EXEC C##IOD.iod_admin.set_blackout(p_minutes => 0);
EXEC DBMS_LOCK.sleep(1);
-- resets automatic maintenance windows
EXEC C##IOD.iod_amw.reset_amw;
-- resets cdb level resource manager plan if it exists and if it is not active already
-- BEGIN
--     FOR i IN (
--         SELECT r.plan
--         FROM dba_cdb_rsrc_plans r
--         WHERE r.plan = 'IOD_CDB_PLAN'
--         AND NOT EXISTS (SELECT NULL FROM v$parameter p WHERE p.name = 'resource_manager_plan' AND p.value = 'FORCE:'||r.plan)
--     )
--     LOOP
--         DBMS_OUTPUT.put_line('ALTER SYSTEM SET RESOURCE_MANAGER_PLAN=''FORCE:'||i.plan||'''');
--         EXECUTE IMMEDIATE 'ALTER SYSTEM SET RESOURCE_MANAGER_PLAN=''FORCE:'||i.plan||'''';
--     END LOOP;
-- END;
-- /
--