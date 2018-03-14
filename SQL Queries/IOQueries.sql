SELECT  COUNT(io_pending)
FROM    sys.dm_io_pending_io_requests
WHERE   io_type = 'disk';
 --and io_pending_ms_ticks > 10

 SELECT  *
FROM    sys.dm_io_pending_io_requests;

select database_id, 
       file_id, 
       io_stall,
       io_pending_ms_ticks,
       scheduler_address 
from sys.dm_io_virtual_file_stats(NULL, NULL) iovfs,
     sys.dm_io_pending_io_requests as iopior
where iovfs.file_handle = iopior.io_handle;




SELECT  r.session_id ,
        s.login_name ,
        s.program_name ,
        r.start_time ,
        r.status ,
        r.command ,
        r.wait_type ,
        r.wait_time ,
        r.last_wait_type ,
        r.logical_reads ,
        ( r.logical_reads * 8192 ) AS 'KB Read' ,
        r.writes ,
        ( r.writes * 8192 ) AS 'KB Written' ,
        t.[text]
FROM    sys.dm_exec_requests r
        CROSS APPLY sys.dm_exec_sql_text(sql_handle) t
        INNER JOIN sys.dm_exec_sessions s ON r.session_id = s.session_id
WHERE   s.is_user_process = 1
        AND ( r.wait_type LIKE 'PAGEIOLATCH%'
              OR r.last_wait_type LIKE 'PAGEIOLATCH%'
            );
