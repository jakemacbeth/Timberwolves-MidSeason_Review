-- Game-level lineup performance table 
-- Stores how each lineup performed in each game
CREATE TABLE IF NOT EXISTS nba.lineup_game_logs (
    game_id VARCHAR(10) NOT NULL,
    season VARCHAR(7) NOT NULL,
    team_id INT NOT NULL,
    group_quantity INT NOT NULL,
    group_id TEXT NOT NULL,
    group_name TEXT NULL,
    -- Game context
    opponent_team_id INT NULL,
    is_home BOOLEAN NULL,
    game_date DATE NULL,
    -- Performance in this game
    min NUMERIC NULL,
    plus_minus INT NULL,
    -- Stats
    pts INT NULL,
    fgm INT NULL,
    fga INT NULL,
    fg_pct NUMERIC NULL,
    fg3m INT NULL,
    fg3a INT NULL,
    fg3_pct NUMERIC NULL,
    ftm INT NULL,
    fta INT NULL,
    ft_pct NUMERIC NULL,
    reb INT NULL,
    ast INT NULL,
    tov INT NULL,
    stl INT NULL,
    blk INT NULL,
    pf INT NULL,
    last_updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (game_id, team_id, group_id),
    CONSTRAINT fk_gamelineup_game FOREIGN KEY (game_id) REFERENCES nba.fact_games (game_id) ON DELETE CASCADE,
    CONSTRAINT fk_gamelineup_team FOREIGN KEY (team_id) REFERENCES nba.dim_teams (team_id)
);

-- Indexes for efficient queries
CREATE INDEX IF NOT EXISTS idx_gamelineups_team_season ON nba.lineup_game_logs (team_id, season);

CREATE INDEX IF NOT EXISTS idx_gamelineups_game ON nba.lineup_game_logs (game_id);

CREATE INDEX IF NOT EXISTS idx_gamelineups_date ON nba.lineup_game_logs (game_date);

CREATE INDEX IF NOT EXISTS idx_gamelineups_group ON nba.lineup_game_logs (group_id);

-- Index for finding games with specific players
CREATE INDEX IF NOT EXISTS idx_gamelineups_names ON nba.lineup_game_logs USING gin (to_tsvector ('english', group_name));

-- VIEWS FOR ANALYSIS
-- View: Lineup performance with opponent strength
CREATE OR REPLACE VIEW nba.vw_lineup_game_analysis AS
SELECT
    lg.*,
    CASE
        WHEN '-' || lg.group_id || '-' LIKE '%-1629675-%' THEN 1
        ELSE 0
    END AS has_reid,
    CASE
        WHEN '-' || lg.group_id || '-' LIKE '%-203944-%' THEN 1
        ELSE 0
    END AS has_randle,
    CASE
        WHEN '-' || lg.group_id || '-' LIKE '%-1630162-%' THEN 1
        ELSE 0
    END AS has_edwards,
    CASE
        WHEN '-' || lg.group_id || '-' LIKE '%-203497-%' THEN 1
        ELSE 0
    END AS has_gobert,
    CASE
        WHEN lg.min > 0 THEN lg.pts::NUMERIC / lg.min
    END AS pts_per_min,
    CASE
        WHEN lg.min > 0 THEN lg.plus_minus::NUMERIC / lg.min
    END AS pm_per_min,
    opp.full_name AS opponent_name,
    opp.abbreviation AS opponent_abbr,
    tb.pts AS team_pts,
    CASE
        WHEN tb.pts > opp_tb.pts THEN 'W'
        WHEN tb.pts < opp_tb.pts THEN 'L'
    END AS game_result,
    EXTRACT (
        MONTH
        FROM
            lg.game_date
    ) AS game_month,
    EXTRACT (
        DOW
        FROM
            lg.game_date
    ) AS game_dow, -- Day of week
    DENSE_RANK () OVER (
        PARTITION BY
            lg.team_id,
            lg.season
        ORDER BY
            lg.game_date
    ) AS game_number
FROM
    nba.lineup_game_logs lg
    LEFT JOIN nba.dim_teams opp ON lg.opponent_team_id = opp.team_id
    LEFT JOIN nba.teambox_pergame tb ON lg.game_id = tb.game_id
    AND lg.team_id = tb.team_id
    LEFT JOIN nba.teambox_pergame opp_tb ON lg.game_id = opp_tb.game_id
    AND lg.opponent_team_id = opp_tb.team_id;

-- View: Aggregate stats by lineup across games
CREATE OR REPLACE VIEW nba.vw_lineup_season_stats AS
SELECT
    team_id,
    season,
    group_quantity,
    group_id,
    group_name,
    -- Game counts
    COUNT(*) AS games_played,
    SUM(
        CASE
            WHEN plus_minus > 0 THEN 1
            ELSE 0
        END
    ) AS games_positive,
    -- Totals
    SUM(min) AS total_min,
    SUM(plus_minus) AS total_plus_minus,
    SUM(pts) AS total_pts,
    -- Averages
    AVG(min) AS avg_min_per_game,
    AVG(plus_minus) AS avg_plus_minus,
    SUM(plus_minus)::NUMERIC / NULLIF(SUM(min), 0) AS avg_pm_per_min,
    -- Variance (important for regression!)
    STDDEV(plus_minus) AS stddev_plus_minus,
    -- Context splits
    AVG(
        CASE
            WHEN is_home THEN plus_minus
            ELSE NULL
        END
    ) AS avg_pm_home,
    AVG(
        CASE
            WHEN NOT is_home THEN plus_minus
            ELSE NULL
        END
    ) AS avg_pm_away,
    -- Player flags
    MAX(
        CASE
            WHEN '-' || group_id || '-' LIKE '%-1629675-%' THEN 1
            ELSE 0
        END
    ) AS has_reid,
    MAX(
        CASE
            WHEN '-' || group_id || '-' LIKE '%-203944-%' THEN 1
            ELSE 0
        END
    ) AS has_randle
FROM
    nba.lineup_game_logs
GROUP BY
    team_id,
    season,
    group_quantity,
    group_id,
    group_name;
