DEF 1 = 'C##IOD';


PRO dbc_dbcps_pdb_metadata. persistent
DECLARE
  l_exists NUMBER;
  l_sql_statement VARCHAR2(32767) := q'[
CREATE TABLE &&1..dbc_dbcps_pdb_metadata (
  -- /* key: id and pdb_name */
  id                              NUMBER          NOT NULL  -- should be enough for uniqueness but sea has two pdbs DBCPS_METADATA and DBCPS_METADATA_PROD, thus collisions on id alone are possible
, pdb_name                        VARCHAR2(128)   NOT NULL
  -- data elements
, compartment_id                  VARCHAR2(128)   NOT NULL
, tenancy_id                      VARCHAR2(128)
, phonebook_entry                 VARCHAR2(256)
, location                        VARCHAR2(64)    NOT NULL  -- phx|phx-ad-1|phx-ad-2|phx-ad-3
, locale                          VARCHAR2(4)     NOT NULL  -- RGN|AD1|AD2|AD3
, state                           VARCHAR2(64)    NOT NULL  -- READY|FAILED|PROVISIONING
, type                            VARCHAR2(128)   NOT NULL  -- KIEV|GENERAL|CASPER|WORKFLOW|TELEMETRY|CANARY_INTERNAL
, parent_cdb_name                 VARCHAR2(128)             -- iod01, iod02, ... kiev02, ... kiev02a1, ... oradb-casp01rg, ... oradb-iod01
, created                         TIMESTAMP(6)    NOT NULL
, last_modified                   TIMESTAMP(6)    NOT NULL
, replicated                      TIMESTAMP(6)    NOT NULL
)
TABLESPACE IOD
]';
  l_sql_statement2 VARCHAR2(32767) := q'[
CREATE UNIQUE INDEX &&1..dbc_dbcps_pdb_metadata_pk 
ON &&1..dbc_dbcps_pdb_metadata 
(id, pdb_name) 
TABLESPACE IOD
]';
  l_sql_statement3 VARCHAR2(32767) := q'[
ALTER TABLE &&1..dbc_dbcps_pdb_metadata ADD PRIMARY KEY 
(id, pdb_name) 
USING INDEX &&1..dbc_dbcps_pdb_metadata_pk
]';
BEGIN
  SELECT COUNT(*) INTO l_exists FROM dba_tables WHERE owner = UPPER(TRIM('&&1.')) AND table_name = UPPER('dbc_dbcps_pdb_metadata');
  IF l_exists = 0 THEN
    EXECUTE IMMEDIATE l_sql_statement;
  END IF;
  SELECT COUNT(*) INTO l_exists FROM dba_indexes WHERE owner = UPPER(TRIM('&&1.')) AND index_name = UPPER('dbc_dbcps_pdb_metadata_pk');
  IF l_exists = 0 THEN
    EXECUTE IMMEDIATE l_sql_statement2;
    EXECUTE IMMEDIATE l_sql_statement3;
  END IF;
END;
/    

/* ------------------------------------------------------------------------------------ */

PRO dbc_parameter. persistent
DECLARE
  l_exists NUMBER;
  l_data_length NUMBER;
  l_sql_statement VARCHAR2(32767) := q'[
CREATE TABLE &&1..dbc_parameter (
  -- /* key: region */
  parameter                       VARCHAR2(30)    NOT NULL
, type                            VARCHAR2(30)    NOT NULL
  -- data elements
, value                           VARCHAR2(256)   NOT NULL
, description                     VARCHAR2(512)
)
TABLESPACE IOD
]';
  l_sql_statement2 VARCHAR2(32767) := q'[
CREATE UNIQUE INDEX &&1..dbc_parameter_pk 
ON &&1..dbc_parameter 
(parameter, type) 
TABLESPACE IOD
]';
  l_sql_statement3 VARCHAR2(32767) := q'[
ALTER TABLE &&1..dbc_parameter ADD PRIMARY KEY 
(parameter, type) 
USING INDEX &&1..dbc_parameter_pk
]';
  l_sql_statement4 VARCHAR2(32767) := q'[
ALTER TABLE &&1..dbc_parameter MODIFY (value VARCHAR2(256))
]';
BEGIN
  SELECT COUNT(*) INTO l_exists FROM dba_tables WHERE owner = UPPER(TRIM('&&1.')) AND table_name = UPPER('dbc_parameter');
  IF l_exists = 0 THEN
    EXECUTE IMMEDIATE l_sql_statement;
  END IF;
  SELECT COUNT(*) INTO l_exists FROM dba_indexes WHERE owner = UPPER(TRIM('&&1.')) AND index_name = UPPER('dbc_parameter_pk');
  IF l_exists = 0 THEN
    EXECUTE IMMEDIATE l_sql_statement2;
    EXECUTE IMMEDIATE l_sql_statement3;
  END IF;
  SELECT data_length INTO l_data_length FROM dba_tab_columns WHERE owner = UPPER(TRIM('&&1.')) AND table_name = UPPER('dbc_parameter') AND column_name = UPPER('value');
  IF l_data_length < 256 THEN
    EXECUTE IMMEDIATE l_sql_statement4;
  END IF;
END;
/    