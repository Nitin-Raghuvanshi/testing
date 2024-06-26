
GO
ALTER FUNCTION [dbo].[Operation_Startup_Hours](@predecessoractivityid NVARCHAR(255),@projectobjectid int)
RETURNS DECIMAL(10,2)
AS
BEGIN
DECLARE @sum DECIMAL(10,2);
   WITH PredecessorList AS (
        SELECT 
            r.successoractivityobjectid AS successor_activityid,
            r.successoractivityid,
            r.successoractivityname,
            a.id AS activityid,
            a.baselineduration,
            a.actualduration,
			a.floatpath,
			a.projectobjectid
        FROM 
            pxrptuser.RELATIONSHIP r 
        INNER JOIN 
            pxrptuser.ACTIVITY a ON r.predecessoractivityobjectid = a.objectid 
        WHERE 
            r.predecessoractivityobjectid = @predecessoractivityid

        UNION ALL

        SELECT 
            r2.successoractivityobjectid,
            r2.successoractivityid,
            r2.successoractivityname,
            pl.activityid,
            a.baselineduration,
            a.actualduration,
			a.floatpath,
			a.projectobjectid
        FROM 
            pxrptuser.RELATIONSHIP r2
        INNER JOIN 
        pxrptuser.ACTIVITY a ON r2.successoractivityobjectid = a.objectid
        JOIN 
            PredecessorList pl ON r2.predecessoractivityobjectid = pl.successor_activityid
        
		
    ), 
	floatpath as (
	SELECT 
    floatpath,
    floatpathorder,
    projectobjectid
FROM  (
    SELECT 
        a.floatpath,
        a.floatpathorder,
        a.projectobjectid,
        ROW_NUMBER() OVER (PARTITION BY a.projectobjectid ORDER BY a.floatpathorder DESC) AS rn
    FROM 
        pxrptuser.ACTIVITY a
    WHERE 
        a.floatpath IS NOT NULL
     AND a.projectobjectid = @projectobjectid
) RankedActivities
WHERE 
    rn = 1),
	
    final AS (
        SELECT DISTINCT p.*,f.floatpathorder FROM PredecessorList p
		inner join floatpath f on p.projectobjectid=f.projectobjectid and f.floatpath=p.floatpath
		--where floatpath=3 
    )

    SELECT @sum = SUM(baselineduration) FROM final where floatpath is not null;
	return @sum;
END;
