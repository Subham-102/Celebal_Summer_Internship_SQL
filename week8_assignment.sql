-- =================================================================================
-- Part 1: Create the Destination Table (DimDate)
-- =================================================================================
-- This script creates the 'DimDate' table which will hold the date attributes.
-- The primary key is the 'DateKey' column.
-- Run this part once to set up your table before creating the procedure.
-- =================================================================================

IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='DimDate' and xtype='U')
BEGIN
    CREATE TABLE dbo.DimDate (
        DateKey DATE PRIMARY KEY,
        FullDateAlternateKey NVARCHAR(10) NOT NULL, -- Format: YYYY-MM-DD
        DayNumberOfWeek TINYINT NOT NULL,
        DayNameOfWeek NVARCHAR(10) NOT NULL,
        DayNumberOfMonth TINYINT NOT NULL,
        DayNumberOfYear SMALLINT NOT NULL,
        WeekNumberOfYear TINYINT NOT NULL,
        MonthName NVARCHAR(10) NOT NULL,
        MonthNumberOfYear TINYINT NOT NULL,
        CalendarQuarter TINYINT NOT NULL,
        CalendarYear SMALLINT NOT NULL,
        CalendarSemester TINYINT NOT NULL,
        FiscalQuarter TINYINT NOT NULL,
        FiscalYear SMALLINT NOT NULL,
        FiscalSemester TINYINT NOT NULL,
        IsWeekend BIT NOT NULL,
        IsWorkDay AS CONVERT(BIT, CASE WHEN IsWeekend = 1 THEN 0 ELSE 1 END) -- Computed column
    );
    PRINT 'Table DimDate created successfully.';
END
ELSE
BEGIN
    PRINT 'Table DimDate already exists.';
END
GO


-- =================================================================================
-- Part 2: Create the Stored Procedure
-- =================================================================================
-- This stored procedure, sp_Populate_DimDate, takes any date as input,
-- determines the start and end of that year, and then populates the DimDate
-- table for every single day of that year.
-- It uses a recursive Common Table Expression (CTE) to generate all dates
-- and populates the table with a single INSERT statement to meet the requirement.
-- =================================================================================

CREATE OR ALTER PROCEDURE dbo.sp_Populate_DimDate
    @InputDate DATE
AS
BEGIN
    -- SET NOCOUNT ON prevents the sending of DONE_IN_PROC messages for each statement
    -- in a stored procedure.
    SET NOCOUNT ON;

    -- SET DATEFIRST to 7 makes Sunday the first day of the week (1=Sunday, 7=Saturday).
    -- This ensures calculations for DayNumberOfWeek are consistent regardless of
    -- the server's default language setting.
    SET DATEFIRST 7;

    -- Determine the start and end dates for the year of the @InputDate
    DECLARE @StartDate DATE = DATEFROMPARTS(YEAR(@InputDate), 1, 1);
    DECLARE @EndDate DATE = DATEFROMPARTS(YEAR(@InputDate), 12, 31);

    -- First, clear any existing data for the target year to avoid primary key conflicts.
    DELETE FROM dbo.DimDate WHERE CalendarYear = YEAR(@InputDate);

    -- Use a recursive Common Table Expression (CTE) to generate a series of dates
    -- from the start date to the end date.
    WITH DateSeries AS
    (
        -- Anchor member: the starting date
        SELECT @StartDate AS TheDate
        UNION ALL
        -- Recursive member: add one day to the previous date
        SELECT DATEADD(day, 1, TheDate)
        FROM DateSeries
        WHERE TheDate < @EndDate -- Stop when the end of the year is reached
    )
    -- The single INSERT statement that populates the DimDate table
    INSERT INTO dbo.DimDate (
        DateKey,
        FullDateAlternateKey,
        DayNumberOfWeek,
        DayNameOfWeek,
        DayNumberOfMonth,
        DayNumberOfYear,
        WeekNumberOfYear,
        MonthName,
        MonthNumberOfYear,
        CalendarQuarter,
        CalendarYear,
        CalendarSemester,
        FiscalQuarter,
        FiscalYear,
        FiscalSemester,
        IsWeekend
    )
    SELECT
        TheDate,                                                     -- DateKey
        CONVERT(NVARCHAR(10), TheDate, 23),                          -- FullDateAlternateKey (YYYY-MM-DD)
        DATEPART(weekday, TheDate),                                  -- DayNumberOfWeek (1=Sun, 7=Sat)
        DATENAME(weekday, TheDate),                                  -- DayNameOfWeek
        DATEPART(day, TheDate),                                      -- DayNumberOfMonth
        DATEPART(dayofyear, TheDate),                                -- DayNumberOfYear
        DATEPART(iso_week, TheDate),                                 -- WeekNumberOfYear (ISO 8601 standard)
        DATENAME(month, TheDate),                                    -- MonthName
        DATEPART(month, TheDate),                                    -- MonthNumberOfYear
        DATEPART(quarter, TheDate),                                  -- CalendarQuarter
        DATEPART(year, TheDate),                                     -- CalendarYear
        CASE WHEN DATEPART(month, TheDate) <= 6 THEN 1 ELSE 2 END,   -- CalendarSemester
        DATEPART(quarter, TheDate),                                  -- FiscalQuarter (assuming fiscal year = calendar year)
        DATEPART(year, TheDate),                                     -- FiscalYear (assuming fiscal year = calendar year)
        CASE WHEN DATEPART(month, TheDate) <= 6 THEN 1 ELSE 2 END,   -- FiscalSemester (assuming fiscal year = calendar year)
        CASE WHEN DATEPART(weekday, TheDate) IN (1, 7) THEN 1 ELSE 0 END -- IsWeekend (1=True, 0=False)
    FROM
        DateSeries
    -- The MAXRECURSION option is set to 366 to handle leap years without error.
    -- The default is 100, which would fail.
    OPTION (MAXRECURSION 366);

    PRINT 'Successfully populated DimDate for the year ' + CONVERT(VARCHAR, YEAR(@InputDate)) + '.';
    PRINT 'Total rows inserted: ' + CONVERT(VARCHAR, @@ROWCOUNT) + '.';

END
GO


-- =================================================================================
-- Part 3: Execution Example
-- =================================================================================
-- This is how you would run the stored procedure.
-- =================================================================================

-- Declare a variable and set it to the date provided in the example (14-07-2020)
DECLARE @MyDate DATE = '2020-07-14';

-- Execute the procedure. It will populate data for the entire year of 2020.
EXEC dbo.sp_Populate_DimDate @InputDate = @MyDate;
GO

-- To verify the results, you can select data from the table.
-- Let's check the data for the specific date we passed in.
SELECT *
FROM dbo.DimDate
WHERE DateKey = '2020-07-14';

-- Let's check the first day of that year.
SELECT *
FROM dbo.DimDate
WHERE DateKey = '2020-01-01';

-- And the last day of that year.
SELECT *
FROM dbo.DimDate
WHERE DateKey = '2020-12-31';

-- You can also run it for a different year, for example, the current year.
-- Note: GETDATE() returns a datetime, it's implicitly converted to a date.
EXEC dbo.sp_Populate_DimDate @InputDate = GETDATE;

-- Verify the data for the current year
SELECT TOP 5 * FROM dbo.DimDate WHERE CalendarYear = YEAR(GETDATE()) ORDER BY DateKey;
GO
