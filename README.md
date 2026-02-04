# Netflix Movies and TV Shows Data Analysis Using SQL

![](https://github.com/AkarshKumar1/Netflix_SQL_Project/blob/main/logo.png)

## Overview
This demo project presents an SQL-based analysis of a movies and TV shows dataset to demonstrate fundamental database querying and data analysis skills. The project focuses on extracting meaningful insights by applying SQL operations such as filtering, aggregation, and conditional queries. Through this analysis, the project highlights practical use of SQL for exploring structured data and answering analytical questions, making it suitable as an academic and learning-oriented data analysis project.

## Objectives

- To analyze the distribution of content types, including movies and TV shows.
- To identify the most frequently occurring ratings across different content categories.
- To examine content trends based on release year, country of origin, and duration.
- To classify and explore content using specific keywords and defined criteria through SQL queries.

## Dataset

The data for this project is sourced from the Kaggle dataset:

- **Dataset link:**  [Movies Dataset](https://www.kaggle.com/datasets/shivamb/netflix-shows?resource=download)

## Schema

```sql
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
```
## Business Problems and Solutions

### 1. Count the Number of Movies vs TV Shows

```sql
SELECT 
    type,
    COUNT(*)
FROM netflix
GROUP BY type;
```

**Objective:** Determine the distribution of content types on Netflix.

### 2. Find the Most Common Rating for Movies and TV Shows

```sql
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
```

**Objective:** Identify the most frequently occurring rating for each type of content.

### 3. List All Movies Released in a Specific Year (e.g., 2020)

```sql
SELECT * from netflix
     where
        TYPE = 'Movie'  -- "we can use type to determine the type of the content between movies and tv-shows"
		AND                        -- "we use logic operator here to check both condition before selecting the output"
        RELEASE_YEAR = 2020;
```

**Objective:** Retrieve all movies released in a specific year.

### 4. Find the Top 5 Countries with the Most Content on Netflix

```sql
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
```

**Objective:** Identify the top 5 countries with the highest number of content items.

### 5. Identify the Longest Movie

```sql
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
```

**Objective:** Find the movie with the longest duration.

### 6. Find Content Added in the Last 5 Years

```sql
SELECT *
    FROM netflix
    WHERE 
        STR_TO_DATE(date_added, '%M %d, %Y') >= CURDATE() - INTERVAL 5 YEAR;
```

**Objective:** Retrieve content added to Netflix in the last 5 years.

### 7. Find All Movies/TV Shows by Director 'Rajiv Chilaka'

```sql
SELECT *
      FROM netflix 
      WHERE
		 type in ('Movie', 'TV Show')
         AND
         director = 'Rajiv Chilaka';
```

**Objective:** List all content directed by 'Rajiv Chilaka'.

### 8. List All TV Shows with More Than 5 Seasons

```sql
SELECT * 
     FROM netflix
     WHERE 
        type = 'TV Show'
        AND 
        duration > '5 Seasons';
```

**Objective:** Identify TV shows with more than 5 seasons.

### 9. Count the Number of Content Items in Each Genre

```sql
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

```

**Objective:** Count the number of content items in each genre.

### 10.Find each year and the average numbers of content release in India on netflix. Return top 5 year with highest avg content release!

```sql
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
```

**Objective:** Calculate and rank years by the average number of content releases by India.

### 11. List All Movies that are Documentaries

```sql
SELECT
     title,
     type
     FROM netflix
     WHERE 
        listed_in = 'Documentaries';
```

**Objective:** Retrieve all movies classified as documentaries.

### 12. Find All Content Without a Director

```sql
SELECT * 
    FROM netflix
    WHERE 
       director = '' ;
```

**Objective:** List content that does not have a director.

### 13. Find How Many Movies Actor 'Salman Khan' Appeared in the Last 10 Years

```sql
SELECT *
     FROM netflix
     WHERE
		cast LIKE '%Salman Khan%'
        AND
        release_year > EXTRACT(YEAR FROM CURDATE()) - 10;
```

**Objective:** Count the number of movies featuring 'Salman Khan' in the last 10 years.

### 14. Find the Top 10 Actors Who Have Appeared in the Highest Number of Movies Produced in India

```sql
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
```

**Objective:** Identify the top 10 actors with the most appearances in Indian-produced movies.

### 15. Categorize Content Based on the Presence of 'Kill' and 'Violence' Keywords

```sql
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
      GROUP BY 1 DESC;
```

**Objective:** Categorize content as 'Bad' if it contains 'kill' or 'violence' and 'Good' otherwise. Count the number of items in each category.

## Findings and Conclusion

- Content Distribution: The dataset shows a varied collection of movies and TV shows spanning multiple genres and ratings.
- Rating Analysis: Identification of common ratings offers insights into the intended audience demographics.
- Geographical Trends: Analysis of country-wise content, including average releases from India, highlights regional distribution patterns.
- Content Categorization: Keyword-based classification helps in understanding the thematic nature of available content.

Overall, this analysis provides a structured overview of Netflix’s content library and demonstrates the effective use of SQL for data exploration and analytical decision-making.
