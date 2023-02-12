--inspecting data

SELECT *
FROM SALES_PROJECT..[sales_data_sample]
--PortfolioProject..[CovidDeaths$]

--checking distinct values

SELECT DISTINCT STATUS 
FROM SALES_PROJECT..[sales_data_sample]  --nice to plot

SELECT DISTINCT YEAR_ID 
FROM SALES_PROJECT..[sales_data_sample]

SELECT DISTINCT PRODUCTLINE 
FROM SALES_PROJECT..[sales_data_sample]  --nice to plot


SELECT DISTINCT COUNTRY 
FROM SALES_PROJECT..[sales_data_sample]  --nice to plot


SELECT DISTINCT DEALSIZE
FROM SALES_PROJECT..[sales_data_sample]  --nice to plot


SELECT DISTINCT TERRITORY
FROM SALES_PROJECT..[sales_data_sample]  --nice to plot

SELECT DISTINCT MONTH_ID
FROM SALES_PROJECT..[sales_data_sample]
WHERE YEAR_ID=2003

--Grouping TOTAL SALES by Productline

SELECT PRODUCTLINE,SUM(SALES) as REVENUE
FROM SALES_PROJECT..[sales_data_sample]
GROUP BY PRODUCTLINE
ORDER BY 2 DESC

--Grouping TOTAL SALES by YEAR

SELECT YEAR_ID,SUM(SALES) REVENUE
FROM SALES_PROJECT..[sales_data_sample]
GROUP BY YEAR_ID
ORDER BY REVENUE DESC

--Grouping TOTAL SALES by DEALSIZE

SELECT DEALSIZE,SUM(SALES) REVENUE
FROM SALES_PROJECT..[sales_data_sample]
GROUP BY DEALSIZE
ORDER BY REVENUE DESC

--Finding the BEST month IN TERMS OF REVENUE for a particular year

SELECT MONTH_ID,SUM(SALES) REVENUE,COUNT(ORDERNUMBER) FREQUENCY
FROM SALES_PROJECT..[sales_data_sample]
WHERE YEAR_ID = 2003
GROUP BY MONTH_ID
ORDER BY REVENUE DESC

--FINDING WHICH PRODUCTLINE SALES HIGHEST IN THE BEST MONTH OF PARTICULAR YEAR

SELECT PRODUCTLINE,COUNT(PRODUCTLINE) FREQUENCY,SUM(SALES) REVENUE
FROM SALES_PROJECT..[sales_data_sample]
WHERE YEAR_ID = 2003 AND MONTH_ID = 11
GROUP BY PRODUCTLINE
ORDER BY FREQUENCY DESC

--FINDING THE BEST CUSTOMER
DROP TABLE IF EXISTS #RFM
;WITH RFM AS
(
SELECT 
      CUSTOMERNAME,
	  SUM(SALES) MoneytaryValue,
	  AVG(SALES) AvgMonetaryvalue,
	  COUNT(ORDERNUMBER) Frequency,
	  MAX(ORDERDATE) last_order_date,
	  (SELECT MAX(ORDERDATE) FROM SALES_PROJECT..[sales_data_sample]) max_order_date,
	  DATEDIFF(DD,MAX(ORDERDATE),(SELECT MAX(ORDERDATE) FROM SALES_PROJECT..[sales_data_sample])) RECENCY
FROM SALES_PROJECT..[sales_data_sample]
GROUP BY CUSTOMERNAME
),
RFM_CALC AS 
(
SELECT R.*,
     NTILE(4) OVER(ORDER BY RECENCY) RFM_RECENCY,
	 NTILE(4) OVER (ORDER BY FREQUENCY) RFM_FREQUENCY,
	 NTILE(4) OVER (ORDER BY AVGMONETARYVALUE) RFM_MONETARY
FROM RFM R
)
SELECT 
    C.*,RFM_RECENCY + RFM_FREQUENCY + RFM_MONETARY AS RFM_CELL,
	CAST(RFM_RECENCY AS VARCHAR) + CAST(RFM_FREQUENCY AS VARCHAR) + CAST(RFM_MONETARY AS VARCHAR) RFM_CELL_STRING
INTO #RFM
FROM RFM_CALC C

select CUSTOMERNAME , rfm_recency, rfm_frequency, rfm_monetary,
	case 
		when rfm_cell_string in (111, 112 , 121, 122, 123, 132, 211, 212, 114, 141) then 'lost_customers'  --lost customers
		when rfm_cell_string in (133, 134, 143, 244, 334, 343, 344, 144) then 'slipping away, cannot lose' -- (Big spenders who haven’t purchased lately) slipping away
		when rfm_cell_string in (311, 411, 331) then 'new customers'
		when rfm_cell_string in (222, 223, 233, 322) then 'potential churners'
		when rfm_cell_string in (323, 333,321, 422, 332, 432) then 'active' --(Customers who buy often & recently, but at low price points)
		when rfm_cell_string in (433, 434, 443, 444) then 'loyal'
	end rfm_segment

from #rfm

