USE MSDB;
SELECT  sj.name JobName,
        sj.description JobDescription,
        sj.enabled JobEnabled,
        sjh.run_status RunStatus,
        CASE sjh.run_status
          WHEN 0 THEN 'Failed'
          WHEN 1 THEN 'Succeeded'
          WHEN 2 THEN 'Retry'
          WHEN 3 THEN 'Canceled'
        END RunStatus_Descr,
        sjh.run_duration/10000 * 3600+sjh.run_duration/100%100 * 60+sjh.run_duration%100 DurationSeconds,
        DATEADD(ss, sjh.run_time/10000 * 3600+sjh.run_time/100%100 * 60+sjh.run_time%100, CONVERT(DATETIME, CAST(sjh.run_date AS VARCHAR(10))))AS RunDateTime,
        DATEADD(ss, (sjh.run_duration/10000 * 3600+sjh.run_duration/100%100 * 60+sjh.run_duration%100), DATEADD(ss, sjh.run_time/10000 * 3600+sjh.run_time/100%100 * 60+sjh.run_time%100, CONVERT(DATETIME, CAST(sjh.run_date AS VARCHAR(10))))) AS EndDateTime
FROM    msdb.dbo.sysjobs sj
        JOIN msdb.dbo.sysjobhistory sjh ON sj.job_id = sjh.job_id
WHERE   sjh.step_id = 0
        AND DATEADD(ss, sjh.run_time/10000 * 3600+sjh.run_time/100%100 * 60+sjh.run_time%100, CONVERT(DATETIME, CAST(sjh.run_date AS VARCHAR(10)))) >= DATEADD(hh, -25, GETDATE())
        AND sj.name <> 'DBA.High Severity Error Filter'
  --      AND DATEADD(ss, (sjh.run_duration/10000 * 3600+sjh.run_duration/100%100 * 60+sjh.run_duration%100), dbo.udf_Convert_ANSI_Date(sjh.run_date, sjh.run_time)) BETWEEN '7/1/2011 07:30:00 AM' AND '07/01/2011 08:30:00 AM'
ORDER BY DATEADD(ss, sjh.run_time/10000 * 3600+sjh.run_time/100%100 * 60+sjh.run_time%100, CONVERT(DATETIME, CAST(sjh.run_date AS VARCHAR(10)))) DESC
/*
sp_helpindex sysjobhistory

SELECT * FROM sysjobs


EXEC usp_showjobs

sp_helptext usp_showjobs

SELECT msdb.dbo.udf_Convert_ANSI_Date('20110513', '200001')

SELECT TOP 100 * FROM sysjobhistory
WHERE step_id = 0

SELECT COUNT(*) FROM msdb.dbo.sysjobhistory

most recent execution failed - red
failure within 24 HOURS - near READ
failure within one week red green?

sp_helptext udf_Convert_ANSI_Date

SELECT CONVERT(DATETIME, RTRIM(run_date)+' ' +RTRIM(run_time)), run_date
FROM sysjobhistory

SELECT run_duration/10000 * 3600+run_duration/100%100 * 60+run_duration%100, run_duration
FROM sysjobhistory
ORDER BY run_date desc

*/