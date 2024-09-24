# World Life Expectancy Project EDA (Exploratory Data Analysis)
#Here we perform some exploratory data analysis looking for correlations between the Life expectancy column and the information in the other columns looking to see if we find any answers to why a country would have a low or high Life expectancy.

SELECT *
FROM world_life_expectancy
;

# Lets start out with finding out how every 'COUNTRY' has done with their life expectancy, have they increased it, descreased it or maintained it in the lapse of 15 years. This will help us see which countries have done really good with increasing their life expectancy and which countries have not.

SELECT 
	Country,
    MIN(`Life expectancy`), #to see their lowest life expectancy
    MAX(`Life expectancy`) #to see their highest life expectancy 
FROM world_life_expectancy
GROUP BY Country
HAVING MIN(`Life expectancy`) <> 0 #there were some rows that had 0 which could be a data quality issue so we filter them out for now
AND MAX(`Life expectancy`) <> 0 #there were some rows that had 0 which could be a data quality issue so we filter them out for now
ORDER BY Country DESC
;

# We want to see which "Countries" have made the biggest stride from their lowest to their highest points 

SELECT 
	Country,
    MIN(`Life expectancy`) AS Lowest_Life_Expectancy, 
    MAX(`Life expectancy`) AS Highest_Life_Expectancy,
#To find that number we find the difference between the MAX() and MIN(), we also will use ROUND() to make it look better
    ROUND(MAX(`Life expectancy`) - MIN(`Life expectancy`),1) AS Improvement_15_Years
FROM world_life_expectancy
GROUP BY Country
HAVING MIN(`Life expectancy`) <> 0 
AND MAX(`Life expectancy`) <> 0 
ORDER BY  Improvement_15_Years DESC   # We ORDER BY column name 'Improvement' in DESC to see the highest ones up top 
;

# Now lets analize the "Year column" to see the Years that have done very well, grouping it by year and calculating the AVG life Expectancy for each year 

SELECT *
FROM world_life_expectancy
;

# Lets use the Year and the AVG() `Life expectancy`
SELECT 
	Year,
    ROUND(AVG(`Life expectancy`),2) AS Avg_Life_expectancy #Using ROUND() to get 2 decimals
FROM world_life_expectancy
WHERE `Life expectancy` <> 0 #to filter out the rows with 0 because it should not be zero those rows should have some value
GROUP BY Year #To see the AVG for each individual Year  
ORDER BY Year ASC
;

# Given the output we can see that as a world in the span of 15 years we have increased our life expectancy 4.87 years we find this number by perfoming this simple calculation (Year2007) 66.76 - 71.62 (Year2022) = 4.87

SELECT *
FROM world_life_expectancy
;

#Lets explore the correlation between `Life expectancy` and the GDP to see if countries with high or low GDPS have any connections with their `Life expectancy`

SELECT # We will work with these columns 
	Country,
    `Life expectancy`,
    GDP
FROM world_life_expectancy
;

# To see any correlation we can go with looking at the AVG() of both `Life expectancy` and GDP per individual countries (GROUP BY)
SELECT 
	Country,
    ROUND(AVG(`Life expectancy`),1) AS avg_life_expectancy,
    ROUND(AVG(GDP),1) AS avg_gdp
FROM world_life_expectancy
GROUP BY Country
HAVING avg_life_expectancy > 0 #Here we are filtering out any Countries with 0 Life expectancy for the same reason than before 
AND avg_gdp > 0 #Here we are filtering out any Countries with 0 GDP for the same reason than before 
ORDER BY avg_gdp
; #Using the output to ORDER BY ASC DESC by whatever column I want where I perform my analisis 

# The GDP does have a positive and negative correlation with the `Life expectancy` of every country, at a glance we can see that the countries with the lowest GDP have a below AVG `Life expectancy` and the countries with a high GDP have a significantly higher `Life expectancy` 

# We can bucket the information in this output and give them categories using something like a CASE() STATEMENT, this can be very intresting to see and then we can group on those catergories to further analyze 

SELECT 
	SUM(CASE WHEN GDP >= 1500 THEN 1 ELSE 0 END) AS High_GDP_Count,
# SUM() counts all the countries with 1 giving us a total of the high GDP countries 
    AVG(CASE WHEN GDP >= 1500 THEN `Life expectancy` ELSE NULL END) AS High_GDP_Life_Expectancy,
	SUM(CASE WHEN GDP < 1500 THEN 1 ELSE 0 END) AS Low_GDP_Count,
    AVG(CASE WHEN GDP < 1500 THEN `Life expectancy` ELSE NULL END) AS Low_GDP_Life_Expectancy 
FROM world_life_expectancy
;
# We can see a 10 year difference between high and low GDP countries confirming the correlation between both stadistics
# HIGH GDP = HIGH LIFE EXPECTANCY and LOW GDP = LOW LIFE EXPECTANCY (Averaging by 10 years) this is called a high correlation. 

# We can do similar calculations with every other column to discover any other high correlations






#Lets look at the Status column and the correlation with the `Life expectancy` between Developing and Developed Countries 

SELECT *
FROM world_life_expectancy
;

SELECT
	Status,
    ROUND(AVG(`Life expectancy`),1)
FROM world_life_expectancy
GROUP BY Status
; #These results look good but they dont give us a clear picture, what if there is only one Developed Country and its Life expectancy is 79.2 and all the rest are Developing. The AVG() wont be accurate so we want to see the count of each Status

SELECT
	Status,
COUNT(DISTINCT Country),
ROUND(AVG(`Life expectancy`),1) #With only 32 Developed countries the AVG will be higher compared to the average of 161 Developing countries 
FROM world_life_expectancy
GROUP BY Status
; #Here we can see a big gap between both Status for Developed we have 32 countries and for Developing we have 161 countries which doesnt give us an accurate AVG. In terms of correlation.  


#Lets check the BMI and compare it to the Life expectancy for each country 

SELECT 
	Country,
    Status,
    ROUND(AVG(`Life expectancy`),1) AS avg_life_expectancy,
    ROUND(AVG(BMI),1) AS avg_BMI
FROM world_life_expectancy
GROUP BY Country, Status
HAVING avg_life_expectancy > 0 #Here we are filtering out any Countries with 0 Life expectancy because that is not posible 
AND avg_BMI > 0 #Here we are filtering out any Countries with 0 BMI for because that is unrealistic 
ORDER BY avg_BMI DESC 
; #We see correlation between BMI and Life expectancy, countries with the lowest life expectancy have a noticeably low BMI compared to countries with a AVG Life expectancy maybe because of the lack of resources and food due to these countries being mainly developing countries. Using a visualization tool we could understand the data better 



#Lets look at Adult Mortality, lets see how many people are dying each year in a country and is that a lot compared to their Life expectancy, what we will do is called a ROLLING TOTAL (This uses a WINDOW FUNCTION) we will use the Adult Mortality column 

SELECT
	Country,
    Year,
    `Life expectancy`,
    `Adult Mortality`,
   SUM(`Adult Mortality`) OVER(PARTITION BY Country ORDER BY Year) AS rolling_total
#We ORDER BY Year because we want it to be added year after year in order, not randomly, this calculation above is a ROLLING TOTAL
FROM world_life_expectancy
;

