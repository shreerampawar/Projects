USE hr__;

ALTER TABLE hr
CHANGE COLUMN ï»¿id emp_id VARCHAR(20);

UPDATE hr 
SET 
    birthdate = CASE
        WHEN
            birthdate LIKE '%/%'
        THEN
            DATE_FORMAT(STR_TO_DATE(birthdate, '%m/%d/%Y'),
                    '%Y-%m-%d')
        WHEN
            birthdate LIKE '%-%'
        THEN
            DATE_FORMAT(STR_TO_DATE(birthdate, '%m-%d-%Y'),
                    '%Y-%m-%d')
        ELSE NULL
    END;

ALTER TABLE hr
MODIFY COLUMN birthdate DATE;

DESCRIBE hr;

UPDATE hr 
SET 
    hire_date = CASE
        WHEN
            hire_date LIKE '%/%'
        THEN
            DATE_FORMAT(STR_TO_DATE(hire_date, '%m/%d/%Y'),
                    '%Y-%m-%d')
        WHEN
            hire_date LIKE '%-%'
        THEN
            DATE_FORMAT(STR_TO_DATE(hire_date, '%m-%d-%Y'),
                    '%Y-%m-%d')
        ELSE NULL
    END;

ALTER TABLE hr
MODIFY COLUMN hire_date DATE;

SET sql_mode = 'ALLOW_INVALID_DATES';

UPDATE hr
SET termdate = IF(termdate IS NOT NULL AND termdate != '', date(str_to_date(termdate, '%Y-%m-%d %H:%i:%s UTC')), '0000-00-00')
WHERE true;

ALTER TABLE hr
MODIFY COLUMN termdate DATE;

ALTER TABLE hr
ADD COLUMN age INT;

UPDATE hr 
SET 
    age = TIMESTAMPDIFF(YEAR,
        birthdate,
        CURDATE());

SELECT 
    MIN(age) AS youngest, MAX(age) AS oldest
FROM
    hr;

DELETE FROM hr 
WHERE
    age < 18;

DELETE FROM hr 
WHERE
    termdate <> CURDATE();

-------------------------------------------------------------------

-- ## EDA ## --

## What is the gender breakdown of employees in the company?
SELECT 
    gender, COUNT(*) AS cnt
FROM
    hr
WHERE
    termdate = '0000-00-00'
GROUP BY gender
ORDER BY cnt DESC;

## What is the race/ethnicity breakdown of employees in the company?
SELECT 
    race, COUNT(*) AS cnt
FROM
    hr
WHERE
    termdate = '0000-00-00'
GROUP BY race
ORDER BY cnt DESC;

## What is the age distribution of employees in the company?
SELECT 
    MIN(age) AS youngest, MAX(age) AS oldest
FROM
    hr
WHERE
    termdate = '0000-00-00';

SELECT 
    CASE
        WHEN age >= 18 AND age <= 24 THEN '18-24'
        WHEN age >= 25 AND age <= 34 THEN '25-34'
        WHEN age >= 35 AND age <= 44 THEN '35-44'
        WHEN age >= 45 AND age <= 54 THEN '45-54'
        WHEN age >= 55 AND age <= 64 THEN '55-64'
        ELSE '>=65'
    END AS age_grp,
    gender,
    COUNT(*) AS cnt
FROM
    hr
WHERE
    termdate = '0000-00-00'
GROUP BY age_grp , gender
ORDER BY age_grp , gender;

## How many employees work at headquarters versus remote locations?
SELECT 
    location, COUNT(*) AS cnt
FROM
    hr
WHERE
    termdate = '0000-00-00'
GROUP BY location;

## What is the average length of employment for employees who have been terminated?
SELECT 
    AVG(DATEDIFF(termdate, hire_date)) / 356 AS avg_len_of_employment
FROM
    hr
WHERE
    termdate <= CURDATE()
        AND termdate != '0000-00-00';

## How does the gender distribution vary across departments and job titles?
SELECT 
    department, gender, COUNT(*) AS cnt
FROM
    hr
WHERE
    termdate = '0000-00-00'
GROUP BY department , gender
ORDER BY department;

SELECT 
    jobtitle, gender, COUNT(*) AS cnt
FROM
    hr
WHERE
    termdate = '0000-00-00'
GROUP BY jobtitle , gender
ORDER BY jobtitle;

## What is the distribution of departments and job titles across the company?
SELECT 
    department, COUNT(*) AS cnt
FROM
    hr
WHERE
    termdate = '0000-00-00'
GROUP BY department
ORDER BY cnt DESC;

SELECT 
    jobtitle, COUNT(*) AS cnt
FROM
    hr
WHERE
    termdate = '0000-00-00'
GROUP BY jobtitle
ORDER BY cnt DESC;

## Which department has the highest turnover rate?
SELECT 
    department,
    total_cnt,
    terminated_cnt,
    terminated_cnt / total_cnt AS termination_rate
FROM
    (SELECT 
        department,
            COUNT(*) AS total_cnt,
            SUM(CASE
                WHEN
                    termdate != '0000-00-00'
                        AND termdate <= CURDATE()
                THEN
                    1
                ELSE 0
            END) AS terminated_cnt
    FROM
        hr
    GROUP BY department) AS sq
ORDER BY termination_rate DESC;

## What is the distribution of employees across locations by city and state?
SELECT 
    location_city AS city, COUNT(*) AS cnt
FROM
    hr
WHERE
    termdate = '0000-00-00'
GROUP BY city
ORDER BY cnt DESC;

SELECT 
    location_state AS state, COUNT(*) AS cnt
FROM
    hr
WHERE
    termdate = '0000-00-00'
GROUP BY state
ORDER BY cnt DESC;

## How has the companys employee count changed over time based on hire and term dates?
SELECT 
    yr,
    hires,
    terminations,
    hires - terminations AS net_change,
    ROUND((hires - terminations) / hires * 100, 2) AS net_change_pct
FROM
    (SELECT 
        YEAR(hire_date) AS yr,
            COUNT(*) AS hires,
            SUM(CASE
                WHEN
                    termdate != '0000-00-00'
                        AND termdate <= CURDATE()
                THEN
                    1
                ELSE 0
            END) AS terminations
    FROM
        hr
    GROUP BY yr) AS sq
ORDER BY yr ASC;

## What is the tenure distribution for each department?
SELECT 
    department,
    AVG(DATEDIFF(CURDATE(), termdate) / 365) AS avg_tenure_by_dep
FROM
    hr
WHERE
    termdate <= CURDATE()
        AND termdate != '0000-00-00'
GROUP BY department
ORDER BY avg_tenure_by_dep DESC;

## What is the tenure distribution for each job title?
SELECT 
    jobtitle,
    AVG(DATEDIFF(CURDATE(), termdate) / 365) AS avg_tenure_by_title
FROM
    hr
WHERE
    termdate <= CURDATE()
        AND termdate != '0000-00-00'
GROUP BY jobtitle
ORDER BY avg_tenure_by_title DESC