USE [Data_Lab_SWL_Live];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

PRINT '========================================';
PRINT 'Creating partition maintenance procedure';
PRINT 'Started: ' + CONVERT(VARCHAR, GETDATE(), 121);
PRINT '========================================';
GO

IF OBJECT_ID('[Analytics].[sp_Extend_Fact_Partitions]', 'P') IS NOT NULL
    DROP PROCEDURE [Analytics].[sp_Extend_Fact_Partitions];
GO

/**
Script Name:   06_Create_Partition_Maintenance.sql
Description:   Extends monthly partition functions for IP/OP/AE facts.
Author:        Sridhar Peddi
Created:       2026-01-12

Change Log:
  2026-01-12  Sridhar Peddi    Initial creation
**/
CREATE PROCEDURE [Analytics].[sp_Extend_Fact_Partitions]
    @MonthsAhead INT = 12,
    @StartFrom DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF @MonthsAhead IS NULL OR @MonthsAhead < 1
    BEGIN
        RAISERROR('MonthsAhead must be >= 1.', 16, 1);
        RETURN;
    END

    DECLARE @Functions TABLE (FunctionName SYSNAME NOT NULL);
    INSERT INTO @Functions (FunctionName)
    VALUES ('PF_OP_Activity_Monthly'),
           ('PF_IP_Activity_Monthly'),
           ('PF_AE_Activity_Monthly');

    DECLARE @FuncName SYSNAME;
    DECLARE @LastBoundary DATE;
    DECLARE @CurrentBoundary DATE;
    DECLARE @Sql NVARCHAR(4000);
    DECLARE @i INT;

    DECLARE func_cursor CURSOR FOR
        SELECT FunctionName FROM @Functions;

    OPEN func_cursor;
    FETCH NEXT FROM func_cursor INTO @FuncName;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        IF EXISTS (SELECT 1 FROM sys.partition_functions WHERE name = @FuncName)
        BEGIN
            SELECT @LastBoundary = MAX(TRY_CONVERT(DATE, prv.value))
            FROM sys.partition_range_values prv
            INNER JOIN sys.partition_functions pf
                ON pf.function_id = prv.function_id
            WHERE pf.name = @FuncName;

            IF @LastBoundary IS NULL
            BEGIN
                SET @LastBoundary = DATEFROMPARTS(YEAR(GETDATE()), MONTH(GETDATE()), 1);
            END

            SET @CurrentBoundary = DATEFROMPARTS(YEAR(@LastBoundary), MONTH(@LastBoundary), 1);

            IF @StartFrom IS NOT NULL AND @StartFrom > @CurrentBoundary
            BEGIN
                SET @CurrentBoundary = DATEFROMPARTS(YEAR(@StartFrom), MONTH(@StartFrom), 1);
            END

            SET @i = 0;
            WHILE @i < @MonthsAhead
            BEGIN
                SET @CurrentBoundary = DATEADD(MONTH, 1, @CurrentBoundary);

                IF NOT EXISTS (
                    SELECT 1
                    FROM sys.partition_range_values prv
                    INNER JOIN sys.partition_functions pf
                        ON pf.function_id = prv.function_id
                    WHERE pf.name = @FuncName
                      AND TRY_CONVERT(DATE, prv.value) = @CurrentBoundary
                )
                BEGIN
                    SET @Sql = N'ALTER PARTITION FUNCTION ' + QUOTENAME(@FuncName)
                        + N'() SPLIT RANGE ('''
                        + CONVERT(VARCHAR(10), @CurrentBoundary, 120) + N''');';
                    EXEC sp_executesql @Sql;
                    PRINT 'Added boundary ' + CONVERT(VARCHAR(10), @CurrentBoundary, 120)
                        + ' to ' + @FuncName;
                END
                ELSE
                BEGIN
                    PRINT 'Boundary already exists for ' + @FuncName + ': '
                        + CONVERT(VARCHAR(10), @CurrentBoundary, 120);
                END

                SET @i = @i + 1;
            END
        END
        ELSE
        BEGIN
            PRINT 'Partition function not found: ' + @FuncName;
        END

        FETCH NEXT FROM func_cursor INTO @FuncName;
    END

    CLOSE func_cursor;
    DEALLOCATE func_cursor;
END
GO

PRINT '[OK] Created procedure: [Analytics].[sp_Extend_Fact_Partitions]';
GO
