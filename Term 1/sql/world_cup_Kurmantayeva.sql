CREATE DATABASE world_cup_project;
USE world_cup_project;

CREATE TABLE Tournaments (
    TournamentID VARCHAR(10) PRIMARY KEY,
    Year INT,
    HostCountry VARCHAR(50),
    Winner VARCHAR(50),
    NumberOfTeams INT,
    GroupStage BOOLEAN,
    RoundOf16 BOOLEAN,
    QuarterFinals BOOLEAN,
    SemiFinals BOOLEAN,
    Final BOOLEAN
);

CREATE TABLE Teams (
    TeamID VARCHAR(10) PRIMARY KEY,
    TeamName VARCHAR(50),
    TeamCode VARCHAR(10),
    Confederation VARCHAR(50)
);

CREATE TABLE Stadiums (
    StadiumID VARCHAR(10) PRIMARY KEY,
    StadiumName VARCHAR(100),
    CityName VARCHAR(50),
    CountryName VARCHAR(50),
    StadiumCapacity INT
);

CREATE TABLE Players (
    PlayerID VARCHAR(10) PRIMARY KEY,
    FamilyName VARCHAR(50),
    GivenName VARCHAR(50),
    GoalKeeper BOOLEAN,
    Defender BOOLEAN,
    Midfielder BOOLEAN,
    Forward BOOLEAN,
    CountTournaments INT
);

CREATE TABLE Matches (
    MatchID VARCHAR(10) PRIMARY KEY,
    MatchDate DATE,
    StadiumID VARCHAR(10),
    HomeTeamID VARCHAR(10),
    AwayTeamID VARCHAR(10),
    TournamentID VARCHAR(10),
    Stage VARCHAR(50),
    HomeTeamScore INT,
    AwayTeamScore INT,
    Outcome VARCHAR(50),
    FOREIGN KEY (StadiumID) REFERENCES Stadiums(StadiumID),
    FOREIGN KEY (HomeTeamID) REFERENCES Teams(TeamID),
    FOREIGN KEY (AwayTeamID) REFERENCES Teams(TeamID),
    FOREIGN KEY (TournamentID) REFERENCES Tournaments(TournamentID)
);

CREATE TABLE Goals (
    GoalID VARCHAR(10) PRIMARY KEY,
    MatchID VARCHAR(10),
    PlayerID VARCHAR(10),
    TeamID VARCHAR(10),
    Minute INT,
    MatchPeriod VARCHAR(50),
    OwnGoal BOOLEAN,
    Penalty BOOLEAN,
    FOREIGN KEY (MatchID) REFERENCES Matches(MatchID),
    FOREIGN KEY (PlayerID) REFERENCES Players(PlayerID),
    FOREIGN KEY (TeamID) REFERENCES Teams(TeamID)
);

CREATE TABLE PlayerStatistics AS
SELECT 
    p.PlayerID,
    CONCAT(
        CASE 
            WHEN p.GivenName = 'not applicable' THEN '' 
            ELSE CONCAT(p.GivenName, ' ')
        END,
        COALESCE(p.FamilyName, '')
    ) AS PlayerName,
    COUNT(g.GoalID) AS TotalGoals,
    COUNT(DISTINCT g.MatchID) AS Appearances,
    CASE 
        WHEN p.GoalKeeper = 1 THEN 'GoalKeeper'
        WHEN p.Defender = 1 THEN 'Defender'
        WHEN p.Midfielder = 1 THEN 'Midfielder'
        WHEN p.Forward = 1 THEN 'Forward'
        ELSE 'Unknown'
    END AS Position,
    COALESCE(COUNT(g.GoalID) / NULLIF(COUNT(DISTINCT g.MatchID), 0), 0) AS AvgGoalsPerMatch
FROM 
    Players p
LEFT JOIN 
    Goals g ON p.PlayerID = g.PlayerID
GROUP BY 
    p.PlayerID;

ALTER TABLE PlayerStatistics MODIFY AvgGoalsPerMatch DECIMAL(5,4);

SELECT PlayerID, PlayerName, TotalGoals, Position, AvgGoalsPerMatch
FROM PlayerStatistics
ORDER BY TotalGoals DESC
LIMIT 10;

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

CREATE TABLE IF NOT EXISTS TeamPerformance AS
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

CREATE TABLE IF NOT EXISTS TournamentSummary AS
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
DELIMITER ;

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

DELIMITER ;

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
DELIMITER ;

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

DELIMITER //
CREATE PROCEDURE RefreshMatchSummary()
BEGIN
    DELETE FROM MatchSummary;
    INSERT INTO MatchSummary
    SELECT 
        m.MatchID,
        m.TournamentID,
        m.MatchDate,
        m.Stage,
        m.HomeTeamID,
        ht.TeamName AS HomeTeamName,
        m.AwayTeamID,
        at.TeamName AS AwayTeamName,
        m.HomeTeamScore,
        m.AwayTeamScore,
        m.Outcome,
        m.StadiumID,
        s.StadiumName,
        s.CityName,
        s.CountryName,
        s.StadiumCapacity
    FROM 
        Matches m
    LEFT JOIN 
        Teams ht ON m.HomeTeamID = ht.TeamID
    LEFT JOIN 
        Teams at ON m.AwayTeamID = at.TeamID
    LEFT JOIN 
        Stadiums s ON m.StadiumID = s.StadiumID;
END //
DELIMITER ;

DELIMITER //
CREATE TRIGGER AfterGoalInsert
AFTER INSERT ON Goals
FOR EACH ROW
BEGIN
    CALL RefreshPlayerStatistics();
END //
DELIMITER ;

DELIMITER //
CREATE TRIGGER AfterMatchInsert
AFTER INSERT ON Matches
FOR EACH ROW
BEGIN
    CALL RefreshMatchSummary();
    CALL RefreshTeamPerformance();
    CALL RefreshTournamentSummary();
END //
DELIMITER ;

DELIMITER //
CREATE TRIGGER AfterPlayerInsert
AFTER INSERT ON Players
FOR EACH ROW
BEGIN
    CALL RefreshPlayerStatistics();
END //
DELIMITER ;

DELIMITER //
CREATE TRIGGER AfterTournamentInsert
AFTER INSERT ON Tournaments
FOR EACH ROW
BEGIN
    CALL RefreshTournamentSummary();
END //
DELIMITER ;

CREATE VIEW TopScorers AS
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
ORDER BY 
    WinPercentage DESC;
    
CREATE VIEW TournamentOverview AS
SELECT 
    TournamentID,
    Year,
    HostCountry,
    Winner,
    NumberOfTeams,
    TotalMatches,
    TotalGoals
FROM 
    TournamentSummary
ORDER BY 
    Year;
    
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

CREATE TABLE MaterializedTopScorers AS
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
