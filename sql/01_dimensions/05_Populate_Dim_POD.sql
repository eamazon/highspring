/**
Script Name:  05_Populate_Dim_POD.sql
Description:  Populate Dim_POD with official NHS England POD taxonomy
Author:       Sridhar Peddi
Created:      2026-01-02

Change Log:
  2026-01-02  Sridhar Peddi    Initial creation
  2026-01-12  Sridhar Peddi    Add ETL batch/table logging
**/

USE [Data_Lab_SWL_Live];
GO
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

PRINT '========================================';
PRINT 'Populating Dim_POD with NHS Taxonomy';
PRINT 'Started: ' + CONVERT(VARCHAR, GETDATE(), 121);
PRINT '========================================';

DECLARE @BatchID INT = NULL;
DECLARE @RowsInserted INT = 0;
DECLARE @ErrorMessage NVARCHAR(4000);

BEGIN TRY
    EXEC [Analytics].[sp_Start_ETL_Batch]
        @BatchName = 'Populate_Dim_POD',
        @BatchID = @BatchID OUTPUT;

    PRINT 'Batch ID: ' + CAST(@BatchID AS VARCHAR);

    -------------------------------------------------------------------------------
    -- Populate Dim_POD with standardized NHS POD codes
    -------------------------------------------------------------------------------

    -- Disable identity insert if applicable
    SET IDENTITY_INSERT [Analytics].[tbl_Dim_POD] OFF;

    ;WITH POD_Source AS (
        SELECT
            v.POD_Code,
            v.POD_Domain,
            v.POD_Subcategory,
            v.POD_Measure,
            v.POD_Description,
            v.POD_Dataset,
            v.POD_MainGroup,
            v.POD_SubGroup,
            v.POD_Category,
            v.Is_Elective,
            v.Is_Emergency,
            v.Is_Admitted,
            v.Is_Outpatient,
            v.Is_AE,
            v.Created_By
        FROM (VALUES
            /* ======================================================================================
               1. ADMITTED PATIENT CARE (Inpatient)
               ====================================================================================== */
            -- Non-Elective (Emergency)
            ('NEL',       'Admitted Patient Care', 'Non-Elective', 'SPELL', 'Non-elective inpatient spell',     'APC', 'Inpatient', 'Non-Elective', 'Activity', 0, 1, 1, 0, 0, SUSER_SNAME()),
            ('NELXBD',    'Admitted Patient Care', 'Non-Elective', 'XBD',   'Emergency excess bed days',        'APC', 'Inpatient', 'Bed Days',     'Activity', 0, 1, 1, 0, 0, SUSER_SNAME()),
            ('NELST',     'Admitted Patient Care', 'Non-Elective', 'SPELL', 'Emergency short stay spell',       'APC', 'Inpatient', 'Non-Elective', 'Activity', 0, 1, 1, 0, 0, SUSER_SNAME()),
            ('NELOBD',    'Admitted Patient Care', 'Non-Elective', 'OBD',   'Emergency occupied bed days',      'APC', 'Inpatient', 'Bed Days',     'Activity', 0, 1, 1, 0, 0, SUSER_SNAME()),
            -- Non-Elective (Non-Emergency/Transfers)
            ('NELNE',     'Admitted Patient Care', 'Non-Elective', 'SPELL', 'Non-emergency finished spell',     'APC', 'Inpatient', 'Non-Elective', 'Activity', 0, 0, 1, 0, 0, SUSER_SNAME()),
            ('NELNEXBD',  'Admitted Patient Care', 'Non-Elective', 'XBD',   'Non-emergency excess bed days',    'APC', 'Inpatient', 'Bed Days',     'Activity', 0, 0, 1, 0, 0, SUSER_SNAME()),
            ('NELNEOBD',  'Admitted Patient Care', 'Non-Elective', 'XBD',   'Non-emergency occupied bed days',  'APC', 'Inpatient', 'Bed Days',     'Activity', 0, 0, 1, 0, 0, SUSER_SNAME()),
            -- Elective & Daycase
            ('DC',        'Admitted Patient Care', 'Day Case',     'SPELL', 'Day case spell',                   'APC', 'Inpatient', 'Day Case',     'Activity', 1, 0, 1, 0, 0, SUSER_SNAME()),
            ('EL',        'Admitted Patient Care', 'Elective',     'SPELL', 'Ordinary elective spell',          'APC', 'Inpatient', 'Elective',     'Activity', 1, 0, 1, 0, 0, SUSER_SNAME()),
            ('RADAY',     'Admitted Patient Care', 'Elective',     'SPELL', 'Regular day admission spell',      'APC', 'Inpatient', 'Elective',     'Activity', 1, 0, 1, 0, 0, SUSER_SNAME()),
            ('RANIGHT',   'Admitted Patient Care', 'Elective',     'SPELL', 'Regular night admission spell',    'APC', 'Inpatient', 'Elective',     'Activity', 1, 0, 1, 0, 0, SUSER_SNAME()),
            ('ELXBD',     'Admitted Patient Care', 'Elective',     'XBD',   'Elective excess bed days',         'APC', 'Inpatient', 'Bed Days',     'Activity', 1, 0, 1, 0, 0, SUSER_SNAME()),
            ('ELOBD',     'Admitted Patient Care', 'Elective',     'OBD',   'Elective occupied bed days',       'APC', 'Inpatient', 'Bed Days',     'Activity', 1, 0, 1, 0, 0, SUSER_SNAME()),
            -- General Inpatient
            ('IPOBD',     'Admitted Patient Care', 'General',      'OBD',   'Generic occupied bed days',        'APC', 'Inpatient', 'Bed Days',     'Activity', 0, 0, 1, 0, 0, SUSER_SNAME()),
            ('IPFCE',     'Admitted Patient Care', 'General',      'FCE',   'Finished Consultant Episode',      'APC', 'Inpatient', 'Episodic',     'Activity', 0, 0, 1, 0, 0, SUSER_SNAME()),
            ('IPSPECIAL', 'Admitted Patient Care', 'General',      'HOUR',  'Specialling (enhanced observation)','APC', 'Inpatient', 'Other',       'Activity', 0, 0, 1, 0, 0, SUSER_SNAME()),

            /* ======================================================================================
               2. OUTPATIENT (Attendance & Procedures)
               ====================================================================================== */
            -- First Attendance
            ('OPFASPCL',  'Outpatient', 'Attendance', 'ATT', 'First OP attendance - Consultant',     'OP', 'Outpatient', 'First',      'Activity', 1, 0, 0, 1, 0, SUSER_SNAME()),
            ('OPFASPNCL', 'Outpatient', 'Attendance', 'ATT', 'First OP attendance - Non-Consultant', 'OP', 'Outpatient', 'First',      'Activity', 1, 0, 0, 1, 0, SUSER_SNAME()),
            ('OPFAMPCL',  'Outpatient', 'Attendance', 'ATT', 'First OP attendance - Multi-Prof',     'OP', 'Outpatient', 'First',      'Activity', 1, 0, 0, 1, 0, SUSER_SNAME()),
            ('OPFAMPNCL', 'Outpatient', 'Attendance', 'ATT', 'First OP attendance - MP Non-Cons',    'OP', 'Outpatient', 'First',      'Activity', 1, 0, 0, 1, 0, SUSER_SNAME()),
            ('NF2FFA',    'Outpatient', 'Attendance', 'ATT', 'First OP attendance - Non-Face2Face',  'OP', 'Outpatient', 'First',      'Activity', 1, 0, 0, 1, 0, SUSER_SNAME()),
            ('OPFAHOME',  'Outpatient', 'Attendance', 'ATT', 'First OP attendance - Domiciliary',    'OP', 'Outpatient', 'First',      'Activity', 1, 0, 0, 1, 0, SUSER_SNAME()),
            ('OPFAPREOP', 'Outpatient', 'Attendance', 'ATT', 'Pre-operative assessment (First)',     'OP', 'Outpatient', 'First',      'Activity', 1, 0, 0, 1, 0, SUSER_SNAME()),
            ('WAFA',      'Outpatient', 'Attendance', 'ATT', 'Ward attender (First)',                'OP', 'Outpatient', 'First',      'Activity', 1, 0, 0, 1, 0, SUSER_SNAME()),
            ('OPFA',      'Outpatient', 'Attendance', 'ATT', 'First OP attendance - Generic',        'OP', 'Outpatient', 'First',      'Activity', 1, 0, 0, 1, 0, SUSER_SNAME()),
            -- Follow-up Attendance
            ('OPFUPSPCL', 'Outpatient', 'Attendance', 'ATT', 'Follow-up OP attendance - Consultant',     'OP', 'Outpatient', 'Follow-up', 'Activity', 1, 0, 0, 1, 0, SUSER_SNAME()),
            ('OPFUPSPNCL','Outpatient', 'Attendance', 'ATT', 'Follow-up OP attendance - Non-Consultant', 'OP', 'Outpatient', 'Follow-up', 'Activity', 1, 0, 0, 1, 0, SUSER_SNAME()),
            ('OPFUPMPCL', 'Outpatient', 'Attendance', 'ATT', 'Follow-up OP attendance - Multi-Prof',     'OP', 'Outpatient', 'Follow-up', 'Activity', 1, 0, 0, 1, 0, SUSER_SNAME()),
            ('OPFUPMPNCL','Outpatient', 'Attendance', 'ATT', 'Follow-up OP attendance - MP Non-Cons',    'OP', 'Outpatient', 'Follow-up', 'Activity', 1, 0, 0, 1, 0, SUSER_SNAME()),
            ('NF2FFUP',   'Outpatient', 'Attendance', 'ATT', 'Follow-up OP attendance - Non-Face2Face',  'OP', 'Outpatient', 'Follow-up', 'Activity', 1, 0, 0, 1, 0, SUSER_SNAME()),
            ('OPFUPHOME', 'Outpatient', 'Attendance', 'ATT', 'Follow-up OP attendance - Domiciliary',    'OP', 'Outpatient', 'Follow-up', 'Activity', 1, 0, 0, 1, 0, SUSER_SNAME()),
            ('OPFUPPREOP','Outpatient', 'Attendance', 'ATT', 'Pre-operative assessment (Follow-up)',     'OP', 'Outpatient', 'Follow-up', 'Activity', 1, 0, 0, 1, 0, SUSER_SNAME()),
            ('WAFUP',     'Outpatient', 'Attendance', 'ATT', 'Ward attender (Follow-up)',                'OP', 'Outpatient', 'Follow-up', 'Activity', 1, 0, 0, 1, 0, SUSER_SNAME()),
            ('OPFUP',     'Outpatient', 'Attendance', 'ATT', 'Follow-up OP attendance - Generic',        'OP', 'Outpatient', 'Follow-up', 'Activity', 1, 0, 0, 1, 0, SUSER_SNAME()),
            -- Procedures
            ('OPPROCFA',  'Outpatient', 'Procedure',  'ATT', 'OP procedure (First)',                 'OP', 'Outpatient', 'Procedure',  'Activity', 1, 0, 0, 1, 0, SUSER_SNAME()),
            ('OPPROCFUP', 'Outpatient', 'Procedure',  'ATT', 'OP procedure (Follow-up)',             'OP', 'Outpatient', 'Procedure',  'Activity', 1, 0, 0, 1, 0, SUSER_SNAME()),
            ('OPPROC',    'Outpatient', 'Procedure',  'ATT', 'OP procedure - Generic',               'OP', 'Outpatient', 'Procedure',  'Activity', 1, 0, 0, 1, 0, SUSER_SNAME()),
            
            /* ======================================================================================
               3. DIRECT ACCESS (Diagnostic)
               ====================================================================================== */
            ('DAIMG',     'Direct Access', 'Imaging', 'ATT',  'Direct access imaging',               'OP', 'Outpatient', 'Diagnostics', 'Activity', 0, 0, 0, 1, 0, SUSER_SNAME()),
            ('DALAB',     'Direct Access', 'Pathology','TEST','Direct access lab test',              'OP', 'Outpatient', 'Diagnostics', 'Activity', 0, 0, 0, 1, 0, SUSER_SNAME()),
            ('DAOTHER',   'Direct Access', 'Other',   'ATT',  'Direct access other',                 'OP', 'Outpatient', 'Diagnostics', 'Activity', 0, 0, 0, 1, 0, SUSER_SNAME()),

            /* ======================================================================================
               4. EMERGENCY CARE (A&E)
               ====================================================================================== */
            ('AE',        'Emergency Care', 'A&E',    'ATT',  'A&E Attendance',                      'AE', 'A&E',        'A&E',         'Activity', 0, 1, 0, 0, 1, SUSER_SNAME()),

            /* ======================================================================================
               5. UNBUNDLED & HIGH COST
               ====================================================================================== */
            ('DRUG',      'Unbundled', 'High Cost',   'COST', 'High cost drugs',                     'Unbundled', 'Unbundled', 'Drugs', 'Financial', 0, 0, 0, 0, 0, SUSER_SNAME()),
            ('DEVICE',    'Unbundled', 'High Cost',   'COST', 'High cost devices',                   'Unbundled', 'Unbundled', 'Devices', 'Financial', 0, 0, 0, 0, 0, SUSER_SNAME()),
            ('UNBCHEMO',  'Unbundled', 'Chemo',       'HRG',  'Chemotherapy',                        'Unbundled', 'Unbundled', 'Chemo', 'Activity', 0, 0, 0, 1, 0, SUSER_SNAME()),
            ('UNBRAD',    'Unbundled', 'Radiology',   'HRG',  'Radiology (Unbundled)',               'Unbundled', 'Unbundled', 'Radio', 'Activity', 0, 0, 0, 1, 0, SUSER_SNAME()),
            ('UNBRTHPY',  'Unbundled', 'Radiotherapy','HRG',  'Radiotherapy',                        'Unbundled', 'Unbundled', 'Radio', 'Activity', 0, 0, 0, 1, 0, SUSER_SNAME()),
            ('UNBREHAB',  'Unbundled', 'Rehab',       'WOBD', 'Rehabilitation weighted bed days',    'Unbundled', 'Unbundled', 'Rehab', 'Activity', 0, 0, 1, 0, 0, SUSER_SNAME()),
            ('UNBPALL',   'Unbundled', 'Palliative',  'HRG',  'Palliative care',                     'Unbundled', 'Unbundled', 'Pall',  'Activity', 0, 0, 0, 0, 0, SUSER_SNAME()),
            ('UNBACC',    'Unbundled', 'Critical Care','OBD', 'Adult critical care',                 'Unbundled', 'Unbundled', 'CC',    'Activity', 0, 1, 1, 0, 0, SUSER_SNAME()),
            ('UNBPCC',    'Unbundled', 'Critical Care','OBD', 'Paediatric critical care',            'Unbundled', 'Unbundled', 'CC',    'Activity', 0, 1, 1, 0, 0, SUSER_SNAME()),
            ('UNBNCC',    'Unbundled', 'Critical Care','OCD', 'Neonatal critical care',              'Unbundled', 'Unbundled', 'CC',    'Activity', 0, 1, 1, 0, 0, SUSER_SNAME()),
            ('UNBOTHER',  'Unbundled', 'Other',       'HRG',  'Other unbundled activity',            'Unbundled', 'Unbundled', 'Other', 'Activity', 0, 0, 0, 0, 0, SUSER_SNAME()),

            /* ======================================================================================
               6. COMMUNITY / OTHER / AMBULANCE
               ====================================================================================== */
            ('YOC',       'Community', 'Care Model',  'YOC',   'Year of care',                       'Comm', 'Community', 'Model',      'Activity', 0, 0, 0, 0, 0, SUSER_SNAME()),
            ('POC',       'Community', 'Care Model',  'POC',   'Package of care',                    'Comm', 'Community', 'Model',      'Activity', 0, 0, 0, 0, 0, SUSER_SNAME()),
            ('MATPATHAN', 'Community', 'Maternity',   'MPATH', 'Maternity pathway (Ante-natal)',     'Comm', 'Community', 'Maternity',  'Activity', 0, 0, 0, 0, 0, SUSER_SNAME()),
            ('MATPATHPN', 'Community', 'Maternity',   'MPATH', 'Maternity pathway (Post-natal)',     'Comm', 'Community', 'Maternity',  'Activity', 0, 0, 0, 0, 0, SUSER_SNAME()),
            ('IVF',       'Specialized','IVF',        'CYCLE', 'IVF treatment cycle',                'Other', 'Specialized','IVF',      'Activity', 1, 0, 0, 1, 0, SUSER_SNAME()),
            ('TEST',      'Other',      'Test',       'TEST',  'Generic Test',                       'Other', 'Other',      'Test',     'Activity', 0, 0, 0, 0, 0, SUSER_SNAME()),
            ('ARD',       'Specialized','Dialysis',   'SESSION','Adult renal dialysis',              'Other', 'Specialized','Dialysis', 'Activity', 0, 0, 0, 1, 0, SUSER_SNAME()),
            ('CRD',       'Specialized','Dialysis',   'SESSION','Child renal dialysis',              'Other', 'Specialized','Dialysis', 'Activity', 0, 0, 0, 1, 0, SUSER_SNAME()),
            ('CCTRANS',   'Ambulance',  'Transport',  'JOURNEY','Critical care transport',           'Amb',   'Ambulance',  'Transport','Activity', 0, 1, 0, 0, 0, SUSER_SNAME()),
            ('AMBUE',     'Ambulance',  'Urgent',     'CALL',   'Ambulance call (Urgent/Emergency)', 'Amb',   'Ambulance',  'Call',     'Activity', 0, 1, 0, 0, 0, SUSER_SNAME()),
            ('AMBHTR',    'Ambulance',  'Hear/Treat', 'PATIENT','Ambulance hear and treat',          'Amb',   'Ambulance',  'Contact',  'Activity', 0, 1, 0, 0, 0, SUSER_SNAME()),
            ('AMBSTR',    'Ambulance',  'See/Treat',  'INCIDENT','Ambulance see and treat',          'Amb',   'Ambulance',  'Contact',  'Activity', 0, 1, 0, 0, 0, SUSER_SNAME()),
            ('AMBSTC',    'Ambulance',  'See/Convey', 'INCIDENT','Ambulance see, treat and convey',  'Amb',   'Ambulance',  'Contact',  'Activity', 0, 1, 0, 0, 0, SUSER_SNAME()),
            ('AMBOTHER',  'Ambulance',  'Other',      'INCIDENT','Other ambulance activity',         'Amb',   'Ambulance',  'Contact',  'Activity', 0, 0, 0, 0, 0, SUSER_SNAME()),
            ('PTSTRANS',  'Ambulance',  'Transport',  'JOURNEY','Patient transport services',        'Amb',   'Ambulance',  'Transport','Activity', 1, 0, 0, 0, 0, SUSER_SNAME()),
            ('MAINT',     'Other',      'Maintenance','MAINT',  'Device maintenance',                'Other', 'Other',      'Maint',    'Activity', 0, 0, 0, 0, 0, SUSER_SNAME()),
            ('DCRE',      'Community',  'Day Care',   'ATT',    'Community day care',                'Comm',  'Community',  'Day Care', 'Activity', 0, 0, 0, 0, 0, SUSER_SNAME()),
            ('COMMINIT',  'Community',  'Contact',    'CONTACT','Community initial contact',         'Comm',  'Community',  'Contact',  'Activity', 0, 0, 0, 0, 0, SUSER_SNAME()),
            ('COMMSUB',   'Community',  'Contact',    'CONTACT','Community subsequent contact',      'Comm',  'Community',  'Contact',  'Activity', 0, 0, 0, 0, 0, SUSER_SNAME()),
            ('COMM',      'Community',  'Contact',    'CONTACT','Community contact (Generic)',       'Comm',  'Community',  'Contact',  'Activity', 0, 0, 0, 0, 0, SUSER_SNAME()),
            ('SCREEN',    'Community',  'Screening',  'PATIENT','Public health screening',           'Comm',  'Community',  'Screening','Activity', 0, 0, 0, 0, 0, SUSER_SNAME()),
            ('MDT',       'Other',      'MDT',        'ATT',    'Multidisciplinary team review',     'Other', 'Other',      'MDT',      'Activity', 0, 0, 0, 0, 0, SUSER_SNAME()),
            ('LAC',       'Community',  'Child',      'ATT',    'Looked after children assessment',  'Comm',  'Community',  'Child',    'Activity', 0, 0, 0, 0, 0, SUSER_SNAME()),
            ('PATIENT',   'Other',      'Patient',    'PATIENT','Generic patient count',             'Other', 'Other',      'Patient',  'Activity', 0, 0, 0, 0, 0, SUSER_SNAME()),
            ('OTHER',     'Other',      'Other',      'OTHER',  'Other activity',                    'Other', 'Other',      'Other',    'Activity', 0, 0, 0, 0, 0, SUSER_SNAME()),
            
            /* ======================================================================================
               7. FINANCIAL ADJUSTMENTS
               ====================================================================================== */
            ('CQUIN',     'Financial', 'Adjustment', 'GBP', 'CQUIN payment',                       'Fin', 'Financial', 'Adjustment', 'Financial', 0, 0, 0, 0, 0, SUSER_SNAME()),
            ('ADJUSTMENT','Financial', 'Adjustment', 'GBP', 'Generic adjustment',                  'Fin', 'Financial', 'Adjustment', 'Financial', 0, 0, 0, 0, 0, SUSER_SNAME()),
            ('BLOCK',     'Financial', 'Block',      'GBP', 'Block contract payment',              'Fin', 'Financial', 'Block',      'Financial', 0, 0, 0, 0, 0, SUSER_SNAME()),
            ('NAOTHER',   'Financial', 'Adjustment', 'GBP', 'Other non-activity adjustment',       'Fin', 'Financial', 'Adjustment', 'Financial', 0, 0, 0, 0, 0, SUSER_SNAME())
        ) AS v(
            POD_Code, POD_Domain, POD_Subcategory, POD_Measure, POD_Description,
            POD_Dataset, POD_MainGroup, POD_SubGroup, POD_Category,
            Is_Elective, Is_Emergency, Is_Admitted, Is_Outpatient, Is_AE,
            Created_By
        )
    )
    INSERT INTO [Analytics].[tbl_Dim_POD] 
      (POD_Code, POD_Domain, POD_Subcategory, POD_Measure, POD_Description,
         POD_Dataset, POD_MainGroup, POD_SubGroup, POD_Category,
       Is_Elective, Is_Emergency, Is_Admitted, Is_Outpatient, Is_AE,
       Created_By)
    SELECT
        s.POD_Code,
        s.POD_Domain,
        s.POD_Subcategory,
        s.POD_Measure,
        s.POD_Description,
        s.POD_Dataset,
        s.POD_MainGroup,
        s.POD_SubGroup,
        s.POD_Category,
        s.Is_Elective,
        s.Is_Emergency,
        s.Is_Admitted,
        s.Is_Outpatient,
        s.Is_AE,
        s.Created_By
    FROM POD_Source s
    WHERE NOT EXISTS (
        SELECT 1
        FROM [Analytics].[tbl_Dim_POD] t
        WHERE t.POD_Code = s.POD_Code
    );

    SET @RowsInserted = @@ROWCOUNT;

    PRINT '[OK] Inserted ' + CAST(@RowsInserted AS VARCHAR) + ' POD codes';

    EXEC [Analytics].[sp_Log_Table_Load]
        @BatchID = @BatchID,
        @TableName = 'Analytics.tbl_Dim_POD',
        @LoadType = 'Static',
        @RowsAffected = @RowsInserted,
        @Status = 'Success';

    EXEC [Analytics].[sp_End_ETL_Batch]
        @BatchID = @BatchID,
        @Status = 'Success',
        @RowsInserted = @RowsInserted,
        @RowsUpdated = 0,
        @RowsDeleted = 0,
        @RowsFailed = 0,
        @ErrorMessage = NULL;
END TRY
BEGIN CATCH
    SET @ErrorMessage = ERROR_MESSAGE();
    PRINT '[FAIL] Dim_POD population failed: ' + @ErrorMessage;

    IF @BatchID IS NOT NULL
    BEGIN
        EXEC [Analytics].[sp_Log_Table_Load]
            @BatchID = @BatchID,
            @TableName = 'Analytics.tbl_Dim_POD',
            @LoadType = 'Static',
            @RowsAffected = 0,
            @RowsFailed = 1,
            @Status = 'Failed',
            @ErrorMessage = @ErrorMessage;

        EXEC [Analytics].[sp_End_ETL_Batch]
            @BatchID = @BatchID,
            @Status = 'Failed',
            @RowsInserted = 0,
            @RowsUpdated = 0,
            @RowsDeleted = 0,
            @RowsFailed = 1,
            @ErrorMessage = @ErrorMessage;
    END

    RAISERROR(@ErrorMessage, 16, 1);
    RETURN;
END CATCH

PRINT '';
PRINT '========================================';
PRINT 'Dim_POD Population Complete';
PRINT 'Completed: ' + CONVERT(VARCHAR, GETDATE(), 121);
PRINT '========================================';
GO