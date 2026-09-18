# Central Regions Sales Analysis | SQL Server

## 📌 Project Overview

This project focuses on analyzing sales data from the Central Regions dataset using SQL Server. The goal is to transform raw sales data into a structured database and extract meaningful business insights related to sales, profit, customers, products, discounts, and orders.

## 🗄️ Database Design

The project uses a **Star Schema** consisting of:

- Customers
- Locations
- Products
- Orders
- Order Details

The schema was designed to organize the data efficiently and support analytical queries.

## 🛠️ Tools & Technologies

- SQL Server
- SQL Server Management Studio (SSMS)
- Excel

## 💻 SQL Concepts Used

Throughout the project, I applied:

- INNER JOIN
- LEFT JOIN
- RIGHT JOIN
- CTEs
- CASE Statements
- GROUP BY
- HAVING
- Aggregate Functions
- Subqueries
- Views
- Stored Procedures
- Window Functions
- Data Filtering & Aggregation

## 📊 Analysis Performed

The project explores several business questions, including:

- Which categories generate the highest profit?
- How does profit change over time?
- Which shipping modes contribute most to profit?
- Which products generate high sales but negative profit?
- How do discounts affect profitability?
- Which products and categories require further analysis?
- How do sales and profit vary across regions?

## 🔍 Key Insights

Some of the findings from the analysis include:

- Technology generated the highest profit contribution.
- Standard Class contributed the largest share of total profit.
- Some products had high sales but negative profit.
- Higher discounts were associated with negative-profit products in parts of the dataset.
- Sales performance and profitability do not always move together.

## 📁 Project Structure

```text
Central-Regions-SQL-Project/
│
├── README.md
├── Database/
│   └── Database_Schema.sql
│
├── Queries/
│   ├── Basic_Analysis.sql
│   ├── Advanced_Analysis.sql
│   ├── Views.sql
│   └── Stored_Procedures.sql
│
├── Images/
│   └── Star_Schema.png
│
└── Dataset/
    └── Central_Regions.xlsx
