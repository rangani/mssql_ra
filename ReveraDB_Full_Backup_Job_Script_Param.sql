USE [msdb]
GO

SET ANSI_NULLS ON
GO 
SET QUOTED_IDENTIFIER ON
GO 

/*=============================================================================
-- Author: Raju Angani
-- Creation Date: 06/09/2018
-- Description: ReveraDB Full Backup Script


*** Drop Full Backup Job

*-- Drop Job Start --*

	DECLARE @jobName VARCHAR(100) = N'ReveraDB_Full_Backup'
	DECLARE @jobId binary(16)

	SELECT @jobId = job_id FROM msdb.dbo.sysjobs WHERE (name = @jobName)
	--PRINT @jobId

	IF (@jobId IS NOT NULL)
	BEGIN
		EXEC msdb.dbo.sp_delete_job @jobId
	END

*-- Drop Job End --*
---==========================================================================*/


/****** Script ReveraDB_Full_Backup  ******/
BEGIN TRANSACTION

DECLARE @ReturnCode		INT
DECLARE @backupPath		VARCHAR(100) = 'E:\SQL_DB_Backup\'
DECLARE @dbName			VARCHAR(50) = 'ReveraDB'
DECLARE @TypeOfBackup	VARCHAR(1) = 'F'

DECLARE @SPOfStep1		VARCHAR(MAX)
DECLARE @SPOfStep2		VARCHAR(MAX)

DECLARE @NoOfDays		INT = 168 -- 7 days
DECLARE @DFExt			VARCHAR(3) = 'BAK'
DECLARE @TLogExt		VARCHAR(3) = 'TRN'


SET @SPOfStep1 = 'EXEC Customize_Database_Backups @backupLocation=''' + @backupPath + ''', @databaseName=''' + @dbName + ''', @backupType=''' + @TypeOfBackup + ''''
--PRINT @SPOfStep1

SET @SPOfStep2 = 'EXEC DeleteOldBackupFiles @path=''' + @backupPath + ''', @extension=''' + @DFExt + ''', @age_in_hrs= ' + CAST(@NoOfDays AS VARCHAR) + ';' 
				 + CHAR(13) + 
                 'EXEC DeleteOldBackupFiles  @path=''' + @backupPath + ''', @extension=''' + @TLogExt + ''', @age_in_hrs=' +  CAST(@NoOfDays AS VARCHAR) + ';' 
--PRINT @SPOfStep2

SELECT @ReturnCode = 0

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'ReveraDB_Full_Backup', 
		@enabled=1, 
		@notify_level_eventlog=3, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=N'sa', @job_id = @jobId OUTPUT

IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

/****** Step_1 Full Database Backup ******/

EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Full_Backup_Step', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		--@on_success_action=4, 
		--@on_success_step_id=2, 
		--@on_fail_action=2, 
		--@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=@SPOfStep1, 
		@database_name=N'master', 
		@flags=0

IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

/****** Step_2 Delete Older Database Backup File for Full, Diff and TLog ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Delete_Older_Full_Diff_And_TLog_Backup_Files', 
		@step_id=2, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=@SPOfStep2, 
		@database_name=@dbName, 
		@flags=0

IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1

IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

/****** Schedule of the FULL Database Backup Job  ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'Full_Backup_Scehdule_Sat_2045', 
		@enabled=1, 
		@freq_type=8, 
		@freq_interval=64, 
		@freq_subday_type=1, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=1, 
		@active_start_date=20180604, 
		@active_end_date=99991231, 
		@active_start_time=224500, 
		@active_end_time=235959

IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = @@SERVERNAME

IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:

GO
