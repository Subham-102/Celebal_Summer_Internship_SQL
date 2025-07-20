-- This script contains the SQL code for creating the SourceCustomers table,
-- all hypothetical dimension tables for SCD Types 0, 1, 2, 3, 4, and 6,
-- and the stored procedures to process data for each SCD type.

-- IMPORTANT:
-- Before running this script, ensure you have a database selected.
-- This script is written for SQL Server. Syntax might vary for other database systems.

-- ============================================================================
-- Source Table: SourceCustomers
-- This table simulates your incoming source data.
-- ============================================================================
IF OBJECT_ID('SourceCustomers', 'U') IS NOT NULL
    DROP TABLE SourceCustomers;

CREATE TABLE SourceCustomers (
    CustomerID INT PRIMARY KEY,
    CustomerName VARCHAR(100),
    Address VARCHAR(200),
    City VARCHAR(100),
    State VARCHAR(100),
    PhoneNumber VARCHAR(20),
    Email VARCHAR(100)
);

-- ============================================================================
-- SCD Type 0: Fixed Attribute
-- Table Structure and Stored Procedure
-- ============================================================================
IF OBJECT_ID('DimCustomers_SCD0', 'U') IS NOT NULL
    DROP TABLE DimCustomers_SCD0;

CREATE TABLE DimCustomers_SCD0 (
    CustomerID INT PRIMARY KEY,
    CustomerName VARCHAR(100),
    Address VARCHAR(200),
    City VARCHAR(100),
    State VARCHAR(100),
    PhoneNumber VARCHAR(20),
    Email VARCHAR(100)
);
GO

IF OBJECT_ID('usp_Process_DimCustomers_SCD0', 'P') IS NOT NULL
    DROP PROCEDURE usp_Process_DimCustomers_SCD0;
GO

CREATE PROCEDURE usp_Process_DimCustomers_SCD0
AS
BEGIN
    -- SCD Type 0: Fixed Attribute
    -- Data is loaded once and never updated.
    -- This procedure only handles initial inserts for new customers.
    -- Any changes to existing customer data in the source will be ignored.

    SET NOCOUNT ON;

    -- Insert new customers only
    INSERT INTO DimCustomers_SCD0 (
        CustomerID,
        CustomerName,
        Address,
        City,
        State,
        PhoneNumber,
        Email
    )
    SELECT
        sc.CustomerID,
        sc.CustomerName,
        sc.Address,
        sc.City,
        sc.State,
        sc.PhoneNumber,
        sc.Email
    FROM
        SourceCustomers sc
    LEFT JOIN
        DimCustomers_SCD0 dc ON sc.CustomerID = dc.CustomerID
    WHERE
        dc.CustomerID IS NULL; -- Only insert if customer does not exist in dimension table

    PRINT 'SCD Type 0 processing complete. New customers inserted.';
END;
GO

-- ============================================================================
-- SCD Type 1: Overwrite
-- Table Structure and Stored Procedure
-- ============================================================================
IF OBJECT_ID('DimCustomers_SCD1', 'U') IS NOT NULL
    DROP TABLE DimCustomers_SCD1;

CREATE TABLE DimCustomers_SCD1 (
    CustomerID INT PRIMARY KEY,
    CustomerName VARCHAR(100),
    Address VARCHAR(200),
    City VARCHAR(100),
    State VARCHAR(100),
    PhoneNumber VARCHAR(20),
    Email VARCHAR(100)
);
GO

IF OBJECT_ID('usp_Process_DimCustomers_SCD1', 'P') IS NOT NULL
    DROP PROCEDURE usp_Process_DimCustomers_SCD1;
GO

CREATE PROCEDURE usp_Process_DimCustomers_SCD1
AS
BEGIN
    -- SCD Type 1: Overwrite
    -- Updates existing records with new values and inserts new records.
    -- No history is preserved.

    SET NOCOUNT ON;

    -- 1. Update existing records where attributes have changed
    UPDATE dc
    SET
        dc.CustomerName = sc.CustomerName,
        dc.Address = sc.Address,
        dc.City = sc.City,
        dc.State = sc.State,
        dc.PhoneNumber = sc.PhoneNumber,
        dc.Email = sc.Email
    FROM
        DimCustomers_SCD1 dc
    INNER JOIN
        SourceCustomers sc ON dc.CustomerID = sc.CustomerID
    WHERE
        -- Check if any relevant attribute has changed
        dc.CustomerName <> sc.CustomerName OR
        dc.Address <> sc.Address OR
        dc.City <> sc.City OR
        dc.State <> sc.State OR
        dc.PhoneNumber <> sc.PhoneNumber OR
        dc.Email <> sc.Email;

    -- 2. Insert new records
    INSERT INTO DimCustomers_SCD1 (
        CustomerID,
        CustomerName,
        Address,
        City,
        State,
        PhoneNumber,
        Email
    )
    SELECT
        sc.CustomerID,
        sc.CustomerName,
        sc.Address,
        sc.City,
        sc.State,
        sc.PhoneNumber,
        sc.Email
    FROM
        SourceCustomers sc
    LEFT JOIN
        DimCustomers_SCD1 dc ON sc.CustomerID = dc.CustomerID
    WHERE
        dc.CustomerID IS NULL; -- Only insert if customer does not exist

    PRINT 'SCD Type 1 processing complete. Existing customers updated, new customers inserted.';
END;
GO

-- ============================================================================
-- SCD Type 2: Add New Row
-- Table Structure and Stored Procedure
-- ============================================================================
IF OBJECT_ID('DimCustomers_SCD2', 'U') IS NOT NULL
    DROP TABLE DimCustomers_SCD2;

CREATE TABLE DimCustomers_SCD2 (
    CustomerSK INT IDENTITY(1,1) PRIMARY KEY, -- Surrogate Key
    CustomerID INT,
    CustomerName VARCHAR(100),
    Address VARCHAR(200),
    City VARCHAR(100),
    State VARCHAR(100),
    PhoneNumber VARCHAR(20),
    Email VARCHAR(100),
    StartDate DATE,
    EndDate DATE,
    IsCurrent BIT -- 1 for current record, 0 for historical
);
GO

IF OBJECT_ID('usp_Process_DimCustomers_SCD2', 'P') IS NOT NULL
    DROP PROCEDURE usp_Process_DimCustomers_SCD2;
GO

CREATE PROCEDURE usp_Process_DimCustomers_SCD2
AS
BEGIN
    -- SCD Type 2: Add New Row
    -- Preserves full history by adding new rows for changes.
    -- Uses StartDate, EndDate, and IsCurrent flag.

    SET NOCOUNT ON;

    DECLARE @CurrentDate DATE = GETDATE();
    DECLARE @MaxEndDate DATE = '9999-12-31'; -- Represents an open-ended current record

    -- Create a temporary table to hold changes
    SELECT
        sc.CustomerID,
        sc.CustomerName,
        sc.Address,
        sc.City,
        sc.State,
        sc.PhoneNumber,
        sc.Email
    INTO
        #ChangedCustomers
    FROM
        SourceCustomers sc
    INNER JOIN
        DimCustomers_SCD2 dc ON sc.CustomerID = dc.CustomerID
    WHERE
        dc.IsCurrent = 1 -- Only compare with current active records
        AND (
            dc.CustomerName <> sc.CustomerName OR
            dc.Address <> sc.Address OR
            dc.City <> sc.City OR
            dc.State <> sc.State OR
            dc.PhoneNumber <> sc.PhoneNumber OR
            dc.Email <> sc.Email
        );

    -- 1. Invalidate (expire) old records for changed customers
    UPDATE dc
    SET
        dc.EndDate = DATEADD(day, -1, @CurrentDate), -- Set EndDate to yesterday
        dc.IsCurrent = 0
    FROM
        DimCustomers_SCD2 dc
    INNER JOIN
        #ChangedCustomers tc ON dc.CustomerID = tc.CustomerID
    WHERE
        dc.IsCurrent = 1;

    -- 2. Insert new records for changed customers (with new data and current flags)
    INSERT INTO DimCustomers_SCD2 (
        CustomerID,
        CustomerName,
        Address,
        City,
        State,
        PhoneNumber,
        Email,
        StartDate,
        EndDate,
        IsCurrent
    )
    SELECT
        tc.CustomerID,
        tc.CustomerName,
        tc.Address,
        tc.City,
        tc.State,
        tc.PhoneNumber,
        tc.Email,
        @CurrentDate AS StartDate,
        @MaxEndDate AS EndDate,
        1 AS IsCurrent
    FROM
        #ChangedCustomers tc;

    -- 3. Insert new customers (who don't exist in the dimension table at all)
    INSERT INTO DimCustomers_SCD2 (
        CustomerID,
        CustomerName,
        Address,
        City,
        State,
        PhoneNumber,
        Email,
        StartDate,
        EndDate,
        IsCurrent
    )
    SELECT
        sc.CustomerID,
        sc.CustomerName,
        sc.Address,
        sc.City,
        sc.State,
        sc.PhoneNumber,
        sc.Email,
        @CurrentDate AS StartDate,
        @MaxEndDate AS EndDate,
        1 AS IsCurrent
    FROM
        SourceCustomers sc
    LEFT JOIN
        DimCustomers_SCD2 dc ON sc.CustomerID = dc.CustomerID
    WHERE
        dc.CustomerID IS NULL; -- Only insert if customer does not exist in dimension table

    -- Clean up temporary table
    DROP TABLE #ChangedCustomers;

    PRINT 'SCD Type 2 processing complete. History preserved for changes, new customers inserted.';
END;
GO

-- ============================================================================
-- SCD Type 3: Add New Attribute
-- Table Structure and Stored Procedure
-- ============================================================================
IF OBJECT_ID('DimCustomers_SCD3', 'U') IS NOT NULL
    DROP TABLE DimCustomers_SCD3;

CREATE TABLE DimCustomers_SCD3 (
    CustomerID INT PRIMARY KEY,
    CustomerName VARCHAR(100),
    Address VARCHAR(200),
    CurrentCity VARCHAR(100),
    PreviousCity VARCHAR(100), -- New column for previous city
    State VARCHAR(100),
    PhoneNumber VARCHAR(20),
    Email VARCHAR(100)
);
GO

IF OBJECT_ID('usp_Process_DimCustomers_SCD3', 'P') IS NOT NULL
    DROP PROCEDURE usp_Process_DimCustomers_SCD3;
GO

CREATE PROCEDURE usp_Process_DimCustomers_SCD3
AS
BEGIN
    -- SCD Type 3: Add New Attribute
    -- Preserves limited history for a specific attribute (e.g., City)
    -- by adding a 'Previous' column.

    SET NOCOUNT ON;

    -- 1. Update existing records where the tracked attribute (City) has changed
    UPDATE dc
    SET
        dc.PreviousCity = dc.CurrentCity, -- Move current city to previous city
        dc.CurrentCity = sc.City,         -- Update current city with new value
        dc.CustomerName = sc.CustomerName, -- Other SCD1 type updates for non-tracked attributes
        dc.Address = sc.Address,
        dc.State = sc.State,
        dc.PhoneNumber = sc.PhoneNumber,
        dc.Email = sc.Email
    FROM
        DimCustomers_SCD3 dc
    INNER JOIN
        SourceCustomers sc ON dc.CustomerID = sc.CustomerID
    WHERE
        dc.CurrentCity <> sc.City OR -- Check if the tracked attribute (City) has changed
        -- Also update if other non-tracked attributes (SCD1 behavior) have changed
        dc.CustomerName <> sc.CustomerName OR
        dc.Address <> sc.Address OR
        dc.State <> sc.State OR
        dc.PhoneNumber <> sc.PhoneNumber OR
        dc.Email <> sc.Email;

    -- 2. Insert new records
    INSERT INTO DimCustomers_SCD3 (
        CustomerID,
        CustomerName,
        Address,
        CurrentCity,
        PreviousCity, -- For new inserts, previous city is NULL
        State,
        PhoneNumber,
        Email
    )
    SELECT
        sc.CustomerID,
        sc.CustomerName,
        sc.Address,
        sc.City,
        NULL AS PreviousCity, -- New customers have no previous city
        sc.State,
        sc.PhoneNumber,
        sc.Email
    FROM
        SourceCustomers sc
    LEFT JOIN
        DimCustomers_SCD3 dc ON sc.CustomerID = dc.CustomerID
    WHERE
        dc.CustomerID IS NULL; -- Only insert if customer does not exist

    PRINT 'SCD Type 3 processing complete. Limited history for City preserved, other attributes updated.';
END;
GO

-- ============================================================================
-- SCD Type 4: History Table
-- Table Structures and Stored Procedure
-- ============================================================================
IF OBJECT_ID('DimCustomers_SCD4_Main', 'U') IS NOT NULL
    DROP TABLE DimCustomers_SCD4_Main;

CREATE TABLE DimCustomers_SCD4_Main (
    CustomerID INT PRIMARY KEY,
    CustomerName VARCHAR(100),
    Address VARCHAR(200),
    City VARCHAR(100),
    State VARCHAR(100),
    PhoneNumber VARCHAR(20),
    Email VARCHAR(100)
);
GO

IF OBJECT_ID('DimCustomers_SCD4_History', 'U') IS NOT NULL
    DROP TABLE DimCustomers_SCD4_History;

CREATE TABLE DimCustomers_SCD4_History (
    HistoryID INT IDENTITY(1,1) PRIMARY KEY,
    CustomerID INT,
    CustomerName VARCHAR(100),
    Address VARCHAR(200),
    City VARCHAR(100),
    State VARCHAR(100),
    PhoneNumber VARCHAR(20),
    Email VARCHAR(100),
    EffectiveDate DATE,
    ExpiryDate DATE
);
GO

IF OBJECT_ID('usp_Process_DimCustomers_SCD4', 'P') IS NOT NULL
    DROP PROCEDURE usp_Process_DimCustomers_SCD4;
GO

CREATE PROCEDURE usp_Process_DimCustomers_SCD4
AS
BEGIN
    -- SCD Type 4: History Table
    -- Main table holds current data (SCD1).
    -- History table stores all previous versions.

    SET NOCOUNT ON;

    DECLARE @CurrentDate DATE = GETDATE();

    -- 1. Identify records in the main dimension table that have changed in the source
    SELECT
        dc.CustomerID,
        dc.CustomerName AS OldCustomerName,
        dc.Address AS OldAddress,
        dc.City AS OldCity,
        dc.State AS OldState,
        dc.PhoneNumber AS OldPhoneNumber,
        dc.Email AS OldEmail,
        sc.CustomerName AS NewCustomerName,
        sc.Address AS NewAddress,
        sc.City AS NewCity,
        sc.State AS NewState,
        sc.PhoneNumber AS NewPhoneNumber,
        sc.Email AS NewEmail
    INTO
        #ChangedRecords
    FROM
        DimCustomers_SCD4_Main dc
    INNER JOIN
        SourceCustomers sc ON dc.CustomerID = sc.CustomerID
    WHERE
        dc.CustomerName <> sc.CustomerName OR
        dc.Address <> sc.Address OR
        dc.City <> sc.City OR
        dc.State <> sc.State OR
        dc.PhoneNumber <> sc.PhoneNumber OR
        dc.Email <> sc.Email;

    -- 2. Insert the old versions of changed records into the history table
    INSERT INTO DimCustomers_SCD4_History (
        CustomerID,
        CustomerName,
        Address,
        City,
        State,
        PhoneNumber,
        Email,
        EffectiveDate,
        ExpiryDate
    )
    SELECT
        cr.CustomerID,
        cr.OldCustomerName,
        cr.OldAddress,
        cr.OldCity,
        cr.OldState,
        cr.OldPhoneNumber,
        cr.OldEmail,
        (SELECT MAX(EffectiveDate) FROM DimCustomers_SCD4_History WHERE CustomerID = cr.CustomerID) AS EffectiveDate, -- Get last effective date
        DATEADD(day, -1, @CurrentDate) AS ExpiryDate -- Expire yesterday
    FROM
        #ChangedRecords cr;

    -- 3. Update the main dimension table with the new values (SCD1 behavior)
    UPDATE dc
    SET
        dc.CustomerName = cr.NewCustomerName,
        dc.Address = cr.NewAddress,
        dc.City = cr.NewCity,
        dc.State = cr.NewState,
        dc.PhoneNumber = cr.NewPhoneNumber,
        dc.Email = cr.NewEmail
    FROM
        DimCustomers_SCD4_Main dc
    INNER JOIN
        #ChangedRecords cr ON dc.CustomerID = cr.CustomerID;

    -- 4. Insert new customers into the main dimension table (and their first entry into history)
    INSERT INTO DimCustomers_SCD4_Main (
        CustomerID,
        CustomerName,
        Address,
        City,
        State,
        PhoneNumber,
        Email
    )
    SELECT
        sc.CustomerID,
        sc.CustomerName,
        sc.Address,
        sc.City,
        sc.State,
        sc.PhoneNumber,
        sc.Email
    FROM
        SourceCustomers sc
    LEFT JOIN
        DimCustomers_SCD4_Main dc ON sc.CustomerID = dc.CustomerID
    WHERE
        dc.CustomerID IS NULL; -- Only insert if customer does not exist

    -- For newly inserted customers, also add their initial state to the history table
    INSERT INTO DimCustomers_SCD4_History (
        CustomerID,
        CustomerName,
        Address,
        City,
        State,
        PhoneNumber,
        Email,
        EffectiveDate,
        ExpiryDate
    )
    SELECT
        sc.CustomerID,
        sc.CustomerName,
        sc.Address,
        sc.City,
        sc.State,
        sc.PhoneNumber,
        sc.Email,
        @CurrentDate AS EffectiveDate,
        '9999-12-31' AS ExpiryDate -- New records are current
    FROM
        SourceCustomers sc
    LEFT JOIN
        DimCustomers_SCD4_Main dc ON sc.CustomerID = dc.CustomerID
    WHERE
        dc.CustomerID IS NULL; -- Only for customers just inserted into main table

    -- Clean up temporary table
    DROP TABLE #ChangedRecords;

    PRINT 'SCD Type 4 processing complete. Main table updated, history preserved in separate table.';
END;
GO

-- ============================================================================
-- SCD Type 6: Hybrid (SCD2 + SCD1 + SCD3)
-- Table Structure and Stored Procedure
-- ============================================================================
IF OBJECT_ID('DimCustomers_SCD6', 'U') IS NOT NULL
    DROP TABLE DimCustomers_SCD6;

CREATE TABLE DimCustomers_SCD6 (
    CustomerSK INT IDENTITY(1,1) PRIMARY KEY, -- Surrogate Key
    CustomerID INT,
    CustomerName VARCHAR(100),
    Address VARCHAR(200),      -- This will be the address at the time of this record's creation
    CurrentAddress VARCHAR(200), -- This will always reflect the *latest* address (SCD1 behavior)
    City VARCHAR(100),
    State VARCHAR(100),
    PhoneNumber VARCHAR(20),
    Email VARCHAR(100),
    StartDate DATE,
    EndDate DATE,
    IsCurrent BIT
);
GO

IF OBJECT_ID('usp_Process_DimCustomers_SCD6', 'P') IS NOT NULL
    DROP PROCEDURE usp_Process_DimCustomers_SCD6;
GO

CREATE PROCEDURE usp_Process_DimCustomers_SCD6
AS
BEGIN
    -- SCD Type 6: Hybrid (SCD2 + SCD1)
    -- Combines SCD2 for full history with SCD1 for specific attributes (e.g., CurrentAddress).

    SET NOCOUNT ON;

    DECLARE @CurrentDate DATE = GETDATE();
    DECLARE @MaxEndDate DATE = '9999-12-31';

    -- Create a temporary table to hold potential changes
    SELECT
        dc.CustomerSK,
        sc.CustomerID,
        sc.CustomerName,
        sc.Address,
        sc.City,
        sc.State,
        sc.PhoneNumber,
        sc.Email,
        dc.CustomerName AS OldCustomerName,
        dc.Address AS OldAddress,
        dc.City AS OldCity,
        dc.State AS OldState,
        dc.PhoneNumber AS OldPhoneNumber,
        dc.Email AS OldEmail
    INTO
        #PotentialChanges
    FROM
        SourceCustomers sc
    INNER JOIN
        DimCustomers_SCD6 dc ON sc.CustomerID = dc.CustomerID
    WHERE
        dc.IsCurrent = 1; -- Only compare with current active records

    -- 1. Update 'CurrentAddress' for all active records (SCD1 behavior for CurrentAddress)
    -- This ensures the latest address is always available in the current active record,
    -- even if other attributes trigger a new SCD2 row.
    UPDATE dc
    SET
        dc.CurrentAddress = pc.Address
    FROM
        DimCustomers_SCD6 dc
    INNER JOIN
        #PotentialChanges pc ON dc.CustomerSK = pc.CustomerSK
    WHERE
        dc.IsCurrent = 1 AND dc.CurrentAddress <> pc.Address;

    -- 2. Identify records that require a new SCD2 row (changes in CustomerName, City, State, etc.)
    -- Note: Address here refers to the 'Address' column which is part of the SCD2 history.
    SELECT
        pc.CustomerSK,
        pc.CustomerID,
        pc.CustomerName,
        pc.Address, -- This is the new address that will go into the 'Address' column of the new SCD2 row
        pc.City,
        pc.State,
        pc.PhoneNumber,
        pc.Email
    INTO
        #SCD2Changes
    FROM
        #PotentialChanges pc
    WHERE
        pc.OldCustomerName <> pc.CustomerName OR
        pc.OldAddress <> pc.Address OR -- If the historical 'Address' changes, trigger SCD2
        pc.OldCity <> pc.City OR
        pc.OldState <> pc.State OR
        pc.OldPhoneNumber <> pc.PhoneNumber OR
        pc.OldEmail <> pc.Email;

    -- 3. Invalidate (expire) old records for customers with SCD2 changes
    UPDATE dc
    SET
        dc.EndDate = DATEADD(day, -1, @CurrentDate),
        dc.IsCurrent = 0
    FROM
        DimCustomers_SCD6 dc
    INNER JOIN
        #SCD2Changes scd2c ON dc.CustomerID = scd2c.CustomerID
    WHERE
        dc.IsCurrent = 1;

    -- 4. Insert new records for customers with SCD2 changes
    INSERT INTO DimCustomers_SCD6 (
        CustomerID,
        CustomerName,
        Address,
        CurrentAddress, -- New SCD2 row gets the latest address
        City,
        State,
        PhoneNumber,
        Email,
        StartDate,
        EndDate,
        IsCurrent
    )
    SELECT
        scd2c.CustomerID,
        scd2c.CustomerName,
        scd2c.Address,
        scd2c.Address, -- For the new row, CurrentAddress is the same as Address initially
        scd2c.City,
        scd2c.State,
        scd2c.PhoneNumber,
        scd2c.Email,
        @CurrentDate AS StartDate,
        @MaxEndDate AS EndDate,
        1 AS IsCurrent
    FROM
        #SCD2Changes scd2c;

    -- 5. Insert new customers (who don't exist in the dimension table at all)
    INSERT INTO DimCustomers_SCD6 (
        CustomerID,
        CustomerName,
        Address,
        CurrentAddress,
        City,
        State,
        PhoneNumber,
        Email,
        StartDate,
        EndDate,
        IsCurrent
    )
    SELECT
        sc.CustomerID,
        sc.CustomerName,
        sc.Address,
        sc.Address, -- For new customers, CurrentAddress is their initial address
        sc.City,
        sc.State,
        sc.PhoneNumber,
        sc.Email,
        @CurrentDate AS StartDate,
        @MaxEndDate AS EndDate,
        1 AS IsCurrent
    FROM
        SourceCustomers sc
    LEFT JOIN
        DimCustomers_SCD6 dc ON sc.CustomerID = dc.CustomerID
    WHERE
        dc.CustomerID IS NULL;

    -- Clean up temporary tables
    DROP TABLE #PotentialChanges;
    DROP TABLE #SCD2Changes;

    PRINT 'SCD Type 6 processing complete. Hybrid approach applied for customer dimension.';
END;
GO
