use [master];
go
--// Create database to test TDE on
create database TDEDemo;
go
--// set to simple recovery for loading data
alter database TDEDemo
	set recovery simple
;
go

use TDEDemo;
go
--// Load data into a table in the database
--// Relies on having the Stack overflow database,
--// replace with another data source if you don't have this.
select *
into dbo.Users
from StackOverflow.dbo.Users
;
go
checkpoint;
go