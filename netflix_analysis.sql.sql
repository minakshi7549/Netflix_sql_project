CREATE DATABASE netflix;
USE netflix;

CREATE TABLE netflix_titles (
  show_id VARCHAR(10),
  type VARCHAR(20),
  title VARCHAR(255),
  director TEXT,
  cast TEXT,
  country VARCHAR(255),
  date_added VARCHAR(50),
  release_year INT,
  rating VARCHAR(20),
  duration VARCHAR(50),
  listed_in VARCHAR(255),
  description TEXT
);

SET GLOBAL local_infile = 1;
SHOW VARIABLES LIKE '%local%';
SHOW SESSION VARIABLES LIKE 'local_infile';
SHOW VARIABLES LIKE 'secure_file_priv';
SELECT USER();
SHOW GRANTS FOR CURRENT_USER();


LOAD DATA LOCAL INFILE 'C:/Users/HP/Desktop/IITP/Code/archive/netflix_titles.csv'
INTO TABLE netflix_titles
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

SELECT 
	COUNT(*) AS total_content
FROM netflix_titles

SELECT DISTINCT type FROM netflix_titles

SELECT * FROM netflix_titles;

-- 15 Business Problems & Solutions

-- 1. Count the number of Movies vs TV Shows

SELECT 
	type,
    COUNT(type) AS total_count 
FROM netflix_titles
GROUP BY type;


-- 2. Find the most common rating for movies and TV shows

SELECT 
	type,
    rating
FROM 
(
	SELECT 
		type,
		rating,
		COUNT(*),
		RANK() OVER(PARTITION BY type ORDER BY COUNT(*) DESC) as ranking
	FROM netflix_titles
	GROUP BY 1,2
	ORDER BY 1,3 DESC
	) AS t1
WHERE 
	ranking = 1;
    

-- 3. List all movies released in a specific year (e.g., 2020)

SELECT 
	COUNT(*)
FROM netflix_titles
WHERE 
	type = 'Movie'
    AND 
    release_year = 2020;


-- 4. Find the top 5 countries with the most content on Netflix

SELECT
  TRIM(jt.country) AS country,
  COUNT(*) AS total_content
FROM netflix_titles t
CROSS JOIN JSON_TABLE(
  CONCAT('["', REPLACE(COALESCE(t.country, ''), ',', '","'), '"]'),
  '$[*]' COLUMNS (country VARCHAR(255) PATH '$')
) AS jt
WHERE TRIM(jt.country) <> ''
GROUP BY TRIM(jt.country)
ORDER BY total_content DESC
LIMIT 5;


-- 5. Identify the longest movie

SELECT 
    title,
    duration
FROM netflix_titles
WHERE type = 'Movie'
ORDER BY CAST(SUBSTRING_INDEX(duration, ' ', 1) AS UNSIGNED) DESC
LIMIT 1;

-- 6. Find content added in the last 5 years

SELECT *
FROM netflix_titles
WHERE STR_TO_DATE(date_added, '%M %d, %Y') >= CURDATE() - INTERVAL 5 YEAR;


-- 7. Find all the movies/TV shows by director 'Masahiko Murata'!

SELECT *
FROM netflix_titles
WHERE director LIKE '%Masahiko Murata%' ;

-- 8. List all TV shows with more than 5 seasons

SELECT *
FROM netflix_titles
WHERE type = 'TV Show'
  AND CAST(SUBSTRING_INDEX(duration, ' ', 1) AS UNSIGNED) > 5;


-- 9. Count the number of content items in each genre

SELECT 
    TRIM(jt.genre) AS genre,
    COUNT(*) AS total_content
FROM netflix_titles t
CROSS JOIN JSON_TABLE(
    CONCAT('["', REPLACE(COALESCE(t.listed_in, ''), ',', '","'), '"]'),
    '$[*]' COLUMNS (genre VARCHAR(255) PATH '$')
) AS jt
WHERE TRIM(jt.genre) <> ''
GROUP BY TRIM(jt.genre)
ORDER BY total_content DESC;
	

-- 10.Find each year and the average numbers of content release in India on netflix.
-- return top 5 year with highest avg content release!

SELECT 
    YEAR(STR_TO_DATE(date_added, '%M %d, %Y')) AS release_year,
    COUNT(*) AS total_content,
    ROUND(
        COUNT(*) / (
            SELECT COUNT(*) 
            FROM netflix_titles 
            WHERE country LIKE '%India%'
        ) * 100, 
    2) AS avg_content
FROM netflix_titles
WHERE country LIKE '%India%'
GROUP BY YEAR(STR_TO_DATE(date_added, '%M %d, %Y'))
ORDER BY release_year DESC;


-- 11. List all movies that are documentaries

SELECT *
FROM netflix_titles
WHERE listed_in LIKE '%Documentaries%';


-- 12. Find all content without a director

SELECT *
FROM netflix_titles
WHERE director IS NULL
   OR director = '';

-- 13. Find how many movies actor 'Salman Khan' appeared in last 10 years!

SELECT COUNT(*) AS salman_khan_movie_count
FROM netflix_titles 
WHERE cast LIKE '%Salman Khan%'
AND STR_TO_DATE(date_added, '%M %d, %Y') >= CURDATE() - INTERVAL 10 YEAR;


-- 14. Find the top 10 actors who have appeared in the highest number of movies produced in India.

SELECT 
    TRIM(jt.actor) AS actor,
    COUNT(*) AS movie_count
FROM netflix_titles t
CROSS JOIN JSON_TABLE(
    CONCAT('["', REPLACE(COALESCE(t.cast, ''), ',', '","'), '"]'),
    '$[*]' COLUMNS (actor VARCHAR(255) PATH '$')
) AS jt
WHERE t.type = 'Movie'
  AND t.country LIKE '%India%'
  AND TRIM(jt.actor) <> ''
GROUP BY TRIM(jt.actor)
ORDER BY movie_count DESC
LIMIT 10;

-- 15.
-- Categorize the content based on the presence of the keywords 'kill' and 'violence' in 
-- the description field. Label content containing these keywords as 'Bad' and all other 
-- content as 'Good'. Count how many items fall into each category.
-- */

SELECT 
    CASE 
        WHEN LOWER(description) LIKE '%kill%' 
          OR LOWER(description) LIKE '%violence%' 
        THEN 'Bad'
        ELSE 'Good'
    END AS category,
    COUNT(*) AS total_items
FROM netflix_titles
GROUP BY category;

