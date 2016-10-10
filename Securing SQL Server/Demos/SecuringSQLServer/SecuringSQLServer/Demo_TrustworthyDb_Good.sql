use [master];
GO

--// Create sample databases to use for demo
--// Set Trustworthy ON for sample database
create database TrustedDB02;
go
alter database TrustedDB02
	set trustworthy on
;
go

--// Create a login that will be used as the owner for DB02
--// Will only be a member of public with no further permissions.
create login DbOwner01
	with password = N'R@nd0mP@$$w0rd!'
;
go

use TrustedDB02;
GO
--// Set owner to DbOwner01 for DB02
--// Crete a user for the demo user and set to be member of db_owner role
exec sp_changedbowner @loginame = N'DbOwner01', @map = false;
create user [DemoUser] for login [DemoUser];
alter role [db_owner] add member [DemoUser];
go

USE TrustedDB02;
go
--// Perform the same actions as above.
execute as user  = 'dbo';
	
	--// These actions should fail as the owner of the datbase 
	--// does not have the permissions at the server level to perform the actions.
	create database AttackerDB02;
	go

	select *
	from AdventureWorks2014.sales.Customer
	;
	select *
	from AdventureWorks2014.Production.Product
	;
revert

use TempDB;
go