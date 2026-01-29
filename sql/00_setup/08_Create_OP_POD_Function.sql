USE [Data_Lab_SWL_Live];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

PRINT '========================================';
PRINT 'Creating OP POD function';
PRINT 'Started: ' + CONVERT(VARCHAR, GETDATE(), 121);
PRINT '========================================';
GO

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'OP')
BEGIN
    EXEC('CREATE SCHEMA [OP]');
    PRINT 'Schema [OP] created successfully.';
END
ELSE
BEGIN
    PRINT 'Schema [OP] already exists.';
END
GO

IF OBJECT_ID('[OP].[fn_GetPODType]', 'FN') IS NOT NULL
    DROP FUNCTION [OP].[fn_GetPODType];
GO

/**
Script Name:   08_Create_OP_POD_Function.sql
Description:   Returns OP POD codes aligned to NHS England taxonomy.
Author:        Sridhar Peddi
Created:       2026-01-23

Change Log:
  2026-01-23  Sridhar Peddi    Initial creation
**/
CREATE FUNCTION [OP].[fn_GetPODType]
(
    @HRG VARCHAR(10),
    @Attended_Or_Did_Not_Attend VARCHAR(2),
    @First_Attendance VARCHAR(1),
    @Main_Specialty_Code VARCHAR(3)
)
RETURNS VARCHAR(50)
AS
BEGIN
    DECLARE @PodType VARCHAR(50) = 'Other';
    DECLARE @HRGCode VARCHAR(10) = LTRIM(RTRIM(ISNULL(@HRG, '')));
    DECLARE @Attend VARCHAR(2) = LTRIM(RTRIM(ISNULL(@Attended_Or_Did_Not_Attend, '')));
    DECLARE @First VARCHAR(1) = LTRIM(RTRIM(ISNULL(@First_Attendance, '')));
    DECLARE @Spec VARCHAR(3) = LTRIM(RTRIM(ISNULL(@Main_Specialty_Code, '')));

    DECLARE @IsFirst BIT = CASE
        WHEN @First IN ('1', '3') THEN 1
        WHEN @First IN ('2', '4') THEN 0
        ELSE NULL
    END;

    DECLARE @IsMultiProf BIT = CASE WHEN @HRGCode LIKE 'WF02%' THEN 1 ELSE 0 END;
    DECLARE @IsConsLed BIT = CASE
        WHEN @Spec IN ('560', '900', '901', '902', '903', '904', '950', '960') THEN 0
        ELSE 1
    END;

    -- DNA check (2/3 or explicit DNA values). If unknown, return Other.
    IF @Attend IN ('2', '3', 'DNA')
        RETURN 'DNA';
    IF @Attend NOT IN ('5', '6')
        RETURN 'Other';

    -- Procedure check (non-WF HRGs).
    IF @HRGCode NOT LIKE 'WF%'
    BEGIN
        IF @IsFirst = 1
            RETURN 'OPPROCFA';
        IF @IsFirst = 0
            RETURN 'OPPROCFUP';
        RETURN 'OPPROC';
    END

    -- Non-face-to-face attendance (WF01/02 C/D/E variants).
    IF @HRGCode LIKE 'WF01C%' OR @HRGCode LIKE 'WF01D%' OR @HRGCode LIKE 'WF01E%'
       OR @HRGCode LIKE 'WF02C%' OR @HRGCode LIKE 'WF02D%' OR @HRGCode LIKE 'WF02E%'
    BEGIN
        IF @IsFirst = 1
            RETURN 'NF2FFA';
        IF @IsFirst = 0
            RETURN 'NF2FFUP';
        RETURN 'Other';
    END

    -- Face-to-face attendance.
    IF @IsFirst = 1
    BEGIN
        IF @IsMultiProf = 1
            SET @PodType = CASE WHEN @IsConsLed = 1 THEN 'OPFAMPCL' ELSE 'OPFAMPNCL' END;
        ELSE
            SET @PodType = CASE WHEN @IsConsLed = 1 THEN 'OPFASPCL' ELSE 'OPFASPNCL' END;
    END
    ELSE IF @IsFirst = 0
    BEGIN
        IF @IsMultiProf = 1
            SET @PodType = CASE WHEN @IsConsLed = 1 THEN 'OPFUPMPCL' ELSE 'OPFUPMPNCL' END;
        ELSE
            SET @PodType = CASE WHEN @IsConsLed = 1 THEN 'OPFUPSPCL' ELSE 'OPFUPSPNCL' END;
    END

    RETURN @PodType;
END
GO

PRINT '[OK] Created function: [OP].[fn_GetPODType]';
GO
