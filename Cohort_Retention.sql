---Cleaning Data
select distinct country from onlineRetails; --38

select distinct description from onlineRetails; 

select count(*) from onlineRetails; --541909 rows, 8 columns

--customers with no ID
select count(*) from onlineRetails
where CustomerID is null; --135080 with null IDs

-- some quantity values are negative, maybe returned items-assumption
-- need to remove records where quantity and unit price are less than zero

with 
online_retail AS
(
    select * from onlineRetails
    where CustomerID is not null
),
quantity_unitprice as
(
    select * from online_retail
    where Quantity > 0 and UnitPrice > 0
), --397884
---Duplicate check
duplicates_check as
(
    select *,ROW_NUMBER() over (partition by invoiceNo,stockcode,quantity order by InvoiceDate) duplicates
    from quantity_unitprice
) -- duplicated records = 4827
select *
into #online_retail_cleaned
from duplicates_check
where duplicates = 1 --clean data - 392669

-- Data is cleaned
-- Data analaysis starts from here
select * from #online_retail_cleaned;
    
-- Unique Identifier (customer ID)
-- initial start date( first invoice date)
-- Revenue Data

select min(invoiceDate) from #online_retail_cleaned;  -- dec 1st 2012 at 8:26am - first invoice date

-- Cohort Analysis
-- Retention analysis 

select 
CustomerID, 
min(InvoiceDate) as first_purchase_date,
DATEFROMPARTS(YEAR(MIN(InvoiceDate)),MONTH(min(InvoiceDate)),1) as cohort_date
into #cohort
from #online_retail_cleaned
GROUP by CustomerID;

select * from #cohort;

--create cohort index : is an integer representation of the number of months that has been passed since the customers first engagement/purchase
select mmm.*,
cohort_index = year_diff *12 + month_diff +1 
into #cohort_retention
from(
    select mm.*, 
    year_diff = invoice_year-cohort_year,
    month_diff = invoice_month - cohort_month
    from(
        select m.*,c.cohort_date,
        year(m.InvoiceDate) invoice_year,
        MONTH(m.InvoiceDate) invoice_month,
        YEAR(c.cohort_date) cohort_year,
        MONTH(c.cohort_date) cohort_month
        from #online_retail_cleaned as m
        left join #cohort as c
        on m.CustomerID = c.CustomerID
    )mm
)mmm
-- where CustomerID = 14733

select *
from #cohort_retention;

-- pivot data to see the cohort table 
select *
into #cohort_pivot
from 
(
    select distinct CustomerID,cohort_date,cohort_index
     from #cohort_retention
)table1
pivot(
   count(CustomerID)
   for cohort_index  IN ([1],[2],[3],[4],[5],[6],[7],[8],[9],[10],[11],[12],[13])
) as pivot_table
-- order by cohort_date;

-- convert to ratios
-- base month = 1

select * from #cohort_pivot;

select * ,1.0*[1]/[1]*100 as [1],
1.0*[2]/[1]*100 as [2],
1.0*[3]/[1]*100 as [3],
1.0*[4]/[1]*100 as [4],
1.0*[5]/[1]*100 as [5],
1.0*[6]/[1]*100 as [6],
1.0*[7]/[1]*100 as [7],
1.0*[8]/[1]*100 as [8],
1.0*[9]/[1]*100 as [9],
1.0*[10]/[1]*100 as [10],
1.0*[11]/[1]*100 as [11],
1.0*[12]/[1]*100 as [12],
1.0*[13]/[1]*100 as [13]
from #cohort_pivot
order by cohort_date;