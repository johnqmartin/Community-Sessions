-------------------------------------------------------------
--------------------- DDM Prerquisites ----------------------
-------------------------------------------------------------

CREATE FUNCTION dbo.fnGetFormattedAddress
(@AddressId INT)
	RETURNS TABLE
AS

	RETURN 
	(
		SELECT a.AddressLine1 + ',' + CHAR(13) + 
			a.City + ',' + CHAR(13) +
			sp.Name + ',' + CHAR(13) +
			a.PostalCode + ',' + CHAR(13) +
			cr.Name AS FormattedAddress
		FROM person.[Address] AS a
		JOIN Person.StateProvince AS sp ON a.StateProvinceID = sp.StateProvinceID
		JOIN Person.CountryRegion AS cr ON sp.CountryRegionCode = cr.CountryRegionCode
		WHERE a.AddressID = @AddressId
	);
GO
