-- Game-level lineup performance table 
-- Stores how each lineup performed in each game

DROP TABLE IF EXISTS nba.lineup_game_logs CASCADE;

CREATE TABLE nba.lineup_game_logs (
    game_id             VARCHAR(10)     NOT NULL,
    season              VARCHAR(7)      NOT NULL,
    team_id             INT             NOT NULL,
    group_quantity      INT             NOT NULL, 
    
    group_id            TEXT            NOT NULL,
    group_name          TEXT            NULL,    
    -- Game context
    opponent_team_id    INT             NULL,
    is_home             BOOLEAN         NULL,
    game_date           DATE            NULL,
    
    -- Performance in this game
    min                 NUMERIC         NULL,
    plus_minus          INT             NULL,
    
    -- Stats
    pts                 INT             NULL,
    fgm                 INT             NULL,
    fga                 INT             NULL,
    fg_pct              NUMERIC         NULL,
    
    fg3m                INT             NULL,
    fg3a                INT             NULL,
    fg3_pct             NUMERIC         NULL,  
    
    ftm                 INT             NULL,
    fta                 INT             NULL,
    ft_pct              NUMERIC         NULL,   
    
    reb                 INT             NULL,
    ast                 INT             NULL,
    tov                 INT             NULL,
    stl                 INT             NULL,
    blk                 INT             NULL,
    pf                  INT             NULL,
    
    last_updated_at     TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    
    PRIMARY KEY (game_id, team_id, group_id),
    
    CONSTRAINT fk_gamelineup_game
        FOREIGN KEY (game_id) REFERENCES nba.fact_games(game_id)
        ON DELETE CASCADE,
    
    CONSTRAINT fk_gamelineup_team
        FOREIGN KEY (team_id) REFERENCES nba.dim_teams(team_id)
);

-- Indexes for efficient queries
CREATE INDEX IF NOT EXISTS idx_gamelineups_team_season 
    ON nba.lineup_game_logs(team_id, season);

CREATE INDEX IF NOT EXISTS idx_gamelineups_game 
    ON nba.lineup_game_logs(game_id);

CREATE INDEX IF NOT EXISTS idx_gamelineups_date 
    ON nba.lineup_game_logs(game_date);

CREATE INDEX IF NOT EXISTS idx_gamelineups_group 
    ON nba.lineup_game_logs(group_id);

-- Index for finding games with specific players
CREATE INDEX IF NOT EXISTS idx_gamelineups_names 
    ON nba.lineup_game_logs USING gin(to_tsvector('english', group_name));



-- VIEWS FOR ANALYSIS


-- View: Lineup performance with opponent strength
CREATE OR REPLACE VIEW nba.vw_lineup_game_analysis AS
SELECT 
    lg.*,
    
    -- Add flags for specific players
    CASE WHEN lg.group_name LIKE '%Reid%' THEN 1 ELSE 0 END as has_reid,
    CASE WHEN lg.group_name LIKE '%Randle%' THEN 1 ELSE 0 END as has_randle,
    CASE WHEN lg.group_name LIKE '%Edwards%' THEN 1 ELSE 0 END as has_edwards,
    CASE WHEN lg.group_name LIKE '%Gobert%' THEN 1 ELSE 0 END as has_gobert,
    
    -- Calculate per-minute stats
    CASE WHEN lg.min > 0 THEN lg.pts::NUMERIC / lg.min ELSE 0 END as pts_per_min,
    CASE WHEN lg.min > 0 THEN lg.plus_minus::NUMERIC / lg.min ELSE 0 END as pm_per_min,
    
    -- Add opponent info
    opp.full_name as opponent_name,
    opp.abbreviation as opponent_abbr,
    
    -- Add team result (from teambox_pergame)
    tb.pts as team_pts,
    CASE 
        WHEN lg.is_home AND tb.pts > (SELECT pts FROM nba.teambox_pergame WHERE game_id = lg.game_id AND team_id = lg.opponent_team_id)
        THEN 'W'
        WHEN NOT lg.is_home AND tb.pts > (SELECT pts FROM nba.teambox_pergame WHERE game_id = lg.game_id AND team_id = lg.opponent_team_id)
        THEN 'W'
        ELSE 'L'
    END as game_result,
    
    -- Time variables for trend analysis
    EXTRACT(MONTH FROM lg.game_date) as game_month,
    EXTRACT(DOW FROM lg.game_date) as game_dow,  -- Day of week
    ROW_NUMBER() OVER (PARTITION BY lg.team_id, lg.season ORDER BY lg.game_date) as game_number
    
FROM nba.lineup_game_logs lg
LEFT JOIN nba.dim_teams opp ON lg.opponent_team_id = opp.team_id
LEFT JOIN nba.teambox_pergame tb ON lg.game_id = tb.game_id AND lg.team_id = tb.team_id;


-- View: Aggregate stats by lineup across games
CREATE OR REPLACE VIEW nba.vw_lineup_season_stats AS
SELECT 
    team_id,
    season,
    group_quantity,
    group_id,
    group_name,
    
    -- Game counts
    COUNT(*) as games_played,
    SUM(CASE WHEN plus_minus > 0 THEN 1 ELSE 0 END) as games_positive,
    
    -- Totals
    SUM(min) as total_min,
    SUM(plus_minus) as total_plus_minus,
    SUM(pts) as total_pts,
    
    -- Averages
    AVG(min) as avg_min_per_game,
    AVG(plus_minus) as avg_plus_minus,
    AVG(CASE WHEN min > 0 THEN plus_minus::NUMERIC / min ELSE 0 END) as avg_pm_per_min,
    
    -- Variance (important for regression!)
    STDDEV(plus_minus) as stddev_plus_minus,
    
    -- Context splits
    AVG(CASE WHEN is_home THEN plus_minus ELSE NULL END) as avg_pm_home,
    AVG(CASE WHEN NOT is_home THEN plus_minus ELSE NULL END) as avg_pm_away,
    
    -- Player flags
    MAX(CASE WHEN group_name LIKE '%Reid%' THEN 1 ELSE 0 END) as has_reid,
    MAX(CASE WHEN group_name LIKE '%Randle%' THEN 1 ELSE 0 END) as has_randle
    
FROM nba.lineup_game_logs
GROUP BY team_id, season, group_quantity, group_id, group_name;


COMMENT ON TABLE nba.lineup_game_logs IS 
'Game-by-game lineup performance. Enables regression analysis, time-series, and controlling for confounders like opponent strength.';

COMMENT ON VIEW nba.vw_lineup_game_analysis IS
'Enriched lineup game data with opponent info, game results, and calculated metrics for analysis.';

COMMENT ON VIEW nba.vw_lineup_season_stats IS
'Aggregated lineup stats across games. Includes variance metrics needed for statistical modeling.';