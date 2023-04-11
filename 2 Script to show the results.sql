--I imported the csv SR file into the database using the wizard
--This query join the SR and City_Hex_Polygons_8
--In the query below I store the results in a tempory table #Temp_City_Hex_Polygons_8
--This query took about 1 min 14 seconds to execute on my pc.
--The spatial index on City_Hex_Polygons_8 made a huge differance speeding up the query
select S.notification_number
      ,S.reference_number
      ,S.creation_timestamp
      ,S.completion_timestamp
      ,S.directorate
      ,S.department
      ,S.branch
      ,S.section
      ,S.code_group
      ,S.code
      ,S.cause_code_group
      ,S.cause_code
      ,S.official_suburb
      ,S.latitude
      ,S.longitude
	  ,CASE WHEN HP.[index] IS Null then CAST(0 as nvarchar) else HP.[index] end h3_level8_index
	  into #Temp_City_Hex_Polygons_8
	  from (
SELECT column1
      ,notification_number
      ,reference_number
      ,creation_timestamp
      ,completion_timestamp
      ,directorate
      ,department
      ,branch
      ,section
      ,code_group
      ,code
      ,cause_code_group
      ,cause_code
      ,official_suburb
      ,COALESCE(CAST([latitude] as float), 0) latitude
      ,COALESCE(CAST([longitude] as float), 0) longitude
	  ,CASE WHEN latitude IS NOT Null and  longitude is not null then geography::Point([latitude], [longitude], 4326) end geom
  FROM dbo.SR) S
  left join City_Hex_Polygons_8 HP WITH(INDEX(SI_City_Hex_Polygons_8)) on S.[GEOM].STIntersects(HP.polygon_geo) = 1
  --Show all the data from #Temp_City_Hex_Polygons_8
  select * from #Temp_City_Hex_Polygons_8 order by notification_number

  --Show the total of records that could not link up
  select count(*) 'Total records failed to join' from #Temp_City_Hex_Polygons_8 where h3_level8_index  = '0'
  --Drop the tempory table
  drop table #Temp_City_Hex_Polygons_8
