USE master
GO
CREATE LOGIN mmdreader WITH PASSWORD=N'MMDUser_001', DEFAULT_DATABASE=ReVeraDB, CHECK_EXPIRATION=OFF, CHECK_POLICY=ON
GO
USE ReVeraDB
GO
CREATE USER mmdreader FOR LOGIN mmdreader
GO
USE ReVeraDB
GO
ALTER ROLE db_datareader ADD MEMBER mmdreader
GO

DECLARE @user	sysname = 'mmdreader'
DECLARE @name	sysname
DECLARE @cmd	NVARCHAR(4000)

DECLARE udt_cur CURSOR LOCAL FAST_FORWARD FOR
SELECT name 
	FROM sys.types 
WHERE is_user_defined = 1;

OPEN udt_cur;

FETCH udt_cur INTO @name;

WHILE @@FETCH_STATUS = 0
BEGIN		
	SET @cmd = 'GRANT EXECUTE ON TYPE::' + @name + ' TO [' + @user + ']'
	EXEC (@cmd)
	FETCH udt_cur INTO @name
END

CLOSE udt_cur;

DEALLOCATE udt_cur;
