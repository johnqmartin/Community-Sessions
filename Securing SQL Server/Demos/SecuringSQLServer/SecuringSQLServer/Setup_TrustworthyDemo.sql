use [master];
go
--// Create sample databases to use for demo
--// Set Trustworthy ON for sample databases
create database TrustedDB01;
go
alter database TrustedDB01
	set trustworthy on
;
go
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
--// Create login for this demo, will connect to the server and database as this user.
--// Will be setup as db_Owner for both demo datbases, no server permissions.
create login DemoUser
	with password = N'M0nk3y!!!'
;
go

--// Set owner to SA for DB01 and owner account for DB02
--// Crete a user for the demo user and set to be member of db_owner role
use TrustedDB01;
go
exec sp_changedbowner @loginame = N'sa', @map = false;
create user [DemoUser] for login [DemoUser];
alter role [db_owner] add member [DemoUser];
go

use TrustedDB02;
go
exec sp_changedbowner @loginame = N'DbOwner01', @map = false;
create user [DemoUser] for login [DemoUser];
alter role [db_owner] add member [DemoUser];
go

--// Set context to a different database, just being tidy.
use [tempdb];
go