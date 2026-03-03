-- Data validation script

-- Row counts 

SELECT 'dim_players' AS table_name, COUNT(*) FROM nba.dim_players
UNION ALL SELECT 'fact_games', COUNT(*) FROM nba.fact_games
UNION ALL SELECT 'playerbox_pergame', COUNT(*) FROM nba.playerbox_pergame
UNION ALL SELECT 'teambox_pergame', COUNT(*) FROM nba.teambox_pergame
UNION ALL SELECT 'lineup_game_logs', COUNT(*) FROM nba.lineup_game_logs
;

-- dim players nulls and blanks count

SELECT
  SUM((player_id IS NULL)::int) AS player_id_nulls,
  SUM((full_name IS NULL)::int) AS full_name_nulls,
  SUM((first_name IS NULL)::int) AS first_name_nulls,
  SUM((last_name IS NULL)::int) AS last_name_nulls,
  SUM((is_active IS NULL)::int) AS is_active_nulls,
  SUM((last_updated_at IS NULL)::int) AS last_updated_at_nulls
FROM nba.dim_players
;

SELECT COUNT(*) AS blank_full_name_rows
FROM nba.dim_players
WHERE full_name IS NULL OR btrim(full_name) = ''
;

-- fact games missing values check

SELECT
  SUM((game_id IS NULL)::int) AS game_id_nulls,
  SUM((season IS NULL)::int) AS season_nulls,
  SUM((game_date IS NULL)::int) AS game_date_nulls,
  SUM((home_team_id IS NULL)::int) AS home_team_id_nulls,
  SUM((away_team_id IS NULL)::int) AS away_team_id_nulls,
  SUM((last_updated_at IS NULL)::int) AS last_updated_at_nulls
FROM nba.fact_games
;

-- playerbox pergame missing values check

SELECT
  SUM((game_id IS NULL)::int) AS game_id_nulls,
  SUM((player_id IS NULL)::int) AS player_id_nulls,
  SUM((team_id IS NULL)::int) AS team_id_nulls,
  SUM((season IS NULL)::int) AS season_nulls,
  SUM((is_home IS NULL)::int) AS is_home_nulls,
  SUM((opponent_team_id IS NULL)::int) AS opponent_team_id_nulls,
  SUM((pts IS NULL)::int) AS pts_nulls,
  SUM((minutes IS NULL)::int) AS minutes_nulls,
  SUM((fgm IS NULL)::int) AS fgm_nulls,
  SUM((fga IS NULL)::int) AS fga_nulls,
  SUM((fg3m IS NULL)::int) AS fg3m_nulls,
  SUM((fg3a IS NULL)::int) AS fg3a_nulls,
  SUM((ftm IS NULL)::int) AS ftm_nulls,
  SUM((fta IS NULL)::int) AS fta_nulls,
  SUM((reb IS NULL)::int) AS reb_nulls,
  SUM((ast IS NULL)::int) AS ast_nulls,
  SUM((tov IS NULL)::int) AS tov_nulls,
  SUM((stl IS NULL)::int) AS stl_nulls,
  SUM((blk IS NULL)::int) AS blk_nulls,
  SUM((pf IS NULL)::int) AS pf_nulls,
  SUM((plus_minus IS NULL)::int) AS plus_minus_nulls,
  SUM((last_updated_at IS NULL)::int) AS last_updated_at_nulls
FROM nba.playerbox_pergame
;

-- teambox pergame missing values check

SELECT
  SUM((game_id IS NULL)::int) AS game_id_nulls,
  SUM((team_id IS NULL)::int) AS team_id_nulls,
  SUM((season IS NULL)::int) AS season_nulls,
  SUM((is_home IS NULL)::int) AS is_home_nulls,
  SUM((opponent_team_id IS NULL)::int) AS opponent_team_id_nulls,
  SUM((minutes IS NULL)::int) AS minutes_nulls,
  SUM((pts IS NULL)::int) AS pts_nulls,
  SUM((fgm IS NULL)::int) AS fgm_nulls,
  SUM((fga IS NULL)::int) AS fga_nulls,
  SUM((fg3m IS NULL)::int) AS fg3m_nulls,
  SUM((fg3a IS NULL)::int) AS fg3a_nulls,
  SUM((ftm IS NULL)::int) AS ftm_nulls,
  SUM((fta IS NULL)::int) AS fta_nulls,
  SUM((reb IS NULL)::int) AS reb_nulls,
  SUM((ast IS NULL)::int) AS ast_nulls,
  SUM((tov IS NULL)::int) AS tov_nulls,
  SUM((stl IS NULL)::int) AS stl_nulls,
  SUM((blk IS NULL)::int) AS blk_nulls,
  SUM((pf IS NULL)::int) AS pf_nulls,
  SUM((off_rating IS NULL)::int) AS off_rating_nulls,
  SUM((def_rating IS NULL)::int) AS def_rating_nulls,
  SUM((net_rating IS NULL)::int) AS net_rating_nulls,
  SUM((pace IS NULL)::int) AS pace_nulls,
  SUM((ts_pct IS NULL)::int) AS ts_pct_nulls,
  SUM((last_updated_at IS NULL)::int) AS last_updated_at_nulls
FROM nba.teambox_pergame;

-- lineup game logs missing values check

SELECT
  SUM((game_id IS NULL)::int) AS game_id_nulls,
  SUM((season IS NULL)::int) AS season_nulls,
  SUM((team_id IS NULL)::int) AS team_id_nulls,
  SUM((group_quantity IS NULL)::int) AS group_quantity_nulls,
  SUM((group_id IS NULL)::int) AS group_id_nulls,
  SUM((group_name IS NULL)::int) AS group_name_nulls,
  SUM((opponent_team_id IS NULL)::int) AS opponent_team_id_nulls,
  SUM((is_home IS NULL)::int) AS is_home_nulls,
  SUM((game_date IS NULL)::int) AS game_date_nulls,
  SUM((plus_minus IS NULL)::int) AS plus_minus_nulls,
  SUM((pts IS NULL)::int) AS pts_nulls,
  SUM((fgm IS NULL)::int) AS fgm_nulls,
  SUM((fga IS NULL)::int) AS fga_nulls,
  SUM((fg3m IS NULL)::int) AS fg3m_nulls,
  SUM((fg3a IS NULL)::int) AS fg3a_nulls,
  SUM((ftm IS NULL)::int) AS ftm_nulls,
  SUM((fta IS NULL)::int) AS fta_nulls,
  SUM((reb IS NULL)::int) AS reb_nulls,
  SUM((ast IS NULL)::int) AS ast_nulls,
  SUM((tov IS NULL)::int) AS tov_nulls,
  SUM((stl IS NULL)::int) AS stl_nulls,
  SUM((blk IS NULL)::int) AS blk_nulls,
  SUM((pf IS NULL)::int) AS pf_nulls,
  SUM((last_updated_at IS NULL)::int) AS last_updated_at_nulls
FROM nba.lineup_game_logs;

SELECT COUNT(*) AS blank_group_name_rows
FROM nba.lineup_game_logs
WHERE group_name IS NULL OR btrim(group_name) = ''
;

-- duplicate checks

-- dim_players
SELECT player_id, COUNT(*) cnt
FROM nba.dim_players
GROUP BY player_id
HAVING COUNT(*) > 1
;

-- fact_games
SELECT game_id, COUNT(*) cnt
FROM nba.fact_games
GROUP BY game_id
HAVING COUNT(*) > 1
;

-- playerbox_pergame 
SELECT game_id, player_id, COUNT(*) cnt
FROM nba.playerbox_pergame
GROUP BY game_id, player_id
HAVING COUNT(*) > 1
;

-- teambox_pergame
SELECT game_id, team_id, COUNT(*) cnt
FROM nba.teambox_pergame
GROUP BY game_id, team_id
HAVING COUNT(*) > 1
;

-- lineup_game_logs 
SELECT game_id, team_id, group_id, COUNT(*) cnt
FROM nba.lineup_game_logs
GROUP BY game_id, team_id, group_id
HAVING COUNT(*) > 1
;

-- referential integrity

-- playerbox -> dim_players
SELECT pb.player_id, COUNT(*) rows_affected
FROM nba.playerbox_pergame pb
LEFT JOIN nba.dim_players dp ON dp.player_id = pb.player_id
WHERE dp.player_id IS NULL
GROUP BY pb.player_id
;

-- playerbox -> fact_games
SELECT pb.game_id, COUNT(*) rows_affected
FROM nba.playerbox_pergame pb
LEFT JOIN nba.fact_games fg ON fg.game_id = pb.game_id
WHERE fg.game_id IS NULL
GROUP BY pb.game_id
;

-- teambox -> fact_games
SELECT tb.game_id, COUNT(*) rows_affected
FROM nba.teambox_pergame tb
LEFT JOIN nba.fact_games fg ON fg.game_id = tb.game_id
WHERE fg.game_id IS NULL
GROUP BY tb.game_id
;

-- lineup -> fact_games
SELECT lgl.game_id, COUNT(*) rows_affected
FROM nba.lineup_game_logs lgl
LEFT JOIN nba.fact_games fg ON fg.game_id = lgl.game_id
WHERE fg.game_id IS NULL
GROUP BY lgl.game_id
;

-- numeric logic checks

-- playerbox_pergame
SELECT *
FROM nba.playerbox_pergame
WHERE fgm > fga OR fg3m > fg3a OR ftm > fta
   OR fgm < 0 OR fga < 0 OR fg3m < 0 OR fg3a < 0 OR ftm < 0 OR fta < 0
   OR pts < 0 OR reb < 0 OR ast < 0 OR tov < 0 OR stl < 0 OR blk < 0 OR pf < 0
   ;

-- teambox_pergame
SELECT *
FROM nba.teambox_pergame
WHERE fgm > fga OR fg3m > fg3a OR ftm > fta
   OR fgm < 0 OR fga < 0 OR fg3m < 0 OR fg3a < 0 OR ftm < 0 OR fta < 0
   OR pts < 0 OR reb < 0 OR ast < 0 OR tov < 0 OR stl < 0 OR blk < 0 OR pf < 0
   ;

-- lineup_game_logs
SELECT *
FROM nba.lineup_game_logs
WHERE fgm > fga OR fg3m > fg3a OR ftm > fta
   OR fgm < 0 OR fga < 0 OR fg3m < 0 OR fg3a < 0 OR ftm < 0 OR fta < 0
   OR pts < 0 OR reb < 0 OR ast < 0 OR tov < 0 OR stl < 0 OR blk < 0 OR pf < 0
   ;

