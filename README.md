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

Screen shots of the interactive Power BI dashboard used to track key player and team performance metrics.

<div align="center">
  <img src="reports/Screenshot_of_team_dashboard.png" width="48%" />
  <img src="reports/Screenshot_of_player_dashboard.png" width="48%" />
</div>

# Database Schema


![NBA ERD](data/erd.png)


# Executive Summary


# Team Performance

<div align="center">
  <img src="reports/offense_defense_rating.png" width="75%" height="auto" />
</div>

  Excluding the January 25th game against the Warriors, the team’s offensive rating has been moderately stable, staying between 100 and 125 with an average distance from the mean of 10.8 points compare to a league average of 11.4. The excluded game looks to be a fluke night because all starters played full minutes and in the following game, they played the same Warriors team as part of a back-to-back improving their offensive rating to 101 from 82. Defensive ratings have been much more volatile with four peaks near 140, multiple lows under 85 and an average distance from the mean of 12.8 compared to the league average of 11.4. Considering the limited sample size, the figure below suggests confirmation of these claims. As expected, when playing average defenses, the Timberwolves score slightly more than when playing the league’s best defenses. When facing the top eight offenses the results split sharply. Against the league’s best teams that are top eight in both offense and defense they allow an average of 112.1 points but against elite offenses with weaker defenses they allow 16.6 more points per game. This inconsistency and the multitude of high defensive rating peaks suggest the team has the capability to be an elite defensive unit but not yet the consistency and warrants further exploration into how they got exposed and under what conditions they defend well in.


<div align="center">
  <img src="reports/team_bucket_table.png" width="75%" />
</div>


  The lower pannels of the dashboard indicates the teams possession creation metrics are nearly the same as the teams they play. There are no significant descreptencies in the number of offensive or defensive rebounds compared to opponents and the turnover margin seems to flip around 50%. As of now this is not an glaring issue because the offense is performing at a very high level. Since they do not dominate in total possessions and have a very volatile defense, there is a smaller margin for error making consistency required on the offensive side of the game.

  <div align="center">
  <img src="reports/reb_tov.png" width="75%" />
</div>

# Player Performance 

## Most Significant Contributers

  The team succeeds in multiple ways with many players making notable contributions. Despite the variety in player impact the typical starting five of DiVincenzo, Gobert, Randle, McDaniels and Edwards are the clearly most efficient, impactful players. Each player dominates in their own way with minimal overlap providing significant evidence the starting lineup has been consistently chosen correctly. 

 #### Anthony Edwards: leads category with his combination of scoring and disciplined defense 
 - Leads the team in scoring averaging seven more points a game than anyone else
 - Despite shooting 14 more shots a game than team average he is sixth in field goal percentage and third in 3-pt percentage
 - He’s the most impactful defender on the team averaging the second most steals and the most blocks of any guard while recording the lowest number of fouls for the starting five
 
<div align="center"> 
  <img src="reports/top_scorers.png" width="48%" /> 
  <img src="reports/steals_blocks_fouls.png" width="48%" /> 
</div> 

#### Donte DiVincenzo: Team’s most reliable player recording the highest plus minus of 5.2
- Impact is largely contributed to ball-security and routine correct decision making
- He averages 4.2 assists per game (Second on team), 2.8 assists for every turnover (Highest on team), records as many steals as turnovers (Highest on team)
- Point of Improvement: Below-average scoring efficiency relative to role, performing comparably to lower-rotation players despite being a primary scoring option

  <div align="center"> 
    <img src="reports/plus_minus.png" width="48%" /> 
    <img src="reports/donte_scatterplot.png" width="48%" /> 
  </div>


Although Rudy Gobert, Julius Randle, and Jaden McDaniels remain positively impactful and justify their starting roles, each has their own distinct limitations. Gobert provides strong defensive value, reflected in his 1.5 blocks per game, yet his offensive contribution is narrowly concentrated. Despite leading the team in shooting efficiency, his scoring volume remains comparatively low and he does not contribute from three points attempts, the most valuable shot in basketball. Randle leads the team in assists but also records the highest turnover rate and ranks near the top in fouls committed. McDaniels demonstrates consistent shooting efficiency, particularly from three point range, but commits the most fouls on the roster and ranks among the top five in turnovers while providing limited playmaking output.

## Impactful Substitutes

#### Naz Reid: productive rotational contributor with clear role-based tradeoffs

- Serves as the primary substitute for Gobert and Randle, maintaining moderate defensive activity recording 0.6 fewer blocks per game than Gobert, a gap that understates the broader defensive differential given Gobert’s elite standing relative to Reid’s more average profile
- Provides stronger perimeter shooting efficiency than either starter he replaces, expanding offensive spacing and contributing diversified scoring
- Commits roughly half the turnovers of Randle but also generates approximately half the assists, reflecting lower usage and playmaking responsibility
- Has performed efficiently in his current role; however, relative defensive impact and overall influence metrics do not currently justify elevation to a starting position

  <div align="center"> 
    <img src="reports/naz_blk_ast_tov.png" width="48%" /> 
    <img src="reports/naz_shootingpct.png" width="48%" /> 
  </div>

  #### Terrance Shannon Jr.: low-usage perimeter specialist with evidence for increased playing time

- Operates as a third-string substitute for McDaniels, averaging 11 minutes per game versus a team average of 17, suggesting potential for increased playing time
- Shoots efficiently from three point range, within 5 percentage points of the team’s top performer McDaniels
- Records low turnover (.6), assist (.6), steals(.3) and foul (1.5) rates — all materially below team averages indicating limited impact outside of shooting
- Negative plus minus differential is likely influenced by low lineup quality and garbage time minutes
- Contribution profile is narrowly concentrated in shooting efficiency, but his low-error production suggests scalability without introducing significant volatility

  <div align="center">
    <img src="reports/terrance_output.png" width="75%" /> 
  </div> 

#### Mike Conley: low-risk facilitator with limited scoring and defensive impact

- Functions as the primary substitute for DiVincenzo and provides strong ball retention, recording the lowest turnover rate (.6 per game) among players with significant minutes
- Ranks top five in assists, reinforcing his role as a stabilizing distributor
- However, he is the least efficient shooter on the roster while also shooting the least and rates below team average across defensive indicators
- Capable of maintaining operational stability, but extended usage may reduce overall efficiency due to limited scoring output and defensive contribution
  
  <div align="center">
    <img src="reports/competing_guards.png" width="48%" /> 
    <img src="reports/conely_donte_shooting.png" width="48%" /> 
  </div>

  #### Bones Hyland: statistically neutral reserve presence

- Serves as the substitute for Anthony Edwards without exhibiting strong separation in any single performance category
- Metrics cluster near team averages across efficiency, turnover rate, assist generation, and defensive indicators
- Does not materially elevate or depress overall performance, functioning primarily as a neutral replacement option

   <div align="center">
    <img src="reports/bones_output.png" width="75%" /> 
  </div> 


