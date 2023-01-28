
/*
		Cancer Data Exploration
		Personal Project

		Skills used:
					- View
					- Joins
					- Aggregate Functions
					- Window Functions with Partitions
					- Scalar Functions
					- Subqueries
					- Union
*/

-- 1. viewing table1 (CancerDeaths):

select		*
from		[dbo].[CancerDeaths]
order by	Entity, Year, Cancer


-- 2. viewing table2 (Population):

select		*
from		[dbo].[Population]
order by	Entity, Year


-- 3. adding the Population column to the Cancer Deaths table:
-- (using Join)

select		CD.*, P.Population
from		[dbo].[CancerDeaths]	as CD
join		[dbo].[Population]		as P
on			CD.Entity = P.Entity
and			CD.Year = P.Year
order by	CD.Entity, CD.Year, CD.Cancer


-- 4. adding a column that calculates the death percentage:

select		CD.*,
			P.Population,
			(CD.Deaths / (P.Population * 1000) * 100) as DeathPercentage
from		[dbo].[CancerDeaths]	as CD
join		[dbo].[Population]		as P
on			CD.Entity = P.Entity
and			CD.Year = P.Year
order by	CD.Entity, CD.Year, CD.Cancer


-- 5. turning the above query into a View for subsequent analysis:

drop view if exists CancerDeathsAndPopulation
create view CancerDeathsAndPopulation as
select		CD.*,
			P.Population,
			(CD.Deaths / (P.Population * 1000) * 100) as DeathPercentage
from		[dbo].[CancerDeaths]	as CD
join		[dbo].[Population]		as P
on			CD.Entity = P.Entity
and			CD.Year = P.Year


-- 6. looking at a certain country's data:

select		*
from		[dbo].[CancerDeathsAndPopulation]
where		Entity = 'Israel'


-- 7. looking at a certain country's data regarding a specific cancer type:

select		*
from		[dbo].[CancerDeathsAndPopulation]
where		Entity = 'Israel'
and			Cancer like '%Lung%'
order by	Year


-- 8. how many people died of <type of cancer> in <country> in <year>, and what percentage is it of its entire population?

select		Entity,
			Year,
			Cancer,
			Deaths,
			ROUND(DeathPercentage, 4) as DeathPercentage
from		[dbo].[CancerDeathsAndPopulation]
where		Entity = 'Israel'
and			Cancer = 'Tracheal, bronchus, and lung'
and			Year = 2016


-- 9. what percentage of the population died of <type of cancer> in <year>, in each country?

select		Entity,
			Year,
			Cancer,
			Deaths,
			ROUND(DeathPercentage, 4) as DeathPercentage
from		[dbo].[CancerDeathsAndPopulation]
where		Cancer = 'Breast'
and			Year = 2016
order by	Entity


-- 10. ranking all countries by death percentage of <type of cancer> in <year>:
-- using Window Function

select		Entity,
			Year,
			Cancer,
			Deaths,
			DeathPercentage,
			RANK() OVER (ORDER BY DeathPercentage desc) as DeathPercentageRanking
from		[dbo].[CancerDeathsAndPopulation]
where		Cancer = 'Stomach'
and			Year = 2016
and			DeathPercentage is not null
order by	DeathPercentage desc


-- 11. what is Israel's ranking, when ranking all countries by death percentage of <type of cancer> in <year>?
-- using Subquery and Window Function

select		*
from
	(			select		Entity,
							Year,
							Cancer,
							Deaths,
							DeathPercentage,
							RANK() OVER (ORDER BY DeathPercentage desc) as DeathPercentageRanking
				from		[dbo].[CancerDeathsAndPopulation]
				where		Cancer = 'Breast'
				and			Year = 2016
				and			DeathPercentage is not null
	)			as			RankingBreastCancerMortality
where		Entity = 'Israel'


-- 12. ranking cancer types by mortality in Israel (per year):
-- using Window Function with Partition

select		Entity,
			Year,
			Cancer,
			Deaths,
			DeathPercentage, 
			RANK() OVER (PARTITION BY Year ORDER BY DeathPercentage desc) as DeathPercentageRanking
from		[dbo].[CancerDeathsAndPopulation]
where		Entity = 'Israel'


-- 13. for each year, which 5 types of cancer have the highest mortality rates in Israel?
-- using Subquery and Window Function with Partition

select		Year,
			Cancer,
			DeathPercentageRanking
from
	(			select		Entity,
							Year,
							Cancer,
							Deaths,
							DeathPercentage, 
							RANK() OVER (PARTITION BY Year ORDER BY DeathPercentage desc) as DeathPercentageRanking
				from		[dbo].[CancerDeathsAndPopulation]
				where		Entity = 'Israel'
	)			as			RankingMortality
where		DeathPercentageRanking <= 5


-- 14. ranking cancer types by mortality, for each year, worldwide:
-- using Window Function with Partition

select		Entity,
			Year,
			Cancer,
			Deaths,
			RANK() OVER (PARTITION BY Year ORDER BY Deaths desc) as DeathPercentageRankingWW
from		[dbo].[CancerDeaths]
where		Entity = 'World'
order by	Entity, Year


-- 15. for each year, which 5 types of cancer have the highest mortality rates worldwide?
-- using Subquery and Window Function with Partition

select		Year,
			Cancer,
			DeathPercentageRankingWW
from
	(			select		Entity,
							Year,
							Cancer,
							Deaths,
							RANK() OVER (PARTITION BY Year ORDER BY Deaths desc) as DeathPercentageRankingWW
				from		[dbo].[CancerDeaths]
				where		Entity = 'World'
	)			as			RankingMortalityWorldwide
where		DeathPercentageRankingWW <= 5


-- 16. Liver cancer has one of the highest mortality rates worldwide, is it one of the highest ones in Israel as well?
-- using Subquery and window function with partition

select		*
from
	(			select		Entity,
							Year,
							Cancer,
							Deaths,
							DeathPercentage, 
							RANK() OVER (PARTITION BY Year ORDER BY DeathPercentage desc) as DeathPercentageRanking
				from		[dbo].[CancerDeathsAndPopulation]
				where		Entity = 'Israel'
	)			as			RankingMortalityIsrael
where		Cancer = 'Liver'

-- it's interesting: when looking at mortality rates across time, Liver cancer is constantly among the top 5 worldwide,
-- but in Israel it's only the 12th-14th.


-- 17. when did Pancreatic cancer first became one of the top 5 types of cancer in Israel (ranking by mortality rate)?
-- using Aggregate Function, Subquery, Window Function with Partition, Group By

select		min(Year) as Year,
			Cancer,
			DeathPercentageRanking
from
	(			select		*,
							RANK() OVER (PARTITION BY Year ORDER BY DeathPercentage desc) as DeathPercentageRanking
				from		[dbo].[CancerDeathsAndPopulation]
				where		Entity = 'Israel'
	)			as			RankingMortality
where		DeathPercentageRanking <= 5
and			Cancer = 'Pancreatic'
group by	DeathPercentageRanking, Cancer


-- 18. when did Stomach cancer stopped being one of the top 5 types of cancer in Israel (ranking by mortality rate)?
-- using Aggregate Function, Subquery, Window Function with Partition

select		max(Year) as Year,
			Cancer,
			DeathPercentageRanking
from
	(			select		*,
							RANK() OVER (PARTITION BY Year ORDER BY DeathPercentage desc) as DeathPercentageRanking
				from		[dbo].[CancerDeathsAndPopulation]
				where		Entity = 'Israel'
	)			as			RankingMortality
where		DeathPercentageRanking <= 5
and			Cancer = 'Stomach'
group by	DeathPercentageRanking, Cancer


-- 19. looking at Breast cancer ranking in Israel across the years:
-- using Subquery and Window Function with Partition

select		Entity,
			Cancer,
			Year,
			DeathPercentage,
			DeathPercentageRanking
from
	(			select		*,
							RANK() OVER (PARTITION BY Year ORDER BY DeathPercentage desc) as DeathPercentageRanking
				from		[dbo].[CancerDeathsAndPopulation]
				where		Entity = 'Israel'
	)			as			RankingMortality
where		Cancer = 'Breast'


-- 20. what were the highest and lowest death percentage of Breast Cancer in Israel across the years?
-- using Aggregate Functions

select		Max(DeathPercentage) as HighestDeathPercentage,
			Min(DeathPercentage) as LowestDeathPercentage
from		[dbo].[CancerDeathsAndPopulation]
where		Entity = 'Israel' and Cancer = 'Breast'


-- 21. in which years was the mortality rate of Breast cancer highest and lowest in Israel?
-- using Union, Subqueries and Aggregate Functions

select		Entity, Cancer, Year, DeathPercentage, 'Highest'
from		[dbo].[CancerDeathsAndPopulation]
where		DeathPercentage = (
				select		Max(DeathPercentage) as HighestDeathPercentage
				from		[dbo].[CancerDeathsAndPopulation]
				where		Entity = 'Israel' and Cancer = 'Breast')
union
select		Entity, Cancer, Year, DeathPercentage, 'Lowest'
from		[dbo].[CancerDeathsAndPopulation]
where		DeathPercentage = (
				select		Min(DeathPercentage) as HighestDeathPercentage
				from		[dbo].[CancerDeathsAndPopulation]
				where		Entity = 'Israel' and Cancer = 'Breast')


-- 22. how many people died of cancer each year worldwide?
-- using Aggregate Function

select		Entity, Year, sum(deaths) as CancerDeaths
from		[dbo].[CancerDeathsAndPopulation]
where		Entity = 'World'
group by	Year, Entity


-- 23. how many people die of cancer each year (on average) worldwide?
-- using Subquery and Aggregate Function

select		ROUND(AVG(CancerDeaths),0) as CancerDeathsYearlyAverageWW
from
	(			select		Entity,
							Year,
							SUM(deaths) as CancerDeaths
				from		[dbo].[CancerDeathsAndPopulation]
				where		Entity = 'World'
				group by	Year, Entity
	)			as			CancerDeathsByYearWW


-- 24. how many people died of cancer in Israel each year, and what percentage is it of the entire population?

select		Entity,
			Year,
			SUM(deaths) as CancerDeaths,
			SUM(DeathPercentage) as DeathPercentage
from		[dbo].[CancerDeathsAndPopulation]
where		Entity = 'Israel'
group by	Year, Entity


-- 25. double checking the previous query:
-- using Join, Subqueries, Aggregate functions

select		IsraelSumDeaths2016.*,
			IsraelPopulation2016.Population,
			SumDeaths/ (Population*1000) *100 as DeathPercentage
from
	(			select		Entity,
							Year,
							sum(Deaths) as SumDeaths
				from		[dbo].[CancerDeathsAndPopulation]
				where		Entity = 'Israel'
				and			Year = 2016
				group by	Entity, Year
	)			as			IsraelSumDeaths2016
join
	(			select		Entity,
							Year,
							Population
				from		[dbo].[Population]
				where		Entity = 'Israel'
				and			Year = 2016
	)			as			IsraelPopulation2016
on			IsraelSumDeaths2016.Entity	=	IsraelPopulation2016.Entity
and			IsraelSumDeaths2016.Year	=	IsraelPopulation2016.Year

