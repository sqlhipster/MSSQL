select database_id, db_name(database_id), name as 'Logical_Name', Physical_Name, 
	(CAST(size AS NUMERIC(18, 4)) * 8 / 1024 / 1024) as Gig
from sys.master_files
