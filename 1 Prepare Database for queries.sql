--Opened city-hex-polygons-8-10.geojson Edge
--Copied all the records and paste in notpad
--Saved the file as city-hex-polygons-8.geojson
--Created n database schema in MSSQL

--Create a json object from the geojson file
Declare @JSON varchar(max)
SELECT @JSON=BulkColumn
FROM OPENROWSET (BULK 'C:\Path to geojson file\city-hex-polygons-8.geojson', SINGLE_CLOB) import

--Select columns from json object
SELECT
	*
into City_Hex_Polygons_8_1
FROM
OPENJSON(@JSON, '$.features')

	WITH (
		[index] nvarchar(300) '$.properties.index',
		[centroid_lat] float '$.properties.centroid_lat',
		[centroid_lon] float '$.properties.centroid_lon',
		[type] nvarchar(300) '$.geometry.type',
		[coorGeo] nvarchar(max) '$.geometry.coordinates' as json
	) 

GO
--Add a spatial column centroid_geo
Alter table City_Hex_Polygons_8_1 add centroid_geo geography
GO
--Add a spatial column polygon_geo
Alter table City_Hex_Polygons_8_1 add polygon_geo geography
GO
--Update coorGeo removing all the brackets from coorGeo
UPDATE  [City_Hex_Polygons_8_1]
set  coorGeo = Replace(Replace(Replace(Replace(Replace(coorGeo,'[' , ''), '],', '*'),',',' '),'*',','),']','')
GO
--Convert coorGeo to spatial polygon table and updating polygon_geo with values
update City_Hex_Polygons_8_1 set polygon_geo = geography::STPolyFromText('POLYGON(('+coorGeo+'))', 4326); 
GO
--Convert centroid_lat and centroid_long to spatial point and updating centroid_geo
update City_Hex_Polygons_8_1 set centroid_geo = geography::Point([centroid_lat], [centroid_lon], 4326)
GO

--Creaing a new table from select just that my data shows in the order I want to
select [index],
	   centroid_lat,
	   centroid_lon,
	   centroid_geo,
	   coorGeo,
	   polygon_geo
into City_Hex_Polygons_8   
from City_Hex_Polygons_8_1
GO
--Change the index column that it is not null
alter table City_Hex_Polygons_8 alter column [index] nvarchar(300) NOT NULL
GO
--Change table and make index column the primary key. 
--This is needed to create spatial index
--Spatial index is needed to make queries running faster
alter table City_Hex_Polygons_8 add primary key ([index])
GO
--Create a spatial index on the polygon_geo
CREATE SPATIAL INDEX SI_City_Hex_Polygons_8 ON City_Hex_Polygons_8(polygon_geo);
GO
--Create a spatial index on centroid_geo
CREATE SPATIAL INDEX SI_City_Hex_Polygons_Point_8  ON City_Hex_Polygons_8(centroid_geo);
GO
Drop table City_Hex_Polygons_8_1

