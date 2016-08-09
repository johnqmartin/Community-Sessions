use [master];
go

--// Remove all objects created as part of this demo.
alter database TDEDemo
	set single_user
	with
		rollback immediate
;
go

drop database TDEDemo;
go

drop certificate myTDECert;
go

drop master key;
go