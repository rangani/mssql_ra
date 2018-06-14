USE [msdb]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/*=============================================================================
-- Author: Raju Angani
-- Creation Date: 06/10/2018
-- Description: ReveraDB Differential Backup Script


*** Drop Differential database backup Job

*-- Drop Job Start --*

	DECLARE @jobName VARCHAR(100) = N'ReveraDB_Diff_Backup'
	DECLARE @jobId binary(16)

	SELECT @jobId = job_id FROM msdb.dbo.sysjobs WHERE (name = @jobName)
	--PRINT @jobId

	IF (@jobId IS NOT NULL)
	BEGIN
		EXEC msdb.dbo.sp_delete_job @jobId
	END

*-- Drop Job End --*

---==========================================================================*/



/****** Script ReveraDB Differential Backup  ******/
BEGIN TRANSACTION

DECLARE @ReturnCode		INT
DECLARE @backupPath		VARCHAR(100) = 'E:\SQL_DB_Backup\'
DECLARE @dbName			VARCHAR(50) = 'ReveraDB'
DECLARE @TypeOfBackup	VARCHAR(1) = 'D'

DECLARE @SPOfStep1		VARCHAR(MAX)

SET @SPOfStep1 = 'EXEC Customize_Database_Backups @backupLocation=''' + @backupPath + ''', @databaseName=''' + @dbName + ''', @backupType=''' + @TypeOfBackup + ''''
--PRINT @SPOfStep1

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'ReveraDB_Diff_Backup', 
		@enabled=1, 
		@notify_level_eventlog=3, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=N'sa', @job_id = @jobId OUTPUT

IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

/****** Step_1 Differential Database Backup ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'ReveraDB_Diff_Backup_Step', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		--@on_success_action=1, 
		--@on_success_step_id=0, 
		--@on_fail_action=2, 
		--@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=@SPOfStep1, 
		@database_name=N'master', 
		@flags=0

IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1

IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

/****** Schedule of the Differential Database Backup Job  ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'ReveraDB_Diff_Backup_Scehdule_Mon_Thru_2130', 
		@enabled=1, 
		@freq_type=8, 
		@freq_interval=19, 
		@freq_subday_type=1, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=1, 
		@active_start_date=20180604, 
		@active_end_date=99991231, 
		@active_start_time=213000, 
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
