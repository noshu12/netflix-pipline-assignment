
use NetflixDB

/*1  for each director count the no of movies and tv shows created by them in separate columns 
for directors who have created tv shows and movies both */

SELECT
    director,
    SUM(CASE WHEN type = 'MOVIE' THEN 1 ELSE 0 END) AS movie_count,
    SUM(CASE WHEN type = 'TV SHOW' THEN 1 ELSE 0 END) AS tv_show_count
FROM netflix_clean_data
WHERE director <> 'Not Available'
GROUP BY director
HAVING
    SUM(CASE WHEN type = 'MOVIE' THEN 1 ELSE 0 END) > 0
    AND
    SUM(CASE WHEN type = 'TV SHOW' THEN 1 ELSE 0 END) > 0
ORDER BY director;



--------------------------------------------------------------------------------------------------------------------
--2 which country has highest number of comedy movies --2 which country has highest number of comedy movies 

SELECT TOP 1
    country,
    COUNT(*) AS comedy_movie_count
FROM netflix_clean_data n
JOIN netflix_genre g
    ON n.show_id = g.show_id
WHERE
    g.genre = 'Comedies'
    AND n.type = 'MOVIE'
    AND country <> 'Not Available'
GROUP BY country
ORDER BY comedy_movie_count DESC;


--------------------------------------------------------------------------------------------------------------------
--3 for each year (as per date added to netflix), which director has maximum number of movies released

WITH director_year_movies AS (
    SELECT
        YEAR(date_added) AS year_added,
        director,
        COUNT(*) AS movie_count
    FROM netflix_clean_data
    WHERE
        type = 'MOVIE'
        AND director <> 'Not Available'
        AND date_added IS NOT NULL
    GROUP BY YEAR(date_added), director
),
ranked_directors AS (
    SELECT *,
           RANK() OVER (PARTITION BY year_added ORDER BY movie_count DESC) AS rnk
    FROM director_year_movies
)
SELECT
    year_added,
    director,
    movie_count
FROM ranked_directors
WHERE rnk = 1
ORDER BY year_added;



--------------------------------------------------------------------------------------------------------------------
--4 what is average duration of movies in each genre

SELECT
    g.genre,
    AVG(n.duration_value * 1.0) AS avg_movie_duration_minutes
FROM netflix_clean_data n
JOIN netflix_genre g
    ON n.show_id = g.show_id
WHERE
    n.type = 'MOVIE'
    AND n.duration_value IS NOT NULL
GROUP BY g.genre
ORDER BY avg_movie_duration_minutes DESC;



--------------------------------------------------------------------------------------------------------------------
--5  find the list of directors who have created horror and comedy movies both.
-- display director names along with number of comedy and horror movies directed by them 

WITH director_genre_movies AS (
    SELECT
        n.director,
        g.genre,
        COUNT(*) AS movie_count
    FROM netflix_clean_data n
    JOIN netflix_genre g
        ON n.show_id = g.show_id
    WHERE
        n.type = 'MOVIE'
        AND n.director <> 'Not Available'
        AND g.genre IN ('Horror Movies', 'Comedies')
    GROUP BY n.director, g.genre
)
SELECT
    director,
    SUM(CASE WHEN genre = 'Comedies' THEN movie_count ELSE 0 END) AS comedy_movies,
    SUM(CASE WHEN genre = 'Horror Movies' THEN movie_count ELSE 0 END) AS horror_movies
FROM director_genre_movies
GROUP BY director
HAVING
    SUM(CASE WHEN genre = 'Comedies' THEN movie_count ELSE 0 END) > 0
    AND
    SUM(CASE WHEN genre = 'Horror Movies' THEN movie_count ELSE 0 END) > 0
ORDER BY director;
