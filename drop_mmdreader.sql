
SET NOCOUNT ON
USE master
 
--DECLARE VARIABLES
DECLARE @Dropping_login_user NVARCHAR(50) = N'mmdreader'
DECLARE @tbl_Databases TABLE (Name NVARCHAR(MAX))
DECLARE @Database_Name NVARCHAR(MAX)
DECLARE @SQL_Drop_Login NVARCHAR(MAX)   
DECLARE @SQL_Drop_DB_Users NVARCHAR(MAX)
      
PRINT 'Begin - Drop Login and User Procedure "' + @Dropping_login_user + '" on server "' + @@SERVERNAME + '"'
             
--DROP LOGIN FROM SERVER
PRINT CHAR(0x0D) + CHAR(0x0A) + 'Begin - Drop Login Step'
IF EXISTS (SELECT * FROM sys.server_principals WHERE name = @Dropping_login_user)
BEGIN TRY
        SET @SQL_Drop_Login = 'DROP LOGIN [' + @Dropping_login_user +']'
        EXEC (@SQL_Drop_Login)
        PRINT '  Dropped Login "' + @Dropping_login_user + '"'
END TRY
BEGIN CATCH
        PRINT '  Could not drop login "' + @Dropping_login_user + '" as the user is currently logged in'

		IF EXISTS (SELECT login_name FROM sys.dm_exec_sessions WHERE login_name = @Dropping_login_user)
		BEGIN
			DECLARE @kill varchar(2048) = '';
			SELECT @kill = @kill + 'kill ' + CONVERT(varchar(5), session_id) + ';'  
			FROM sys.dm_exec_sessions
			WHERE login_name = @Dropping_login_user;

			-- FORCE KILL SESSIONS
			EXEC (@kill)
			PRINT '   Force Killing Login "' + @Dropping_login_user + '"'
			IF  EXISTS (SELECT loginname FROM master.dbo.syslogins where name = @Dropping_login_user)
			BEGIN
				DECLARE @SqlStatement varchar(2048) = '';
				SELECT @SqlStatement = 'DROP LOGIN ' + QUOTENAME(@Dropping_login_user)
				EXEC(@SqlStatement)
				PRINT '  Dropped Login "' + @Dropping_login_user + '"'
			END
		END
END CATCH
ELSE
        PRINT '  User Login Not Found'
PRINT  'End - Drop Login Step'
 
--USER DROP PROCEDURE
PRINT CHAR(0x0D) + CHAR(0x0A) + 'Begin - Drop User Step'
      
--LOAD DATABASE NAMES INTO TEMP TABLE
INSERT INTO @tbl_Databases (Name)
SELECT Name
FROM master.sys.databases WITH(NOLOCK)
      
--LOOP THROUGH EACH DATABASE AND DROP USER IF EXISTS
WHILE EXISTS (SELECT TOP 1 * FROM @tbl_Databases)
BEGIN
        SET @Database_Name = (SELECT TOP 1 Name FROM @tbl_Databases)
        SET @SQL_Drop_Login ='USE '+@Database_Name
        +' IF  EXISTS (SELECT * FROM sys.database_principals WHERE name = ''' + @Dropping_login_user + ''')
        BEGIN TRY
                DROP USER [' + @Dropping_login_user +']
                PRINT ''  Dropped User in ' + @Database_Name + '''
        END TRY
        BEGIN CATCH
                PRINT ''  User Found But Could Not Drop in ' + @Database_Name + '''
        END CATCH
        ELSE PRINT ''  User Not Found in ' + @Database_Name + '''
        '
        EXEC (@SQL_Drop_Login)
        DELETE FROM @tbl_Databases WHERE Name = @Database_Name
END
 
PRINT 'End - User Drop Step'
 
--END
PRINT CHAR(0x0D) + CHAR(0x0A) + 'End - Drop Login and User Procedure "' + @Dropping_login_user + '" on server "' + @@SERVERNAME + '"'
 
SET NOCOUNT OFF