WITH    Paths
          AS ( /*anchor*/ SELECT    CAST(0 AS INT) AS Index1, /*Seed start for every row to zero*/
                                    CHARINDEX('\', physical_name) AS Index2, /*seed location of first "\" for this row*/
                                    physical_name AS FullPath/*,
                        LEFT(physical_name, CHARINDEX('\', physical_name))*/
                          FROM      sys.master_files
               UNION ALL
               /*recursive*/
               SELECT   Index2 + 1, /*start after previous find*/
                        CHARINDEX('\', FullPath, Index2 + 1), /* index of next "\" after previous find */
                        FullPath
               FROM     Paths
               WHERE    Index2 > 0 /*there must be a "\" left in the string or the thing will blow up */
             ) ,
        SubPaths
          AS ( SELECT  DISTINCT
                        UPPER(LEFT(FullPath, Index2)) AS SubPath
               FROM     Paths
             )
    SELECT  SubPaths.SubPath,
            CAST(SUM(SIZE) * 8.00 / 1024.00 / 1024.00 AS NUMERIC(18, 2)) AS GB,
	        SERVERPROPERTY('ComputerNamePhysicalNetBIOS') AS HostOS
    FROM    SubPaths
            JOIN sys.master_files mf ON SubPaths.SubPath = LEFT(mf.physical_name, LEN(subpaths.subpath))
    WHERE   LEN(SubPath) > 0
    GROUP BY subpaths.subpath
    ORDER BY SubPath
