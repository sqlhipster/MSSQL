
SELECT 
    GETDATE() AS collection_time, 
    d.name AS [Database], 
    f.physical_name AS [File], 
    (fs.num_of_bytes_read / 1024.0 / 1024.0) [Total MB Read], 
    (fs.num_of_bytes_written / 1024.0 / 1024.0) AS [Total MB Written], 
    (fs.num_of_reads + fs.num_of_writes) AS [Total I/O Count], 
    fs.io_stall AS [Total I/O Wait Time (ms)], 
    fs.size_on_disk_bytes / 1024 / 1024 AS [Size (MB)]
INTO #past_coll_time
FROM sys.dm_io_virtual_file_stats(default, default) AS fs
INNER JOIN sys.master_files f ON fs.database_id = f.database_id AND fs.file_id = f.file_id
INNER JOIN sys.databases d ON d.database_id = fs.database_id; 

WAITFOR DELAY '00:00:10';


SELECT 
    GETDATE() AS collection_time, 
    d.name AS [Database], 
    f.physical_name AS [File], 
    (fs.num_of_bytes_read / 1024.0 / 1024.0) [Total MB Read], 
    (fs.num_of_bytes_written / 1024.0 / 1024.0) AS [Total MB Written], 
    (fs.num_of_reads + fs.num_of_writes) AS [Total I/O Count], 
    fs.io_stall AS [Total I/O Wait Time (ms)], 
    fs.size_on_disk_bytes / 1024 / 1024 AS [Size (MB)]
INTO #curr_coll_time
FROM sys.dm_io_virtual_file_stats(default, default) AS fs
INNER JOIN sys.master_files f ON fs.database_id = f.database_id AND fs.file_id = f.file_id
INNER JOIN sys.databases d ON d.database_id = fs.database_id; 


SELECT 
    cur.[Database], 
    cur.[File] AS [File Name], 
    CONVERT (numeric(28,1), (cur.[Total MB Read] - prev.[Total MB Read]) * 1000 /DATEDIFF (millisecond, prev.collection_time, cur.collection_time)) AS [MB/sec Read], 
    CONVERT (numeric(28,1), (cur.[Total MB Written] - prev.[Total MB Written]) * 1000 / DATEDIFF (millisecond, prev.collection_time, cur.collection_time)) AS [MB/sec Written], 
	CONVERT (numeric(28,1), (cur.[Total I/O Wait Time (ms)] - prev.[Total I/O Wait Time (ms)]) ) AS [Total I/O Stall (ms)],
    -- protect from div-by-zero
    CASE 
        WHEN (cur.[Total I/O Count] - prev.[Total I/O Count]) = 0 THEN 0
        ELSE
            (cur.[Total I/O Wait Time (ms)] - prev.[Total I/O Wait Time (ms)]) 
                / (cur.[Total I/O Count] - prev.[Total I/O Count])
    END AS [Response Time (ms per transaction)]
INTO #response_time_cal
FROM #curr_coll_time AS cur
INNER JOIN #past_coll_time AS prev ON prev.[Database] = cur.[Database] AND prev.[File] = cur.[File];


SELECT *
FROM #response_time_cal
WHERE [Response Time (ms per transaction)] > 0;

DROP table #response_time_cal;
DROP TABLE #curr_coll_time;
DROP TABLE #past_coll_time;


