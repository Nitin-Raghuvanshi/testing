GO
ALTER FUNCTION [dbo].[Operation_Shut_Down_Hours](@predecessoractivityid NVARCHAR(255),@projectobjectid int)
RETURNS DECIMAL(10,2)
AS
BEGIN
DECLARE @sum DECIMAL(10,2);
    WITH PredecessorList AS (
        SELECT 
            r.predecessoractivityobjectid AS predecessor_activityid,
            r.predecessoractivityid,
            r.predecessoractivityname,
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
            r2.predecessoractivityobjectid,
            r2.predecessoractivityid,
            r2.predecessoractivityname,
            pl.activityid,
            a.baselineduration,
            a.actualduration,
			a.floatpath,
			a.projectobjectid
        FROM 
            pxrptuser.RELATIONSHIP r2
        INNER JOIN 
            pxrptuser.ACTIVITY a ON r2.predecessoractivityobjectid = a.objectid
        JOIN 
            PredecessorList pl ON r2.successoractivityobjectid = pl.predecessor_activityid
        
			
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
    rn = 1
	   	),

    final AS (
        SELECT DISTINCT p.*,f.floatpathorder FROM PredecessorList p
		inner join floatpath f on p.projectobjectid=f.projectobjectid and p.floatpath=f.floatpath
		
    )

    --SELECT sum(baselineduration) FROM final where floatpath is not null;


    SELECT @sum = SUM(baselineduration) FROM final where floatpath is not null;
	return @sum;
END;


--select a.FloatPath ,  *from pxrptuser.ACTIVITY a where floatpath is not null