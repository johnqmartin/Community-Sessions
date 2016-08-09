use [master];
go
--// Create server master key
create master key
	encryption by password = N'M0nk3y!!!'
;
go

--// Generate server certificate to use for
--// encrypting the database.
create certificate myTDECert
	with
		subject = N'TDE Certificate'
;
go

--// Switch context to Demo database.
use TDEDemo;
go
--// Create a key in the database that we want to encrypt.
create database encryption key
	with
		algorithm = AES_256
		encryption by server certificate myTDECert
;
go

--// Now we can turn on the TDE
alter database TDEDemo
	set encryption on
;
go

--// This script will track the progress of the encryption,
--// process in the database.
--// Also notice that TempDB is also encrypted when you encrypt a user database.
while exists(select 1 from sys.dm_database_encryption_keys where database_id = db_id() and encryption_state <> 3)
begin

	select db_name(dek.database_id) as dbName,
		dek.encryption_state,
		dek.percent_complete
	from sys.dm_database_encryption_keys as dek

end