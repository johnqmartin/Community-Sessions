--// Criteria for condition
---------------------
--// Database Owner is a member of SysAdmin
--// Database has TRUSTWORTHY ON
--// Database has members in the db_owner database role
--// Database has users that can impersonance members of db_owner
--// Database is NOT MSDB

CREATE TABLE #DbOwnerList
       (
        DatabaseId INT,
        DatabaseName sysname,
        RoleName sysname,
        Membername sysname
       );
GO

CREATE TABLE #ImpersonationList
       (
        DatabaseId INT,
        DatabaseName sysname,
        ImperonatingUser sysname,
        ImpersonatedUser sysname,
		ImpersonatedUserRole sysname
       );
GO

CREATE PROCEDURE #ForEachDB
       (
        @cmd NVARCHAR(MAX),
        @name_pattern NVARCHAR(257) = '%',
        @recovery_model NVARCHAR(60) = NULL
       )
AS
       BEGIN
             SET NOCOUNT ON;

             DECLARE @sql NVARCHAR(MAX),
                     @db NVARCHAR(257);

             DECLARE c CURSOR LOCAL FORWARD_ONLY STATIC READ_ONLY
             FOR
                     SELECT QUOTENAME(name)
                     FROM   sys.databases
                     WHERE  (
                             @recovery_model IS NULL OR (recovery_model_desc = @recovery_model)
                            ) AND name LIKE @name_pattern AND state = 0 AND is_read_only = 0
                     ORDER BY name;

             OPEN c;
    
             FETCH NEXT FROM c INTO @db;

             WHILE @@Fetch_Status <> -1
                   BEGIN
                         SET @sql = REPLACE(@cmd, '?', @db);
                         BEGIN TRY
                               EXEC(@sql);
                         END TRY
                         BEGIN CATCH
                               PRINT ERROR_MESSAGE();
                         END CATCH;

                         FETCH NEXT FROM c INTO @db;
                   END;

             CLOSE c;
             DEALLOCATE c;
       END;
GO

DECLARE @SqlStatement NVARCHAR(MAX) = (N'USE ?
		
		SELECT DB_ID() AS DatabaseId,
			DB_NAME() AS DatabaseName,
			roles.name AS RoleName,
			members.name AS MemberName
		from sys.database_role_members as rm
		join sys.database_principals as roles on rm.role_principal_id = roles.principal_id
		right join sys.database_principals as members on rm.member_principal_id = members.principal_id
		WHERE roles.name = N''db_owner'' AND members.name <> N''dbo'';');

INSERT  INTO #DbOwnerList
        (
         DatabaseId,
         DatabaseName,
         RoleName,
         Membername
        )
        EXEC #ForEachDB @cmd = @SqlStatement;

SET @SqlStatement = (N'USE ?
		
		SELECT DB_ID() AS DatabaseId,
			DB_NAME() AS DatabaseName,
			Impersonator.name AS ImperonatingUser,
			Impersonated.name AS ImpersonatedUser,
			DatabaseRole.name AS ImpersonatedUserRole
		FROM sys.database_permissions AS dp
		JOIN sys.database_principals AS Impersonated ON dp.major_id = Impersonated.principal_id
		JOIN sys.database_principals AS Impersonator ON dp.grantee_principal_id = Impersonator.principal_id
		JOIN sys.database_role_members AS RoleMembers ON Impersonated.principal_id = RoleMembers.member_principal_id
		JOIN sys.database_principals AS DatabaseRole ON RoleMembers.role_principal_id = DatabaseRole.principal_id
		WHERE permission_name = ''impersonate''
			AND DatabaseRole.name = ''db_owner''
		;');

INSERT  INTO #ImpersonationList
        (
         DatabaseId,
         DatabaseName,
         ImperonatingUser,
         ImpersonatedUser,
		 ImpersonatedUserRole
        )
        EXEC #ForEachDB @cmd = @SqlStatement;


--// Script to identify databases at risk.
WITH _ServerPrincipals
AS (
		SELECT    members.sid AS memberSid,
				members.name AS PrincipalName,
				roles.name AS RoleName,
				roles.is_fixed_role,
				CASE WHEN roles.name = 'sysadmin' THEN 1
						ELSE 0
				END AS IsSysAdmin
		FROM sys.server_role_members AS rm
		JOIN sys.server_principals AS roles ON rm.role_principal_id = roles.principal_id
		RIGHT JOIN sys.server_principals AS members ON rm.member_principal_id = members.principal_id
	)
SELECT DISTINCT N'DatabaseName : ' + d.name 
	+ N' | DbOwner : ' + p.PrincipalName 
	+ N' DbOwnerRole : ' + p.RoleName 
	+ N'[IsSysAdmin=' 
	+ CASE p.IsSysAdmin
		WHEN 1 THEN N'Yes]'
		ELSE N'No]'
		END
	+ ISNULL((+ N'| DbRole : ' + dbr.RoleName + N' | Role Members :'),N'')
	+ ISNULL(STUFF((SELECT N', ' + N'{' + dbl.Membername + N'}'
			FROM #DbOwnerList AS dbl
			WHERE dbl.DatabaseId = d.Database_id
			ORDER BY dbl.DatabaseId, dbl.RoleName
			FOR XML PATH(N''),TYPE).value(N'.[1]',N'NVARCHAR(MAX)'),1,2,N''),N'')
	+ ISNULL((+ N' | ImpersonatedUser : ' + ipl.ImpersonatedUser + N'(' + ipl.ImpersonatedUserRole + N')'),N'')
	+ ISNULL(STUFF(
		(SELECT N', ' + N'{' + il.ImperonatingUser + N'}'
		FROM #ImpersonationList AS il
		WHERE il.DatabaseId = d.database_id
		ORDER BY il.DatabaseId, il.ImpersonatedUser
		FOR XML PATH(N''),TYPE).value(N'.[1]',N'NVARCHAR(MAX)'),1,2,N''),N'') AS InfoColumn,
	CASE 
		WHEN(d.is_trustworthy_on = 1 AND p.IsSysAdmin = 1) THEN CAST(1 AS BIT)
        ELSE CAST(0 AS BIT)
	END AS DbAtRisk
FROM sys.databases AS d
LEFT JOIN #DbOwnerList AS dbr ON d.database_id = dbr.DatabaseId
LEFT JOIN #ImpersonationList AS ipl ON d.database_id = ipl.DatabaseId
JOIN _ServerPrincipals AS p ON d.owner_sid = p.memberSid
ORDER BY DbAtRisk DESC
;

DROP PROCEDURE #ForEachDB;
DROP TABLE #DbOwnerList;
DROP TABLE #ImpersonationList;
GO 