USE covidproject;
CREATE DATABASE covidproject;
show tables from CovidProject;
select * from CovidProject.worldometer_data;
select * from CovidProject.usa_county_wise;
#... changing the column names to avoid getting more errors
select 'Country/Region' from CovidProject.worldometer_data;
ALTER TABLE CovidProject.worldometer_data
CHANGE COLUMN `Country/Region` Location VARCHAR(255);

#trying to create and manipulate the data to create a relationship for both tables
# to effectively achieve a join Query 
select * from CovidProject.usa_county_wise;
ALTER TABLE CovidProject.usa_county_wise
CHANGE COLUMN  UID  Population INT;

# now creating a common indentifier for both tables
#Add ID column to worldometer_data table
ALTER TABLE CovidProject.worldometer_data
ADD COLUMN ID INT AUTO_INCREMENT PRIMARY KEY;

# Add ID column to usa_county_wise table
ALTER TABLE CovidProject.usa_county_wise
ADD COLUMN ID INT AUTO_INCREMENT PRIMARY KEY;


ALTER TABLE worldometer_data
MODIFY COLUMN Population BIGINT;


#Update ID values for worldometer_data
UPDATE worldometer_data
SET Population = population * 2
WHERE ID IN (
    SELECT ID
    FROM (
        SELECT ID
        FROM worldometer_data
        WHERE population > 331198130
    ) AS subquery
);



#Extracting the data in ascending order from our table
Select Continent,population,TotalCases,NewCases,TotalDeaths from CovidProject.worldometer_data
order by 1,2,3;

#looking at Total Cases and Total Deaths based on location and population
Select Location,population,TotalCases,TotalDeaths, (TotalDeaths/TotalCases)*100 as DeathPercentage
from CovidProject.worldometer_data
Order by 1,2;

#.... LOOKING AT THE TOTAL CASES VS POPULATION
# Shows what percentage of population got covid in particular location
Select Location,population,TotalCases,TotalDeaths, (population/TotalCases)*100 as populationcases
from CovidProject.worldometer_data
Order by 1,2;

#.....looking for location and population with the total recovery percentage by Group
#shows the total cases and recovery comapring it to their location and population.
SELECT Location, Population, SUM(TotalCases) AS TotalCases, SUM(TotalRecovered) AS TotalRecoveryNo, 
       SUM(TotalRecovered / TotalCases) * 100 AS RecoveryPercentage
FROM CovidProject.worldometer_data
GROUP BY Location, Population
order by RecoveryPercentage desc;

#highest death count in different location
SELECT Location, SUM(TotalDeaths) AS TotalDeathnumber
FROM worldometer_data
GROUP BY Location;

#lets gain more exploration from the continent
#--- showing the continent with the Highest death count
SELECT Continent, SUM(TotalDeaths) AS TotalDeathnumber
FROM worldometer_data
GROUP BY Continent
order by TotalDeathnumber desc;

#showing continent where covid is till has active cases
SELECT Continent, SUM(TotalCases) AS TotalCases, SUM(ActiveCases) AS ActiveCasesNO, 
       SUM(ActiveCases / TotalCases) * 100 AS ActivePercentage
FROM CovidProject.worldometer_data
GROUP BY Continent
order by ActivePercentage desc;

#now let find out the total. number of new death cases comparing it with the percentage
Select SUM(NewCases) as total_cases, SUM(NewDeaths) as total_deaths, SUM(NewDeaths / NewCases) * 100 AS TotalNewDeaths
FROM CovidProject.worldometer_data
order by TotalNewDeaths desc;

#showing how to join both tables to add dates in our finding
select W.location, W.population, US.Date, US.FIPS
FROM CovidProject.worldometer_data W
JOIN CovidProject.usa_county_wise US ON W.ID = US.ID;

#let do more findings AT the province states AND BE MORE FOCUS ON THE UNITED STATES
#Which are more afffected.
SELECT US.date, US.Country_Region, US.Province_State, W.TotalDeaths, W.TotalRecovered,
       SUM(TotalCases) AS TotalCasesUS, SUM(TotalRecovered / TotalCases) * 100 AS RecoveryPercentage
FROM CovidProject.usa_county_wise US
JOIN CovidProject.worldometer_data W ON US.ID = W.ID
GROUP BY Country_Region, date, Province_State, US.ID;

#CREATE A TEMP TABLE THAT CAN SHOW US VACCINATED INFORMATION
-- TEMP TABLE
DROP TABLE IF exists VaccinatedPeople
CREATE TEMPORARY TABLE VaccinatedPeople (
    ID INT PRIMARY KEY,
    Continent VARCHAR(255),
    Location VARCHAR(255),
    Date DATETIME,
    Population DECIMAL,
    total_vaccinated DECIMAL,
    Not_vaccinated DECIMAL
);
# ADD SOME DATA INTO THE TABLE
SELECT * FROM VaccinatedPeople;
 -- Inserting a little data into the temporary table
INSERT INTO VaccinatedPeople (ID, Continent, Location, Date, Population, total_vaccinated, Not_vaccinated)
VALUES
    (1, 'Asia', 'Japan', '2023-2-01', 21500000, 11200000, 4300000),
    (2, 'Europe', 'Germany', '2023-3-02', 800000, 700000, 100000),
    (3, 'North America', 'USA', '2023-10-03', 2500000, 2000000, 500000),
    (4, 'South America', 'Brazil', '2023-10-04', 1200000, 1900000, 200000),
    (5, 'Asia', 'Korea', '2023-8-01', 1580000, 120700, 900000),
    (6, 'Europe', 'Germany', '2023-7-02', 800000, 700000, 800000),
    (7, 'North America','columbia ', '2023-6-03', 2500000, 2000000, 500000),
    (8, 'South America', 'Brazil', '2023-11-04', 1200000, 1000000, 200000);



#INSERT INTO #VaccinatedPeople (Location,Population,Date,total_vaccinated)
SELECT
    W.location,
    W.population,
    US.Date,
    US.FIPS,
    VAC.total_vaccinated,
    SUM(VAC.total_vaccinated) OVER (PARTITION BY W.location ORDER BY US.Date) AS people_already_vaccinated
FROM
    CovidProject.worldometer_data W
JOIN
    CovidProject.usa_county_wise US ON W.ID = US.ID
JOIN
    CovidProject.VaccinatedPeople VAC ON W.ID = VAC.ID
ORDER BY
    W.location, US.Date;
    # showing our table with total vaccinated comparison to population
    SELECT *, (total_vaccinated /Population)*100
    FROM CovidProject.VaccinatedPeople


