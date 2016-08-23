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