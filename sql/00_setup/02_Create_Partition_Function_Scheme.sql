USE [Data_Lab_SWL_Live];
GO

-- =============================================
-- Partition Function: PF_OP_Activity_Monthly
-- Description:   Monthly partitioning for 6.5 years (2019/20 to 2025/26)
-- Range: Right (Time grows forward)
-- Granularity: Monthly
-- =============================================

IF NOT EXISTS (SELECT * FROM sys.partition_functions WHERE name = 'PF_OP_Activity_Monthly')
BEGIN
    -- Define partition boundaries from Apr 2019 to Mar 2026
    CREATE PARTITION FUNCTION PF_OP_Activity_Monthly (DATE)
    AS RANGE RIGHT FOR VALUES
    (
        '2019-04-01', '2019-05-01', '2019-06-01', '2019-07-01', '2019-08-01', '2019-09-01',
        '2019-10-01', '2019-11-01', '2019-12-01', '2020-01-01', '2020-02-01', '2020-03-01',
        '2020-04-01', '2020-05-01', '2020-06-01', '2020-07-01', '2020-08-01', '2020-09-01',
        '2020-10-01', '2020-11-01', '2020-12-01', '2021-01-01', '2021-02-01', '2021-03-01',
        '2021-04-01', '2021-05-01', '2021-06-01', '2021-07-01', '2021-08-01', '2021-09-01',
        '2021-10-01', '2021-11-01', '2021-12-01', '2022-01-01', '2022-02-01', '2022-03-01',
        '2022-04-01', '2022-05-01', '2022-06-01', '2022-07-01', '2022-08-01', '2022-09-01',
        '2022-10-01', '2022-11-01', '2022-12-01', '2023-01-01', '2023-02-01', '2023-03-01',
        '2023-04-01', '2023-05-01', '2023-06-01', '2023-07-01', '2023-08-01', '2023-09-01',
        '2023-10-01', '2023-11-01', '2023-12-01', '2024-01-01', '2024-02-01', '2024-03-01',
        '2024-04-01', '2024-05-01', '2024-06-01', '2024-07-01', '2024-08-01', '2024-09-01',
        '2024-10-01', '2024-11-01', '2024-12-01', '2025-01-01', '2025-02-01', '2025-03-01',
        '2025-04-01', '2025-05-01', '2025-06-01', '2025-07-01', '2025-08-01', '2025-09-01',
        '2025-10-01', '2025-11-01', '2025-12-01', '2026-01-01', '2026-02-01', '2026-03-01'
    );
    PRINT 'Partition Function [PF_OP_Activity_Monthly] created.';
END
ELSE
BEGIN
    PRINT 'Partition Function [PF_OP_Activity_Monthly] already exists.';
END
GO

-- =============================================
-- Partition Scheme: PS_OP_Activity_Monthly
-- Description:   Maps partitions to filegroups
-- Strategy: All to PRIMARY (as per spec)
-- =============================================

IF NOT EXISTS (SELECT * FROM sys.partition_schemes WHERE name = 'PS_OP_Activity_Monthly')
BEGIN
    CREATE PARTITION SCHEME PS_OP_Activity_Monthly
    AS PARTITION PF_OP_Activity_Monthly
    ALL TO ([PRIMARY]);
    PRINT 'Partition Scheme [PS_OP_Activity_Monthly] created.';
END
ELSE
BEGIN
    PRINT 'Partition Scheme [PS_OP_Activity_Monthly] already exists.';
END
GO

-- =============================================
-- Partition Function: PF_IP_Activity_Monthly
-- Description:   Monthly partitioning for 6.5 years (2019/20 to 2025/26)
-- Range: Right (Time grows forward)
-- Granularity: Monthly
-- =============================================

IF NOT EXISTS (SELECT * FROM sys.partition_functions WHERE name = 'PF_IP_Activity_Monthly')
BEGIN
    CREATE PARTITION FUNCTION PF_IP_Activity_Monthly (DATE)
    AS RANGE RIGHT FOR VALUES
    (
        '2019-04-01', '2019-05-01', '2019-06-01', '2019-07-01', '2019-08-01', '2019-09-01',
        '2019-10-01', '2019-11-01', '2019-12-01', '2020-01-01', '2020-02-01', '2020-03-01',
        '2020-04-01', '2020-05-01', '2020-06-01', '2020-07-01', '2020-08-01', '2020-09-01',
        '2020-10-01', '2020-11-01', '2020-12-01', '2021-01-01', '2021-02-01', '2021-03-01',
        '2021-04-01', '2021-05-01', '2021-06-01', '2021-07-01', '2021-08-01', '2021-09-01',
        '2021-10-01', '2021-11-01', '2021-12-01', '2022-01-01', '2022-02-01', '2022-03-01',
        '2022-04-01', '2022-05-01', '2022-06-01', '2022-07-01', '2022-08-01', '2022-09-01',
        '2022-10-01', '2022-11-01', '2022-12-01', '2023-01-01', '2023-02-01', '2023-03-01',
        '2023-04-01', '2023-05-01', '2023-06-01', '2023-07-01', '2023-08-01', '2023-09-01',
        '2023-10-01', '2023-11-01', '2023-12-01', '2024-01-01', '2024-02-01', '2024-03-01',
        '2024-04-01', '2024-05-01', '2024-06-01', '2024-07-01', '2024-08-01', '2024-09-01',
        '2024-10-01', '2024-11-01', '2024-12-01', '2025-01-01', '2025-02-01', '2025-03-01',
        '2025-04-01', '2025-05-01', '2025-06-01', '2025-07-01', '2025-08-01', '2025-09-01',
        '2025-10-01', '2025-11-01', '2025-12-01', '2026-01-01', '2026-02-01', '2026-03-01'
    );
    PRINT 'Partition Function [PF_IP_Activity_Monthly] created.';
END
ELSE
BEGIN
    PRINT 'Partition Function [PF_IP_Activity_Monthly] already exists.';
END
GO

-- =============================================
-- Partition Scheme: PS_IP_Activity_Monthly
-- Description:   Maps partitions to filegroups
-- Strategy: All to PRIMARY (as per spec)
-- =============================================

IF NOT EXISTS (SELECT * FROM sys.partition_schemes WHERE name = 'PS_IP_Activity_Monthly')
BEGIN
    CREATE PARTITION SCHEME PS_IP_Activity_Monthly
    AS PARTITION PF_IP_Activity_Monthly
    ALL TO ([PRIMARY]);
    PRINT 'Partition Scheme [PS_IP_Activity_Monthly] created.';
END
ELSE
BEGIN
    PRINT 'Partition Scheme [PS_IP_Activity_Monthly] already exists.';
END
GO

-- =============================================
-- Partition Function: PF_AE_Activity_Monthly
-- Description:   Monthly partitioning for 6.5 years (2019/20 to 2025/26)
-- Range: Right (Time grows forward)
-- Granularity: Monthly
-- =============================================

IF NOT EXISTS (SELECT * FROM sys.partition_functions WHERE name = 'PF_AE_Activity_Monthly')
BEGIN
    CREATE PARTITION FUNCTION PF_AE_Activity_Monthly (DATE)
    AS RANGE RIGHT FOR VALUES
    (
        '2019-04-01', '2019-05-01', '2019-06-01', '2019-07-01', '2019-08-01', '2019-09-01',
        '2019-10-01', '2019-11-01', '2019-12-01', '2020-01-01', '2020-02-01', '2020-03-01',
        '2020-04-01', '2020-05-01', '2020-06-01', '2020-07-01', '2020-08-01', '2020-09-01',
        '2020-10-01', '2020-11-01', '2020-12-01', '2021-01-01', '2021-02-01', '2021-03-01',
        '2021-04-01', '2021-05-01', '2021-06-01', '2021-07-01', '2021-08-01', '2021-09-01',
        '2021-10-01', '2021-11-01', '2021-12-01', '2022-01-01', '2022-02-01', '2022-03-01',
        '2022-04-01', '2022-05-01', '2022-06-01', '2022-07-01', '2022-08-01', '2022-09-01',
        '2022-10-01', '2022-11-01', '2022-12-01', '2023-01-01', '2023-02-01', '2023-03-01',
        '2023-04-01', '2023-05-01', '2023-06-01', '2023-07-01', '2023-08-01', '2023-09-01',
        '2023-10-01', '2023-11-01', '2023-12-01', '2024-01-01', '2024-02-01', '2024-03-01',
        '2024-04-01', '2024-05-01', '2024-06-01', '2024-07-01', '2024-08-01', '2024-09-01',
        '2024-10-01', '2024-11-01', '2024-12-01', '2025-01-01', '2025-02-01', '2025-03-01',
        '2025-04-01', '2025-05-01', '2025-06-01', '2025-07-01', '2025-08-01', '2025-09-01',
        '2025-10-01', '2025-11-01', '2025-12-01', '2026-01-01', '2026-02-01', '2026-03-01'
    );
    PRINT 'Partition Function [PF_AE_Activity_Monthly] created.';
END
ELSE
BEGIN
    PRINT 'Partition Function [PF_AE_Activity_Monthly] already exists.';
END
GO

-- =============================================
-- Partition Scheme: PS_AE_Activity_Monthly
-- Description:   Maps partitions to filegroups
-- Strategy: All to PRIMARY (as per spec)
-- =============================================

IF NOT EXISTS (SELECT * FROM sys.partition_schemes WHERE name = 'PS_AE_Activity_Monthly')
BEGIN
    CREATE PARTITION SCHEME PS_AE_Activity_Monthly
    AS PARTITION PF_AE_Activity_Monthly
    ALL TO ([PRIMARY]);
    PRINT 'Partition Scheme [PS_AE_Activity_Monthly] created.';
END
ELSE
BEGIN
    PRINT 'Partition Scheme [PS_AE_Activity_Monthly] already exists.';
END
GO
