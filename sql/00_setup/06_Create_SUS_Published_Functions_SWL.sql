USE [Data_Lab_SWL];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

PRINT '========================================';
PRINT 'Creating SWL SUS publish status functions';
PRINT 'Started: ' + CONVERT(VARCHAR, GETDATE(), 121);
PRINT '========================================';
GO

IF OBJECT_ID('[SWL].[fn_SUS_Published_Cutoff_Date]', 'FN') IS NOT NULL
    DROP FUNCTION [SWL].[fn_SUS_Published_Cutoff_Date];
GO

/**
Script Name:   06_Create_SUS_Published_Functions_SWL.sql
Description:   SWL-scoped function to resolve published SUS activity cutoff date.
Author:        Sridhar Peddi
Created:       2026-01-15

Notes:
- Source table lives in [SWL].[tbl_SUS_Delivery_Schedule].
- If source table is missing or has no deliverable rows, function returns NULL.
**/
CREATE FUNCTION [SWL].[fn_SUS_Published_Cutoff_Date]
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
        FROM sys.tables t
        INNER JOIN sys.schemas s ON s.schema_id = t.schema_id
        WHERE s.name = 'SWL'
          AND t.name = 'tbl_SUS_Delivery_Schedule'
    )
    BEGIN
        RETURN NULL;
    END

    SELECT @CutoffDate = MAX(d.Activity_Date)
    FROM [SWL].[tbl_SUS_Delivery_Schedule] s
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

PRINT '[OK] Created function: [SWL].[fn_SUS_Published_Cutoff_Date]';
GO
