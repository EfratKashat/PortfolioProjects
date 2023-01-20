
/*	
	Corona Data Exploration
	Guided Project

	Skills used:
				- Aggregate Functions
				- Converting Data Types
				- Joins
				- Windows Functions
				- CTE
				- Temp Tables
				- Creating Views,
*/

-- view table1 (deaths):

select		*
from		[dbo].[CovidDeaths]
where		continent is not null
order by	location, date


-- view table2 (vaccinations):

select		*
from		[dbo].[CovidVaccinations]
where		continent is not null
order by	location, date


-- the basic data:

select		location, date, total_cases, new_cases, total_deaths, population
from		[dbo].[CovidDeaths]
order by	location, date


-- total cases vs. total deaths (the Where clause can be used to show the likelihood of dying if you contract covid in a certain country):

select		location, date, total_cases, total_deaths, total_deaths/total_cases*100 as death_percentage
from		[dbo].[CovidDeaths]
--where		location = 'Israel'
order by	location, date


-- infection rate by country:

select		location, date, population, total_cases, total_cases/population*100 as infection_percentage
from		[dbo].[CovidDeaths]
order by	location, date


-- countries with highest infection rate:

select		location, population, MAX(total_cases) as highest_infection_count, MAX(total_cases/population*100) as highest_infection_rate
from		[dbo].[CovidDeaths]
group by	location, population
order by	highest_infection_rate desc


-- countries with highest death count:

select		location, MAX(cast(total_deaths as int)) as total_death_count
from		[dbo].[CovidDeaths]
where		continent is not null
group by	location
order by	total_death_count desc


-- countries with highest death rate:

select		location, population, MAX(total_deaths) as highest_death_count, MAX(total_deaths/population*100) as highest_death_rate
from		[dbo].[CovidDeaths]
group by	location, population
order by	highest_death_rate desc


-- BREAKING THINGS DOWN BY CONTINENT:

-- continents with highest death count:

select		continent, MAX(cast(total_deaths as int)) as total_death_count
from		[dbo].[CovidDeaths]
where		continent is not null
group by	continent
order by	total_death_count desc

-- continents with highest death rate:

select		location, population, MAX(total_deaths/population*100) as highest_death_rate
from		[dbo].[CovidDeaths]
where		continent is null
group by	location, population
order by	highest_death_rate desc


-- GLOBAL NUMBERS:

-- new cases, new deaths, death rate - by date:

select		date,
			sum(new_cases) as new_cases_count,
			sum(cast(new_deaths as int)) as new_deaths_count,
			( sum(cast(new_deaths as int)) / sum(new_cases) * 100 ) as death_percentage
from		[dbo].[CovidDeaths]
where		continent is not null
group by	date
order by	date


-- all time:

select		sum(new_cases) as new_cases_count,
			sum(cast(new_deaths as int)) as new_deaths_count,
			( sum(cast(new_deaths as int)) / sum(new_cases) * 100 ) as death_percentage
from		[dbo].[CovidDeaths]
where		continent is not null


-- LOOKING AT BOTH TABLES:

-- new vaccinations and total vaccination by date and country:
--(total vaccinations calculated using PARTITION BY, instead of using the total_vaccinations column)

select		D.continent,
			D.location,
			D.date,
			D.population,
			V.new_vaccinations,
			SUM(CONVERT(int, V.new_vaccinations)) OVER (PARTITION BY D.location ORDER BY D.location, D.date) as rolling_people_caccinated
from		[dbo].[CovidDeaths] as D
join		[dbo].[CovidVaccinations] as V
			on	D.location = V.location
			and D.date = V.date
where		D.continent is not null
order by	D.location, d.date


-- vaccinated rate (using CTE):

with		VacVsPop (continent, location, date, population, new_vaccinations, rolling_people_vaccinated)
as
(
select		D.continent,
			D.location,
			D.date,
			D.population,
			V.new_vaccinations,
			SUM(CONVERT(int, V.new_vaccinations)) OVER (PARTITION BY D.location ORDER BY D.location, D.date) as rolling_people_vaccinated
from		[dbo].[CovidDeaths] as D
join		[dbo].[CovidVaccinations] as V
			on	D.location = V.location
			and D.date = V.date
where		D.continent is not null
)

select		*, (rolling_people_vaccinated/population*100) as vaccinated_percentage
from		VacVsPop
order by	location, date


-- vaccinated rate (using Temp Table):

drop table if exists #Vaccinated_Percentage
create table #Vaccinated_Percentage
(
			continent nvarchar(225),
			location nvarchar(225),
			date datetime,
			population numeric,
			new_vaccinations numeric,
			rolling_people_vaccinated numeric
)

insert into #Vaccinated_Percentage
select		D.continent,
			D.location,
			D.date,
			D.population,
			V.new_vaccinations,
			SUM(CONVERT(int, V.new_vaccinations)) OVER (PARTITION BY D.location ORDER BY D.location, D.date) as rolling_people_vaccinated
from		[dbo].[CovidDeaths] as D
join		[dbo].[CovidVaccinations] as V
			on	D.location = V.location
			and D.date = V.date
where		D.continent is not null

select		*, (rolling_people_vaccinated/population*100) as vaccinated_percentage
from		#Vaccinated_Percentage
order by	location, date


-- creating a View to store data for later:

create view Vaccinated_Percentage as
select		D.continent,
			D.location,
			D.date,
			D.population,
			V.new_vaccinations,
			SUM(CONVERT(int, V.new_vaccinations)) OVER (PARTITION BY D.location ORDER BY D.location, D.date) as rolling_people_vaccinated
from		[dbo].[CovidDeaths] as D
join		[dbo].[CovidVaccinations] as V
			on	D.location = V.location
			and D.date = V.date
where		D.continent is not null

select		*
from		Vaccinated_Percentage
