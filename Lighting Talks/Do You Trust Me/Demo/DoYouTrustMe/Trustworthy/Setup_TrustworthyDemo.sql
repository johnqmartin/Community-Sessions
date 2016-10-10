use [master];
GO
--// Create login for this demo, will connect to the server and database as this user.
--// Will be setup as db_Owner for both demo datbases, no server permissions.
create login DemoUser
	with password = N'M0nk3y!!!'
;
GO