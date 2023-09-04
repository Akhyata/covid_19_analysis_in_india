create database project;
use project;

select * from state_covid_data;
select * from district_covid_data;
select * from  covid_timeseries_data ;

#removing data of states which are not in Inida present in covid_timeseries_data table -
delete from covid_timeseries_data where StateCode='TT' or StateCode='UN';


-- 1. Weekly evolution of number of confirmed cases, recovered cases, deaths, tests. For instance, 
        -- your dashboard should be able to compare Week 3 of May with Week 2 of August
with cte as(
select year(date) as year_, 
monthname(date) as month_name,
month(date) as month_, 
week(date) as week_number,
max(confirmed) as total_confirmed,
max(recovered) as total_recovered,
max(tested) as total_tests,
max(deceased) as total_death
from covid_timeseries_data
group by year_,month_name,month_,week_number
order by year_,month_,week_number
)
select year_,month_name,month_,week_number,
total_confirmed,total_recovered,total_tests,total_death
from cte
order by year_,month_,week_number;



-- - Let’s call `testing ratio(tr) = (number of tests done) / (population)`, 
-- now categorise every district in one of the following categories:
--     - Category A: 0.05 ≤ tr ≤ 0.1
--     - Category B: 0.1 < tr ≤ 0.3
--     - Category C: 0.3 < tr ≤ 0.5
--     - Category D: 0.5 < tr ≤ 0.75
--     - Category E: 0.75 < tr ≤ 1.0
--     
--     Now perform an analysis of number of deaths across all category. 
--     Example, what was the number / % of deaths in Category A district as compared for Category E districts

select * from district_covid_data;


with cte1 as 
(
select district_code, tested_total, deceased_total,population_meta,(tested_total/population_meta) as test_ratio  
from district_covid_data 
where tested_total <> 0 and population_meta <> 0
) ,cte2 as 
(
select *, case 
when  test_ratio > 0  and test_ratio <= 0.1 then 'Category A'
when  test_ratio > 0.1 and test_ratio <= 0.3 then 'Category B'
when  test_ratio > 0.3 and test_ratio <= 0.5 then 'Category C'
when  test_ratio > 0.5 and test_ratio <= 0.75 then  'Category D'
else 'Category E' end as Category from cte1 
where test_ratio < 1
order by district_code
)
select Category,
sum(deceased_total) as TotalDeaths,
(sum(deceased_total) * 100.0) / sum(sum(deceased_total)) over () as PercentageOfTotalDeaths
from cte2
group by  Category
order by  Category;



-- Compare delta7 confirmed cases with respect to vaccination
select * from district_covid_data;
with cte as 
(
select district_code, confirmed_delta7 , population_meta ,(vaccinated1_delta7 + vaccinated2_delta7) as Vaccinated 
from district_covid_data 
where confirmed_delta7 > 0 and population_meta>0
group by 1,2,3 
having  Vaccinated > 0 
) 
select *, Vaccinated/ population_meta * 100 as Vaccinaion_rate from cte ;

-- Compare delta7 confirmed cases with respect to only vaccination1
with cte as 
(
select district_code, confirmed_delta7 , population_meta , vaccinated1_delta7
from district_covid_data where  confirmed_delta7 > 0  and vaccinated1_delta7 > 0 and population_meta>0
) 
select *, vaccinated1_delta7/ population_meta * 100 as Vaccinaion_rate from cte ;

-- Compare delta7 confirmed cases with respect to only vaccination2
with cte as 
(
select district_code, confirmed_delta7 , population_meta , vaccinated2_delta7
from district_covid_data where  confirmed_delta7 > 0  and vaccinated2_delta7 > 0 and population_meta>0
) 
select *, vaccinated2_delta7/ population_meta * 100 as Vaccinaion_rate from cte ;


-- Categorise total number of confirmed cases in a state by Months and come 
#up with that one month which was worst for India in terms of number of cases
 
select * from covid_timeseries_data ;
select * from state_covid_data; 

with cte as 
(
select statecode,year(date) as yr,monthname(date) as mnth,
max(confirmed) as total_confirmed,dense_rank() over (order by max(confirmed) desc ) as rank_
from covid_timeseries_data 
group by 1,2,3
)
select statecode,yr,mnth from cte where rank_ = 1 ;
