-------------------------------------------------------------
------------------------ Clear Demo -------------------------
-------------------------------------------------------------

--// Clean up stored procedures.
DROP PROCEDURE IF EXISTS dbo.getSalesOrder;
DROP PROCEDURE IF EXISTS dbo.getSalesOrderRLS;
DROP PROCEDURE IF EXISTS security.setContextInfoEmployee;
DROP PROCEDURE IF EXISTS sales.getSalesOrderRLS;
DROP PROCEDURE IF EXISTS sales.getSalesOrder;
GO 

DROP INDEX IF EXISTS ix_rls_SalesOrderDeail ON Sales.SalesOrderDetail;
DROP INDEX IF EXISTS ix_rls_SalesOrderHeader ON Sales.SalesOrderHeader;
GO 

IF EXISTS
(
	SELECT *
	FROM sys.stats AS s
	WHERE s.name = 'TotalDueStats'
		AND s.object_id = OBJECT_ID('sales.SalesOrderHeader')
)
BEGIN
	DROP STATISTICS sales.SalesOrderHeader.TotalDueStats;
END 
GO 

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