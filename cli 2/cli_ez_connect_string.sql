COL pdb_name FOR A30;
COL realm FOR A5;
COL region_acronym FOR A4 HEA 'RGN';
COL locale FOR A6;
COL db_name FOR A9;
COL host_name FOR A64;
COL ez_connect_string FOR A128;
--
SELECT pdb_name, realm, region_acronym, locale, db_name, host_name, ez_connect_string
  FROM C##IOD.dbc_pdbs p
 WHERE p.timestamp = (SELECT MAX(timestamp) FROM C##IOD.dbc_pdbs)
ORDER BY pdb_name, realm, region_acronym, locale, db_name
/