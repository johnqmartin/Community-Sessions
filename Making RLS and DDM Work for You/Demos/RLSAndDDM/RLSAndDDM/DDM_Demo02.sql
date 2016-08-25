-------------------------------------------------------------
------------------------ DDM Demo 01 ------------------------
-------------------------------------------------------------
--// Demo works through some basic examples of applying masking to different 
--// data types and columns.

--// Create the sample table.
CREATE TABLE dbo.DDM_SampleData
(
	TableID TINYINT IDENTITY(1,1) PRIMARY KEY,
	TextColumn01 NVARCHAR(10),
	IntegerColumn01 INT,
	TextColumn02 NVARCHAR(10),
	IntegerColumn02 INT,
	BitColumn BIT,
	NumericColumn DECIMAL,
	GUIDColumn UNIQUEIDENTIFIER
)
;
GO
--// Load it with data.
INSERT INTO dbo.DDM_SampleData
        ( 
          TextColumn01 ,
          IntegerColumn01 ,
          TextColumn02 ,
          IntegerColumn02 ,
          BitColumn ,
          NumericColumn ,
          GUIDColumn
        )
VALUES  (
          N'A' , -- TextColumn01 - nvarchar(10)
          0 , -- IntegerColumn01 - int
          N'A' , -- TextColumn02 - nvarchar(10)
          0 , -- IntegerColumn02 - int
          0 , -- BitColumn - bit
          0.1 , -- NumericColumn - decimal
          NEWID()  -- GUIDColumn - uniqueidentifier
        ),
(
          N'AB' , -- TextColumn01 - nvarchar(10)
          1 , -- IntegerColumn01 - int
          N'AB' , -- TextColumn02 - nvarchar(10)
          1 , -- IntegerColumn02 - int
          1 , -- BitColumn - bit
          0.2 , -- NumericColumn - decimal
          NEWID()  -- GUIDColumn - uniqueidentifier
        ),
(
          N'ABC' , -- TextColumn01 - nvarchar(10)
          2 , -- IntegerColumn01 - int
          N'ABC' , -- TextColumn02 - nvarchar(10)
          2 , -- IntegerColumn02 - int
          0 , -- BitColumn - bit
          0.3 , -- NumericColumn - decimal
          NEWID()  -- GUIDColumn - uniqueidentifier
        ),
(
          N'ABCD' , -- TextColumn01 - nvarchar(10)
          3 , -- IntegerColumn01 - int
          N'ABCD' , -- TextColumn02 - nvarchar(10)
          3 , -- IntegerColumn02 - int
          1 , -- BitColumn - bit
          0.4 , -- NumericColumn - decimal
          NEWID()  -- GUIDColumn - uniqueidentifier
        ),
(
          N'ABCDE' , -- TextColumn01 - nvarchar(10)
          4 , -- IntegerColumn01 - int
          N'ABCDE' , -- TextColumn02 - nvarchar(10)
          4 , -- IntegerColumn02 - int
          0 , -- BitColumn - bit
          0.5 , -- NumericColumn - decimal
          NEWID()  -- GUIDColumn - uniqueidentifier
        ),
(
          N'ABCDEF' , -- TextColumn01 - nvarchar(10)
          5 , -- IntegerColumn01 - int
          N'ABCDEF' , -- TextColumn02 - nvarchar(10)
          5 , -- IntegerColumn02 - int
          1 , -- BitColumn - bit
          0.6 , -- NumericColumn - decimal
          NEWID()  -- GUIDColumn - uniqueidentifier
        )
;
go

SELECT *
FROM dbo.DDM_SampleData

--// Setup a user to demonstrate masking.
CREATE USER MaskedUser
	WITHOUT LOGIN
;
GO
GRANT SELECT ON dbo.DDM_SampleData TO MaskedUser;
GO

--// Execute statement as low level user that we created.
EXECUTE AS USER = 'maskeduser'

	SELECT *
	FROM dbo.DDM_SampleData

REVERT

--// Add masks to columns
ALTER TABLE dbo.DDM_SampleData
	ALTER COLUMN TextColumn01 ADD MASKED WITH (FUNCTION = 'default()')
;
GO

ALTER TABLE dbo.DDM_SampleData
	ADD ComputedCol01 AS TextColumn01 + CAST(IntegerColumn01 AS NVARCHAR(10))
;
GO

ALTER TABLE dbo.DDM_SampleData
	ADD ComputedCol02 AS TextColumn02 + CAST(IntegerColumn02 AS NVARCHAR(10))
;
GO

--// Execute statement as low level user that we created.
EXECUTE AS USER = 'maskeduser'

	SELECT *
	FROM dbo.DDM_SampleData

REVERT