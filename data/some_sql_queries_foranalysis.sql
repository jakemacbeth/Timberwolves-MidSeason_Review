/* Lineup stats for all groups that played together for 
   more than 30 seconds */

SELECT
	lgl.game_id, 
    lgl.group_id,
    lgl.group_name, 
    lgl.opponent_team_id, 
    lgl.min, 
    lgl.plus_minus, 
    lgl.pts, 
    lgl.fgm, 
    lgl.fga, 
    lgl.fg_pct, 
    lgl.fg3m, 
    lgl.fg3a, 
    lgl.fg3_pct,
    lgl.ftm, 
    lgl.fta, 
    lgl.ft_pct, 
    lgl.reb, 
    lgl.ast, 
    lgl.tov, 
    lgl.stl,
    lgl.blk, 
    lgl.pf, 
    fg.home_team_id, 
    fg.away_team_id
FROM nba.lineup_game_logs lgl
JOIN nba.fact_games fg
ON lgl.game_id = fg.game_id
WHERE lgl.min >= 0.5
; 

/* Finding teams the Timberwolves have played during the season */

SELECT 
DISTINCT team.team_name, 
         team.team_id
FROM nba.dim_teams team
JOIN nba.lineup_game_logs lineup
	ON team.team_id = lineup.opponent_team_id
;

/* Finding teams the Timberwolves have not played yet this season */

SELECT 
DISTINCT team.team_name,
         team.team_id
FROM nba.dim_teams team
LEFT JOIN nba.lineup_game_logs lineup
	ON team.team_id = lineup.opponent_team_id
WHERE lineup.opponent_team_id IS NULL
;

/* Table of win percenage against opponent strength */

WITH team_szn AS (
  -- season-to-dateratings for every team
  SELECT
    season,
    team_id,
    AVG(off_rating) AS off_rtg_szn,
    AVG(def_rating) AS def_rtg_szn
  FROM nba.teambox_pergame
  WHERE season = '2025-26'  
  GROUP BY season, team_id
),
ranks AS (
  SELECT
    season,
    team_id,
    off_rtg_szn,
    def_rtg_szn,
    DENSE_RANK() OVER (PARTITION BY season ORDER BY off_rtg_szn DESC) AS off_rank,
    DENSE_RANK() OVER (PARTITION BY season ORDER BY def_rtg_szn ASC)  AS def_rank
  FROM team_szn
),
wolves_games AS (
  -- wolves games with opponent points to define W/L
  SELECT
    w.season,
    w.game_id,
    w.team_id,
    w.opponent_team_id,
    w.pts AS wolves_pts,
    o.pts AS opp_pts
  FROM nba.teambox_pergame w
  JOIN nba.teambox_pergame o
    ON o.season = w.season
   AND o.game_id   = w.game_id
   AND o.team_id   = w.opponent_team_id
  WHERE w.season = '2025-26'     
    AND w.team_id   = 1610612750     -- Wolves
),
labeled AS (
  SELECT
    g.*,
    (g.wolves_pts > g.opp_pts) AS is_win,
    (r.off_rank <= 8) AS opp_top8_off,
    (r.def_rank <= 8) AS opp_top8_def
  FROM wolves_games g
  JOIN ranks r
    ON r.season = g.season
   AND r.team_id   = g.opponent_team_id
)
SELECT
  CASE
    WHEN opp_top8_off AND opp_top8_def THEN 'Top8 Off / Top8 Def'
    WHEN opp_top8_off AND NOT opp_top8_def THEN 'Top8 Off / Bottom22 Def'
    WHEN NOT opp_top8_off AND opp_top8_def THEN 'Bottom22 Off / Top8 Def'
    ELSE 'Bottom22 Off / Bottom22 Def'
  END AS opp_bucket,
  COUNT(*) AS games,
  SUM(CASE WHEN is_win THEN 1 ELSE 0 END) AS wins,
  ROUND(100.0 * AVG(CASE WHEN is_win THEN 1.0 ELSE 0.0 END), 2) AS win_pct
FROM labeled
GROUP BY 1
ORDER BY 1
;

-- Top five scorers on the timberwovles

SELECT 
	dp.full_name
	ROUND(AVG(pg.pts):: as avg_pts, 
FROM playerbox_pergame pg
JOIN dim_players dp
	ON pg.player_id = dp.player_id
WHERE pg.team_id = 1610612750
limit 5



/* Wolves boxscores for games vs specific opponent strength buckets,
   with opponent team name + opponent off/def ranks */

WITH team_szn AS (
  SELECT
    season,
    team_id,
    AVG(off_rating) AS off_rtg_szn,
    AVG(def_rating) AS def_rtg_szn
  FROM nba.teambox_pergame
  WHERE season = '2025-26'
  GROUP BY season, team_id
),
ranks AS (
  SELECT
    season,
    team_id,
    off_rtg_szn,
    def_rtg_szn,
    DENSE_RANK() OVER (PARTITION BY season ORDER BY off_rtg_szn DESC) AS off_rank,
    DENSE_RANK() OVER (PARTITION BY season ORDER BY def_rtg_szn ASC)  AS def_rank
  FROM team_szn
),
wolves_games AS (
  SELECT
    w.season,
    w.game_id,
    w.team_id,
    w.opponent_team_id
  FROM nba.teambox_pergame w
  WHERE w.season = '2025-26'
    AND w.team_id = 1610612750  -- Wolves
),
labeled AS (
  SELECT
    g.season,
    g.game_id,
    g.opponent_team_id,
    r.off_rank,
    r.def_rank,
    CASE
      WHEN r.off_rank <= 8 AND r.def_rank <= 8 THEN 'Top8 Off / Top8 Def'
      WHEN r.off_rank <= 8 AND r.def_rank >  8 THEN 'Top8 Off / Bottom22 Def'
      ELSE NULL
    END AS opp_bucket
  FROM wolves_games g
  JOIN ranks r
    ON r.season = g.season
   AND r.team_id = g.opponent_team_id
  WHERE r.off_rank <= 8  
)
SELECT
  l.game_id,
  l.opp_bucket,
  l.off_rank,
  l.def_rank,
  dt.team_name AS opponent_team_name,
  w.*  
FROM labeled l
JOIN nba.teambox_pergame w
  ON w.season  = l.season
 AND w.game_id = l.game_id
 AND w.team_id = 1610612750
LEFT JOIN nba.dim_teams dt
  ON dt.team_id = l.opponent_team_id
WHERE l.opp_bucket IS NOT NULL
ORDER BY l.opp_bucket, l.game_id
;

/* Wolves opponents boxscores for games vs specific opponent strength buckets,
   with opponent team name + opponent off/def ranks */

WITH team_szn AS (
  SELECT
    season,
    team_id,
    AVG(off_rating) AS off_rtg_szn,
    AVG(def_rating) AS def_rtg_szn
  FROM nba.teambox_pergame
  WHERE season = '2025-26'
  GROUP BY season, team_id
),
ranks AS (
  SELECT
    season,
    team_id,
    off_rtg_szn,
    def_rtg_szn,
    DENSE_RANK() OVER (PARTITION BY season ORDER BY off_rtg_szn DESC) AS off_rank,
    DENSE_RANK() OVER (PARTITION BY season ORDER BY def_rtg_szn ASC)  AS def_rank
  FROM team_szn
),
wolves_games AS (
  SELECT
    w.season,
    w.game_id,
    w.team_id,
    w.opponent_team_id
  FROM nba.teambox_pergame w
  WHERE w.season = '2025-26'
    AND w.team_id = 1610612750
),
labeled AS (
  SELECT
    g.season,
    g.game_id,
    g.opponent_team_id,
    r.off_rank,
    r.def_rank,
    CASE
      WHEN r.off_rank <= 8 AND r.def_rank <= 8 THEN 'Top8 Off / Top8 Def'
      WHEN r.off_rank <= 8 AND r.def_rank > 8 THEN 'Top8 Off / Bottom22 Def'
      ELSE NULL
    END AS opp_bucket
  FROM wolves_games g
  JOIN ranks r
    ON r.season = g.season
   AND r.team_id = g.opponent_team_id
  WHERE r.off_rank <= 8
)

SELECT
  l.game_id,
  l.opp_bucket,
  l.off_rank,
  l.def_rank,
  dt.team_name AS opponent_team_name,


  (wolves.pts > opp.pts) AS wolves_win,

  opp.*   

FROM labeled l

JOIN nba.teambox_pergame opp
  ON opp.season = l.season
 AND opp.game_id = l.game_id
 AND opp.team_id = l.opponent_team_id

JOIN nba.teambox_pergame wolves
  ON wolves.season = l.season
 AND wolves.game_id = l.game_id
 AND wolves.team_id = 1610612750

LEFT JOIN nba.dim_teams dt
  ON dt.team_id = l.opponent_team_id

WHERE l.opp_bucket IS NOT NULL
ORDER BY l.opp_bucket, l.game_id
;
