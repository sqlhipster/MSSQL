
USE [DBA]
GO
/****** Object:  Table [dbo].[blocking]    Script Date: 02/25/2013 11:46:53 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[blocking](
	[tstamp] [datetime] NOT NULL,
	[spid] [int] NULL,
	[blocked] [int] NULL,
	[waittype] [varchar](max) NULL,
	[waittime] [bigint] NULL,
	[physical_io] [bigint] NULL,
	[cpu_in_seconds] [bigint] NULL,
	[memusage] [bigint] NULL,
	[name] [nvarchar](max) NOT NULL,
	[open_tran] [tinyint] NULL,
	[status] [varchar](max) NULL,
	[hostname] [varchar](max) NULL,
	[program_name] [varchar](max) NULL,
	[cmd] [varchar](max) NULL,
	[nt_domain] [varchar](max) NULL,
	[nt_username] [varchar](max) NULL,
	[loginame] [varchar](max) NULL,
	[EventType] [varchar](max) NULL,
	[Parameters] [varchar](max) NULL,
	[EventInfo] [varchar](max) NULL,
	[text] [text] NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
SET ANSI_PADDING OFF


USE [DBA]
GO
/****** Object:  Table [dbo].[Daily_Health_Report_Archive]    Script Date: 02/25/2013 11:47:04 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Daily_Health_Report_Archive](
	[ServerName] [sql_variant] NULL,
	[DBName] [sysname] NOT NULL,
	[RecoveryModel] [varchar](255) NULL,
	[IsAutoClose] [varchar](255) NULL,
	[IsAutoShrink] [varchar](255) NULL,
	[LastFullBackup] [datetime] NOT NULL,
	[LastTranBackup] [datetime] NOT NULL,
	[DataSize] [float] NULL,
	[LogSize] [float] NULL,
	[LastSuccessfulCheckDB] [datetime] NULL,
	[VLFCount] [int] NOT NULL,
	[DBState] [nvarchar](60) NULL,
	[IsReadOnly] [bit] NULL,
	[SnapOfDB] [sysname] NULL,
	[Deadlock_Count] [int] NOT NULL,
	[Block_Count] [int] NOT NULL,
	[DateRun] [datetime] NOT NULL DEFAULT (getdate())
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF


USE [DBA]
GO
/****** Object:  Table [dbo].[DailyHealthReport_Overrides]    Script Date: 02/25/2013 11:47:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[DailyHealthReport_Overrides](
	[DatabaseName] [nvarchar](100) NOT NULL,
	[LastFullBackupThresholdDays] [int] NOT NULL,
	[LastTransBackup_Threshold_Hours] [int] NOT NULL,
	[LastSuccessfulCheckDB_Threshold_Days] [int] NOT NULL,
	[VLF_Threshold_Yellow] [int] NOT NULL,
	[AutoClose_Ignore] [bit] NOT NULL,
	[AutoShrink_Ignore] [bit] NOT NULL,
	[State_Ignore] [bit] NOT NULL,
	[Deadlock_Threshold_Count] [int] NOT NULL,
	[Block_Threshold_Count] [int] NOT NULL,
	[VLF_Threshold_Orange] [int] NOT NULL
) ON [PRIMARY]



USE [DBA]
GO
/****** Object:  Table [dbo].[Deadlock_Log]    Script Date: 02/25/2013 11:47:24 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Deadlock_Log](
	[DL_ID] [int] IDENTITY(1,1) NOT NULL,
	[Database] [nvarchar](200) NOT NULL,
	[Server] [nvarchar](200) NOT NULL,
	[Date] [int] NOT NULL,
	[Time] [int] NOT NULL,
	[Severity] [int] NOT NULL,
	[Error] [int] NOT NULL,
	[Message] [nvarchar](3000) NOT NULL
) ON [PRIMARY]


