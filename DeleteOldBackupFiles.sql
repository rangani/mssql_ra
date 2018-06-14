/****** Object: StoredProcedure DeleteOldBackupFiles ******/ 

SET ANSI_NULLS ON
GO 
SET QUOTED_IDENTIFIER ON
GO 

/*=============================================================================
-- Author: Raju Angani
-- Creation Date: 06/09/2018
-- Description: Delete Older Database Backup file for all 3 types (FULL, DIFFERENTIAL, T-Log)

-- BackupType and Location are mandatory parameters.

*** If you skip databaseName (i.e.: Parameter1), the script will perform backup for all user
databases.

-- Parameter1: Backup File Path (i.e.: E:\SQL_DB_BACKUP)
-- Parameter2: Backup File Extension, FULL and DIFF is .BAK, Transaction-log is .TRN
   * Note: .TRN extension was used instead of .LOG to confusion.
-- Parameter3: Back File age, default value is 7 days

***  Stored Procedure Usage
-- Delete FULL and Differential Backup Files older by 1 week
EXEC DeleteOldBackupFiles 'F:\SQL_DB_Backup', 'BAK', 168

-- Delete Transaction log Backup Files older by 1 week
EXEC DeleteOldBackupFiles 'F:\SQL_DB_Backup', 'TRN', 168

---==========================================================================*/

-- DROP PROCEDURE DeleteOldBackupFiles

CREATE PROCEDURE DeleteOldBackupFiles	@path NVARCHAR(256),
										@extension NVARCHAR(10),
										@age_in_hrs INT = 168  -- 7 Days
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @DeleteDate		NVARCHAR(50)
	DECLARE @DeleteDateTime DATETIME

	/* Calculate start datetime to delete the files */
	SET @DeleteDateTime = DateAdd(hh, - @age_in_hrs, GetDate())
	-- PRINT '@DeleteDateTime = ' + CAST(@DeleteDateTime as VARCHAR)

	/* Generate datetime in format 2018-06-10T11:47:05 */
    SET @DeleteDate = (Select Replace(Convert(nvarchar, @DeleteDateTime, 111), '/', '-') + 'T' + Convert(nvarchar, @DeleteDateTime, 108))
	-- PRINT '@DeleteDate = ' + CAST(@DeleteDate as VARCHAR)
	
	/* Delete the .BAK and .TRN files for the @DeleteDate*/
	EXECUTE master.dbo.xp_delete_file 0,
		@path,
		@extension,
		@DeleteDate,
		1

END

--	DeleteOldBackupFiles 'F:\SQL_DB_Backup', 'BAK', 168
--	DeleteOldBackupFiles 'F:\SQL_DB_Backup', 'TRN', 168


