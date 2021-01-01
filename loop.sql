SET TIM ON TIMI ON;
DECLARE
  l_date DATE := SYSDATE;
  l_seconds INTEGER := 600;
BEGIN
  WHILE l_date + (l_seconds/24/60/60) > SYSDATE -- loop for l_seconds
  LOOP
    NULL;
  END LOOP;
END;
/
