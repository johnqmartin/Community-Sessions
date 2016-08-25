-------------------------------------------------------------
------------------------ Setup Demo -------------------------
-------------------------------------------------------------

--// Create a schema for our Row Level Security Objects to reside in.
CREATE SCHEMA security;
GO

--// When using applications we will use a procedure to set the connection context.
CREATE PROCEDURE security.setContextInfoEmployee (@employeeID INT)
AS
       BEGIN
	
	--// Details on session_context : https://msdn.microsoft.com/en-us/library/mt590806.aspx
	--// Details on sp_set_session_context : https://msdn.microsoft.com/en-us/library/mt605113.aspx
             EXEC sp_set_session_context N'EmployeeId', @employeeID, 1;
	
       END;
GO


--// Need to create a function to signal if the rows should be returned to the caller or not.]
--// The security restriction needs to be built into the design of the application & database.
CREATE FUNCTION security.fn_rls_salesOrders (@appuser INT)
RETURNS TABLE
       WITH SCHEMABINDING
AS
	RETURN
       SELECT   1 AS authorized
       FROM     (
                 SELECT e.BusinessEntityID
                 FROM   HumanResources.Employee AS e
                 WHERE  e.OrganizationNode.IsDescendantOf((
                                                           SELECT
                                                              emp.OrganizationNode
                                                           FROM
                                                              HumanResources.Employee
                                                              AS emp
                                                           WHERE
                                                              emp.BusinessEntityID = @appuser)) = 1)
                AS employees
       WHERE    employees.BusinessEntityID = (
                                              SELECT    SESSION_CONTEXT(N'EmployeeId'));
GO

--// Security policy is what applies the function to the object that we want to restrict access to.
CREATE SECURITY POLICY security.SalesOrderFilter
ADD FILTER PREDICATE security.fn_rls_salesOrders(SalesPersonID)
ON Sales.SalesOrderHeader
WITH(STATE=ON
)
;
GO

-------------------------------------------------------------
---------------- Setup Complete, Start Demo -----------------
-------------------------------------------------------------
--// Create procedures to get data.
CREATE PROCEDURE Sales.getSalesOrderRLS
AS
       BEGIN

             SELECT h.SalesOrderNumber,
                    h.CustomerID,
                    h.SalesPersonID,
                    h.OrderDate,
                    h.DueDate,
                    h.ShipDate,
                    h.SubTotal,
                    h.Freight,
                    h.TaxAmt,
                    h.TotalDue,
                    sd.ProductID,
                    p.Name AS ProductName,
                    p.ProductNumber,
                    psc.Name AS ProductSubCategoryName,
                    pc.Name AS ProductCategoryName,
                    sd.OrderQty,
                    sd.UnitPrice,
                    sd.UnitPriceDiscount,
                    so.Description AS DiscountDescription,
                    so.Type AS DiscountType
             FROM   Sales.SalesOrderHeader AS h
             JOIN   Sales.SalesOrderDetail AS sd ON sd.SalesOrderID = h.SalesOrderID
             JOIN   Sales.SpecialOfferProduct AS sop ON sd.ProductID = sop.ProductID
             JOIN   Production.Product AS p ON sop.ProductID = p.ProductID
             JOIN   Sales.SpecialOffer AS so ON sop.SpecialOfferID = so.SpecialOfferID
             JOIN   Production.ProductSubcategory AS psc ON p.ProductSubcategoryID = psc.ProductSubcategoryID
             JOIN   Production.ProductCategory AS pc ON psc.ProductCategoryID = pc.ProductCategoryID;

       END;
GO

--// Procedure that uses a predicate to filter the results.
CREATE PROCEDURE Sales.getSalesOrder (@SalesPersonID INT)
AS
       BEGIN

             SELECT h.SalesOrderNumber,
                    h.CustomerID,
                    h.SalesPersonID,
                    h.OrderDate,
                    h.DueDate,
                    h.ShipDate,
                    h.SubTotal,
                    h.Freight,
                    h.TaxAmt,
                    h.TotalDue,
                    sd.ProductID,
                    p.Name AS ProductName,
                    p.ProductNumber,
                    psc.Name AS ProductSubCategoryName,
                    pc.Name AS ProductCategoryName,
                    sd.OrderQty,
                    sd.UnitPrice,
                    sd.UnitPriceDiscount,
                    so.Description AS DiscountDescription,
                    so.Type AS DiscountType
             FROM   Sales.SalesOrderHeader AS h
             JOIN   Sales.SalesOrderDetail AS sd ON sd.SalesOrderID = h.SalesOrderID
             JOIN   Sales.SpecialOfferProduct AS sop ON sd.ProductID = sop.ProductID
             JOIN   Production.Product AS p ON sop.ProductID = p.ProductID
             JOIN   Sales.SpecialOffer AS so ON sop.SpecialOfferID = so.SpecialOfferID
             JOIN   Production.ProductSubcategory AS psc ON p.ProductSubcategoryID = psc.ProductSubcategoryID
             JOIN   Production.ProductCategory AS pc ON psc.ProductCategoryID = pc.ProductCategoryID
             WHERE  SalesPersonID = @SalesPersonID;

       END;
GO

-------------------------------------------------------------
---------------- Application Simulation Time ----------------
-------------------------------------------------------------

--// Application Connection Opens

--// Set the application connection context
--// Here we are passing in an application security identifier
EXEC security.setContextInfoEmployee 274;

--// Show value for Session Context
SELECT  SESSION_CONTEXT(N'EmployeeId');

--// Lets select some data
EXEC Sales.getSalesOrderRLS;

--// Application Connection Closes

-------------------------------------------------------------
---------------- Application Simulation Time ----------------
-------------------------------------------------------------

--/ Now lets look at some execution plans.
--// We are carrying over the same session context value's here,
--// this is because SSMS has not closed the session.
--// We can get round it by reconnecting.
--// Get the data
SET STATISTICS TIME ON;
SET STATISTICS IO ON;

	--// Execute the statements again and see what we get.
	EXEC Sales.getSalesOrder 274;

	EXEC Sales.getSalesOrderRLS;

SET STATISTICS TIME OFF;
SET STATISTICS IO OFF;

--// OK, lets get this indexes built.
CREATE NONCLUSTERED INDEX ix_rls_SalesOrderHeader
ON Sales.SalesOrderHeader(SalesPersonID)
INCLUDE
(OrderDate, DueDate, ShipDate, SalesOrderNumber,CustomerID,SubTotal,TaxAmt,Freight,TotalDue);
GO

CREATE INDEX ix_rls_SalesOrderDeail
	ON AdvWorks.Sales.SalesOrderDetail(ProductID)
INCLUDE
	(OrderQty, UnitPrice, UnitPriceDiscount)
;
GO

-------------------------------------------------------------
--------------------- Security details ----------------------
-------------------------------------------------------------

--// SQL Server 2012 and above requires only SELECT permission to view statistics.

--// Create statistics object to query.
CREATE STATISTICS TotalDueStats
ON Sales.SalesOrderHeader(TotalDue)
WITH
FULLSCAN;
GO

--// Create low level permissions user.
--// Grant SELECT to RLS covered object and non-RLS covered object.
CREATE USER SelectUser WITHOUT LOGIN;
GRANT SELECT ON Sales.SalesOrderHeader
	TO SelectUser;
GO
GRANT SELECT ON Sales.Customer
	TO SelectUser;
GO

--// Get statistics object for the table we have SELECT on,
--// but is not using RLS.
EXECUTE AS USER = 'SelectUser';

	DBCC SHOW_STATISTICS('Sales.Customer','IX_Customer_TerritoryID');

REVERT;

--// Get statistics object for the table we have SELECT on,
--// but is using RLS.
EXECUTE AS USER = 'SelectUser';

	DBCC SHOW_STATISTICS('Sales.SalesOrderHeader','TotalDueStats');

REVERT;