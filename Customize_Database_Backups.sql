/****** Object: StoredProcedure Customize_Database_Backups ******/ 

SET ANSI_NULLS ON
GO 
SET QUOTED_IDENTIFIER ON
GO 

/*=============================================================================
-- Author: Raju Angani
-- Creation Date: 06/04/2018
-- Description: Backup Database for all 3 types (FULL, DIFFERENTIAL, T-Log)

-- BackupType and Location are mandatory parameters.

*** If you skip databaseName (i.e.: Parameter1), the script will perform backup for all user
databases.

-- Parameter1: DatabaseName ()
-- Parameter2: BackupType F=Full, D=Differential, L=Transaction-Log
-- Parameter3: Backup File Location

-- Usage for all 3 backup types:
EXEC Customize_Database_Backups  @backupType='F', @backupLocation='E:\SQL_DB_BACKUP\'

-- If you want to backup all user database
EXEC Customize_Database_Backups  @backupType='F', @backupLocation='E:\SQL_DB_BACKUP\'

--Full Backup
-- EXEC Customize_Database_Backups @databaseName='USERDB',  @backupType='F', @backupLocation='E:\SQL_DB_BACKUP\'

--Differential Backup
-- EXEC Customize_Database_Backups  @databaseName='USERDB', @BackupType='D', @backupLocation ='E:\SQL_DB_BACKUP'

--T-Log Backup
-- EXEC Customize_Database_Backups @databaseName='USERDB', @backupType='L', @backupLocation='E:\SQL_DB_BACKUP\'

---==========================================================================*/

-- DROP PROCEDURE [Customize_Database_Backups]  

CREATE PROCEDURE Customize_Database_Backups
            @databaseName     sysname = null,
            @backupType       CHAR(1),
            @backupLocation   NVARCHAR(200) 

AS 
      SET NOCOUNT ON; 
      DECLARE @DB_List TABLE
      (
            ID       INT IDENTITY PRIMARY KEY,
            DBNAME   NVARCHAR(500)
      )

       -- Pick out only databases which are online in case ALL databases are chosen to be backed up
       -- If specific database is chosen to be backed up only pick that out from @DB_List
      INSERT INTO @DB_List (DBNAME)
      SELECT Name FROM master.sys.databases
      WHERE state=0
      AND name=@DatabaseName
      OR @DatabaseName IS NULL
      ORDER BY Name

      -- Filter out databases which do not need to backed up
      IF @backupType='F'
            BEGIN
            DELETE @DB_List WHERE DBNAME IN ('tempdb','Northwind','pubs','AdventureWorks')
            END
      ELSE IF @backupType='D'
            BEGIN
            DELETE @DB_List WHERE DBNAME IN ('tempdb','Northwind','pubs','master','AdventureWorks')
            END
      ELSE IF @backupType='L'
            BEGIN
            DELETE @DB_List WHERE DBNAME IN ('tempdb','Northwind','pubs','master','AdventureWorks')
            END
      ELSE
            BEGIN
            RETURN
            END

      -- Declare variables
      DECLARE @BackupName  VARCHAR(100)
      DECLARE @BackupFile  VARCHAR(100)
      DECLARE @DBNAME      VARCHAR(300)
      DECLARE @sqlCommand  NVARCHAR(1000)
      DECLARE @dateTime    NVARCHAR(20)
      DECLARE @Loop        INT

      -- Loop through the databases one by one
      SELECT @Loop = min(ID) FROM @DB_List

      WHILE @Loop IS NOT NULL
      BEGIN
         -- Database Names have to be in [dbname] format since some have - or _ in their name
         SET @DBNAME = '['+(SELECT DBNAME FROM @DB_List WHERE ID = @Loop)+']'

         -- Set the current date and time n yyyyhhmmss format
         SET @dateTime = REPLACE(CONVERT(VARCHAR, GETDATE(),101),'/','_') + '_' + REPLACE(CONVERT(VARCHAR, GETDATE(),108),':','_')

         -- Create backup filename in path\filename.extension format for full,diff and log backups
         IF @backupType = 'F'
            SET @BackupFile = @backupLocation + REPLACE(REPLACE(@DBNAME, '[',''),']','') + '_FULL_' + @dateTime + '.BAK'
         ELSE IF @backupType = 'D'
            SET @BackupFile = @backupLocation + REPLACE(REPLACE(@DBNAME, '[',''),']','') + '_DIFF_' + @dateTime + '.BAK'
         ELSE IF @backupType = 'L'
            SET @BackupFile = @backupLocation + REPLACE(REPLACE(@DBNAME, '[',''),']','') + '_LOG_' + @dateTime + '.TRN'

         -- Provide the backup a name for storing on the disk
         IF @backupType = 'F'
            SET @BackupName = REPLACE(REPLACE(@DBNAME,'[',''),']','') + ' full backup for ' + @dateTime

         IF @backupType = 'D'
            SET @BackupName = REPLACE(REPLACE(@DBNAME,'[',''),']','') + ' differential backup for ' + @dateTime

         IF @backupType = 'L'
            SET @BackupName = REPLACE(REPLACE(@DBNAME,'[',''),']','') + ' log backup for ' + @dateTime


         -- Generate the dynamic SQL command for backup to be executed
         IF @backupType = 'F'
            BEGIN
               SET @sqlCommand = 'BACKUP DATABASE ' + @DBNAME + ' TO DISK = ''' + @BackupFile +  ''' WITH INIT, NAME= ''' + @BackupName + ''', NOSKIP, NOFORMAT, COMPRESSION, CHECKSUM, STATS = 10'
            END

         IF @backupType = 'D'
            BEGIN
               SET @sqlCommand = 'BACKUP DATABASE ' + @DBNAME + ' TO DISK = ''' + @BackupFile +  ''' WITH DIFFERENTIAL, INIT, NAME= ''' + @BackupName + ''', NOSKIP, NOFORMAT, COMPRESSION, CHECKSUM, STATS = 10'
            END

         IF @backupType = 'L'
            BEGIN
               SET @sqlCommand = 'BACKUP LOG ' + @DBNAME + ' TO DISK = ''' + @BackupFile +  ''' WITH INIT, NAME= ''' + @BackupName + ''', NOSKIP, NOFORMAT, COMPRESSION, CHECKSUM, STATS = 10'
            END

         -- Execute the generated backup SQL command
         EXEC(@sqlCommand)


         -- Varify Backup Step
         DECLARE @backupSetId             INT = 1
         DECLARE @mesg                    VARCHAR(512)
         DECLARE @physical_device_name    VARCHAR(1000)

         SELECT @physical_device_name = physical_device_name,
                @backupSetId=ISNULL(a.position, 0)
           FROM msdb.dbo.backupset a join msdb.dbo.backupmediafamily b
            on a.media_set_id = b.media_set_id
         WHERE database_name = @DBNAME AND
               a.backup_set_id = (SELECT MAX(backup_set_id) FROM msdb..backupset WHERE database_name=@DBNAME)

         IF @backupSetId = 0
            BEGIN
               SET @mesg = 'Verify failed. Backup information for database ' + @DBNAME + ' not found.' 
               RAISERROR(@mesg, 16, 1)
            END
         ELSE
            BEGIN
               -- Execute the verify backup SQL command               
               SET @sqlCommand = 'RESTORE VERIFYONLY FROM DISK = ' + @physical_device_name + ' WITH CHECKSUM, FILE = ' + @backupSetId
               EXEC(@sqlCommand)

               IF @@ERROR = 0
                  BEGIN
                  PRINT 'Backup checksum verfication successful'
                  END
               ELSE
                  BEGIN
                  PRINT 'Backup not useable'
               END
            END

         -- Goto the next database
         SELECT @Loop = MIN(ID) FROM @DB_List WHERE ID > @Loop
END