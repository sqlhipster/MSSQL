select EntryTimeStamp, ServerName, Notification_Code, ExecutionPath, JobPackageName, TaskName, ErrorMessage, Note, *
  from [PROCESSCONTROL].[dbo].[ProcessStatusLog]  where 
       --EntryTimeStamp > '2018-01-23 10:00:00'  --and EntryTimeStamp < '2017-05-16 00:00:00'
       EntryTimeStamp > '2018-01-13 00:00:00'  
       --AND  
       --Cast(EntryTimeStamp as date) = cast(@date as date)
       --and Notification_Code like 'Block82%'
       --and 
       --ServerName like '%PROD16%'--in ('LVFR1') --, 'LVEDWDEV1\EDW2')
       --and EventName like ('%OnError%') 
       --AND 
       --JobPackageName like '%RestoreTarget_Serve%_LVEDWPROD16%' --AUTO EDW Sequence '
       --and DBName = 'BANK_EDW'
       --and ExecutionPath like 'AUTO_EDW%'
       --AND EventName = 'OnPostExec'
       --and 
       --JobPackageName LIKE 'STAGE[_]MNT[_]RESTORES[_]FROM[_]DH%' -- '%3[_][_]CSC[_]CMSI[_]ExecStoredProdList%'--= 'Kick off QA16 BANK_EDW ' --'BANK_EDW Sequence'
       --and Note = '[LVRISKSQL16].[PROD].[dbo].[populate_data_Accounts]'
       --ID = 41731
       --and 
       --Notification_Code like 'STAGE[_]MNT[_]RESTORES[_]FROM[_]DH%' 
       --errormessage like '%DTS_E_PROCESSINPUTFAILED%'
       --and errormessage like '%Connection[r-w]%'
       and Notification_Code like '%Fundtech_to_Fiserv%'
order by --JobPackageName, 1 DESC
      2, 4, 1 desc
