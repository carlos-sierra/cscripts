SET SERVEROUT ON;
-- sets cpu_count for instance caging
DECLARE
  l_reserved_cores CONSTANT NUMBER := 2; -- for anything outside database
  l_num_cpu_cores NUMBER;
  l_num_cpus NUMBER;
  l_value VARCHAR2(4000);
  l_cpu_count NUMBER;
BEGIN
  SELECT value INTO l_num_cpu_cores FROM v$osstat WHERE stat_name = 'NUM_CPU_CORES';
  SELECT value INTO l_num_cpus FROM v$osstat WHERE stat_name = 'NUM_CPUS';
  SELECT value INTO l_value FROM v$parameter WHERE name = 'cpu_count';
  l_cpu_count := l_num_cpus - (l_reserved_cores * l_num_cpus / l_num_cpu_cores);
  DBMS_OUTPUT.PUT_LINE('current NUM_CPU_CORES: '||l_num_cpu_cores);
  DBMS_OUTPUT.PUT_LINE('current NUM_CPUS: '||l_num_cpus);
  DBMS_OUTPUT.PUT_LINE('current cpu_count: '||l_value);
  DBMS_OUTPUT.PUT_LINE('expected cpu_count: '||l_cpu_count);
  IF TO_NUMBER(l_value) <> l_cpu_count THEN
    DBMS_OUTPUT.PUT_LINE('set cpu_count to: '||l_cpu_count);
    EXECUTE IMMEDIATE 'ALTER SYSTEM SET cpu_count = '||l_cpu_count;
    SELECT value INTO l_value FROM v$parameter WHERE name = 'cpu_count';
    DBMS_OUTPUT.PUT_LINE('new cpu_count: '||l_value);
  END IF;
END;
/
