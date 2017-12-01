SET SERVEROUT ON LIN 300;
BEGIN
  FOR i IN (SELECT sql_id, address, hash_value, SUBSTR(sql_text, 1, 100) sql_text_100,
                   COUNT(*) cursors, COUNT(DISTINCT con_id) pdbs, COUNT(DISTINCT plan_hash_value) plans
              FROM v$sql
             WHERE parsing_user_id > 0
             GROUP BY sql_id, address, hash_value, SUBSTR(sql_text, 1, 100)
            HAVING COUNT(*) > 100
             ORDER BY sql_id, address, hash_value)
  LOOP
    DBMS_OUTPUT.PUT_LINE('SQL_ID:'||i.sql_id||' ADDRESS:'||i.address||' HASH_VALUE:'||i.hash_value||' CURSORS:'||i.cursors||' PDBS:'||i.pdbs||' PLANS:'||i.plans||' '||i.sql_text_100);
    DBMS_SHARED_POOL.PURGE(i.address||','||i.hash_value, 'c');
  END LOOP;
EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('*** '||SQLERRM);
END;
/
