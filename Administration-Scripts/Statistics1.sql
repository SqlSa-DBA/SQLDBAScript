SELECT
	sch.name + '.' + so.name AS "Table",
    ss.name AS "Statistic Name",
	sp.last_updated AS "Stats Last Updated", 
    CASE
            WHEN ss.auto_Created = 0 AND ss.user_created = 0 THEN 'Index Statistic'
            WHEN ss.auto_created = 0 AND ss.user_created = 1 THEN 'User Created'
            WHEN ss.auto_created = 1 AND ss.user_created = 0 THEN 'Auto Created'
            WHEN ss.AUTO_created = 1 AND ss.user_created = 1 THEN 'Not Possible'
    END AS "Statistic Type",
     
    sp.rows AS "Rows", 
    sp.rows_sampled AS "Rows Sampled", 
    sp.unfiltered_rows AS "nfiltered Rows",
    sp.modification_counter AS "Row Modifications",
    sp.steps AS "Histogram Steps",
    CASE
            WHEN ss.has_filter = 1 THEN 'Filtered Index'
            WHEN ss.has_filter = 0 THEN 'No Filter'
    END AS 'Filtered?', 
    CASE
            WHEN ss.filter_definition IS NULL THEN ''
            WHEN ss.filter_definition IS NOT NULL THEN ss.filter_definition
    END AS "Filter Definition"

FROM sys.stats ss
JOIN sys.objects so ON ss.object_id = so.object_id
JOIN sys.schemas sch ON so.schema_id = sch.schema_id
OUTER APPLY sys.dm_db_stats_properties(so.object_id, ss.stats_id) AS sp 
WHERE so.TYPE = 'U' AND sp.last_updated < getdate() - 1
ORDER BY sp.modification_counter DESC, sp.last_updated DESC;