-- SQL DATA CLEANING PROJECT: GLOBAL LAYOFFS DATASET
-- Description: This project cleans and standardizes a global layoffs dataset
-- using MySQL. The process includes duplicate removal, data standardization,
-- date formatting, and handling of missing values.

-- ------------------------------------------------------------
-- STEP 1: SELECT DATABASE
-- ------------------------------------------------------------
USE world_layoffs;

-- ------------------------------------------------------------
-- STEP 2: INITIAL DATA INSPECTION
-- ------------------------------------------------------------
SELECT * FROM layoffs_staging;
SELECT COUNT(*) FROM world_layoffs.layoffs_staging;

-- ------------------------------------------------------------
-- STEP 3: IDENTIFY DUPLICATES USING A CTE
-- ------------------------------------------------------------
WITH duplicate_cte AS (
    SELECT *,
           ROW_NUMBER() OVER(
               PARTITION BY company, total_laid_off, `date`,
                            percentage_laid_off, industry, stage,
                            funds_raised, country, date_added
           ) AS ROW_NUM
    FROM layoffs_staging
)
SELECT * 
FROM duplicate_cte 
WHERE ROW_NUM > 1;

-- ------------------------------------------------------------
-- STEP 4: CREATE A STAGING TABLE FOR CLEANING
-- ------------------------------------------------------------
CREATE TABLE `layoffs_staging2` (
  `company` TEXT,
  `location` TEXT,
  `total_laid_off` BIGINT DEFAULT NULL,
  `date` TEXT,
  `percentage_laid_off` TEXT,
  `industry` TEXT,
  `source` TEXT,
  `stage` TEXT,
  `funds_raised` TEXT,
  `country` TEXT,
  `date_added` TEXT,
  `ROW_NUM` INT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- ------------------------------------------------------------
-- STEP 5: INSERT CLEANED DATA WITH ROW NUMBERS
-- ------------------------------------------------------------
INSERT INTO layoffs_staging2
SELECT *,
       ROW_NUMBER() OVER(
           PARTITION BY company, total_laid_off, `date`,
                        percentage_laid_off, industry, stage,
                        funds_raised, country, date_added
       ) AS ROW_NUM
FROM layoffs_staging;

-- ------------------------------------------------------------
-- STEP 6: STANDARDIZE COMPANY NAMES
-- ------------------------------------------------------------
-- Remove leading/trailing spaces
UPDATE layoffs_staging2
SET company = TRIM(company);

-- Check for variations (e.g., 'Amazon' vs 'amazon')
SELECT DISTINCT company
FROM layoffs_staging2
WHERE company LIKE '%amazon%';

-- ------------------------------------------------------------
-- STEP 7: STANDARDIZE INDUSTRY NAMES
-- ------------------------------------------------------------
-- Example: Unify 'Crypto', 'Cryptocurrency', etc.
SELECT *
FROM layoffs_staging2
WHERE industry LIKE '%Crypto%';

UPDATE layoffs_staging2
SET industry = 'Crypto'
WHERE industry LIKE 'Crypto%';

-- ------------------------------------------------------------
-- STEP 8: CLEAN UP COUNTRY NAMES
-- ------------------------------------------------------------
-- Example: Remove trailing periods (e.g., 'United States.')
UPDATE layoffs_staging2
SET country = TRIM(TRAILING '.' FROM country)
WHERE country LIKE 'United States%';

-- ------------------------------------------------------------
-- STEP 9: CONVERT DATE STRINGS TO DATE FORMAT
-- ------------------------------------------------------------
-- Preview conversion
SELECT `date`, STR_TO_DATE(`date`, '%m/%d/%Y')
FROM layoffs_staging2;

-- Apply conversion
UPDATE layoffs_staging2
SET `date` = STR_TO_DATE(`date`, '%m/%d/%Y');

-- Change column type to proper DATE
ALTER TABLE layoffs_staging2
MODIFY COLUMN `date` DATE;

-- ------------------------------------------------------------
-- STEP 10: HANDLE MISSING VALUES
-- ------------------------------------------------------------

-- Check for missing or blank industries
SELECT *
FROM layoffs_staging2
WHERE industry IS NULL OR industry = '';

-- Check for Appsmith (only row missing industry)
SELECT *
FROM layoffs_staging2
WHERE company = 'Appsmith';

-- Assign industry based on research
UPDATE layoffs_staging2
SET industry = 'Software'
WHERE company = 'Appsmith';

-- Check for missing 'funds_raised'
SELECT COUNT(*)
FROM layoffs_staging2
WHERE funds_raised IS NULL OR funds_raised = '';

-- Check for missing 'country'
SELECT *
FROM layoffs_staging2
WHERE country IS NULL OR country = '';

-- Check for missing 'stage'
SELECT *
FROM layoffs_staging2
WHERE stage IS NULL OR stage = '';

-- Check for missing 'percentage_laid_off'
SELECT COUNT(*)
FROM layoffs_staging2
WHERE percentage_laid_off IS NULL OR percentage_laid_off = '';

-- ------------------------------------------------------------
-- STEP 11: VALIDATE MISSING DATA HANDLING
-- ------------------------------------------------------------
-- Check if other rows can help fill missing industries
SELECT * 
FROM layoffs_staging2 t1
JOIN layoffs_staging2 t2
  ON t1.company = t2.company
WHERE (t1.industry = '' OR t1.industry IS NULL)
  AND t2.industry IS NOT NULL;

-- ------------------------------------------------------------
-- STEP 12: FINAL DATA VALIDATION
-- ------------------------------------------------------------
-- Confirm no blank values remain for numeric or critical columns
SELECT * 
FROM layoffs_staging2
WHERE (total_laid_off = '' OR total_laid_off IS NULL)
   OR (percentage_laid_off = '' OR percentage_laid_off IS NULL);

-- View final cleaned dataset
SELECT * 
FROM layoffs_staging2;

-- ------------------------------------------------------------
-- STEP 13: REMOVE TEMPORARY HELPER COLUMN
-- ------------------------------------------------------------
ALTER TABLE layoffs_staging2
DROP COLUMN ROW_NUM;

-- ------------------------------------------------------------
-- ✅ FINAL CLEANED TABLE READY FOR ANALYSIS
-- ------------------------------------------------------------
SELECT *
FROM layoffs_staging2
LIMIT 50;

-- ------------------------------------------------------------
-- END OF SCRIPT
-- ------------------------------------------------------------

