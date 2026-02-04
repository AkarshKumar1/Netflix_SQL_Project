CREATE DATABASE NETFLIX;
USE NETFLIX;
-- Drop the existing table to start fresh
DROP TABLE IF EXISTS netflix;

CREATE TABLE netflix (
    show_id varchar(10) PRIMARY KEY,
    type varchar(10),
    title varchar(255),
    director varchar(255),
    cast TEXT,              -- Changed to TEXT for long cast lists
    country varchar(255),
    date_added varchar(50),
    release_year INT,
    rating varchar(15),
    duration varchar(20),
    listed_in TEXT,         -- Changed to TEXT for long genre lists
    description TEXT        -- Changed to TEXT for long summaries
);

-- Now run the import command
LOAD DATA LOCAL INFILE 'C:/Users/akars/OneDrive/Desktop/netflix_titles.csv' 
INTO TABLE netflix 
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"' 
LINES TERMINATED BY '\n' 
IGNORE 1 ROWS;

select count(*) as total_content from netflix;

select distinct type from netflix;

-- 15 Business Problems

-- 1. Count the Number of Movies vs TV Shows

select 
   type,
   count(*)  as total_content 
   from netflix 
   group by type ;

-- 2. Find the Most Common Rating for Movies and TV Shows

select 
   type, 
   rating
   from(
       select 
           type,
           rating,
           count(*),
		   rank() over(partition by type order by count(*) desc) as ranking
           from netflix
           group by 1, 2
) as t1
   where ranking = 1;

-- 3. List All Movies Released in a Specific Year (e.g., 2020)

SELECT * from netflix
     where
        TYPE = 'Movie'  -- "we can use type to determine the type of the content between movies and tv-shows"
		AND                        -- "we use logic operator here to check both condition before selecting the output"
        RELEASE_YEAR = 2020;
   
-- 4. Find the Top 5 Countries with the Most Content on Netflix

WITH RECURSIVE cte AS (                     -- WITH RECURSIVE is used to create a CTE that can repeatedly call itself.
     SELECT Show_id,                        -- TRIM() removes leading and trailing spaces from a string.
        TRIM(SUBSTRING_INDEX(country, ',', 1)) AS country,    -- SUBSTRING_INDEX() extracts part of a string before a specified delimiter.
        SUBSTRING(country, LENGTH(SUBSTRING_INDEX(country, ',', 1))+ 2) AS rest   -- SUBSTRING() extracts a portion of a string starting from a given position.
     FROM netflix
        WHERE                                -- LENGTH() returns the number of characters in a string.
           country IS NOT NULL
           
     UNION ALL                                -- UNION ALL combines the base query with the recursive query results.
     
     SELECT show_id,
          TRIM(SUBSTRING_INDEX(rest, ',', 1)),
          SUBSTRING(rest, LENGTH(SUBSTRING_INDEX(rest, ',', 1)) + 2)
     FROM cte 
     WHERE rest <> ''                        -- WHERE rest <> '' stops recursion when no values are left to split.
)    
SELECT country, COUNT(*) AS total_content    -- COUNT(*) returns the total number of rows in each group.
FROM cte 
GROUP BY country;                            -- GROUP BY is used to group rows with the same country.
SELECT 
    country,
    COUNT(*) AS total_content
FROM netflix
GROUP BY country
ORDER BY total_content DESC
LIMIT 5;
                                            
         
-- 5. Identify the Longest Movie

 SELECT
    title,
    type,
    duration
 FROM netflix
 WHERE type = 'Movie'
 AND CAST(SUBSTRING_INDEX(duration, ' ', 1) AS UNSIGNED) = (          -- CAST() converts a string value into a numeric value.
    SELECT MAX(CAST(SUBSTRING_INDEX(duration, ' ', 1) AS UNSIGNED))  -- MAX() returns the highest value from a column.
    FROM netflix                                         -- SUBSTRING_INDEX() extracts numeric duration from the duration column.
    WHERE type = 'Movie'
);

-- 6. Find Content Added in the Last 5 Years

SELECT *
    FROM netflix
    WHERE 
        STR_TO_DATE(date_added, '%M %d, %Y') >= CURDATE() - INTERVAL 5 YEAR;

-- 7. Find All Movies/TV Shows by Director 'Rajiv Chilaka'

SELECT *
      FROM netflix 
      WHERE
		 type in ('Movie', 'TV Show')
         AND
         director = 'Rajiv Chilaka';
         
-- 8. List All TV Shows with More Than 5 Seasons

SELECT * 
     FROM netflix
     WHERE 
        type = 'TV Show'
        AND 
        duration > '5 Seasons';

-- 9. Count the Number of Content Items in Each Genre


SELECT DISTINCT listed_in FROM netflix;

WITH RECURSIVE cte AS (                     -- WITH RECURSIVE is used to create a CTE that can repeatedly call itself.
     SELECT Show_id,                        -- TRIM() removes leading and trailing spaces from a string.
        TRIM(SUBSTRING_INDEX(listed_in, ',', 1)) AS genre,    -- SUBSTRING_INDEX() extracts part of a string before a specified delimiter.
        SUBSTRING(listed_in, 
             LENGTH(SUBSTRING_INDEX(listed_in, ',', 1))+ 2) AS rest   -- SUBSTRING() extracts a portion of a string starting from a given position.
     FROM netflix
        WHERE                                -- LENGTH() returns the number of characters in a string.
           listed_in IS NOT NULL
           
     UNION ALL                                -- UNION ALL combines the base query with the recursive query results.
     
     SELECT show_id,
          TRIM(SUBSTRING_INDEX(rest, ',', 1)),
          SUBSTRING(rest, LENGTH(SUBSTRING_INDEX(rest, ',', 1)) + 2)
     FROM cte 
     WHERE rest <> ''                        -- WHERE rest <> '' stops recursion when no values are left to split.
)    
SELECT 
     genre, 
     COUNT(*) AS total_content    -- COUNT(*) returns the total number of rows in each group.
FROM cte 
GROUP BY genre;                            -- GROUP BY is used to group rows with the same genre.

-- 10.Find each year and the average numbers of content release in India on netflix.

SELECT 
	year,
    total_content,
   AVG(total_content) OVER() AS avg_content_per_year         -- AVG() OVER() computes the average without grouping rows.
FROM(   
  SELECT
      EXTRACT(YEAR FROM STR_TO_DATE(date_added, '%M %d, %Y')) AS year,   -- EXTRACT() retrieves the year from the date.
      count(*) AS total_content                                      -- STR_TO_DATE() converts string date into DATE format.
      FROM netflix
	  WHERE 
         country LIKE '%INDIA%'
         GROUP BY year
) t                                   -- t is a table alias used to reference the result of the subquery.
ORDER BY year;

-- 11. List All Movies that are Documentaries

SELECT
     title,
     type
     FROM netflix
     WHERE 
        listed_in = 'Documentaries';

-- 12. Find All Content Without a Director

SELECT * 
    FROM netflix
    WHERE 
       director = '' ;

-- 13. Find How Many Movies Actor 'Salman Khan' Appeared in the Last 10 Years

SELECT *
     FROM netflix
     WHERE
		cast LIKE '%Salman Khan%'
        AND
        release_year > EXTRACT(YEAR FROM CURDATE()) - 10;

-- 14. Find the Top 10 Actors Who Have Appeared in the Highest Number of Movies Produced in India

WITH RECURSIVE cte AS (                     -- WITH RECURSIVE is used to create a CTE that can repeatedly call itself.
     SELECT Show_id,                        -- TRIM() removes leading and trailing spaces from a string.
        TRIM(SUBSTRING_INDEX(`cast`, ',', 1)) AS actor,    -- SUBSTRING_INDEX() extracts part of a string before a specified delimiter.
        SUBSTRING(`cast`, 
             LENGTH(SUBSTRING_INDEX('cast', ',', 1))+ 2) AS rest   -- SUBSTRING() extracts a portion of a string starting from a given position.
     FROM netflix
        WHERE                                -- LENGTH() returns the number of characters in a string.
           `cast` IS NOT NULL
           AND
           TRIM(`cast`) <> ''
           AND 
           country LIKE '%India%'
           
     UNION ALL                                -- UNION ALL combines the base query with the recursive query results.
     
     SELECT show_id,
          TRIM(SUBSTRING_INDEX(rest, ',', 1)),
          SUBSTRING(rest, LENGTH(SUBSTRING_INDEX(rest, ',', 1)) + 2)
     FROM cte 
     WHERE rest <> ''                        -- WHERE rest <> '' stops recursion when no values are left to split.
)    
SELECT 
     actor, 
     COUNT(*) AS total_content    -- COUNT(*) returns the total number of rows in each group.
FROM cte 
    WHERE 
       actor IS NOT NULL
       AND 
       actor <> ''                          -- actor <> '' removes empty strings after splitting.
       AND
       actor REGEXP '^[A-Za-z .]{3,}$'      -- REGEXP filters out invalid or broken actor names.
       AND
       actor LIKE '% %'                     -- LIKE '% %' ensures only full names (first and last name) are selected.
GROUP BY actor                              -- GROUP BY actor groups records actor-wise for counting.
ORDER BY total_content desc                 -- ORDER BY total_content DESC sorts actors by highest appearances.
LIMIT 10;


-- 15. Categorize Content Based on the Presence of 'Kill' and 'Violence' Keywords in the description field.
	-- Label Content containing these keywords as 'Bad' and all other content as 'Good'. Count how many items fall into
    -- each category

WITH new_table                                   --  WITH is used to create a temporary named result set (CTE).
AS
(    
SELECT 
    *,
    CASE                                       -- CASE is used to classify content based on keywords in the description.
       WHEN description LIKE '%kill%'          -- LIKE checks for the presence of specific words in a text column.
             OR
			description LIKE '%violence%'
	    THEN 'Bad Content'
        ELSE 'Good Content'
	END Category                             
    FROM netflix
)
  SELECT
      category,                                -- AS Category assigns a name to the derived column.
      count(*) as total_content
      FROM new_table
      GROUP BY 1 DESC

