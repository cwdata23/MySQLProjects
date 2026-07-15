-- Original Data: https://github.com/AlexTheAnalyst/MySQL-YouTube-Series/blob/main/layoffs.csv

-- looking at the data
SELECT *
FROM layoffs;

-- do not want to work on the raw data, create a staging table
CREATE TABLE layoffs_staging
LIKE layoffs;

INSERT layoffs_staging
SELECT *
FROM layoffs;

SELECT * 
FROM layoffs_staging;

-- removing duplicates
SELECT *,
ROW_NUMBER() OVER(
PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions) AS row_num
FROM layoffs_staging; 

WITH duplicate_cte AS
(
SELECT *,
ROW_NUMBER() OVER(
PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions) AS row_num
FROM layoffs_staging
)
SELECT *
FROM duplicate_cte
WHERE row_num > 1;

-- double checking that these are duplicates
SELECT *
FROM layoffs_staging
WHERE company = 'Casper';

-- making sure to only delete duplicates (5 duplicates)
CREATE TABLE `layoffs_staging2` (
  `company` text,
  `location` text,
  `industry` text,
  `total_laid_off` int DEFAULT NULL,
  `percentage_laid_off` text,
  `date` text,
  `stage` text,
  `country` text,
  `funds_raised_millions` int DEFAULT NULL,
  `row_num` int
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

INSERT INTO layoffs_staging2
SELECT *,
ROW_NUMBER() OVER(
PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions) AS row_num
FROM layoffs_staging;

DELETE
FROM layoffs_staging2
WHERE row_num > 1;

-- shows they have been deleted
SELECT *
FROM layoffs_staging2
WHERE row_num > 1; 

-- standardizing the data
-- removing blank spaces starting company names
UPDATE layoffs_stagings2
SET company = TRIM(company);

SELECT DISTINCT company, industry
FROM layoffs_staging2;
-- checking for company names that might need to be fixed
-- NOTE: some companies have different names with the same industry, some companies have the same name with different industries. I will change only ones I can verify are the same company with the same industry.
-- [done] Ada and Ada Support are the same company - change to Ada Support
-- [done] Impossible Foods and Impossible Foods copy - change to Impossible Foods
-- [done] Stash and Stash Financial are the same - change to Stash Financial
-- [done] character encoding error - UalÃ¡ - company is Ualá - change to Ualá or Uala if the error continues
-- [done] Politico / Protocol - change to just Politico
-- [done] Pear Therapeutics / Healthcare is showing up twice but they look the same, maybe spacing?
-- [done] WeWork / Real Estate is also showing up twice but they look the same

SELECT ASCII(RIGHT(company, 1)) FROM layoffs_staging2 WHERE company LIKE 'Pear Therapeutics%';
-- trim isn't working despite it saying 32 (standard space)

UPDATE layoffs_staging2
SET company = 'Pear Therapeutics'
WHERE company LIKE 'Pear Therapeutics%';

UPDATE layoffs_staging2
SET company = 'WeWork'
WHERE company LIKE 'WeWork%';

-- want to make sure when replacing other names that it doesn't change anywhere else. For example, changing Ada can affect "Ada Health", "Adaptive Biotechnologies", and "Adara"

UPDATE layoffs_staging2
SET company = REGEXP_REPLACE(company, '\\bAda\\b(?!\\s+(?:Health|Support))', 'Ada Support')
WHERE company REGEXP '\\bAda\\b';

UPDATE layoffs_staging2
SET company = REGEXP_REPLACE(company, ' copy$', '')
WHERE company LIKE '% copy';

UPDATE layoffs_staging2
SET company = REGEXP_REPLACE(company, '\\bStash\\b(?!\\sFinancial)', 'Stash Financial')
WHERE company REGEXP '\\bStash\\b';

UPDATE layoffs_staging2
SET company = 'Ualá'
WHERE company LIKE 'UalÃ¡';

UPDATE layoffs_staging2
SET company = 'Politico'
WHERE company LIKE 'Politico / Protocol';

SELECT DISTINCT industry
FROM layoffs_staging2
ORDER BY 1;
-- looking at the industry: noticing for that crypto has 3 distinct names

UPDATE layoffs_staging2
SET industry = 'Crypto'
WHERE industry LIKE 'Crypto%';

SELECT DISTINCT country
FROM layoffs_staging2
ORDER BY 1;
-- looking at the countries to see if things need to be fixed: there is a United States. 

UPDATE layoffs_staging2
SET country = TRIM(TRAILING '.' FROM country)
WHERE country LIKE 'United States%';

-- if working with dates, data type for date needs to be changed
UPDATE layoffs_staging2
SET `date` = STR_TO_DATE(`date`, '%m/%d/%Y');

ALTER TABLE layoffs_staging2
MODIFY COLUMN `date` DATE;

SELECT DISTINCT location
FROM layoffs_staging2;
-- checking to see if any location data needs to be fixed
-- [done] character encoding error - 'DÃ¼sseldorf' - change to Düsseldorf
-- [done] change 'Dusseldorf' to Düsseldorf for continuity
-- [done] haracter encoding error - 'FlorianÃ³polis' - change to Florianópolis
-- [done] character encoding error - 'MalmÃ¶' - change to Malmö
-- [done] change 'Malmo' to Malmö for continuity

UPDATE layoffs_staging2
SET location = 'Düsseldorf'
WHERE location LIKE 'DÃ¼sseldorf';

UPDATE layoffs_staging2
SET location = 'Düsseldorf'
WHERE location LIKE 'Dusseldorf';

UPDATE layoffs_staging2
SET location = 'Florianópolis'
WHERE location LIKE 'FlorianÃ³polis';

UPDATE layoffs_staging2
SET location = 'Malmö'
WHERE location LIKE 'MalmÃ¶';

UPDATE layoffs_staging2
SET location = 'Malmö'
WHERE location LIKE 'Malmo';

SELECT DISTINCT stage
FROM layoffs_staging2;
-- stage seems fine

-- fixing null and blank values
-- [done] fix Airbnb (one has no industry listed - Travel)
-- [done] fix Carvana (one has no industry listed - Transportation)
-- [done] fix Juul (one has no industry listed - Consumer)
-- Bally's Interactive has a NULL industry - unknown industry (doesn't have another one to compare to)

UPDATE layoffs_staging2
SET industry = NULL
WHERE industry = '';

UPDATE layoffs_staging2 t1
JOIN layoffs_staging2 t2
	ON t1.company = t2.company
SET t1.industry = t2.industry
WHERE (t1.industry IS NULL OR t1.industry = '')
AND t2. industry IS NOT NULL;

-- delete redundant columns (row_num that was created before)
ALTER TABLE layoffs_staging2
DROP COLUMN row_num;

-- generally shouldn't delete data // for the sake of this example and use in data exploration, I will delete entries that have null values for BOTH total_laid_off and percentage_laid_off. 
DELETE
FROM layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

-- FINAL VIEW
SELECT*
FROM layoffs_staging2;

