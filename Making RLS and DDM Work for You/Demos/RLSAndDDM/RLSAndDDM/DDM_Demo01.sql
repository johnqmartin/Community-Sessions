-------------------------------------------------------------
------------------------ DDM Demo 01 ------------------------
-------------------------------------------------------------

--// Create a local user to execute in the context 
--// as for the purposes of the demo.
CREATE USER [MaskedUser]
	WITHOUT LOGIN
;
GO
--// Grant select on the tables we need.
GRANT SELECT ON HumanResources.Employee TO [MaskedUser];
GRANT SELECT ON Person.Person TO [MaskedUser];
GRANT SELECT ON Person.EmailAddress TO [MaskedUser];
GRANT SELECT ON Person.BusinessEntityAddress TO [MaskedUser];
GRANT SELECT ON dbo.fnGetFormattedAddress TO [MaskedUser];
GO

EXECUTE AS USER = 'MaskedUser'

--// Basic Query for sensitive business data
	SELECT  p.FirstName,
		p.LastName,
		p.PersonType,
		e.HireDate,
		e.JobTitle,
		e.NationalIDNumber,
		em.EmailAddress,
		e.SickLeaveHours,
		fa.FormattedAddress
	FROM HumanResources.Employee AS e
	JOIN Person.Person AS p 
		ON e.BusinessEntityID = p.BusinessEntityID
	JOIN Person.EmailAddress AS em 
		ON p.BusinessEntityID = em.BusinessEntityID
	JOIN person.BusinessEntityAddress AS bea 
		ON bea.BusinessEntityID = e.BusinessEntityID
	CROSS APPLY dbo.fnGetFormattedAddress(bea.AddressID) AS fa
	;

REVERT

-------------------------------------------------------------
----------------------- Masking Data ------------------------
-------------------------------------------------------------

--// Core employee Data
ALTER TABLE HumanResources.Employee
	ALTER COLUMN NationalIDNumber ADD MASKED WITH(FUNCTION='default()')
;
ALTER TABLE HumanResources.Employee
	ALTER COLUMN SickLeaveHours ADD MASKED WITH(FUNCTION='random(1,100)')
;
ALTER TABLE Person.EmailAddress 
	ALTER COLUMN EmailAddress ADD MASKED WITH(FUNCTION='email()')
;

EXECUTE AS USER = 'MaskedUser'

--// Basic Query for sensitive business data
	SELECT  p.FirstName,
		p.LastName,
		p.PersonType,
		e.HireDate,
		e.JobTitle,
		e.NationalIDNumber,
		em.EmailAddress,
		e.SickLeaveHours,
		fa.FormattedAddress
	FROM HumanResources.Employee AS e
	JOIN Person.Person AS p 
		ON e.BusinessEntityID = p.BusinessEntityID
	JOIN Person.EmailAddress AS em 
		ON p.BusinessEntityID = em.BusinessEntityID
	JOIN person.BusinessEntityAddress AS bea 
		ON bea.BusinessEntityID = e.BusinessEntityID
	CROSS APPLY dbo.fnGetFormattedAddress(bea.AddressID) AS fa
	;

REVERT

--// Lets alter the NationalIdNumber mask.
ALTER TABLE HumanResources.Employee
	ALTER COLUMN NationalIDNumber ADD MASKED WITH(FUNCTION='partial(1,"-XXXX-",2)')
;
GO
--// Now re-run the query.

-------------------------------------------------------------
-------------------------------------------------------------

--// But, how do we handle the address?
--// Data is returned from a function.
ALTER TABLE Person.Address
	ALTER COLUMN AddressLine1 ADD MASKED WITH (FUNCTION='default()')
;
ALTER TABLE Person.Address
	ALTER COLUMN PostalCode ADD MASKED WITH (FUNCTION='default()')
;
GO

EXECUTE AS USER = 'MaskedUser'

--// Basic Query for sensitive business data
	SELECT  p.FirstName,
		p.LastName,
		p.PersonType,
		e.HireDate,
		e.JobTitle,
		e.NationalIDNumber,
		em.EmailAddress,
		e.SickLeaveHours,
		fa.FormattedAddress
	FROM HumanResources.Employee AS e
	JOIN Person.Person AS p 
		ON e.BusinessEntityID = p.BusinessEntityID
	JOIN Person.EmailAddress AS em 
		ON p.BusinessEntityID = em.BusinessEntityID
	JOIN person.BusinessEntityAddress AS bea 
		ON bea.BusinessEntityID = e.BusinessEntityID
	CROSS APPLY dbo.fnGetFormattedAddress(bea.AddressID) AS fa
	;

REVERT

--// The concatenation of the masked and un-masked columns takes 
--// the most restrictive result.

-------------------------------------------------------------
-------------------------------------------------------------

--// Lets change the query.
EXECUTE AS USER = 'MaskedUser';

	WITH _AddressCTE
	AS
	(
		SELECT a.AddressID,
			a.AddressLine1 + ',' + CHAR(13) + 
			a.City + ',' + CHAR(13) +
			sp.Name + ',' + CHAR(13) +
			a.PostalCode + ',' + CHAR(13) +
			cr.Name AS FormattedAddress
		FROM person.[Address] AS a
		JOIN Person.StateProvince AS sp ON a.StateProvinceID = sp.StateProvinceID
		JOIN Person.CountryRegion AS cr ON sp.CountryRegionCode = cr.CountryRegionCode
	)
	SELECT  p.FirstName,
		p.LastName,
		p.PersonType,
		e.HireDate,
		e.JobTitle,
		e.NationalIDNumber,
		em.EmailAddress,
		e.SickLeaveHours,
		ac.FormattedAddress
	FROM HumanResources.Employee AS e
	JOIN Person.Person AS p 
		ON e.BusinessEntityID = p.BusinessEntityID
	JOIN Person.EmailAddress AS em 
		ON p.BusinessEntityID = em.BusinessEntityID
	JOIN person.BusinessEntityAddress AS bea 
		ON bea.BusinessEntityID = e.BusinessEntityID
	JOIN _AddressCTE AS ac ON bea.AddressID = ac.AddressID
	;

REVERT

--// We now need additional permissions onthe tables we are querying.
GRANT SELECT ON Person.CountryRegion TO MaskedUser;
GRANT SELECT ON Person.StateProvince TO MaskedUser;
GRANT SELECT ON Person.Address TO MaskedUser;
GO
--// Now re-run the query!

-------------------------------------------------------------
-------------------------------------------------------------

--// Lets rewrite it, again!
EXECUTE AS USER = 'MaskedUser';

	WITH _AddressCTE
	AS
	(
		SELECT a.AddressID,
			a.AddressLine1,
			a.City,
			sp.Name AS StateProvinceName,
			a.PostalCode,
			cr.Name AS CountryName
		FROM person.[Address] AS a
		JOIN Person.StateProvince AS sp ON a.StateProvinceID = sp.StateProvinceID
		JOIN Person.CountryRegion AS cr ON sp.CountryRegionCode = cr.CountryRegionCode
	)
	SELECT  p.FirstName,
		p.LastName,
		p.PersonType,
		e.HireDate,
		e.JobTitle,
		e.NationalIDNumber,
		em.EmailAddress,
		e.SickLeaveHours,
		ac.AddressLine1,
		ac.City,
		ac.StateProvinceName,
		ac.PostalCode,
		ac.CountryName
	FROM HumanResources.Employee AS e
	JOIN Person.Person AS p 
		ON e.BusinessEntityID = p.BusinessEntityID
	JOIN Person.EmailAddress AS em 
		ON p.BusinessEntityID = em.BusinessEntityID
	JOIN person.BusinessEntityAddress AS bea 
		ON bea.BusinessEntityID = e.BusinessEntityID
	JOIN _AddressCTE AS ac ON bea.AddressID = ac.AddressID
	;

REVERT
--// Now we can see the masked and un-masked columns.

-------------------------------------------------------------
----------------------- DDM Security ------------------------
-------------------------------------------------------------

--// SQL Server 2012+, only requires SELECT on an object to view Statistics..
EXECUTE AS USER = 'MaskedUser'

	DBCC SHOW_STATISTICS('HumanResources.Employee','AK_Employee_NationalIDNumber')

REVERT 

--// Even a low level user can get to the stats tables..
EXECUTE AS USER = 'MaskedUser'

	SELECT OBJECT_NAME(s.object_id) AS objectName,
		s.name AS StatsName,
		col.name
	FROM sys.stats AS s
	JOIN sys.stats_columns AS sc ON s.object_id = sc.object_id
		AND s.stats_id = sc.stats_id
	JOIN sys.columns AS col ON sc.column_id = col.column_id
		AND sc.object_id = col.object_id
	WHERE s.object_id = OBJECT_ID('Person.Address')
	;

REVERT

--// Lets create some stats.
EXECUTE AS USER ='MaskedUser'

	SELECT *
	FROM Person.Address
	WHERE PostalCode = 1
	;

REVERT

--// We get an error, the data is masked.
--// But! Run the stats query again....

EXECUTE AS USER = 'MaskedUser'

	DBCC SHOW_STATISTICS('Person.Address','_WA_Sys_00000006_5EBF139D')

REVERT 

-------------------------------------------------------------
-------------------------------------------------------------

--// How to work around this.
--// Views, Procedures etc.
CREATE VIEW dbo.EmployeeDetails
AS 
	SELECT  p.FirstName,
		p.LastName,
		p.PersonType,
		e.HireDate,
		e.JobTitle,
		e.NationalIDNumber,
		em.EmailAddress,
		e.SickLeaveHours,
		bea.AddressID
	FROM HumanResources.Employee AS e
	JOIN Person.Person AS p 
		ON e.BusinessEntityID = p.BusinessEntityID
	JOIN Person.EmailAddress AS em 
		ON p.BusinessEntityID = em.BusinessEntityID
	JOIN person.BusinessEntityAddress AS bea 
		ON bea.BusinessEntityID = e.BusinessEntityID
;
GO

CREATE VIEW dbo.EmployeeAddress
AS
SELECT a.AddressID,
	a.AddressLine1,
	a.City,
	sp.Name AS StateProvinceName,
	a.PostalCode,
	cr.Name AS CountryName
FROM person.[Address] AS a
JOIN Person.StateProvince AS sp ON a.StateProvinceID = sp.StateProvinceID
JOIN Person.CountryRegion AS cr ON sp.CountryRegionCode = cr.CountryRegionCode
;
GO

CREATE PROCEDURE dbo.GetEmployeeDetails
AS
BEGIN

	WITH _AddressCTE
	AS
	(
		SELECT a.AddressID,
			a.AddressLine1,
			a.City,
			sp.Name AS StateProvinceName,
			a.PostalCode,
			cr.Name AS CountryName
		FROM person.[Address] AS a
		JOIN Person.StateProvince AS sp ON a.StateProvinceID = sp.StateProvinceID
		JOIN Person.CountryRegion AS cr ON sp.CountryRegionCode = cr.CountryRegionCode
	)
	SELECT  p.FirstName,
		p.LastName,
		p.PersonType,
		e.HireDate,
		e.JobTitle,
		e.NationalIDNumber,
		em.EmailAddress,
		e.SickLeaveHours,
		ac.AddressLine1,
		ac.City,
		ac.StateProvinceName,
		ac.PostalCode,
		ac.CountryName
	FROM HumanResources.Employee AS e
	JOIN Person.Person AS p 
		ON e.BusinessEntityID = p.BusinessEntityID
	JOIN Person.EmailAddress AS em 
		ON p.BusinessEntityID = em.BusinessEntityID
	JOIN person.BusinessEntityAddress AS bea 
		ON bea.BusinessEntityID = e.BusinessEntityID
	JOIN _AddressCTE AS ac ON bea.AddressID = ac.AddressID
	;

END

--// Revoke select permissions on the objects from earlier.
REVOKE SELECT ON HumanResources.Employee TO [MaskedUser];
REVOKE SELECT ON Person.Person TO [MaskedUser];
REVOKE SELECT ON Person.EmailAddress TO [MaskedUser];
REVOKE SELECT ON Person.BusinessEntityAddress TO [MaskedUser];
REVOKE SELECT ON dbo.fnGetFormattedAddress TO [MaskedUser];
REVOKE SELECT ON Person.CountryRegion TO MaskedUser;
REVOKE SELECT ON Person.StateProvince TO MaskedUser;
REVOKE SELECT ON Person.Address TO MaskedUser;
GO

--// Now grant rights to views and Procedure
GRANT EXECUTE ON dbo.GetEmployeeDetails TO MaskedUser;
GRANT SELECT ON dbo.EmployeeDetails TO MaskedUser;
GRANT SELECT ON dbo.EmployeeAddress TO MaskedUser;

--// Now get the data
EXECUTE AS USER = 'MaskedUser'

	EXEC dbo.GetEmployeeDetails;

	SELECT *
	FROM dbo.EmployeeDetails AS ed
	JOIN dbo.EmployeeAddress AS ea ON ed.AddressId = ea.AddressID
	WHERE ea.PostalCode = '98052'
	;

REVERT

-------------------------------------------------------------
----------------------- Removing DDM ------------------------
-------------------------------------------------------------

--// Removing the masks from the columns
ALTER TABLE HumanResources.Employee
	ALTER COLUMN NationalIDNumber DROP MASKED;
GO
EXECUTE AS USER = 'MaskedUser'

	EXEC dbo.GetEmployeeDetails;

REVERT

-------------------------------------------------------------
-------------------------------------------------------------

--// Granting unmask ability to user.
REVOKE UNMASK TO [MaskedUser];
GO

EXECUTE AS USER = 'MaskedUser'

	EXEC dbo.GetEmployeeDetails;

REVERT
--// Problem! - This is global, there is no granularity to it :-(