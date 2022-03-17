--EXPLORING AND DATA CLEANING-----
SELECT *
FROM PortfolioProject..dailyActivity ---940 rows in total
SELECT *
FROM PortfolioProject..dailyCalories ---940 rows in total
SELECT *
FROM PortfolioProject..dailyIntensities--940 rows in total
SELECT *
FROM PortfolioProject..dailySteps--940 rows in total

--Double check again
--------------Verify dailyActivity and dailyCalories dataset
SELECT COUNT(*)
FROM PortfolioProject..dailyActivity act
LEFT JOIN PortfolioProject..dailyCalories cal
	ON act.ActivityDate = cal.ActivityDay
	AND act.Calories = cal.Calories
	AND act.Id = cal.Id
--940---
--Verify dailyActivity and dailyIntensive
SELECT COUNT(*)
FROM PortfolioProject..dailyActivity act
LEFT JOIN PortfolioProject..dailyIntensities inten
	ON act.Id = inten.Id
	AND act.ActivityDate =inten.ActivityDay
	AND act.SedentaryMinutes = inten.SedentaryMinutes
	AND act.LightlyActiveMinutes = inten.LightlyActiveMinutes
	AND act.FairlyActiveMinutes = inten.FairlyActiveMinutes
	AND act.VeryActiveMinutes = inten.VeryActiveMinutes
	AND act.SedentaryActiveDistance = inten.SedentaryActiveDistance
	AND act.LightActiveDistance = inten.LightActiveDistance
	AND act.ModeratelyActiveDistance = inten.ModeratelyActiveDistance
	AND act.VeryActiveDistance = inten.VeryActiveDistance
--940--
--Verify dailyActivity and dailySteps
SELECT COUNT(*)
FROM PortfolioProject..dailyActivity act
LEFT JOIN PortfolioProject..dailySteps step
	ON act.Id = step.Id
	AND act.ActivityDate = step.ActivityDay
	AND act.TotalSteps = step.StepTotal
--940--
--The dailyActivity dataset contains data from dailyCalories, dailyIntensities, dailySteps so we only need the dailyActiviy dataset for further work
--Remove dailyCalories, dailyIntensities, dailySteps dataset
DROP TABLE PortfolioProject..dailyCalories,PortfolioProject..dailyIntensities, PortfolioProject..dailySteps


---------------------REMOVE DUPLICATES-------------
--1. dailyActivity
WITH RowNumCTE AS (
	SELECT *, ROW_NUMBER() OVER ( PARTITION BY Id, ActivityDate, TotalSteps, Calories ORDER BY Id ) row_num
	FROM PortfolioProject..dailyActivity
)
SELECT *
FROM RowNumCTE
WHERE row_num > 1
ORDER BY ActivityDate
----no duplicates----

--2. hourlySteps
--check duplicates 
WITH RowNumCTE1 AS (
	SELECT *, ROW_NUMBER() OVER ( PARTITION BY Id, ActivityHour,StepTotal ORDER BY Id ) row_num
	FROM PortfolioProject..hourlySteps
)
SELECT *
FROM RowNumCTE1
WHERE row_num > 1
ORDER BY ActivityHour
----no duplicates---

--3. Check duplicates in sleepDay dataset
WITH RowNumCTE2 AS (
	SELECT *, ROW_NUMBER() OVER (PARTITION BY Id, SleepDay, TotalSleeprecords, TotalMinutesAsleep, TotalTimeInBed ORDER BY Id) AS row_num
	FROM PortfolioProject..sleepDay
)
SELECT *
FROM RowNumCTE2
WHERE row_num >1
ORDER BY sleepDay
--- have duplicated datas then now remove the duplicated data 
WITH RowNumCTE2 AS (
	SELECT *, ROW_NUMBER() OVER (PARTITION BY Id, SleepDay, TotalSleeprecords, TotalMinutesAsleep, TotalTimeInBed ORDER BY Id) AS row_num
	FROM PortfolioProject..sleepDay
)
DELETE
FROM RowNumCTE2
WHERE row_num >1
--ORDER BY sleepDay


-----STANDARDIZE DATE FORMAT
SELECT *
FROM PortfolioProject..dailyActivity
ALTER TABLE PortfolioProject..dailyActivity
ADD Activity_Date Date
UPDATE PortfolioProject..dailyActivity
SET Activity_Date = CONVERT(Date,ActivityDate)
---Remove old column ActivityDate that we wont use anymore
ALTER TABLE PortfolioProject..dailyActivity
DROP COLUMN ActivityDate

SELECT *
FROM PortfolioProject..sleepDay
ALTER TABLE PortfolioProject..sleepDay
ADD Sleep_Date Date
UPDATE PortfolioProject..sleepDay
SET Sleep_Date = CONVERT(Date,sleepDay)
ALTER TABLE PortfolioProject..sleepDay
DROP COLUMN SleepDay
---Standardize datetime format

SELECT *
FROM PortfolioProject..hourlySteps
ALTER TABLE PortfolioProject..hourlySteps
ADD Date_time datetime
UPDATE PortfolioProject..hourlySteps
SET Date_time = CONVERT(datetime, ActivityHour)
ALTER TABLE PortfolioProject..hourlySteps
DROP COLUMN ActivityHour


-- Join data
SELECT ac.Id,ac.Activity_Date,ac.TotalSteps, ac.Calories, ac.SedentaryMinutes, sl.TotalMinutesAsleep, sl.TotalTimeInBed
FROM PortfolioProject..dailyActivity ac
FULL OUTER JOIN PortfolioProject..sleepDay sl
	ON sl.Id = ac.Id
	AND sl.Sleep_Date = ac.Activity_Date
ORDER BY ac.Activity_Date
--Create view to store data for further visualization
CREATE VIEW Activity_SleepDay AS
SELECT ac.Id,ac.Activity_Date,ac.TotalSteps, ac.Calories, ac.SedentaryMinutes, sl.TotalMinutesAsleep, sl.TotalTimeInBed
FROM PortfolioProject..dailyActivity ac
FULL OUTER JOIN PortfolioProject..sleepDay sl
	ON sl.Id = ac.Id
	AND sl.Sleep_Date = ac.Activity_Date
SELECT *
FROM 


--- See on average how many steps taken per day, time pp spent sitting or inactive, and time sleeping in minutes
SELECT 
AVG(ac.TotalSteps) as averageSteps, AVG(ac.SedentaryMinutes) as sedentary, AVG(sl.TotalMinutesAsleep) as timesleep
FROM PortfolioProject..dailyActivity ac
LEFT JOIN PortfolioProject..sleepDay sl
	ON sl.Id = ac.Id
	AND sl.Sleep_Date = ac.Activity_Date
--- On average, users takes 7638 steps per day
--- On average, users spend 16.5 hour per day sitting or do nothing
--- And each user sleeps 6,98 hours per day 


------ TABLEAU VISUALIZATION---------
---Table 1 Relationship between total steps and calories
SELECT TotalSteps, Calories
FROM PortfolioProject..dailyActivity
ORDER BY 1
----- As expected, there has correlation between total steps and calories. The more steps taken the more calories be burnt

---Table 2 Total steps and sedentary
SELECT Id,AVG(TotalSteps) as averageStepperid, AVG(SedentaryMinutes) as averagetimeSedentary
FROM PortfolioProject..dailyActivity
GROUP BY Id
ORDER BY 2
----- Table 2 show the number of time user spend in sitting or sedentary and total steps. there has no clearly correlations between them in this case
--- Table 3 Relationship between total steps per day and sleeping time per day
SELECT ac.Id,ac.TotalSteps,sl.TotalMinutesAsleep
FROM PortfolioProject..dailyActivity ac
LEFT JOIN PortfolioProject..sleepDay sl
	ON sl.Id = ac.Id
	AND sl.Sleep_Date = ac.Activity_Date
WHERE TotalMinutesAsleep is not null
ORDER BY 1
------- In general, users who steps more during a day tend to spend more time in sleeping.

---Table 4 Active steps in a day during week

SELECT *
FROM PortfolioProject..hourlySteps
ALTER TABLE PortfolioProject..hourlySteps
ADD Step_date date
UPDATE PortfolioProject..hourlySteps
SET Step_date = CONVERT(, Date_time);

ALTER TABLE PortfolioProject..hourlySteps
ADD Step_time time
UPDATE PortfolioProject..hourlySteps
SET Step_time = CONVERT(time, Date_time)

ALTER TABLE PortfolioProject..hourlySteps
DROP COLUMN Date_time
--name weekday 
SELECT Id,StepTotal,DATENAME(WEEKDAY,Step_date) as Step_weekday,Step_time
FROM PortfolioProject..hourlySteps

---- Table 4 shows people started their day later on weekend and are most active 11am to 1pm on Saturday and 5pm-6pm on Wednesday

