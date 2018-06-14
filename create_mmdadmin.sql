USE master
GO
CREATE LOGIN mmdadmin WITH PASSWORD=N'MMDSoftware_007', DEFAULT_DATABASE=master, CHECK_EXPIRATION=OFF, CHECK_POLICY=ON
GO
ALTER SERVER ROLE sysadmin ADD MEMBER mmdadmin
GO
USE master
GO
CREATE USER mmdadmin FOR LOGIN mmdadmin
GO
USE model
GO
CREATE USER mmdadmin FOR LOGIN mmdadmin
GO
USE msdb
GO
CREATE USER mmdadmin FOR LOGIN mmdadmin
GO
USE ReVeraDB
GO
CREATE USER mmdadmin FOR LOGIN mmdadmin
GO
USE tempdb
GO
CREATE USER mmdadmin FOR LOGIN mmdadmin
GO
USE NovaSIMSRepository
GO
CREATE USER mmdadmin FOR LOGIN mmdadmin
GO