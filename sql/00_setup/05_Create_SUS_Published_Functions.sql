USE [Data_Lab_SWL_Live];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

PRINT '========================================';
PRINT 'Creating SUS publish status functions';
PRINT 'Started: ' + CONVERT(VARCHAR, GETDATE(), 121);
PRINT '========================================';
GO

IF OBJECT_ID('[Analytics].[fn_SUS_Published_Cutoff_Date]', 'FN') IS NOT NULL
    DROP FUNCTION [Analytics].[fn_SUS_Published_Cutoff_Date];
GO

/**
Script Name:   05_Create_SUS_Published_Functions.sql
Description:   Functions to resolve published SUS activity cutoff dates and publish status.
Author:        Sridhar Peddi
Created:       2026-01-12

Notes:
- Source table lives in [Data_Lab_SWL].[SWL].[tbl_SUS_Delivery_Schedule].
- If source table is missing or has no deliverable rows, function returns NULL.

Change Log:
  2026-01-12  Sridhar Peddi    Initial creation
**/
CREATE FUNCTION [Analytics].[fn_SUS_Published_Cutoff_Date]
(
    @AsAtDate DATE = NULL
)
RETURNS DATE
AS
BEGIN
    DECLARE @AsAtDateActual DATE = ISNULL(@AsAtDate, CAST(GETDATE() AS DATE));
    DECLARE @CutoffDate DATE = NULL;

    IF NOT EXISTS (
        SELECT 1
        FROM [Data_Lab_SWL].sys.tables t
        INNER JOIN [Data_Lab_SWL].sys.schemas s ON s.schema_id = t.schema_id
        WHERE s.name = 'SWL'
          AND t.name = 'tbl_SUS_Delivery_Schedule'
    )
    BEGIN
        RETURN NULL;
    END

    SELECT @CutoffDate = MAX(d.Activity_Date)
    FROM [Data_Lab_SWL].[SWL].[tbl_SUS_Delivery_Schedule] s
    CROSS APPLY (
        SELECT
            Activity_Date = TRY_CONVERT(
                DATE,
                CASE
                    WHEN ISNUMERIC(CAST(s.SK_Date AS VARCHAR(30))) = 1
                        THEN RIGHT('00000000' + CAST(s.SK_Date AS VARCHAR(8)), 8)
                    ELSE CONVERT(CHAR(8), s.SK_Date, 112)
                END,
                112
            ),
            Delivery_Date = TRY_CONVERT(
                DATE,
                CASE
                    WHEN ISNUMERIC(CAST(s.ICB_Delivery_Date AS VARCHAR(30))) = 1
                        THEN RIGHT('00000000' + CAST(s.ICB_Delivery_Date AS VARCHAR(8)), 8)
                    ELSE CONVERT(CHAR(8), s.ICB_Delivery_Date, 112)
                END,
                112
            )
    ) d
    WHERE d.Delivery_Date <= @AsAtDateActual;

    RETURN @CutoffDate;
END
GO

IF OBJECT_ID('[Analytics].[fn_SUS_Publish_Status]', 'FN') IS NOT NULL
    DROP FUNCTION [Analytics].[fn_SUS_Publish_Status];
GO

/**
Script Name:   05_Create_SUS_Published_Functions.sql
Description:   Returns Published/UnPublished status for a given activity date.
Author:        Sridhar Peddi
Created:       2026-01-12

Change Log:
  2026-01-12  Sridhar Peddi    Initial creation
**/
CREATE FUNCTION [Analytics].[fn_SUS_Publish_Status]
(
    @ActivityDate DATE,
    @AsAtDate DATE = NULL
)
RETURNS VARCHAR(12)
AS
BEGIN
    DECLARE @CutoffDate DATE = [Analytics].[fn_SUS_Published_Cutoff_Date](@AsAtDate);

    IF @CutoffDate IS NULL OR @ActivityDate IS NULL
        RETURN 'UnPublished';

    IF @ActivityDate <= @CutoffDate
        RETURN 'Published';

    RETURN 'UnPublished';
END
GO

PRINT '[OK] Created function: [Analytics].[fn_SUS_Published_Cutoff_Date]';
PRINT '[OK] Created function: [Analytics].[fn_SUS_Publish_Status]';
GO
