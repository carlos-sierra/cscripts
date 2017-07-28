-- hour of the day (military format) when first maintenance window for a PDB may open during week days
-- i.e. if dbtimezone is UCT and we want to open 1st at 8AM PST we set to 15
VAR weekday_start_hh24 NUMBER; 
EXEC :weekday_start_hh24 := 15;
-- for how many hours we want to open maintenance windows for PDBs during week days
-- i.e. if we want to open windows within a 4 hours interval we set to 4
VAR weekday_hours NUMBER;
EXEC :weekday_hours := 4;
-- how long we want the maintenance window to last for each PDB during week days
-- i.e. if we want each PDB to have a window of 1 hour then we set to 1
VAR weekday_duration NUMBER;
EXEC :weekday_duration := 1;

-- hour of the day (military format) when first maintenance window for a PDB may open during weekends
-- i.e. if dbtimezone is UCT and we want to open 1st at 8AM PST we set to 15
VAR weekend_start_hh24 NUMBER; 
EXEC :weekend_start_hh24 := 15;
-- for how many hours we want to open maintenance windows for PDBs during weekends
-- i.e. if we want to open windows within a 4 hours interval we set to 4
VAR weekend_hours NUMBER;
EXEC :weekend_hours := 5;
-- how long we want the maintenance window to last for each PDB during weekends
-- i.e. if we want each PDB to have a window of 1 hour then we set to 1
VAR weekend_duration NUMBER;
EXEC :weekend_duration := 2;

WITH
pdbs AS ( -- list of PDBs ordered by CON_ID with enumerator as rank_num
SELECT pdb_id, pdb_name, RANK () OVER (ORDER BY pdb_id) rank_num FROM dba_pdbs WHERE pdb_id > 2
),
slot AS ( -- PDBs count
SELECT MAX(rank_num) count FROM pdbs
),
start_time AS (
SELECT pdb_id, pdb_name, 
       (TRUNC(SYSDATE) + (:weekday_start_hh24 / 24) + ((pdbs.rank_num - 1) * :weekday_hours / (slot.count - 1) / 24)) weekdays,
       (TRUNC(SYSDATE) + (:weekend_start_hh24 / 24) + ((pdbs.rank_num - 1) * :weekend_hours / (slot.count - 1) / 24)) weekends   
  FROM pdbs, slot
 WHERE slot.count > 1
)
SELECT pdb_id, pdb_name, 
       TO_CHAR(weekdays, 'HH24') weekdays_hh24, TO_CHAR(weekdays, 'MI') weekdays_mi, TO_CHAR(weekdays, 'SS') weekdays_ss,
       TO_CHAR(weekends, 'HH24') weekends_hh24, TO_CHAR(weekends, 'MI') weekends_mi, TO_CHAR(weekends, 'SS') weekends_ss
  FROM start_time
 ORDER BY
       pdb_id;
