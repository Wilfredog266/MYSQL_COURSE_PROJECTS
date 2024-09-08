# World Life Expectancy Project (Data Cleaning)
# This project was offered by analystbuilder.com from the MySQL for Data Analytics online course presented by "Alex the analyst"
# world_life_expectancy_stage this is the original table, world_life_expectancy is the updated table

SELECT *
FROM world_life_expectancy_stage
;

# Here I am trying to figure out if we have any duplicates in the table to then delete them 
SELECT 
	Country, 
	Year, 
	CONCAT(Country, Year), # This is to see the country an year together which makes it easier to see any duplicated year 
	COUNT(CONCAT(Country, Year)) # We count the number of rows in the CONCAT() and group it to see if any show '2' meaning it is duplicated 
FROM world_life_expectancy_stage
GROUP BY 
	Country, 
	Year, 
	CONCAT(Country, Year) 
# We can also order the COUNT() in DESC and will see the numbers greater than 1 at the top 
HAVING COUNT(CONCAT(Country, Year)) > 1 # We filter the aggregate function with a HAVING CLAUSE to find all the duplicates 
;

# We need to find the unique Row_ID for each of the duplicates to then remove them with an UPDATE
# We will use a PARTITON BY with ROW_NUMBER

SELECT 
	Row_ID, 
	CONCAT(Country, Year),  
    ROW_NUMBER() OVER( PARTITION BY CONCAT(Country, Year) ORDER BY CONCAT(Country, Year)) AS Row_Num 
FROM world_life_expectancy_stage
ORDER BY Row_Num DESC #To see the duplicates first 
;

# We need to filter it, we must use the previous query as a subquery in the FROM statement and then we filter to find the specific Row_ID we want
# Because we can not filter in a WINDOW FUNCTION 

SELECT *
FROM (
		SELECT 
			Row_ID, 
			CONCAT(Country, Year),  
			ROW_NUMBER() OVER( PARTITION BY CONCAT(Country, Year) ORDER BY CONCAT(Country, Year)) AS Row_Num 
			FROM world_life_expectancy_stage
	  ) AS Row_table
WHERE Row_Num > 1
;

# Now we have the Row_ID of the duplicate rows and can delete the duplicate rows 
# It is good practice to always have an original copy of any table we are working with

DELETE 
FROM world_life_expectancy
WHERE #Using a subquery withing a subquery in the WHERE clause, with the query we previously used to get the Row_ID of the duplicates 
	Row_ID IN (
		SELECT Row_ID 
		FROM (
				SELECT 
				Row_ID, 
				CONCAT(Country, Year),  
				ROW_NUMBER() OVER( PARTITION BY CONCAT(Country, Year) ORDER BY CONCAT(Country, Year)) AS Row_Num 
				FROM world_life_expectancy
				) AS Row_table
		WHERE Row_Num > 1
)
;
# We did this work around because there was no primary key in this table so we had to create our own unique value column 
# We have successfully removed the duplicates 


SELECT *
FROM world_life_expectancy_stage 
WHERE Status = '' # That means where the rows in the Status column are equal to blank different from NULLS 
;

SELECT DISTINCT(Status) #To find the DISTINCT data that populates the Status column
FROM world_life_expectancy_stage
WHERE Status <> '' #Because we want the values where the rows are populated, not BLANK 
; # Status = Developing or Developed 

SELECT DISTINCT(Country)
FROM world_life_expectancy_stage
WHERE Status = 'Developing'
; # We will UPDATE 'Developing' where it fits

UPDATE world_life_expectancy
SET Status = 'Developing'
WHERE Country IN ( SELECT DISTINCT(Country) # This does not work, subqueries can not be used in an UPDATE statement
				   FROM world_life_expectancy
				   WHERE Status = 'Developing'
				 )
;

# We do this instead, we join the table to itself so that we can basically apply multiple conditions to a single column 
# We are still updating one table because we will specify in the update statement which table we want to update (table 1)
UPDATE world_life_expectancy AS t1 #Table 1
JOIN world_life_expectancy AS t2 #Table 2
	ON t1.Country = t2.Country 
SET t1.Status = 'Developing' #This is what we will populate with
WHERE t1.Status = '' #Where in table 1 Status is blank 
AND t2.Status <> '' #AND in table 2 Status is not blank 
AND t2.Status = 'Developing' #AND in table 2 Status says Developing
; #This worked!!

SELECT *
FROM world_life_expectancy_stage #Original table to see the process so output will be as if there was no UPDATE this is to see 'United States of America' that goes as 'Developed' 
WHERE Status = ''
; #We successfully populated the blanks with 'Developing' but looks like we have one more left that did not UPDATE this might be because it needs to be populated with 'Developed'

# This is to confirm it needs to be populated with 'Developed'
SELECT *
FROM world_life_expectancy_stage
WHERE Country = 'United States of America'
; #Now we do the exact same thing but changing it to 'Developed'

UPDATE world_life_expectancy AS t1 # Table 1
JOIN world_life_expectancy AS t2 # Table 2
	ON t1.Country = t2.Country 
SET t1.Status = 'Developed'
WHERE t1.Status = ''
AND t2.Status <> ''
AND t2.Status = 'Developed'
;

#Now we successfully populated all the blank rows in the Status column 
SELECT *
FROM world_life_expectancy 
WHERE Status = ''
;

#We continue with the `Life expectancy` column 
SELECT *
FROM world_life_expectancy_stage
WHERE `Life expectancy` = '' #Is equal to blank 
; #We have two blanks with year 2018 

#Reasoning here is to populate these blank rows with the result from (previous year(2017) + next year(2019)/ 2) to retrieve an AVG for our empty row
SELECT #This is the data we need to do this 
	Country,
	Year,
	`Life expectancy`
FROM world_life_expectancy 
; # We wil do this by performing a SELF JOIN three times, so we can gather all the information needed with 3 tables 

SELECT 
	t1.Country, t1.Year, t1.`Life expectancy` , #table to be populated 
    t2.Country, t2.Year, t2.`Life expectancy` , #table with year 2019
    t3.Country, t3.Year, t3.`Life expectancy` , #table with year 2017 
    ROUND((t2.`Life expectancy` + t3.`Life expectancy`)/2,1) #the avg to populate blank rows
FROM world_life_expectancy_stage AS t1
JOIN  world_life_expectancy_stage AS t2
	ON t1.Country = t2.Country
    AND t1.Year = t2.Year - 1 # -1 to get year above 2018 in table 2
JOIN  world_life_expectancy_stage AS t3
	ON t1.Country = t3.Country
    AND t1.Year = t3.Year + 1 # +1 to get year below 2018 in table 3
WHERE t1.`Life expectancy` = '' #filtering for the rows that are blank 
;
#Now we have our AVG `Life expectancy` for each blank row 

#Knowing it works we now use the same logic to now UPDATE table 1 from the join 
UPDATE world_life_expectancy AS t1
JOIN world_life_expectancy AS t2
	ON t1.Country = t2.Country
    AND t1.Year = t2.Year - 1 
JOIN world_life_expectancy AS t3
	ON t1.Country = t3.Country
    AND t1.Year = t3.Year + 1 
SET t1.`Life expectancy` = ROUND((t2.`Life expectancy` + t3.`Life expectancy`)/2,1) #set to this result which is the avg life expectancy 
WHERE t1.`Life expectancy` = '' #only UPDATE the blank rows 
;

# Data Cleaning done, table looks good!!

SELECT *
FROM world_life_expectancy
;
