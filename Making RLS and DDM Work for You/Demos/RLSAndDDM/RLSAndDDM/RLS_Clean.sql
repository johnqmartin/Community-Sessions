-------------------------------------------------------------
------------------------ Clear Demo -------------------------
-------------------------------------------------------------

--// Clean up stored procedures.
DROP PROCEDURE IF EXISTS dbo.getSalesOrder;
DROP PROCEDURE IF EXISTS dbo.getSalesOrderRLS;
DROP PROCEDURE IF EXISTS security.setContextInfoEmployee ;

--// Clean up security policy
IF EXISTS(SELECT * FROM sys.objects AS o WHERE o.name = 'SalesOrderFilter' AND o.type = 'sp')
BEGIN
	DROP SECURITY POLICY security.SalesOrderFilter;
end

--// Clean up FUnctions
DROP FUNCTION IF EXISTS [security].fn_rls_salesOrders;

--// Clear Schema
DROP SCHEMA IF EXISTS [security];

--// Clean up user
DROP USER IF EXISTS SelectUser;
GO