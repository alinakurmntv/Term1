-- Creating a new database for the World Cup project
CREATE DATABASE world_cup_project;
USE world_cup_project;

-- Creating the Tournaments table to store data about each tournament
CREATE TABLE Tournaments (
    TournamentID VARCHAR(10) PRIMARY KEY,  -- Unique identifier for each tournament
    Year INT,                              -- Year of the tournament
    HostCountry VARCHAR(50),               -- Country hosting the tournament
    Winner VARCHAR(50),                    -- Team that won the tournament
    NumberOfTeams INT,                     -- Number of teams participating
    GroupStage BOOLEAN,                    -- Indicator for group stage presence
    RoundOf16 BOOLEAN,                     -- Indicator for round of 16 stage presence
    QuarterFinals BOOLEAN,                 -- Indicator for quarter-finals stage presence
    SemiFinals BOOLEAN,                    -- Indicator for semi-finals stage presence
    Final BOOLEAN                          -- Indicator for the final match presence
);


-- Creating the Teams table to store information about each team
CREATE TABLE Teams (
    TeamID VARCHAR(10) PRIMARY KEY,       -- Unique identifier for each team
    TeamName VARCHAR(50),                 -- Full name of the team
    TeamCode VARCHAR(10),                 -- The code representing the team
    Confederation VARCHAR(50)             -- Confederation the team belongs to
);

-- Creating the Stadiums table to store data about stadiums used in tournaments
CREATE TABLE Stadiums (
    StadiumID VARCHAR(10) PRIMARY KEY,     -- Unique identifier for each stadium
    StadiumName VARCHAR(100),              -- Name of the stadium
    CityName VARCHAR(50),                  -- City where the stadium is located
    CountryName VARCHAR(50),               -- Country of the stadium
    StadiumCapacity INT                    -- Seating capacity of the stadium
);

-- Creating the Players table to store data about individual players
CREATE TABLE Players (
    PlayerID VARCHAR(10) PRIMARY KEY,       -- Unique identifier for each player
    FamilyName VARCHAR(50),                 -- Player's last name
    GivenName VARCHAR(50),                  -- Player's name
    GoalKeeper BOOLEAN,                     -- Indicator if the player is a goalkeeper
    Defender BOOLEAN,                       -- Indicator if the player is a defender
    Midfielder BOOLEAN,                     -- Indicator if the player is a midfielder
    Forward BOOLEAN,                        -- Indicator if the player is a forward
    CountTournaments INT                    -- Number of tournaments the player has participated in
);

-- Creating the Matches table to store details of each match in the tournament
CREATE TABLE Matches (
    MatchID VARCHAR(10) PRIMARY KEY,       -- Unique identifier for each match
    MatchDate DATE,                        -- Date of the match
    StadiumID VARCHAR(10),                 -- Stadium where the match was held
    HomeTeamID VARCHAR(10),                -- Team ID of the home team
    AwayTeamID VARCHAR(10),                -- Team ID of the away team
    TournamentID VARCHAR(10),              -- Tournament ID in which the match took place
    Stage VARCHAR(50),                     -- Stage of the tournament 
    HomeTeamScore INT,                     -- Score of the home team
    AwayTeamScore INT,                     -- Score of the away team
    Outcome VARCHAR(50),                   -- Outcome of the match 
    FOREIGN KEY (StadiumID) REFERENCES Stadiums(StadiumID),
    FOREIGN KEY (HomeTeamID) REFERENCES Teams(TeamID),
    FOREIGN KEY (AwayTeamID) REFERENCES Teams(TeamID),
    FOREIGN KEY (TournamentID) REFERENCES Tournaments(TournamentID)
);

-- Creating the Goals table to record details of each goal scored in a match
CREATE TABLE Goals (
    GoalID VARCHAR(10) PRIMARY KEY,        -- Unique identifier for each goal
    MatchID VARCHAR(10),                   -- Match in which the goal was scored
    PlayerID VARCHAR(10),                  -- Player who scored the goal
    TeamID VARCHAR(10),                    -- Team for which the goal was scored
    Minute INT,                            -- Minute in which the goal was scored
    MatchPeriod VARCHAR(50),               -- Period of the match 
    OwnGoal BOOLEAN,                       -- Indicator if the goal was an own goal
    Penalty BOOLEAN,                       -- Indicator if the goal was a penalty
    FOREIGN KEY (MatchID) REFERENCES Matches(MatchID),
    FOREIGN KEY (PlayerID) REFERENCES Players(PlayerID),
    FOREIGN KEY (TeamID) REFERENCES Teams(TeamID)
);

-- Creating the PlayerStatistics table to show player statistics
CREATE TABLE PlayerStatistics AS
SELECT 
    p.PlayerID,
    CONCAT(
        CASE WHEN p.GivenName = 'not applicable' THEN '' 
             ELSE CONCAT(p.GivenName, ' ')
        END,
        COALESCE(p.FamilyName, '')
    ) AS PlayerName,                      -- Concatenates given and family name of the player
    COUNT(g.GoalID) AS TotalGoals,         -- Total goals scored by the player
    COUNT(DISTINCT g.MatchID) AS Appearances, -- Number of matches played by the player
    CASE 
        WHEN p.GoalKeeper = 1 THEN 'GoalKeeper'
        WHEN p.Defender = 1 THEN 'Defender'
        WHEN p.Midfielder = 1 THEN 'Midfielder'
        WHEN p.Forward = 1 THEN 'Forward'
        ELSE 'Unknown'
    END AS Position,                       -- Position of the player on the field
    COALESCE(COUNT(g.GoalID) / NULLIF(COUNT(DISTINCT g.MatchID), 0), 0) AS AvgGoalsPerMatch -- Goals per match
FROM 
    Players p
LEFT JOIN 
    Goals g ON p.PlayerID = g.PlayerID
GROUP BY 
    p.PlayerID;

-- Adjusting the AvgGoalsPerMatch column to have decimal precision
ALTER TABLE PlayerStatistics MODIFY AvgGoalsPerMatch DECIMAL(5,4);

-- Query to retrieve top 10 scorers ordered by total goals
SELECT PlayerID, PlayerName, TotalGoals, Position, AvgGoalsPerMatch
FROM PlayerStatistics
ORDER BY TotalGoals DESC
LIMIT 10;

-- Creating the TeamPerformance table with the aggregated performance metrics for each team and tournament
CREATE TABLE TeamPerformance AS
SELECT 
    t.TeamID,
    t.TeamName,
    m.TournamentID,
    SUM(CASE 
        WHEN (m.HomeTeamID = t.TeamID AND m.Outcome = 'home team win') OR 
             (m.AwayTeamID = t.TeamID AND m.Outcome = 'away team win')
        THEN 1 ELSE 0 END) AS Wins,
    SUM(CASE 
        WHEN (m.HomeTeamID = t.TeamID AND m.Outcome = 'away team win') OR 
             (m.AwayTeamID = t.TeamID AND m.Outcome = 'home team win')
        THEN 1 ELSE 0 END) AS Losses,
    SUM(CASE WHEN m.Outcome = 'draw' THEN 1 ELSE 0 END) AS Draws,
    SUM(CASE WHEN m.HomeTeamID = t.TeamID THEN m.HomeTeamScore ELSE m.AwayTeamScore END) AS GoalsScored,
    SUM(CASE WHEN m.HomeTeamID = t.TeamID THEN m.AwayTeamScore ELSE m.HomeTeamScore END) AS GoalsConceded,
    SUM(CASE WHEN m.HomeTeamID = t.TeamID THEN (m.HomeTeamScore - m.AwayTeamScore)
             ELSE (m.AwayTeamScore - m.HomeTeamScore) END) AS GoalDifference,
    t.Confederation
FROM 
    Teams t
LEFT JOIN 
    Matches m ON t.TeamID = m.HomeTeamID OR t.TeamID = m.AwayTeamID
GROUP BY 
    t.TeamID, m.TournamentID;

-- Creating the TournamentSummary table with high-level tournament data
CREATE TABLE TournamentSummary AS
SELECT 
    t.TournamentID,
    t.Year,
    t.HostCountry,
    t.Winner,
    t.NumberOfTeams,
    SUM(t.GroupStage) AS GroupStage,
    SUM(t.RoundOf16) AS RoundOf16,
    SUM(t.QuarterFinals) AS QuarterFinals,
    SUM(t.SemiFinals) AS SemiFinals,
    SUM(t.Final) AS Final,
    COUNT(m.MatchID) AS TotalMatches,
    SUM(m.HomeTeamScore + m.AwayTeamScore) AS TotalGoals
FROM 
    Tournaments t
LEFT JOIN 
    Matches m ON t.TournamentID = m.TournamentID
GROUP BY 
    t.TournamentID;

 -- Procedure to refresh the PlayerStatistics table based on current data in the Goals table
DELIMITER //

CREATE PROCEDURE RefreshPlayerStatistics()
BEGIN
    DELETE FROM PlayerStatistics;
    INSERT INTO PlayerStatistics
    SELECT 
        p.PlayerID,
        CONCAT(COALESCE(p.GivenName, ''), ' ', COALESCE(p.FamilyName, '')) AS PlayerName,
        COUNT(g.GoalID) AS TotalGoals,
        COUNT(DISTINCT g.MatchID) AS Appearances,
        CASE 
            WHEN p.GoalKeeper = 1 THEN 'GoalKeeper'
            WHEN p.Defender = 1 THEN 'Defender'
            WHEN p.Midfielder = 1 THEN 'Midfielder'
            WHEN p.Forward = 1 THEN 'Forward'
            ELSE 'Unknown'
        END AS Position,
        IFNULL(COUNT(g.GoalID) / NULLIF(COUNT(DISTINCT g.MatchID), 0), 0) AS AvgGoalsPerMatch
    FROM 
        Players p
    LEFT JOIN 
        Goals g ON p.PlayerID = g.PlayerID
    GROUP BY 
        p.PlayerID;
END //
DELIMITER;

-- Procedure to refresh the TeamPerformance table with team-specific statistics
DELIMITER //
CREATE PROCEDURE RefreshTeamPerformance()
BEGIN
    DELETE FROM TeamPerformance;
    INSERT INTO TeamPerformance
    SELECT 
        t.TeamID,
        t.TeamName,
        m.TournamentID,
        SUM(CASE 
            WHEN (m.HomeTeamID = t.TeamID AND m.Outcome = 'home team win') OR 
                 (m.AwayTeamID = t.TeamID AND m.Outcome = 'away team win')
            THEN 1 ELSE 0 END) AS Wins,
        SUM(CASE 
            WHEN (m.HomeTeamID = t.TeamID AND m.Outcome = 'away team win') OR 
                 (m.AwayTeamID = t.TeamID AND m.Outcome = 'home team win')
            THEN 1 ELSE 0 END) AS Losses,
        SUM(CASE WHEN m.Outcome = 'draw' THEN 1 ELSE 0 END) AS Draws,
        SUM(CASE WHEN m.HomeTeamID = t.TeamID THEN m.HomeTeamScore ELSE m.AwayTeamScore END) AS GoalsScored,
        SUM(CASE WHEN m.HomeTeamID = t.TeamID THEN m.AwayTeamScore ELSE m.HomeTeamScore END) AS GoalsConceded,
        SUM(CASE WHEN m.HomeTeamID = t.TeamID THEN (m.HomeTeamScore - m.AwayTeamScore)
                 ELSE (m.AwayTeamScore - m.HomeTeamScore) END) AS GoalDifference,
        t.Confederation
    FROM 
        Teams t
    LEFT JOIN 
        Matches m ON t.TeamID = m.HomeTeamID OR t.TeamID = m.AwayTeamID
    GROUP BY 
        t.TeamID, m.TournamentID;
END //

DELIMITER;
-- Creating a procedure to refresh TournamentSummary data
DELIMITER //
CREATE PROCEDURE RefreshTournamentSummary()
BEGIN
    DELETE FROM TournamentSummary;
    INSERT INTO TournamentSummary
    SELECT 
        t.TournamentID,
        t.Year,
        t.HostCountry,
        t.Winner,
        t.NumberOfTeams,
        SUM(t.GroupStage) AS GroupStage,
        SUM(t.RoundOf16) AS RoundOf16,
        SUM(t.QuarterFinals) AS QuarterFinals,
        SUM(t.SemiFinals) AS SemiFinals,
        SUM(t.Final) AS Final,
        COUNT(m.MatchID) AS TotalMatches,
        SUM(m.HomeTeamScore + m.AwayTeamScore) AS TotalGoals
    FROM 
        Tournaments t
    LEFT JOIN 
        Matches m ON t.TournamentID = m.TournamentID
    GROUP BY 
        t.TournamentID;
END //

DELIMITER ;

-- Trigger to refresh PlayerStatistics when a new goal is inserted
DELIMITER //
CREATE TRIGGER AfterGoalInsert
AFTER INSERT ON Goals
FOR EACH ROW
BEGIN
    CALL RefreshPlayerStatistics();
END //
DELIMITER ;

-- Trigger to refresh PlayerStatistics when a new player is added
DELIMITER //
CREATE TRIGGER AfterPlayerInsert
AFTER INSERT ON Players
FOR EACH ROW
BEGIN
    CALL RefreshPlayerStatistics();
END //
DELIMITER ;

-- Trigger to refresh TournamentSummary when a new tournament is added
DELIMITER //
CREATE TRIGGER AfterTournamentInsert
AFTER INSERT ON Tournaments
FOR EACH ROW
BEGIN
    CALL RefreshTournamentSummary();
END //
DELIMITER ;

-- Creating views for analytical insights

-- TopScorers view to list the top 10 players by total goals
CREATE VIEW TopScorers AS
SELECT 
    CASE
        WHEN SUBSTRING_INDEX(PlayerName, ' ', 1) = 'not' AND SUBSTRING_INDEX(PlayerName, ' ', 2) = 'not applicable'
        THEN SUBSTRING_INDEX(PlayerName, ' ', -1)
        ELSE PlayerName
    END AS PlayerName,
    TotalGoals,
    Position,
    AvgGoalsPerMatch
FROM 
    PlayerStatistics
ORDER BY 
    TotalGoals DESC
LIMIT 10;

-- TeamWinRate view to calculate win percentage for each team by tournament
CREATE VIEW TeamWinRate AS
SELECT 
    TeamName,
    TournamentID,
    Wins,
    Losses,
    Draws,
    (Wins / NULLIF(Wins + Losses + Draws, 0)) * 100 AS WinPercentage
FROM 
    TeamPerformance
WHERE 
    Wins IS NOT NULL AND
    Losses IS NOT NULL AND
    Draws IS NOT NULL AND
    (Wins + Losses + Draws) > 0  -- Ensures the denominator in WinPercentage isn't zero
ORDER BY 
    TournamentID ASC,            -- Sorts by each tournament
    WinPercentage DESC;

-- TournamentOverview view to summarize tournament details
CREATE OR REPLACE VIEW TournamentOverview AS
SELECT 
    TournamentID,
    Year,
    HostCountry,
    Winner,
    NumberOfTeams,
    -- This is to replace NULL values in TotalMatches with "Data Missing"
    COALESCE(CAST(TotalMatches AS CHAR), 'Data Missing') AS TotalMatches,
    -- replacing NULL values in TotalGoals with "Data Missing"
    COALESCE(CAST(TotalGoals AS CHAR), 'Data Missing') AS TotalGoals
FROM 
    TournamentSummary
ORDER BY 
    Year;
CREATE TABLE MaterializedTopScorers AS
SELECT 
    CONCAT(
        CASE WHEN SUBSTRING_INDEX(PlayerName, ' ', 1) = 'not applicable' 
             THEN '' 
             ELSE SUBSTRING_INDEX(PlayerName, ' ', 1) 
        END,
        ' ',
        SUBSTRING_INDEX(PlayerName, ' ', -1)
    ) AS PlayerName,
    TotalGoals,
    Position,
    AvgGoalsPerMatch
FROM 
    PlayerStatistics
ORDER BY 
    TotalGoals DESC
LIMIT 10;


-- ConfederationPerformance view to summarize performance by confederation
CREATE VIEW ConfederationPerformance AS
SELECT 
    Confederation,
    SUM(Wins) AS TotalWins,
    SUM(Losses) AS TotalLosses,
    SUM(Draws) AS TotalDraws,
    SUM(GoalsScored) AS TotalGoalsScored,
    SUM(GoalsConceded) AS TotalGoalsConceded
FROM 
    TeamPerformance
GROUP BY 
    Confederation
ORDER BY 
    TotalWins DESC;

-- MaterializedTopScorers table to show top scorers
CREATE TABLE MaterializedTopScorers AS
SELECT 
    CASE
        WHEN SUBSTRING_INDEX(PlayerName, ' ', 1) = 'not' AND SUBSTRING_INDEX(PlayerName, ' ', 2) = 'not applicable'
        THEN SUBSTRING_INDEX(PlayerName, ' ', -1)
        ELSE PlayerName
    END AS PlayerName,
    TotalGoals,
    Position,
    AvgGoalsPerMatch
FROM 
    PlayerStatistics
ORDER BY 
    TotalGoals DESC
LIMIT 10;

-- An event to refresh the MaterializedTopScorers table daily
DELIMITER //
CREATE EVENT RefreshMaterializedTopScorers
ON SCHEDULE EVERY 1 DAY
DO
BEGIN
    TRUNCATE TABLE MaterializedTopScorers;
    INSERT INTO MaterializedTopScorers
    SELECT 
        PlayerName,
        TotalGoals,
        Position,
        AvgGoalsPerMatch
    FROM 
        PlayerStatistics
    ORDER BY 
        TotalGoals DESC
    LIMIT 10;
END //
DELIMITER ;

-- NOW LETS TEST THE DATA!

-- Checking the tables
SELECT COUNT(*) AS PlayerCount FROM Players;
SELECT COUNT(*) AS TeamCount FROM Teams;
SELECT COUNT(*) AS TournamentCount FROM Tournaments;
SELECT COUNT(*) AS StadiumCount FROM Stadiums;
SELECT COUNT(*) AS MatchCount FROM Matches;
SELECT COUNT(*) AS GoalCount FROM Goals;

-- test for missing foreign keys in Goal table
SELECT *
FROM Goals
WHERE MatchID IS NULL OR PlayerID IS NULL OR TeamID IS NULL;

-- test for missing foreign keys in Matches table
SELECT *
FROM Matches
WHERE StadiumID IS NULL OR HomeTeamID IS NULL OR AwayTeamID IS NULL OR TournamentID IS NULL;

-- test for view Topscorer and the same for other views
SELECT * FROM TopScorers;

-- test for ETL procedures and the same for other procedures 
CALL RefreshPlayerStatistics();
SELECT * FROM PlayerStatistics ORDER BY TotalGoals DESC LIMIT 10;

-- test for materialized view
TRUNCATE TABLE MaterializedTopScorers;
INSERT INTO MaterializedTopScorers
SELECT 
    CASE
        WHEN SUBSTRING_INDEX(PlayerName, ' ', 1) = 'not' THEN SUBSTRING_INDEX(PlayerName, ' ', -1)
        ELSE PlayerName
    END AS PlayerName,
    TotalGoals,
    Position,
    AvgGoalsPerMatch
FROM 
    PlayerStatistics
ORDER BY 
    TotalGoals DESC
LIMIT 10;

-- test MaterializedTopScorers for accuracy
SELECT * FROM MaterializedTopScorers;

-- insert the data and test for triggers 
INSERT INTO Goals (GoalID, MatchID, PlayerID, TeamID, Minute, MatchPeriod, OwnGoal, Penalty)
VALUES ('G-00001', 'M-TEST', 'P-00002', 'T-01', 45, 'first half', 0, 0);
SELECT * FROM PlayerStatistics WHERE PlayerID = 'P-00002';

-- clean 
DELETE FROM Goals WHERE GoalID = 'G-0001';

-- rerun all the pricedures
CALL RefreshPlayerStatistics();

-- FINISH! Thank you! 
