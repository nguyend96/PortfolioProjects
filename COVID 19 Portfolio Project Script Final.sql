
select *
from PortfolioProject..CovidVaccinations
WHERE continent IS NOT NULL
order by 3,4;

--select data that we are going to be using

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1,2;

--Looking at Total Cases vs. Total Deaths
-- Shows likelihood of dying from COVID-19 per country.

SELECT location, date, total_cases, total_deaths, (cast(total_deaths AS FLOAT)/cast(total_cases AS FLOAT))*100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE location LIKE '%United States%'
AND continent IS NOT NULL
ORDER BY 1,2;

-- Looking at Total Cases vs. Population
-- Shows % of population that contracted COVID-19

SELECT location, date,population,total_cases, (cast(total_cases AS FLOAT)/cast(population AS FLOAT))*100 AS PREVALENCE
FROM PortfolioProject..CovidDeaths
WHERE location LIKE 'United States'
AND continent IS NOT NULL
ORDER BY 1,2;

-- Looking at Countries with Highest Infection Rate compared to respective Population.

SELECT location, population, MAX(total_cases) AS HighestInfectionCount, (MAX(total_cases)/population)*100 AS PercentPopulationInfected
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
--WHERE location LIKE 'United States'
GROUP BY location, population
--GROUP BY continent
ORDER BY PercentPopulationInfected DESC;

--Showing Highest Mortality Rate per Population

SELECT location, MAX(cast(Total_deaths AS BIGINT)) AS TotalDeathCount
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
--WHERE location LIKE 'United States'
GROUP BY location
--GROUP BY continent
ORDER BY TotalDeathCount DESC;

-- Separating Data By Continent

-- Continents With Highest Death Count/Mortality

SELECT continent, MAX(cast(Total_deaths AS BIGINT)) AS TotalDeathCount
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
--WHERE location LIKE 'United States'
GROUP BY continent
ORDER BY TotalDeathCount DESC;

-- Global Covid-19 Cases vs. Deaths

SELECT SUM(new_cases) AS total_cases, SUM(CAST(new_deaths AS BIGINT)) AS total_deaths, SUM(CAST(new_deaths AS BIGINT))/SUM(New_Cases)*100 AS DeathPercent
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
--WHERE location LIKE '%United States%'
--GROUP BY date
ORDER BY 1,2;

-- Total Population vs. Vaccinations
-- Shows % of Population that has received at least one Covid-19 Vaccination by Date. %'s over 100 indicate 2/3/4 doses of vaccine shots.

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS VaccinationRollingCount
-- Include (vaccinationrollingcount/population) * 100 With CTE
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2, 3;

-- CTE to perform calculation on PARTITION BY for the previous query.

WITH PopVsVac (continent, location, date, population, new_vaccinations, VaccinationRollingCount)
AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS VaccinationRollingCount
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
--ORDER BY 2, 3
)
SELECT *, (VaccinationRollingCount/population)*100 AS RollingPercentCount
FROM PopVsVac;

-- TEMP Table to perform calculations on PARTITION BY in previous query.

DROP TABLE IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
VaccinationRollingCount numeric,
)

INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS VaccinationRollingCount
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
--ORDER BY 2, 3;

SELECT *, (VaccinationRollingCount/population)*100 AS RollingPercentCount
FROM #PercentPopulationVaccinated;


-- Creating View to Store Data for Visualizations

CREATE VIEW PercentPopulationVaccinated AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS VaccinationRollingCount
-- Include (vaccinationrollingcount/population) * 100 With CTE
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
--ORDER BY 2, 3;

SELECT *
FROM PercentPopulationVaccinated;

CREATE VIEW ContinentTotalDeathCount
SELECT continent, MAX(cast(Total_deaths AS BIGINT)) AS TotalDeathCount
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
--WHERE location LIKE 'United States'
GROUP BY continent
ORDER BY TotalDeathCount DESC;

SELECT *
FROM ContinentTotalDeathCount;