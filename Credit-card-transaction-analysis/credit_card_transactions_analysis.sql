describe credit_card_transactions;
select * from credit_card_transactions limit 5;

Alter table credit_card_transactions
change `Card Type` card_type varchar(50);

Alter table credit_card_transactions
change `Exp Type` Exp_type varchar(50);

-- 1)  Write a query to print top 5 cities with highest spends and their percentage contribution of total credit card spends
SELECT 
    city,
    SUM(Amount) AS Spending,
    (SUM(Amount) / (SELECT SUM(Amount) FROM credit_card_transactions) * 100)
    AS '% of total spending'
FROM
    credit_card_transactions
GROUP BY City
ORDER BY Spending DESC
LIMIT 5;


-- 2)  Write a query to print highest spend month and amount spent in that month for each card type

with C as(
select card_type, Year, Month, sum(Amount) as monthly_spending,
dense_rank() over (partition by card_type order by sum(Amount) desc) as rank_
from credit_card_transactions
group by card_type, Month, Year)
select *
from C
where rank_=1;

-- 3) Write a query to print the transaction details (all columns from the table) for each card type 
-- when it reaches a cumulative of 1000000 total spends (We should have 4 rows in the o/p one 
-- for each card type) 
WITH CTE1 as(
select *, sum(Amount) over (partition by card_type order by Amount) cu_sum
from credit_card_transactions),
CTE2 as(
select *, dense_rank() over (partition by card_type order by cu_sum desc) as rank_
from CTE1
where cu_sum <= 1000000)
select *
from CTE2
where rank_ = 1;


-- 4) Write a query to find city which had lowest percentage spend for gold card type 
select City, sum(Amount) as spend,
sum(Amount) * 100 / (select sum(Amount) from credit_card_transactions) as goldcard_percentage_of_total
from credit_card_transactions
where card_type = 'Gold'
group by City
order by goldcard_percentage_of_total
limit 1;


-- 5)  Write a query to print 3 columns:  city, highest_expense_type , lowest_expense_type (example format : Delhi , Bills, Fuel) 
with CTE1 as(
select City, Exp_type, sum(Amount) as spend
from credit_card_transactions
group by City, Exp_type
order by City, spend),
CTE2 as(
select *, dense_rank() over (partition by City order by spend) as as_,
dense_rank() over (partition by City order by spend desc) as ds_
from CTE1)
select City,
MAX(CASE
	when as_ = 1 then Exp_type
    end) as lowest_expense_type,
MAX(case
	when ds_ = 1 then Exp_type
    end) as highest_expense_type
from CTE2
group by City;


-- 6) Write a query to find percentage contribution of spends by females for each expense type
with C as(
select Exp_type,
sum(CASE when Gender = 'F' then Amount end) as F_amt,
sum(Amount) as cat_amt
from credit_card_transactions
group by Exp_type)
select *, F_amt*100/cat_amt as percentage_from_F
from C;

-- 7) Which card and expense type combination saw highest month over month growth in Jan 2014
WITH CTE1 as(
select card_type, Exp_type, Year, sum(Amount) as curr_spend
from credit_card_transactions
where (Year=2014 and Month = 1) or (Year = 2013 and Month=12)
group by card_type, Exp_type, Year
order by Year, curr_spend),
CTE2 as(
select *, LAG(curr_spend) over (partition by card_type, Exp_type order by year, curr_spend) as prev_spend
from CTE1)
select card_type, Exp_type, Round(curr_spend - prev_spend)*100/prev_spend as mom 
from CTE2
order by mom desc
limit 1;

-- 8) Which city has highest total spend to total no of transactions ratio during weekends
SELECT City, ROUND(SUM(amount)/COUNT(AMOUNT), 2) AS ratio  
FROM credit_card_transactions
WHERE DAYOFWEEK(date) IN (1, 7)  
GROUP BY city
ORDER BY ratio DESC
LIMIT 1;  


-- 9) Which city took least number of days to reach its 500th transaction after the first transaction in that city
WITH CityTransactionDates AS (
    SELECT 
        City,
        Date,
        ROW_NUMBER() OVER (PARTITION BY City ORDER BY Date) AS t_number
    FROM 
        credit_card_transactions
),
City500thTransaction AS (
    SELECT 
        City,
        MIN(Date) AS first_transaction_date,
        MAX(CASE WHEN t_number = 500 THEN Date END) AS date_500th_transaction
    FROM 
        CitytransactionDates
    GROUP BY 
        City
),
CityDaysTo500thTransaction AS (
    SELECT 
        city,
        DATEDIFF(date_500th_transaction, first_transaction_date) AS days_to_500th
    FROM 
        City500thTransaction
    WHERE 
        date_500th_transaction IS NOT NULL
)

SELECT 
    City,
    days_to_500th
FROM 
    CityDaysTo500thTransaction
ORDER BY 
    days_to_500th
LIMIT 1;
