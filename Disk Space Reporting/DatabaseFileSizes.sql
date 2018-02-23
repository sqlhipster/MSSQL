select @@servername AS 'Server_Name'
		, DB_NAME(database_id) AS 'Database_Name'
		, name AS 'Logical_Name'
		, physical_name AS 'File_Name'
		, type_desc as 'File_Type'
		, (convert(bigint, size) * 8) / 1024 AS 'Size_In_MB'
		, GETDATE() AS 'Time_Stamp'
from sys.master_files


