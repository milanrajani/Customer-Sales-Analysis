# Sales & Customer Data Analysis Portfolio

A comprehensive end-to-end data analysis project showcasing real-world analytics skills: data cleaning, SQL analysis, Python visualization, Excel reporting, and interactive Tableau dashboards.

## 📊 Project Overview

This project demonstrates a complete data analysis workflow using a realistic sales and customer dataset. It covers:

- **Data Exploration & Cleaning** — Identify quality issues, handle missing values, standardize formats
- **SQL Analysis** — Exploratory queries, data quality checks, RFM segmentation, cohort analysis
- **Python Analysis** — Pandas transformations, statistical analysis, visualization generation
- **Excel Reporting** — Formatted summary reports with embedded charts and KPIs
- **Tableau Dashboards** — Interactive visualizations for sales metrics and customer insights

## 🔧 Tech Stack

- **Python 3.9+** — Data processing (pandas, numpy, matplotlib, seaborn)
- **SQL** — Data exploration and analysis queries
- **Tableau** — Interactive dashboards
- **Excel** — Summary reporting (openpyxl)
- **Faker** — Synthetic data generation

## 📂 Folder Structure

```
data-analyst-portfolio/
├── data/
│   ├── raw/           # Source CSV files (customers, orders, products)
│   ├── processed/     # Cleaned data and analysis outputs
│   └── excel/         # Generated Excel reports
├── sql/
│   ├── 01_data_exploration.sql
│   ├── 02_data_cleaning.sql
│   ├── 03_advanced_analysis.sql
│   └── 04_dashboard_data.sql
├── python/
│   ├── 01_data_loading.py
│   ├── 02_data_cleaning.py
│   ├── 03_exploratory_analysis.py
│   ├── 04_visualization.py
│   └── utils.py
├── tableau/
│   ├── sales_dashboard.twbx
│   ├── customer_analysis.twbx
│   └── README_TABLEAU.md
├── excel/
│   └── README_EXCEL.md
├── docs/
│   ├── SETUP.md
│   ├── DATA_DICTIONARY.md
│   ├── ANALYSIS_GUIDE.md
│   └── INSIGHTS.md
├── README.md
├── requirements.txt
└── .gitignore
```

## 🚀 Quick Start

### 1. Setup Environment
```bash
# Create virtual environment
python -m venv venv
source venv/Scripts/activate  # Windows: venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt
```

### 2. Run Analysis Pipeline
```bash
# Execute scripts in order
python python/01_data_loading.py
python python/02_data_cleaning.py
python python/03_exploratory_analysis.py
python python/04_visualization.py
```

### 3. View Results
- **Excel Report**: Open `data/excel/sales_analysis.xlsx`
- **Tableau Dashboards**: Open `tableau/sales_dashboard.twbx` and `tableau/customer_analysis.twbx`
- **Documentation**: See `docs/INSIGHTS.md` for key findings

## 📋 Analysis Scope

### Data Volume
- **10,000+ Customers** with demographics and signup dates
- **50,000+ Orders** spanning 2022-2025
- **100+ Products** across multiple categories

### Key Metrics & Analyses
- **RFM Analysis** — Customer segmentation by Recency, Frequency, Monetary value
- **Customer Lifetime Value (LTV)** — Total spend per customer
- **Cohort Analysis** — Retention patterns by signup period
- **Product Performance** — Revenue, units sold, and category trends
- **Sales Trends** — Monthly and seasonal patterns
- **Geographic Analysis** — Sales by region/country

## 📖 Documentation

- **[SETUP.md](docs/SETUP.md)** — Detailed installation & execution guide
- **[DATA_DICTIONARY.md](docs/DATA_DICTIONARY.md)** — Field definitions for all data tables
- **[ANALYSIS_GUIDE.md](docs/ANALYSIS_GUIDE.md)** — Explanation of methodology and scripts
- **[INSIGHTS.md](docs/INSIGHTS.md)** — Key findings and business insights
- **[README_TABLEAU.md](tableau/README_TABLEAU.md)** — Tableau dashboard navigation
- **[README_EXCEL.md](excel/README_EXCEL.md)** — Excel workbook guide

## 🎯 Workflow

1. **Data Loading** (`01_data_loading.py`) — Ingest raw CSVs, inspect structure
2. **Data Cleaning** (`02_data_cleaning.py`) — Remove duplicates, standardize formats, handle outliers
3. **EDA** (`03_exploratory_analysis.py`) — Distributions, correlations, visualizations
4. **Analysis & Export** (`04_visualization.py`) — RFM, aggregations, Excel, Tableau prep

## ✅ Verification Checklist

- [ ] All Python scripts run without errors
- [ ] `data/processed/cleaned_data.csv` generated
- [ ] `data/excel/sales_analysis.xlsx` created with 4+ tabs
- [ ] Tableau files connect to data successfully
- [ ] All documentation matches actual folder structure

## 💡 Key Findings

See [docs/INSIGHTS.md](docs/INSIGHTS.md) for detailed analysis results including:
- Top customers by lifetime value
- Best-performing products and categories
- Seasonal sales patterns
- RFM segment distribution
- Customer retention trends

## 📝 Notes

- Synthetic data generated using Faker library for reproducibility
- All CSV files are version-controlled
- SQL queries provided for learning and reference
- Excel formulas preserve data lineage for transparency

---

**Created**: March 2026  
**Last Updated**: March 29, 2026  
**Portfolio Project**: Data Analysis & Business Intelligence
