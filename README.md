# Project Background

Insights and recommendations are provided on the following key areas:

- Team performance and points of further analysis
- Review of individual player performance quantifying significant contributers and points of improvement
- Hypothesis testing to test for Julius Randle and Naz Reid joint impact on team performance


Data is sourced from the nba api via a weekly scheduled batch ETL pipeline stored in a PGAdmin database. Utilized pythons built in logging library for error tracking.
Scripts/
  - create_core_tables.py creates tables used to store the data
  - weekly_run.py runs the scheduled pipeline
sql folder holds sql files for creating aggregations for visualizations and preperations to use in the analysis
src/db/schema holds sql files for table creation ran with the create_core_tables script
src/etl holds etl files used to extract data from the api and load into PGAdmin which are ran in the weekly_run script as well as an error handling script that sends errors to the PGAdmin database.

An interactive Tableau dashboard to track team and player performance can be found here [link].
 

# Database Schema

![NBA ERD](docs//GitHub/Timberwolves-MidSeason-Review/data/erd.png)
