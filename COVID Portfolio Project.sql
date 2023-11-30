SELECT * 
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 3,4;

SELECT * 
FROM PortfolioProject..CovidVaccinations
WHERE continent IS NOT NULL
ORDER BY 3,4;

SELECT Location, date, total_cases, new_cases, total_deaths, population 
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1,2;

-- Comparaison : Total Cases vs Total Deaths
--Probabilité de mourir en cas de contamination dans un pays
SELECT Location, date, total_cases, total_deaths, ROUND((CAST(total_deaths AS float)/CAST(total_cases AS float))*100,2) AS DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE Location like '%states%'
AND WHERE continent IS NOT NULL
ORDER BY 1,2;

-- Comparaison : Total Cases vs Population
-- Pourcentage de la population contaminé
SELECT Location, date, Population, total_cases, ROUND((CAST(total_cases AS float)/Population )*100,2) AS PopPercentageInfected
FROM PortfolioProject..CovidDeaths
WHERE Location like '%states%'
ORDER BY 1,2;

-- Pays avec taux d'infection le + élevé
SELECT Location, Population, MAX(total_cases) AS Max_infection, MAX(ROUND((CAST(total_cases AS float)/Population )*100,2)) AS PopPercentageInfected
FROM PortfolioProject..CovidDeaths
--WHERE Location like '%states%'
GROUP BY Location, Population 
ORDER BY PopPercentageInfected DESC;

-- Pays ayant enregistré le + de décès
SELECT Location, MAX(CAST(total_deaths AS float )) AS TotalDeathCount
FROM PortfolioProject..CovidDeaths
--WHERE Location like '%states%'
WHERE continent IS NOT NULL
GROUP BY Location
ORDER BY TotalDeathCount DESC;

--Continents ayant enregistré le plus de décès
SELECT continent, MAX(CAST(total_deaths AS float )) AS TotalDeathCount
FROM PortfolioProject..CovidDeaths
--WHERE Location like '%states%'
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY TotalDeathCount DESC;

--Chiffres globaux
SELECT
	date,
    SUM(CAST(COALESCE(CAST(new_cases AS float), 0) AS float)) AS total_cases,
    SUM(CAST(COALESCE(CAST(new_deaths AS float), 0) AS float)) AS total_deaths,
    ROUND(SUM(CAST(COALESCE(CAST(new_deaths AS float), 0) AS float)) / NULLIF(SUM(CAST(COALESCE(CAST(new_cases AS float), 0) AS float)), 0) * 100,2) AS DeathPercentage
FROM
    PortfolioProject..CovidDeaths
WHERE
    continent IS NOT NULL
GROUP BY date
ORDER BY
    1,2 DESC;

-- Total Population vs Vaccinations
SELECT d.continent, d.location, d.date, d.population, v.new_vaccinations, 
	SUM(CONVERT(float,v.new_vaccinations)) OVER (PARTITION BY d.location ORDER BY d.location, d.date) AS Cumul_vacc
FROM PortfolioProject..CovidDeaths AS d
INNER JOIN PortfolioProject..CovidVaccinations AS v
ON d.location = v.location 
AND d.date = v.date
WHERE d.continent IS NOT NULL
ORDER BY 2,3;

-- Taux de Vaccinations dans la population
WITH PopsVac(continent, location, date, population, new_vaccinations, Cumul_vacc)
AS
(
SELECT d.continent, d.location, d.date, d.population, v.new_vaccinations, 
	SUM(CONVERT(float,v.new_vaccinations)) OVER (PARTITION BY d.location ORDER BY d.location, d.date) AS Cumul_vacc
FROM PortfolioProject..CovidDeaths AS d
INNER JOIN PortfolioProject..CovidVaccinations AS v
ON d.location = v.location 
AND d.date = v.date
WHERE d.continent IS NOT NULL
)
SELECT *, ROUND((Cumul_vacc/population)*100,2) AS Taux_vacc
FROM PopsVac;



-- Temp TABLE 

DROP Table if exists #PourcentPopuVacc 
Create Table #PourcentPopuVacc

(
Continent nvarchar(255),
Location nvarchar (255),
Date datetime,
Population float,
New_vaccinations float,
Cumul_vacc float
)

Insert into #PourcentPopuVacc

SELECT d.continent, d.location, d.date, d.population, v.new_vaccinations, 
	SUM(CONVERT(float,v.new_vaccinations)) OVER (PARTITION BY d.location ORDER BY d.location, d.date) AS Cumul_vacc
FROM PortfolioProject..CovidDeaths AS d
INNER JOIN PortfolioProject..CovidVaccinations AS v
ON d.location = v.location 
AND d.date = v.date
--WHERE d.continent IS NOT NULL
SELECT *, ROUND((Cumul_vacc/population)*100,2) AS Taux_vacc
FROM #PourcentPopuVacc;

-- Création de vue
CREATE VIEW PourcentPopuVacc AS 
SELECT d.continent, d.location, d.date, d.population, v.new_vaccinations, 
	SUM(CONVERT(float,v.new_vaccinations)) OVER (PARTITION BY d.location ORDER BY d.location, d.date) AS Cumul_vacc
FROM PortfolioProject..CovidDeaths AS d
INNER JOIN PortfolioProject..CovidVaccinations AS v
ON d.location = v.location 
AND d.date = v.date
WHERE d.continent IS NOT NULL
--ORDER BY 2,3;