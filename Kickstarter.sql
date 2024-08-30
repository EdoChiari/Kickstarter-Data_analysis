Copy kickstart FROM '/Users/edoardochiari/Desktop/Kickstarter.csv' DELIMITER ',' CSV HEADER

SELECT *
FROM kickstart;

-- 1) Find % of all the status.
WITH t1 AS (
    SELECT COUNT(*) AS Total_Count
    FROM kickstart
),

t2 AS (
    SELECT COUNT(*) AS Successful_Count
    FROM kickstart
    WHERE state = 'successful'
),

t3 AS (
    SELECT COUNT(*) AS Failed_Count
    FROM kickstart
    WHERE state = 'failed'
),

t4 AS (
    SELECT COUNT(*) AS Canceled_Count
    FROM kickstart
    WHERE state = 'canceled'
),

t5 AS (
    SELECT COUNT(*) AS Lived_Count
    FROM kickstart
    WHERE state = 'live'
),

t6 AS (
    SELECT COUNT(*) AS Suspended_Count
    FROM kickstart
    WHERE state = 'suspended'
),

t7 AS (
    SELECT COUNT(*) AS Undefined_Count
    FROM kickstart
    WHERE state = 'undefined'
)

SELECT 
    ROUND((t2.Successful_Count * 100.0 / t1.Total_Count), 2) AS percent_successful,
    ROUND((t3.Failed_Count * 100.0 / t1.Total_Count), 2) AS percent_failed,
    ROUND((t4.Canceled_Count * 100.0 / t1.Total_Count), 2) AS percent_canceled,
	ROUND((t5.Lived_Count * 100.0 / t1.Total_Count), 2) AS percent_lived,
	ROUND((t6.Suspended_Count * 100.0 / t1.Total_Count), 2) AS percent_suspended,
	ROUND((t7.Undefined_Count * 100.0 / t1.Total_Count), 2) AS percent_undefined
FROM t1, t2, t3, t4, t5, t6, t7;

-- Find the country with the highest number of total backer overall and vice versa.

WITH t1 AS (
	SELECT country AS c1, SUM(backers) AS Total_Backers
	FROM kickstart
	WHERE country != 'N,0"'  -- Exclude invalid country
	GROUP BY country
	ORDER BY Total_Backers DESC  -- Order by descending backers to get the most
	LIMIT 1
),

t2 AS (
	SELECT country AS c2, SUM(backers) AS Total_Backers
	FROM kickstart
	WHERE country != 'N,0"'  -- Exclude invalid country
	GROUP BY country
	ORDER BY Total_Backers ASC  -- Order by ascending backers to get the least
	LIMIT 1
)

SELECT c1 AS Country_with_most_backers, c2 AS Country_with_least_backers
FROM t1, t2;

-- How many launch were done in each year

SELECT EXTRACT(YEAR FROM launched) AS year, COUNT(*) AS total_project_launched
FROM kickstart
GROUP BY year
ORDER BY year ASC;

-- Which is the country with the highest average goal for each category

SELECT *
FROM kickstart

SELECT category, country
FROM
(
SELECT category, country, AVG(goal) AS avg_goal,
RANK() OVER(PARTITION BY category ORDER BY AVG(goal) DESC) AS rnk
FROM kickstart
GROUP BY category, country
) a WHERE a.rnk<2;

-- Find category wise highest percent successful for each of the countries

WITH case1 AS (
    SELECT 
        category, 
        country, 
        CASE WHEN state = 'successful' THEN 1 ELSE 0 END AS case_for_analysis
    FROM kickstart
),

case2 AS (
    SELECT 
        category, 
        country, 
        ROUND(SUM(case_for_analysis) * 100.0 / COUNT(case_for_analysis), 2) AS Percentage_successful
    FROM case1
    GROUP BY category, country
),

case3 AS (
    SELECT 
        category, 
        country, 
        Percentage_successful, 
        RANK() OVER (PARTITION BY category ORDER BY Percentage_successful DESC) AS rn
    FROM case2
)

SELECT 
    category, 
    country, 
    Percentage_successful
FROM case3
WHERE rn = 1;

-- Find the project that was launched in the earliest year, was successful, and had the highest goal among the successful projects from that year

SELECT * 
FROM kickstart
WHERE state = 'successful'
ORDER BY EXTRACT(YEAR FROM launched) ASC, goal DESC
LIMIT 1;

-- What is the average goal completion percentage (Pledged / Goal) for each category, among projects with a goal greater than $1,000 that were successful?

WITH t1 AS (
    SELECT * 
    FROM kickstart
    WHERE goal > 1000 AND state = 'successful'
),

t2 AS (
    SELECT *, 
           ROUND((pledged * 100.0 / goal), 2) AS percent_pledge_by_goal
    FROM t1
),

t3 AS (
    SELECT category, 
           ROUND(AVG(percent_pledge_by_goal), 2) AS avg_percent_pledgebygoal
    FROM t2
    GROUP BY category
    ORDER BY avg_percent_pledgebygoal DESC
)

SELECT * 
FROM t3;

-- Which category was the most successful in terms of percent_success in each year

WITH t1 AS (
    SELECT *,
        EXTRACT(YEAR FROM launched) AS launch_year
    FROM kickstart
),

t2 AS (
    SELECT *,
        CASE WHEN state = 'successful' THEN 1 ELSE 0 END AS case_for_analysis
    FROM t1
),

t3 AS (
    SELECT launch_year,
        category,
        ROUND(SUM(case_for_analysis) * 100.0 / COUNT(case_for_analysis), 2) AS percent_successful
    FROM t2
    GROUP BY launch_year, category
),

t4 AS (
    SELECT *,
        RANK() OVER (PARTITION BY launch_year ORDER BY percent_successful DESC) AS rn
    FROM t3
)

SELECT launch_year, category, percent_successful
FROM t4
WHERE rn = 1 AND percent_successful != 0;
