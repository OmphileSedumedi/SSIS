

-- CREATE DB

CREATE DATABASE financial_transactions_db;

USE financial_transactions_db;
------------------------------------------------------------------------------------------
--CREATE TABLE

CREATE TABLE financial_transactions (

    transaction_id INT PRIMARY KEY,
    customer_id INT,
    supplier_name VARCHAR(50),
    transaction_date DATE,
    amount DECIMAL(10, 2),
    currency VARCHAR(10)
);

-- INSERT VALUES
INSERT INTO financial_transactions (
transaction_id, customer_id, supplier_name, transaction_date, amount, currency)
VALUES
    (1, 101, 'ABC Corp', '2024-01-15', 1000.00, 'USD'),
    (2, 102, 'XYZ Ltd', '2024-01-20', 1500.50, 'EUR'),
    (3, 103, 'Global Inc', '2024-02-05', 2000.00, 'GBP'),
    (4, 104, 'ABC Corp', '2024-02-10', 500.25, 'USD');

SELECT *
FROM [dbo].[financial_transactions]

------------------------------------------------------------------------------------------
--CREATE TABLE

CREATE TABLE customer_details (

    customer_id INT PRIMARY KEY,
    customer_name VARCHAR(50),
    email VARCHAR(100),
    phone VARCHAR(20)
);

-- INSERT VALUES

INSERT INTO customer_details (customer_id, customer_name, email, phone)

VALUES
    (101, 'John Doe', 'john.doe@example.com', '123-456-7890'),
    (102, 'Jane Smith', 'jane.smith@example.com', '234-567-8901'),
    (103, 'Mike Johnson', 'mike.johnson@example.com', '345-678-9012'),
    (104, 'Emily Davis', 'emily.davis@example.com', '456-789-0123');

SELECT *
FROM [dbo].[customer_details]
------------------------------------------------------------------------------------------

/*


Business Request

The business has customer purchase data in local currency, but needs that data converted and needs the Customer contact information with it.

The purchase data is in SQL Server, the currency conversion data is in Excel, and the customer contact information is in a csv file.

Your task is to bring this data together in a new SQL Server database for the business.

*/

------------------------------------------------------------------------------------------

-- dtsx in vs studio = data transformation services
-- Microsoft OLE DB Driver for SQL Server: newest one (use driver and not provider)
-- Microsoft OLE DB Provider for SQL Server: oldest one

------------------------------------------------------------------------------------------
--CREATING WAREHOUSE DESTINATION FOR ETL/ Data Warehouse Setup

-- Create Data Warehouse Database

CREATE DATABASE financial_data_warehouse;

-- Use Data Warehouse Database

USE financial_data_warehouse;

-- Create Financial Analysis Table in Data Warehouse

CREATE TABLE financial_analysis (
    transaction_id INT PRIMARY KEY,
    customer_name VARCHAR(50),
    supplier_name VARCHAR(50),
    transaction_date DATE,
    amount_usd DECIMAL(10, 2),
    supplier_phone VARCHAR(20)
);

------------------------------------------------------------------------------------------
-- MOVE FINANCIAL TRANSACTIONS TABLE OVER FROM FINANCIAL_TRANSACTIONS_DB TO FINANCIAL_DATA_WAREHOUSE
-- Right click on table-> Script table -> As Create
/*
USE [financial_data_warehouse]
GO

/****** Object:  Table [dbo].[financial_transactions]    Script Date: 9/24/2026 10:49:54 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[financial_transactions1](
	[transaction_id] [int] NOT NULL,
	[customer_id] [int] NULL,
	[supplier_name] [varchar](50) NULL,
	[transaction_date] [date] NULL,
	[amount] [decimal](10, 2) NULL,
	[currency] [varchar](10) NULL,
PRIMARY KEY CLUSTERED 
(
	[transaction_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
*/
USE [financial_data_warehouse]
GO

/****** Object:  Table [dbo].[financial_transactions]    Script Date: 9/16/2026 2:08:24 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[financial_transactions](
	[transaction_id] [int] NOT NULL,
	[customer_id] [int] NULL,
	[supplier_name] [varchar](50) NULL,
	[transaction_date] [date] NULL,
	[amount] [decimal](10, 2) NULL,
	[currency] [varchar](10) NULL,
PRIMARY KEY CLUSTERED 
(
	[transaction_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO


----- After SSIS Source to Destination Data move
SELECT * 
FROM [dbo].[financial_transactions];
-----
------------------------------------------------------------------------------------------
-- PROJECT CONNECTIONS

-- 1. Rename from Local Host to datbasesonly
-- 2. Right click on the connections, then convert to project connection
-- 3. This connection can be used across all packages

-- Creatiing data source with SQL Joins
USE [financial_transactions_db];


SELECT * 
FROM [dbo].[customer_details]

SELECT *
FROM [dbo].[financial_transactions]

/*
SELECT *
FROM [dbo].[financial_transactions] AS t
INNER JOIN [dbo].[customer_details] AS c 
ON t.customer_id = c.customer_id;
*/

-- Use the below query on SSIS --> click on source--> data access mode--> sql command 
SELECT t.*, c.customer_name, c.email AS customer_email, c.phone AS customer_phone
FROM [dbo].[financial_transactions] AS t
INNER JOIN [dbo].[customer_details] AS c 
ON t.customer_id = c.customer_id;

-- Add the columns that are not there in destination
USE [financial_data_warehouse]

ALTER TABLE [dbo].[financial_transactions]

ADD	
[customer_name] [varchar](50) NULL,
[customer_email] [varchar](100) NULL,
[customer_phone] [varchar](20) NULL

-- Now on SSIS no of columns from source = no of columns in destination

------------------------------------------------------------------------------------------

-- DEBUGGING COMMON DEVELOPMENT ERRORS

-- transaction_id is primary key in [dbo].[financial_transactions]
-- So we need to Truncate Destination Table before trying to load more data into it[To avoid loading records that are already loaded]

------------------------------------------------------------------------------------------
-- USING SCRIPT TASK IN CONTROL FLOW

TRUNCATE TABLE [dbo].[financial_transactions];

-- We want this to happen before our data flow run

SELECT * 
FROM [dbo].[financial_transactions]

------------------------------------------------------------------------------------------

-- CREATING FLAT FILE TABLES FOR ETL

USE [financial_data_warehouse]
 
-- CREATE EXCHANGE RATE TABLE
CREATE TABLE dbo.exchange_rates 
(
from_currency VARCHAR(10),
to_currency VARCHAR(10),
exchange_rate FLOAT,
effective_date DATE
)

-- CREATE SUPPLIERS TABLE

CREATE TABLE dbo.suppliers
(
supplier_id INT,
supplier_name VARCHAR(100),
contact_name VARCHAR(100),
phone VARCHAR(25)
)

------------------------------------------------------------------------------------------
-- IMPORTING EXCEL DATA(EXCHANGE RATES)

--SSIS : DataFlow Task -> Excel Source + OLE DB Destination to load data
------------------------------------------------------------------------------------------

-- DATA CONVERSION TECHNIQUES
-- Match the data types from excel with data types in the tables
-- SSIS: Use data conversion 
-- Change input columns from excel from unicode to string(varchar)
-- Change the Mappings with the updated columns
-- Take note of the length of the columns from tables vs length on SSIS data conversion

SELECT *
FROM [dbo].[financial_transactions]

SELECT *
FROM [dbo].[exchange_rates]

SELECT *
FROM [dbo].[suppliers]

------------------------------------------------------------------------------------------
-- IMPORTING CSV DATA(SUPPLIER DATA)
-- Text qualifier: when you have double quotes around your text

------------------------------------------------------------------------------------------
-- HANDLING DUPLICATE DATA

-- Truncate tables: only doing this because we are dealing with <5 rows
------------------------------------------------------------------------------------------
-- CURRENCY CONVERSION OVERVIEW

-- ADD amount_USD column

ALTER TABLE [dbo].[financial_transactions]
ADD amount_USD float;
------------------------------------------------------------------------------------------
-- CURRENCY CONVERSION USING CONTROL FLOW

------------------------------------------------------------------------------------------


-- CURRENCY CONVERSION USING LOOK UP IN THE  [Data Flow Task- Customer Transactions]

------------------------------------------------------------------------------------------
-- DEBUGGING CURRENCY CONVERSION WITH DATA VIEWER

-- Enable data viewer [right click on the arrow]shows the data when you run


------------------------------------------------------------------------------------------
-- HANDLING NO MATCHES OUTPUT FROM LOOKUP
/*
Derived column: connect the lookup to  derived column

Look up no match: head over to the derived column
*/


------------------------------------------------------------------------------------------
-- COMBINING DATA WITH UNION ALL
/*
Input 1 = matches from lookup
Input 2 = no matches from derived column
*/
    

------------------------------------------------------------------------------------------
-- DEBUGGING DATA TYPE ERRORS IN THE UNION ALL
/*
exchange rate data type in input 1 =dtr8
excahneg rate data type i input 2 = 4 byte signed integer
match the two by fixing input 2 data type
use type cast
*/
------------------------------------------------------------------------------------------
-- CALCULATING EXCHANGE RATES WITH DERIVED COLUMN

/*
Columns -> drag amount column to Expression editor * drag exchange_rate column
*/

------------------------------------------------------------------------------------------
-- TESTING LOOKUP WITH NO MATCH OUTPUT

/*
Go to financial_transaction_db 

Right click on the db

Edit Top 200 Rows

Change 4th Row Currency from USD to USDx

Go to Look up- exchange_rates -> General-> Specify how to handle rows with no matching entries-> Redirect rows to no match output

Go back to fix the data after testing - remove the X back USD
*/

SELECT *
FROM [dbo].[financial_transactions]

SELECT *
FROM [dbo].[exchange_rates]

SELECT *
FROM [dbo].[suppliers]
------------------------------------------------------------------------------------------
-- SUPPLIER DATA LOOKUP

/*

Alter table to add columns: 

*/


ALTER TABLE [dbo].[financial_transactions]
ADD [supplier_contact_name ] varchar(100)NULL,
	[supplier_phone] varchar(25) NULL;

------------------------------------------------------------------------------------------
-- ERROR HANDLING WITH MULTI CAST AND SPLIT

-- use multi cast: to send data in 2 directions

-- [dbo].[financial_transactions]> Right click > select top 200 rows

-- then rename one of the record under supplier_contact_name to test if the split works [make sure it's the database transactions table and not the warehouse]


