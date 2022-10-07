SELECT name
  FROM v$containers
 WHERE (name LIKE '%DEV%' OR name LIKE '%TEST%')
   AND NOT (name LIKE '%\_DEV%' ESCAPE '\' OR name LIKE '%\_TEST%' ESCAPE '\')
/

