use master;
--// Remove all objects created as part of this demo.
alter database TrustedDb01
	set single_user
	with
		rollback immediate
;
go

drop database TrustedDB01;
go

alter database TrustedDb02
	set single_user
	with
		rollback immediate
;
go

drop database TrustedDB02;
go

alter database AttackerDB01
	set single_user
	with
		rollback immediate
;
go

drop database AttackerDB01;
go

drop login [DbOwner01];
go

drop login DemoUser;
go