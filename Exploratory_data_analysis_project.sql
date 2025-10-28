-- ===============================================================
-- PROJECT: LAYOFFS DATA EXPLORATION (CLEANED DATASET)
-- ===============================================================

-- ---------------------------------------------------------------
-- View all the data in the table
-- ---------------------------------------------------------------
SELECT * FROM layoffs_staging2;

-- ---------------------------------------------------------------
-- Count total number of rows in the dataset
-- ---------------------------------------------------------------
SELECT COUNT(*) FROM layoffs_staging2;

-- ---------------------------------------------------------------
-- Find the company with the maximum number of layoffs
-- ---------------------------------------------------------------
SELECT * 
FROM layoffs_staging2
WHERE total_laid_off = (SELECT MAX(total_laid_off) FROM layoffs_staging2);

-- ---------------------------------------------------------------
-- Find total layoffs by industry, ordered from highest to lowest
-- ---------------------------------------------------------------

SELECT industry, SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY industry
ORDER BY 2 DESC;

-- ---------------------------------------------------------------
-- Find companies that laid off 100% of their employees and rank them by total laid off
-- ---------------------------------------------------------------

SELECT company, MAX(total_laid_off) AS max_laid_off, MAX(percentage_laid_off)
FROM layoffs_staging2
WHERE percentage_laid_off = '100%'
GROUP BY company 
ORDER BY max_laid_off DESC;

-- ---------------------------------------------------------------
-- Find total layoffs by country, ordered from highest to lowest
-- ---------------------------------------------------------------

SELECT country, SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY country
ORDER BY 2 DESC;

-- ---------------------------------------------------------------
-- Find total layoffs per year, ordered by year
-- ---------------------------------------------------------------

SELECT YEAR(`date`), SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY YEAR(`date`)
ORDER BY 1 DESC;

-- ---------------------------------------------------------------
-- Find total layoffs by company stage (e.g., Seed, Series A, Post-IPO)
-- ---------------------------------------------------------------

SELECT stage, SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY stage
ORDER BY 1 DESC;

-- ---------------------------------------------------------------
-- Find total layoffs per month (YYYY-MM format)
-- ---------------------------------------------------------------

SELECT SUBSTRING(`date`,1,7) AS `MONTH`, SUM(total_laid_off) AS TOTAL_OFF
FROM layoffs_staging2
GROUP BY `MONTH`
ORDER BY 1 ASC;

-- ---------------------------------------------------------------
-- Calculate the cumulative (rolling) total layoffs over time
-- ---------------------------------------------------------------

WITH ROLLING_TOTAL AS (
    SELECT SUBSTRING(`date`,1,7) AS `MONTH`, SUM(total_laid_off) AS TOTAL_OFF
    FROM layoffs_staging2
    GROUP BY `MONTH`
    ORDER BY 1 ASC
)
SELECT `MONTH`, TOTAL_OFF, SUM(TOTAL_OFF) OVER(ORDER BY `MONTH`) AS ROLL_OVER_TOTAL
FROM ROLLING_TOTAL;

-- ---------------------------------------------------------------
-- Find total layoffs by company and year
-- ---------------------------------------------------------------

SELECT company, SUBSTRING(`date`,1,4) AS `year`, SUM(total_laid_off) AS TOTAL_OFF
FROM layoffs_staging2
GROUP BY company, `year`;

-- ---------------------------------------------------------------
-- Rank companies each year by number of layoffs and select the top 5 per year
-- ---------------------------------------------------------------

WITH company_year AS (
    SELECT company, SUBSTRING(`date`,1,4) AS `year`, SUM(total_laid_off) AS TOTAL_OFF
    FROM layoffs_staging2
    GROUP BY company, `year`
    ORDER BY company ASC
),
company_year_ranking AS (
    SELECT *, DENSE_RANK() OVER (PARTITION BY `year` ORDER BY TOTAL_OFF DESC) AS RANKING 
    FROM company_year
)
SELECT * 
FROM company_year_ranking 
WHERE RANKING <= 5;

