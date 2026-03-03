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

An interactive Power BI Dashboard to track player and team key metrics thorughout season.

 
![Dashboard Preview](reports/Screenshot_of_player_dashboard.png)

# Database Schema

![NBA ERD](data/erd.png)

# Executive Summary


# Team Performance

![Dashboard Preview](reports/Screenshot_of_team_dashboard.png)

Excluding the January 25th game against the Warriors, the team’s offensive rating has been moderately stable, staying between 100 and 125. The excluded game looks to be a fluke night because all starters played full minutes and in the following game, they played the same Warriors team as part of a back-to-back improving their offensive rating to 101 from 82. Defensive ratings have been much more volatile with four peaks near 140 and multiple lows under 85. Considering the limited sample size, figure 3 below suggests confirmation of these claims. As expected, when playing average defenses, the Timberwolves score slightly more than when playing the league’s best defenses. When facing the top eight offenses the results split sharply. Against the league’s best teams that are top eight in both offense and defense they allow an average of 112.1 points but against elite offenses with weaker defenses they allow 16.6 more points per game. This inconsistency and the multitude of high defensive rating peaks suggest the team has the capability to be an elite defensive unit but not yet the consistency and warrants further exploration into how they got exposed and under what conditions they defend well in.

![Team Strength Buckets Table](reports/team__buckets_table.png)

Referring back to the lower section of the dashboard the team has been about average for creating possessions. There are no emergent trends in the number of offensive or defensive rebounds compared to opponents and the turnover margin seems to flip around 50%. As of now this is not an glaring issue because the offense is performing at a very high level. Since they do not dominate in total possessions and have a very volatile defense, there is a smaller margin for error making consistency required on the offensive side of the game.

# Player Performance 

