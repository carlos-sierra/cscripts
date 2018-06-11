$Header: 215187.1 readme.txt 11.4.5.8 2013/05/10 carlos.sierra $

How to Migrate a Plan using SQL Plan Management (SPM)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Notes:
1. AWR requires a license of the Oracle Diagnostics Pack
2. SQL Tuning Sets require a license of the Oracle Tuning Pack

Options to migrate a plan from one system to another using SPM:

Option 1:
  Steps:
    1. Create SQL Plan Baseline (SPB) in Source
       1.a From a Cursor; or
       1.b From AWR (requires Tuning Pack license)
    2. Package & Export SPB from Source
    3. Import & Restore SPB into Target

  pros: Simple
  cons: Requires a SPB in Source system

Option 2: (requires Tuning Pack license)
  Steps:
    1. Create SQL Tuning Set (STS) in Source
       1.a From a Cursor; or
       1.b From AWR
    2. Package & Export STS from Source
    3. Import & Restore STS into Target
    4. Create SPB from STS in Target

  pros: No SPB is required in Source system
  cons: Requires license for SQL Tuning Pack

Option 3: (requires Tuning Pack license)
  Steps:
    1. Use CoE Load SQL Baseline in Source
    2. Use output of 1 in Target. Follow instructions in log

  pros: Allows you to create SPB with plan from modified SQL (opt)
  cons: Requires license for SQL Tuning Pack

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
