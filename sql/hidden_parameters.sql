SET HEA ON LIN 500 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF;

COL name FOR A50;
COL value FOR A50;
COL isdefault FOR A10;
COL ismod FOR A10;
COL isadj FOR A10;

SELECT x.ksppinm name, 
       y.kspftctxvl value, 
       y.kspftctxdf isdefault, 
       DECODE(BITAND(y.kspftctxvf,7),1,'MODIFIED',4,'SYSTEM_MOD','FALSE') ismod,
       DECODE(BITAND(y.kspftctxvf,2),2,'TRUE','FALSE') isadj 
  FROM sys.x$ksppi x, 
       sys.x$ksppcv2 y 
 WHERE x.inst_id = USERENV('INSTANCE')
   AND y.inst_id = USERENV('INSTANCE') 
   AND x.indx+1 = y.kspftctxpn
   --AND x.ksppinm LIKE '\_%' ESCAPE '\'
   AND (y.kspftctxdf = 'FALSE' OR DECODE(BITAND(y.kspftctxvf,7),1,'MODIFIED',4,'SYSTEM_MOD','FALSE') <> 'FALSE')
 ORDER BY
       x.ksppinm
/
