SET LINES 200;

COL ksppinm FOR A80 HEA 'NAME';
COL ksppstvl FOR A80 HEA 'VALUE';

SELECT p.ksppinm,
       v.con_id,
       v.ksppstvl
  FROM x$ksppi p, 
       x$ksppsv v 
 WHERE SUBSTR(p.ksppinm, 1, 1) = '_'
   AND p.ksppinm LIKE '%&parameter_name.%'
   AND v.indx = p.indx
   AND v.inst_id = p.inst_id
 ORDER BY
       p.ksppinm,
       v.con_id
/
