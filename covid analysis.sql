select date, location, total_cases, new_cases, total_deaths, population 
from Portfolio..CovidDeaths
Where location = 'Fiji'
Order by location, date;

-- Fiji Covid Death Rate by date

select date, location, total_cases, total_deaths, (total_deaths*100/total_cases) AS DeathPercentage
from Portfolio..CovidDeaths
where location = 'Fiji'
Order by date;

-- Fiji New Vaccinations
Select d.date, d.continent, d.location, d.population, v.new_vaccinations
From Portfolio..CovidDeaths d
Join Portfolio..CovidVaccinations v
ON d.location = v.location
and d.date = v.date
where v.new_vaccinations is not null and d.continent is not null
and d.location = 'Fiji'
order by d.date;

-- Calculating % Vaccinated of Fiji Population using CTE

With percent_vaccinated (Date, Continent, Location, Population, New_Vaccinations, total_vacc_per_day)
as 
(
Select d.date, d.continent, d.location, d.population, v.new_vaccinations,
SUM(cast(v.new_vaccinations as int)) 
OVER (Partition by d.location order by d.location, d.date) AS total_vaccinations_by_day
From Portfolio..CovidDeaths d
Join Portfolio..CovidVaccinations v
ON d.location = v.location
and d.date = v.date
where v.new_vaccinations is not null and d.continent is not null
and d.location = 'Fiji'
)
Select Date, Continent, Location, Population, New_Vaccinations, total_vacc_per_day,
(total_vacc_per_day/Population)*100 AS '% of population vaccinated'
FROM percent_vaccinated;

-- Highest infection rate (Countries)
select location, MAX(total_cases) as HighestInfectionCount, population, MAX((total_cases/population))*100 AS infection_rate
from Portfolio..CovidDeaths
Where continent is not null
Group by location, population
order by infection_rate desc;

-- Highest Death Count (Countries)
Select location, MAX(CAST(total_deaths as int)) as TotalDeathCount
from Portfolio..CovidDeaths
Where continent is not null
group by location
order by TotalDeathCount desc;

-- Highest Death Count (Continent)
Select location, MAX(CAST(total_deaths as int)) as TotalDeathCount
from Portfolio..CovidDeaths
Where continent is null
group by location
order by TotalDeathCount desc;

-- Highest Death Count (Countries and Continent)
Select location, continent, MAX(CAST(total_deaths as int)) as TotalDeathCount
from Portfolio..CovidDeaths
Where continent is not null
group by location, continent
order by TotalDeathCount desc;

-- Global Numbers - New cases and new deaths per day
Select date, location, SUM(cast(new_cases as int)) as newCases, SUM(cast(new_deaths as int)) as newDeaths
from Portfolio..CovidDeaths
where location = 'World'
group by date, location
Order by date;

--Global - Total Cases and Total Deaths with Death Rate
select MAX(total_cases) as global_cases, MAX(cast(total_deaths as int)) as global_deaths,
ROUND(MAX(cast(total_deaths as float))*100/MAX(total_cases), 2) as 'death_rate (%)'
from Portfolio..CovidDeaths;

-- Global - Total Population Vs Vaccinations
Select d.date, d.continent, d.location, d.population, v.new_vaccinations
From Portfolio..CovidDeaths d
Join Portfolio..CovidVaccinations v
ON d.location = v.location
and d.date = v.date
where v.new_vaccinations is not null and d.continent is not null
order by d.date, d.location;

-- Global - Total Population Vs Vaccinations
Select d.date, d.continent, d.location, d.population, v.new_vaccinations,
SUM(cast(v.new_vaccinations as int)) 
OVER (Partition by d.location order by d.location, d.date) AS total_vaccinations_by_day
From Portfolio..CovidDeaths d
Join Portfolio..CovidVaccinations v
ON d.location = v.location
and d.date = v.date
where v.new_vaccinations is not null and d.continent is not null
order by d.location;

-- Global - Calculating % Vaccinated of Population using CTE

With percent_vaccinated (Date, Continent, Location, Population, New_Vaccinations, total_vacc_per_day)
as 
(
Select d.date, d.continent, d.location, d.population, v.new_vaccinations,
SUM(cast(v.new_vaccinations as int)) 
OVER (Partition by d.location order by d.location, d.date) AS total_vaccinations_by_day
From Portfolio..CovidDeaths d
Join Portfolio..CovidVaccinations v
ON d.location = v.location
and d.date = v.date
where v.new_vaccinations is not null and d.continent is not null
)
Select Date, Continent, Location, Population, New_Vaccinations, total_vacc_per_day,
ROUND((total_vacc_per_day/Population)*100,4) AS '% of population vaccinated'
FROM percent_vaccinated;

-- Create Temp Table for Global - Calculating % Vaccinated of Population using CTE
DROP Table if exists #PercentPopulationVaccincated
Create Table #PercentPopulationVaccincated
(
Date datetime,
Continent nvarchar(255),
Location nvarchar(255),
Population numeric,
New_Vaccincations numeric,
Total_Vaccinations_per_day numeric,
percent_population_vaccinated float
);

With percent_vaccinated (Date, Continent, Location, Population, New_Vaccinations, total_vacc_per_day)
as 
(
Select d.date, d.continent, d.location, d.population, v.new_vaccinations,
SUM(cast(v.new_vaccinations as int)) 
OVER (Partition by d.location order by d.location, d.date) AS total_vaccinations_by_day
From Portfolio..CovidDeaths d
Join Portfolio..CovidVaccinations v
ON d.location = v.location
and d.date = v.date
where v.new_vaccinations is not null and d.continent is not null
)
Insert into #PercentPopulationVaccincated
Select Date, Continent, Location, Population, New_Vaccinations, total_vacc_per_day,
ROUND((total_vacc_per_day/Population)*100,4) AS '% of population vaccinated'
FROM percent_vaccinated;

Select * From #PercentPopulationVaccincated;

-- Create View to store data for visualizations

Create View PercentPopulationVaccinated as
With percent_vaccinated (Date, Continent, Location, Population, New_Vaccinations, total_vacc_per_day)
as 
(
Select d.date, d.continent, d.location, d.population, v.new_vaccinations,
SUM(cast(v.new_vaccinations as int)) 
OVER (Partition by d.location order by d.location, d.date) AS total_vaccinations_by_day
From Portfolio..CovidDeaths d
Join Portfolio..CovidVaccinations v
ON d.location = v.location
and d.date = v.date
where v.new_vaccinations is not null and d.continent is not null
)
Select Date, Continent, Location, Population, New_Vaccinations, total_vacc_per_day,
ROUND((total_vacc_per_day/Population)*100,4) AS '% of population vaccinated'
FROM percent_vaccinated;
