-------------------------------------------------------------
------------------------ Clear Demo -------------------------
-------------------------------------------------------------

--// Drop stats object for Demo01
IF EXISTS
(
	SELECT *
	FROM sys.stats AS s
	WHERE s.name = '_WA_Sys_00000006_5EBF139D'
		AND s.object_id = OBJECT_ID('Person.Address')
)
BEGIN
	DROP STATISTICS Person.Address._WA_Sys_00000006_5EBF139D;
END 
GO 

--// Drop user for Demo01 & Demo 02
DROP USER IF EXISTS [MaskedUser];
GO

--// Drop table from Demo02
DROP TABLE IF EXISTS dbo.DDM_SampleData;
GO

--// Remove masks used in Demo01
IF EXISTS
(
SELECT *
FROM sys.columns AS c
WHERE c.name = 'NationalIDNumber'
	AND c.is_masked = 1
	AND c.object_id = OBJECT_ID('HumanResources.Employee')
)
BEGIN
	ALTER TABLE HumanResources.Employee
		ALTER COLUMN NationalIDNumber DROP MASKED;
END

IF EXISTS
(
SELECT *
FROM sys.columns AS c
WHERE c.name = 'SickLeaveHours'
	AND c.is_masked = 1
	AND c.object_id = OBJECT_ID('HumanResources.Employee')
)
BEGIN
	ALTER TABLE HumanResources.Employee
		ALTER COLUMN SickLeaveHours DROP MASKED;
END

IF EXISTS
(
SELECT *
FROM sys.columns AS c
WHERE c.name = 'EmailAddress'
	AND c.is_masked = 1
	AND c.object_id = OBJECT_ID('Person.EmailAddress')
)
BEGIN
	ALTER TABLE Person.EmailAddress 
		ALTER COLUMN EmailAddress DROP MASKED;
END

IF EXISTS
(
SELECT *
FROM sys.columns AS c
WHERE c.name = 'AddressLine1'
	AND c.is_masked = 1
	AND c.object_id = OBJECT_ID('Person.Address')
)
BEGIN
	ALTER TABLE Person.Address
		ALTER COLUMN AddressLine1 DROP MASKED;
END

IF EXISTS
(
SELECT *
FROM sys.columns AS c
WHERE c.name = 'PostalCode'
	AND c.is_masked = 1
	AND c.object_id = OBJECT_ID('Person.Address')
)
BEGIN
	--SELECT * FROM Person.Address
	ALTER TABLE Person.Address 
		ALTER COLUMN PostalCode DROP MASKED;
END
GO

--// Remove prerequisite function for Demo01
DROP FUNCTION IF EXISTS dbo.fnGetFormattedAddress;
GO

--// Drop procedure used in Demo01
DROP PROCEDURE IF EXISTS dbo.GetEmployeeDetails;
GO

--// Drop views used in Demo01
DROP VIEW IF EXISTS dbo.EmployeeDetails;
DROP VIEW IF EXISTS dbo.EmployeeAddress;
GO
