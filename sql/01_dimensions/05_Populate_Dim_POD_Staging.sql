/**
Script Name:  05_Populate_Dim_POD_Staging.sql
Description:  SQL object
Author:       Sridhar Peddi
Created:      2026-01-09

Change Log:
  2026-01-09  Sridhar Peddi    Initial creation
**/

USE [Data_Lab_SWL_Live];
GO

PRINT '========================================';
PRINT 'Populating Staging_POD';
PRINT 'Started: ' + CONVERT(VARCHAR, GETDATE(), 121);
PRINT '========================================';
GO

-- Clear existing staging data
TRUNCATE TABLE [Analytics].[Staging_POD];
PRINT '[OK] Truncated staging table';
GO

-- Populate staging with NHS POD taxonomy
INSERT INTO [Analytics].[Staging_POD] 
    (POD_Code, POD_Domain, POD_Subcategory, POD_Measure, POD_Description)
VALUES
    -- INPATIENT ACTIVITY
    ('NEL', 'Admitted Patient Care', 'Non-Elective', 'SPELL', 'Non-elective inpatient spell'),
    ('EL', 'Admitted Patient Care', 'Elective', 'SPELL', 'Elective inpatient spell'),
    ('DC', 'Admitted Patient Care', 'Day Case', 'SPELL', 'Day case spell'),
    ('MAT', 'Admitted Patient Care', 'Maternity', 'SPELL', 'Maternity spell'),
    ('OBD', 'Admitted Patient Care', 'Occupied Bed Days', 'OBD', 'Occupied bed days'),
    
    -- OUTPATIENT ACTIVITY  
    ('OPFASPCL', 'Outpatient', 'First Attendance', 'ATT', 'First OP attendance - specialist'),
    ('OPFAGPCL', 'Outpatient', 'First Attendance', 'ATT', 'First OP attendance - GP-led'),
    ('OPFOLSPCL', 'Outpatient', 'Follow-up', 'ATT', 'Follow-up OP attendance - specialist'),
    ('OPFOLGPCL', 'Outpatient', 'Follow-up', 'ATT', 'Follow-up OP attendance - GP-led'),
    ('OPDNA', 'Outpatient', 'Did Not Attend', 'ATT', 'OP did not attend'),
    ('OPPROC', 'Outpatient', 'Procedure', 'PROC', 'OP procedure'),
    
    -- A&E ACTIVITY
    ('AE', 'Accident & Emergency', 'Emergency Attendance', 'ATT', 'A&E attendance'),
    ('AETYPE1', 'Accident & Emergency', 'Type 1 Department', 'ATT', 'A&E Type 1 attendance'),
    ('AETYPE2', 'Accident & Emergency', 'Type 2 Department', 'ATT', 'A&E Type 2 attendance'),
    ('AETYPE3', 'Accident & Emergency', 'Type 3 Department', 'ATT', 'A&E Type 3 attendance'),
    
    -- COMMUNITY & OTHER
    ('COMM', 'Community', 'Community Contact', 'CONT', 'Community service contact'),
    ('MH', 'Mental Health', 'MH Contact', 'CONT', 'Mental health contact'),
    ('IAPT', 'Mental Health', 'IAPT', 'TREAT', 'IAPT treatment');

PRINT '[OK] Inserted ' + CAST(@@ROWCOUNT AS VARCHAR) + ' POD records into staging';
GO

PRINT '';
PRINT 'Validation: Sample staging data';
SELECT TOP 10 * FROM [Analytics].[Staging_POD];
GO

PRINT '';
PRINT '========================================';
PRINT 'POD Staging Population Complete';
PRINT 'Completed: ' + CONVERT(VARCHAR, GETDATE(), 121);
PRINT '========================================';
PRINT '';
PRINT 'Next Step: Run sp_Load_Dim_POD to load into dimension table';
GO
