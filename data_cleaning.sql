CREATE DATABASE NetflixDB;

use NetflixDB

--Verifying

SELECT COUNT(*) FROM netflix_raw_data;
SELECT TOP 10 * FROM [dbo].[netflix_raw_data];

--ALWAYS KEEP RAW DATA SAFE
SELECT *
INTO [dbo].[netflix_clean_data]
FROM [dbo].[netflix_raw_data];

--REMOVE DUPLICATES
SELECT show_id, COUNT(*) AS cnt
FROM netflix_clean_data
GROUP BY show_id
HAVING COUNT(*) > 1;

--Delete duplicates (keep 1 record)
WITH cte AS (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY show_id ORDER BY show_id) AS rn
    FROM netflix_clean_data
)
DELETE FROM cte
WHERE rn > 1;


--HANDLE NULL VALUES
--Replace NULL text values
UPDATE netflix_clean_data
SET
    director = ISNULL(director, 'Not Available'),
    cast = ISNULL(cast, 'Not Available'),
    country = ISNULL(country, 'Not Available'),
    rating = ISNULL(rating, 'Not Rated');

--Replace NULL numeric values
UPDATE netflix_clean_data
SET release_year = 0
WHERE release_year IS NULL;


--TRIM & STANDARDIZE TEXT
--🔹 Remove extra spaces
UPDATE netflix_clean_data
SET
    title = LTRIM(RTRIM(title)),
    director = LTRIM(RTRIM(director)),
    country = LTRIM(RTRIM(country)),
    listed_in = LTRIM(RTRIM(listed_in));
--🔹 Standardize case (optional)
UPDATE netflix_clean_data
SET type = UPPER(type);

--CONVERT & CLEAN DATE COLUMN
--🔹 Add proper date column
ALTER TABLE netflix_clean_data
ADD date_added_clean DATE;
--🔹  safely
UPDATE netflix_clean_data
SET date_added_clean = TRY_CONVERT(DATE, date_added);

--SPLIT DURATION COLUMN
--🔹 Add new columns
ALTER TABLE netflix_clean_data
ADD
    duration_value INT,
    duration_type VARCHAR(20);

--🔹 Extract values

UPDATE netflix_clean_data
SET
    duration_value = TRY_CAST(LEFT(duration, CHARINDEX(' ', duration) - 1) AS INT),
    duration_type = SUBSTRING(duration, CHARINDEX(' ', duration) + 1, LEN(duration));

--SPLIT MULTI-VALUE COLUMNS
--🔹 Create genre table
SELECT
    show_id,
    LTRIM(value) AS genre
INTO netflix_genre
FROM netflix_clean_data
CROSS APPLY STRING_SPLIT(listed_in, ',');

--FINAL QUALITY CHECK
SELECT * FROM netflix_clean_data;
SELECT COUNT(*) FROM netflix_clean_data;
