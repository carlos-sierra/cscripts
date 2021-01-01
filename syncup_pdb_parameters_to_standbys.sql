-- syncup_pdb_parameters_to_standbys.sql - Sync up SPFILE PDB Parameters from Primary into Standby and Bystander
UNDEF pdb_name;
SET SERVEROUT ON;
BEGIN
  FOR i IN (SELECT name FROM v$containers WHERE name LIKE '%&pdb_name.%' AND open_mode = 'READ WRITE')
  LOOP
    DBMS_OUTPUT.put_line(i.name);
    C##IOD.PDB_CONFIG.CONFIGURE(P_PDB_NAME=>i.name,P_CONFIG_NAME=>'syncup pdb parameters to standbys');
  END LOOP;
END;
/
UNDEF pdb_name;
