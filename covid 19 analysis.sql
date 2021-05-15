/*
Covid 19 Data Exploration
Explored Fiji data and Global

Skills used: Joins, CTE, Temp Tables, Aggregate Functions, Creating Views, Converting Data Types
*/

-- Fiji's First Covid Case until 12th May, 2021

SELECT date,
         location,
         total_cases,
         new_cases,
         total_deaths,
         population
FROM Portfolio..CovidDeaths
WHERE location = 'Fiji'
        AND total_cases is NOT null
ORDER BY  location, date;

-- Fiji Covid Death Rate by date

SELECT date,
         location,
         total_cases,
         total_deaths,
         (total_deaths*100/total_cases) AS DeathPercentage
FROM Portfolio..CovidDeaths
WHERE location = 'Fiji'
ORDER BY  date;

-- Fiji New Vaccinations
SELECT d.date,
         d.continent,
         d.location,
         d.population,
         v.new_vaccinations
FROM Portfolio..CovidDeaths d
JOIN Portfolio..CovidVaccinations v
    ON d.location = v.location
        AND d.date = v.date
WHERE v.new_vaccinations is NOT null
        AND d.continent is NOT null
        AND d.location = 'Fiji'
ORDER BY  d.date;

-- Calculating % Vaccinated of Fiji Population using CTE

With percent_vaccinated (Date, Continent, Location, Population, New_Vaccinations, total_vacc_per_day) AS 
    (SELECT d.date,
         d.continent,
         d.location,
         d.population,
         v.new_vaccinations,
         SUM(cast(v.new_vaccinations AS int))
        OVER (Partition by d.location
    ORDER BY  d.location, d.date) AS total_vaccinations_by_day
    FROM Portfolio..CovidDeaths d
    JOIN Portfolio..CovidVaccinations v
        ON d.location = v.location
            AND d.date = v.date
    WHERE v.new_vaccinations is NOT null
            AND d.continent is NOT null
            AND d.location = 'Fiji' )
SELECT Date,
         Continent,
         Location,
         Population,
         New_Vaccinations,
         total_vacc_per_day,
         (total_vacc_per_day/Population)*100 AS '% of population vaccinated'
FROM percent_vaccinated;

-- Highest infection rate (Countries)
SELECT location,
         MAX(total_cases) AS HighestInfectionCount,
         population,
         MAX((total_cases/population))*100 AS infection_rate
FROM Portfolio..CovidDeaths
WHERE continent is NOT null
GROUP BY  location, population
ORDER BY  infection_rate desc; 

-- Highest Death Count (Countries)
SELECT location,
         MAX(CAST(total_deaths AS int)) AS TotalDeathCount
FROM Portfolio..CovidDeaths
WHERE continent is NOT null
GROUP BY  location
ORDER BY  TotalDeathCount desc;

-- Highest Death Count (Continent)
SELECT location,
         MAX(CAST(total_deaths AS int)) AS TotalDeathCount
FROM Portfolio..CovidDeaths
WHERE continent is null
GROUP BY  location
ORDER BY  TotalDeathCount desc;

-- Highest Death Count (Countries and Continent)
SELECT location,
         continent,
         MAX(CAST(total_deaths AS int)) AS TotalDeathCount
FROM Portfolio..CovidDeaths
WHERE continent is NOT null
GROUP BY  location, continent
ORDER BY  TotalDeathCount desc;

-- Global Numbers - New cases and new deaths per day
SELECT date,
         location,
         SUM(cast(new_cases AS int)) AS newCases,
         SUM(cast(new_deaths AS int)) AS newDeaths
FROM Portfolio..CovidDeaths
WHERE location = 'World'
GROUP BY  date, location
ORDER BY  date;

--Global - Total Cases and Total Deaths with Death Rate
SELECT MAX(total_cases) AS global_cases,
         MAX(cast(total_deaths AS int)) AS global_deaths,
         ROUND(MAX(cast(total_deaths AS float))*100/MAX(total_cases),
         2) AS 'death_rate (%)'
FROM Portfolio..CovidDeaths;

-- Global - Total Population Vs Vaccinations
SELECT d.date,
         d.continent,
         d.location,
         d.population,
         v.new_vaccinations
FROM Portfolio..CovidDeaths d
JOIN Portfolio..CovidVaccinations v
    ON d.location = v.location
        AND d.date = v.date
WHERE v.new_vaccinations is NOT null
        AND d.continent is NOT null
ORDER BY  d.date, d.location;

-- Global - Total Population Vs Vaccinations
SELECT d.date,
         d.continent,
         d.location,
         d.population,
         v.new_vaccinations,
         SUM(cast(v.new_vaccinations AS int))
    OVER (Partition by d.location
ORDER BY  d.location, d.date) AS total_vaccinations_by_day
FROM Portfolio..CovidDeaths d
JOIN Portfolio..CovidVaccinations v
    ON d.location = v.location
        AND d.date = v.date
WHERE v.new_vaccinations is NOT null
        AND d.continent is NOT null
ORDER BY  d.location;

-- Global - Calculating % Vaccinated of Population USING CTE

WITH percent_vaccinated (Date, Continent, Location, Population, New_Vaccinations, total_vacc_per_day) AS 
    (SELECT d.date,
         d.continent,
         d.location,
         d.population,
         v.new_vaccinations,
         SUM(cast(v.new_vaccinations AS int))
        OVER (Partition by d.location
    ORDER BY  d.location, d.date) AS total_vaccinations_by_day
    FROM Portfolio..CovidDeaths d
    JOIN Portfolio..CovidVaccinations v
        ON d.location = v.location
            AND d.date = v.date
    WHERE v.new_vaccinations is NOT null
            AND d.continent is NOT NULL )
SELECT Date,
         Continent,
         Location,
         Population,
         New_Vaccinations,
         total_vacc_per_day,
         ROUND((total_vacc_per_day/Population)*100,
        4) AS '% of population vaccinated'
FROM percent_vaccinated;

-- Create Temp Table for Global - Calculating % Vaccinated of Population using CTE
DROP Table if EXISTS #PercentPopulationVaccincated 
Create Table #PercentPopulationVaccincated ( Date datetime, Continent nvarchar(255), Location nvarchar(255), Population numeric, New_Vaccincations numeric, Total_Vaccinations_per_day numeric, percent_population_vaccinated float );

With percent_vaccinated (Date, Continent, Location, Population, New_Vaccinations, total_vacc_per_day)
as 
(
SELECT d.date,
         d.continent,
         d.location,
         d.population,
         v.new_vaccinations,
         SUM(cast(v.new_vaccinations AS int))
    OVER (Partition by d.location
ORDER BY  d.location, d.date) AS total_vaccinations_by_day
FROM Portfolio..CovidDeaths d
JOIN Portfolio..CovidVaccinations v
    ON d.location = v.location
        AND d.date = v.date
WHERE v.new_vaccinations is NOT null
        AND d.continent is NOT null
)
Insert into #PercentPopulationVaccincated
SELECT Date,
         Continent,
         Location,
         Population,
         New_Vaccinations,
         total_vacc_per_day,
         ROUND((total_vacc_per_day/Population)*100,
        4) AS '% of population vaccinated'
FROM percent_vaccinated;

Select * From #PercentPopulationVaccincated;

-- Create View to store data for visualizations

Create View PercentPopulationVaccinated as
WITH percent_vaccinated (Date, Continent, Location, Population, New_Vaccinations, total_vacc_per_day) AS 
    (SELECT d.date,
         d.continent,
         d.location,
         d.population,
         v.new_vaccinations,
         SUM(cast(v.new_vaccinations AS int))
        OVER (Partition by d.location
    ORDER BY  d.location, d.date) AS total_vaccinations_by_day
    FROM Portfolio..CovidDeaths d
    JOIN Portfolio..CovidVaccinations v
        ON d.location = v.location
            AND d.date = v.date
    WHERE v.new_vaccinations is NOT null
            AND d.continent is NOT NULL )
SELECT Date,
         Continent,
         Location,
         Population,
         New_Vaccinations,
         total_vacc_per_day,
         ROUND((total_vacc_per_day/Population)*100,
        4) AS '% of population vaccinated'
FROM percent_vaccinated;

Select * from PercentPopulationVaccinated;