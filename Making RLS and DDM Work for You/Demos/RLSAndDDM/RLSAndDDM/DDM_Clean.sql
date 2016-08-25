-------------------------------------------------------------
------------------------ Clear Demo -------------------------
-------------------------------------------------------------

--// Drop stats object for Demo01
DROP STATISTICS Person.Address._WA_Sys_00000006_5EBF139D;
GO

--// Drop user for Demo01 & Demo 02
DROP USER IF EXISTS [MaskedUser];
GO

--// Drop table from Demo02
DROP TABLE IF EXISTS dbo.DDM_SampleData;
GO

--// Remove masks used in Demo01
ALTER TABLE HumanResources.Employee
	ALTER COLUMN NationalIDNumber ADD MASKED WITH(FUNCTION='default()');
ALTER TABLE HumanResources.Employee
	ALTER COLUMN SickLeaveHours ADD MASKED WITH(FUNCTION='random(1,100)');
ALTER TABLE Person.EmailAddress 
	ALTER COLUMN EmailAddress ADD MASKED WITH(FUNCTION='email()');
ALTER TABLE Person.Address
	ALTER COLUMN AddressLine1 ADD MASKED WITH (FUNCTION='default()');
ALTER TABLE Person.Address
	ALTER COLUMN PostalCode ADD MASKED WITH (FUNCTION='default()');
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
