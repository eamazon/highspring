USE [Data_Lab_SWL_Live];
GO

-- Create Analytics Schema for new platform objects
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'Analytics')
BEGIN
    EXEC('CREATE SCHEMA [Analytics]')
    PRINT 'Schema [Analytics] created successfully.'
END
ELSE
BEGIN
    PRINT 'Schema [Analytics] already exists.'
END
GO
