DROP DATABASE IF EXISTS mistrzostwa_swiata_w_pilce_noznej_2022;

CREATE DATABASE mistrzostwa_swiata_w_pilce_noznej_2022;

USE mistrzostwa_swiata_w_pilce_noznej_2022;


CREATE TABLE Trainers (
    TrainerID INT AUTO_INCREMENT NOT NULL,
    PRIMARY KEY (TrainerID),
    FirstName VARCHAR(50) NOT NULL,
    LastName VARCHAR(50) NOT NULL,
    TrainerNationality VARCHAR(50) DEFAULT NULL
);

CREATE TABLE NationalTeams (
    NationalTeamID INT AUTO_INCREMENT NOT NULL,
    PRIMARY KEY (NationalTeamID),
    Country VARCHAR(50) NOT NULL,
    EarnedPoints SMALLINT DEFAULT 0
);

CREATE TABLE Groups (
    GroupID INT AUTO_INCREMENT NOT NULL,
    PRIMARY KEY (GroupID),
    GroupType VARCHAR(20) NOT NULL,
    FirstPosition VARCHAR(50) NOT NULL,
    SecondPosition VARCHAR(50) NOT NULL
);

CREATE TABLE Stadiums (
    StadiumID INT AUTO_INCREMENT NOT NULL,
    PRIMARY KEY (StadiumID),
    StadiumName VARCHAR(50) NOT NULL,
    Capacity INT DEFAULT NULL,
    StadiumLocation VARCHAR(50) DEFAULT NULL
);

CREATE TABLE Referees (
    RefereeID INT AUTO_INCREMENT NOT NULL,
    PRIMARY KEY (RefereeID),
    FirstName VARCHAR(50) NOT NULL,
    LastName VARCHAR(50) NOT NULL,
    RefereeNationality VARCHAR(50) DEFAULT NULL
);

CREATE TABLE Matches (
    MatchID INT AUTO_INCREMENT NOT NULL,
    PRIMARY KEY (MatchID),
    FirstTeamID INT,
    FOREIGN KEY (FirstTeamID) REFERENCES NationalTeams (NationalTeamID),
    SecondTeamID INT,
    FOREIGN KEY (SecondTeamID) REFERENCES NationalTeams (NationalTeamID),
    GroupID INT,
    FOREIGN KEY (GroupID) REFERENCES Groups (GroupID),
    GoalsFirstTeam TINYINT DEFAULT 0,
    GoalsSecondTeam TINYINT DEFAULT 0,
    StadiumID INT,
    FOREIGN KEY (StadiumID) REFERENCES Stadiums (StadiumID),
    MatchDate DATE,
    RefereeID INT,
    FirstTeamName VARCHAR(50),
    SecondTeamName VARCHAR(50),
    FOREIGN KEY (RefereeID) REFERENCES Referees (RefereeID),
    NumberOfRedCardsInMatch TINYINT DEFAULT 0,
    NumberOfYellowCardsInMatch TINYINT DEFAULT 0
);



CREATE TABLE Players (
    PlayerID INT AUTO_INCREMENT NOT NULL,
    PRIMARY KEY (PlayerID),
    FirstName VARCHAR(50) NOT NULL,
    LastName VARCHAR(50) NOT NULL,
    PlayerNationality VARCHAR(50) NOT NULL,
    PlayerBirthdate DATE NOT NULL,
    Position VARCHAR(50),
    ScoredGoals SMALLINT DEFAULT 0,
    NumberOfRedCards TINYINT DEFAULT 0,
    NumberOfYellowCards TINYINT DEFAULT 0,
    JerseyNumber SMALLINT,
    NationalTeamID INT,
    FOREIGN KEY (NationalTeamID) REFERENCES NationalTeams (NationalTeamID)
);




CREATE TABLE GroupMatches (
    GroupMatchID INT AUTO_INCREMENT NOT NULL,
    PRIMARY KEY (GroupMatchID),
    GroupID INT,
    FOREIGN KEY (GroupID) REFERENCES Groups (GroupID),
    MatchID INT,
    FOREIGN KEY (MatchID) REFERENCES Matches (MatchID)
);

CREATE TABLE footballwarinigs (
    FootballWarningID INT AUTO_INCREMENT NOT NULL,
    PRIMARY KEY (FootballWarningID),
    PlayerID INT,
    FOREIGN KEY (PlayerID) REFERENCES Players (PlayerID),
    MatchID INT,
    FOREIGN KEY (MatchID) REFERENCES Matches (MatchID),
    YellowCards BOOLEAN DEFAULT NULL,
    RedCards BOOLEAN DEFAULT NULL,
    FootballWarningTime INT
);

CREATE TABLE Goals (
    GoalID INT AUTO_INCREMENT NOT NULL,
    PRIMARY KEY (GoalID),
    NationalTeamID INT,
    FOREIGN KEY (NationalTeamID) REFERENCES NationalTeams (NationalTeamID),
    MatchID INT,
    FOREIGN KEY (MatchID) REFERENCES Matches (MatchID),
    PlayerID INT,
    FOREIGN KEY (PlayerID) REFERENCES Players (PlayerID),
    IsOwnGoal TINYINT,
    IsPenalty TINYINT,
    GoalTime INT
);



ALTER TABLE footballwarinigs
CHANGE YellowCards YellowCards TINYINT(1) NULL DEFAULT NULL,
CHANGE RedCards RedCards TINYINT(1) NULL DEFAULT NULL;

ALTER TABLE nationalteams
ADD TrainerID int;
ALTER TABLE nationalteams
ADD FOREIGN KEY (TrainerID) REFERENCES trainers(TrainerID);

ALTER TABLE nationalteams
ADD GroupID int; 
ALTER TABLE nationalteams
ADD FOREIGN KEY (GroupID) REFERENCES groups(GroupID);

ALTER TABLE nationalteams
ADD PlayedMatches int DEFAULT 0; 

ALTER TABLE nationalteams
ADD ScoredGoalsTeam int(11) DEFAULT 0;




DELIMITER $$
CREATE TRIGGER `after_footballwarnings_insarte_update_NumberOfYellowCards` 
AFTER INSERT ON `footballwarinigs` 
FOR EACH ROW 
BEGIN
IF NEW.YellowCards > 0 THEN 
UPDATE matches SET matches.NumberOfYellowCardsInMatch = matches.NumberOfYellowCardsInMatch + NEW.YellowCards 
WHERE MatchID = NEW.MatchID; 
END IF;
END$$
DELIMITER ;


DELIMITER $$
CREATE TRIGGER `after_footballwarnings_insarte_update_NumberOfRedCards` 
AFTER INSERT ON `footballwarinigs` 
FOR EACH ROW 
BEGIN
IF NEW.RedCards > 0 THEN 
UPDATE matches SET matches.NumberOfRedCardsInMatch = matches.NumberOfRedCardsInMatch + NEW.RedCards 
WHERE MatchID = NEW.MatchID; 
END IF;
END$$
DELIMITER ;


DELIMITER $$
CREATE TRIGGER `after_footballwarnings_insarte_update_NumberOfRedCardsPlayer` 
AFTER INSERT ON `footballwarinigs` 
FOR EACH ROW 
BEGIN
IF NEW.RedCards > 0 THEN 
UPDATE players SET players.NumberOfRedCards = players.NumberOfRedCards + NEW.RedCards 
WHERE PlayerID = NEW.PlayerID; 
END IF;
END$$
DELIMITER ;


DELIMITER $$
CREATE TRIGGER `after_footballwarnings_insarte_update_NumberOfYellowCardsPlayer` 
AFTER INSERT ON `footballwarinigs` 
FOR EACH ROW 
BEGIN
IF NEW.YellowCards > 0 THEN 
UPDATE players SET players.NumberOfYellowCards = players.NumberOfYellowCards + NEW.YellowCards 
WHERE PlayerID = NEW.PlayerID; 
END IF;
END$$
DELIMITER ;


DELIMITER $$
CREATE TRIGGER `after_matches_insert_AddMatchToGroup` 
AFTER INSERT ON `matches` 
FOR EACH ROW 
BEGIN
INSERT INTO groupmatches (MatchID, GroupID) 
VALUES (NEW.MatchID, NEW.GroupID);
END$$
DELIMITER ;


DELIMITER $$

CREATE TRIGGER after_goals_insert_update_GoalsInMatch
AFTER INSERT ON goals
FOR EACH ROW
BEGIN
    DECLARE team_id INT;
    DECLARE match_id INT;
    DECLARE is_own_goal TINYINT;  
    DECLARE first_team_id INT;
    DECLARE second_team_id INT;
    
    SELECT NationalTeamID, MatchID, IsOwnGoal INTO team_id, match_id, is_own_goal
    FROM goals
    WHERE GoalID = NEW.GoalID;
   
    SELECT FirstTeamID, SecondTeamID INTO first_team_id, second_team_id
    FROM matches
    WHERE MatchID = NEW.MatchID;
    
    IF is_own_goal = 1 THEN
        IF team_id = first_team_id THEN
            UPDATE matches
            SET GoalsSecondTeam = GoalsSecondTeam + 1
            WHERE MatchID = match_id;  
        ELSE
            UPDATE matches
            SET GoalsFirstTeam = GoalsFirstTeam + 1
            WHERE MatchID = match_id;
        END IF;
    ELSE
        IF team_id = first_team_id THEN
            UPDATE matches
            SET GoalsFirstTeam = GoalsFirstTeam + 1
            WHERE MatchID = match_id;
        ELSE
            UPDATE matches
            SET GoalsSecondTeam = GoalsSecondTeam + 1
            WHERE MatchID = match_id;
        END IF;
    END IF;
END$$
DELIMITER ;


DELIMITER $$
CREATE TRIGGER after_goals_insert_update_PlayerScoredGoals
AFTER INSERT ON goals
FOR EACH ROW
BEGIN
    DECLARE player_id INT;
    
    SELECT PlayerID INTO player_id
    FROM goals
    WHERE GoalID = NEW.GoalID;
   
    UPDATE players
    SET ScoredGoals = ScoredGoals + 1
    WHERE PlayerID = player_id;
END$$
DELIMITER ;


DELIMITER $$
CREATE TRIGGER after_goals_insert_update_ScoredGoalsTeam
AFTER INSERT ON goals
FOR EACH ROW
BEGIN
    UPDATE nationalteams
    SET ScoredGoalsTeam = ScoredGoalsTeam + 1
    WHERE NationalTeamID = NEW.NationalTeamID;
END$$
DELIMITER ;

DELIMITER $$
CREATE TRIGGER before_goals_delete_update_ScoredGoalsTeam
BEFORE DELETE ON goals
FOR EACH ROW
BEGIN
    UPDATE nationalteams
    SET ScoredGoalsTeam = ScoredGoalsTeam - 1
    WHERE NationalTeamID = OLD.NationalTeamID;
END$$
DELIMITER ;


DELIMITER $$
CREATE TRIGGER before_players_insert_CheckJeresynumberRange
BEFORE INSERT ON players
FOR EACH ROW
BEGIN
    IF NEW.JerseyNumber < 1 OR NEW.JerseyNumber > 99 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Wartość numeru na koszulce powinna być w przedziale od 1 do 99';
    END IF;
END$$
DELIMITER ;


DELIMITER $$
CREATE TRIGGER before_goals_delete_update_GoalsInMatch
BEFORE DELETE ON goals
FOR EACH ROW
BEGIN
    DECLARE team_id INT;
    DECLARE match_id INT;
    DECLARE is_own_goal TINYINT;  
    DECLARE first_team_id INT;
    DECLARE second_team_id INT;
    
    SELECT NationalTeamID, MatchID, IsOwnGoal INTO team_id, match_id, is_own_goal
    FROM goals
    WHERE GoalID = OLD.GoalID;
   
    SELECT FirstTeamID, SecondTeamID INTO first_team_id, second_team_id
    FROM matches
    WHERE MatchID = OLD.MatchID;
    
    IF is_own_goal = 1 THEN
        IF team_id = first_team_id THEN
            UPDATE matches
            SET GoalsSecondTeam = (SELECT GoalsSecondTeam - 1 FROM matches WHERE MatchID = match_id)
            WHERE MatchID = match_id;  
        ELSE
            UPDATE matches
            SET GoalsFirstTeam = (SELECT GoalsFirstTeam - 1 FROM matches WHERE MatchID = match_id)
            WHERE MatchID = match_id;
        END IF;
    ELSE
        IF team_id = first_team_id THEN
            UPDATE matches
            SET GoalsFirstTeam = (SELECT GoalsFirstTeam - 1 FROM matches WHERE MatchID = match_id)
            WHERE MatchID = match_id;
        ELSE
            UPDATE matches
            SET GoalsSecondTeam = (SELECT GoalsSecondTeam - 1 FROM matches WHERE MatchID = match_id)
            WHERE MatchID = match_id;
        END IF;
    END IF;
END$$
DELIMITER ;


DELIMITER $$
CREATE TRIGGER before_goals_delete_update_PlayerScoredGoals
BEFORE DELETE ON goals
FOR EACH ROW
BEGIN
    DECLARE player_id INT;
    
    SELECT PlayerID INTO player_id
    FROM goals
    WHERE GoalID = OLD.GoalID;
   
    UPDATE players
    SET ScoredGoals = ScoredGoals - 1
    WHERE PlayerID = player_id;
END$$
DELIMITER ;


DELIMITER $$
CREATE TRIGGER before_players_insert_CheckPlayerLimit
BEFORE INSERT ON players
FOR EACH ROW
BEGIN
    DECLARE team_count INT;
    SELECT COUNT(*) INTO team_count
    FROM players
    WHERE NationalTeamID = NEW.NationalTeamID;
    
    IF team_count >= 26 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'W tej drużynie osiągnięto maksymalną liczbę przypisanych piłkarzy (26)';
    END IF;
END$$
DELIMITER ;


DELIMITER $$
CREATE TRIGGER after_matches_insert_update_MatchesPlayed
AFTER INSERT ON matches
FOR EACH ROW
BEGIN
    UPDATE nationalteams
    SET PlayedMatches = PlayedMatches + 1
    WHERE NationalTeamID = NEW.FirstTeamID;
    
    UPDATE nationalteams
    SET PlayedMatches = PlayedMatches + 1
    WHERE NationalTeamID = NEW.SecondTeamID;
END$$
DELIMITER ;


DELIMITER $$
CREATE TRIGGER before_matches_delete_update_MatchesPlayed
BEFORE DELETE ON matches
FOR EACH ROW
BEGIN
    UPDATE nationalteams
    SET PlayedMatches = PlayedMatches - 1
    WHERE NationalTeamID = OLD.FirstTeamID;
    
    UPDATE nationalteams
    SET PlayedMatches = PlayedMatches - 1
    WHERE NationalTeamID = OLD.SecondTeamID;
    
    DELETE FROM groupmatches
    WHERE MatchID = OLD.MatchID;
END$$
DELIMITER ;


DELIMITER $$
CREATE PROCEDURE COUNT_MATCHES_IN_GROUP(IN group_id INT, OUT match_count INT)
BEGIN
    SELECT COUNT(*) INTO match_count
    FROM groupmatches
    WHERE GroupID = group_id;
END$$
DELIMITER ;


DELIMITER $$
CREATE PROCEDURE COUNT_GOALS_BY_COUNTRY(IN country_id INT, OUT goal_count INT)
BEGIN
    SELECT SUM(ScoredGoals) INTO goal_count
    FROM players
    WHERE NationalTeamID = country_id;
END$$
DELIMITER ;


DELIMITER $$
CREATE PROCEDURE UPDATE_GROUP_POSITIONS()
BEGIN
    DECLARE group_id INT;
    SET group_id = 1;
    WHILE group_id <= 2 DO
        UPDATE groups AS g
        SET g.FirstPosition = (
            SELECT nt.Country
            FROM nationalteams AS nt
            WHERE nt.GroupID = group_id
            ORDER BY nt.EarnedPoints DESC, nt.ScoredGoalsTeam DESC
            LIMIT 1
        )
        WHERE g.GroupID = group_id;
        UPDATE groups AS g
        SET g.SecondPosition = (
            SELECT nt.Country
            FROM nationalteams AS nt
            WHERE nt.GroupID = group_id
            ORDER BY nt.EarnedPoints DESC, nt.ScoredGoalsTeam DESC
            LIMIT 1, 1
        )
        WHERE g.GroupID = group_id;
        
        SET group_id = group_id + 1;
    END WHILE;
END $$
DELIMITER ;


DELIMITER $$
CREATE PROCEDURE ADD_NEW_MATCH(
    IN first_team_id INT,
    IN second_team_id INT,
    IN match_date DATE,
    IN referee_id INT,
    IN stadium_id INT,
    IN group_id INT,
    OUT match_id INT
)
BEGIN
DECLARE first_team_name VARCHAR(255);
    DECLARE second_team_name VARCHAR(255);

SELECT Country INTO first_team_name
FROM nationalteams
WHERE NationalTeamID = first_team_id;

SELECT Country INTO second_team_name
FROM nationalteams
WHERE NationalTeamID = second_team_id;
    
	INSERT INTO Matches (FirstTeamID, SecondTeamID, MatchDate, RefereeID, StadiumID, GroupID)
    VALUES (first_team_id, second_team_id, match_date, referee_id, stadium_id, group_id );
    
    SET match_id = LAST_INSERT_ID();
    
    SELECT CONCAT('Dodano nowy mecz ', first_team_name, ' vs ', second_team_name, ', MatchID: ', match_id) AS message;
END$$

DELIMITER ;



DELIMITER $$
CREATE PROCEDURE ADD_NEW_GOAL(
    IN p_NationalTeamID INT,
    IN p_MatchID INT,
    IN p_PlayerID INT,
    IN p_IsOwnGoal TINYINT,
    IN p_IsPenalty TINYINT
)
BEGIN
    INSERT INTO Goals (NationalTeamID, MatchID, PlayerID, IsOwnGoal, IsPenalty)
    VALUES (p_NationalTeamID, p_MatchID, p_PlayerID, p_IsOwnGoal, p_IsPenalty);
END$$
DELIMITER ;

DELIMITER $$

CREATE PROCEDURE UPDATE_EARNED_POINTS_BY_TEAM(
    IN team_id INT
)
BEGIN
    DECLARE team_points INT;
    SELECT SUM(CASE
        WHEN GoalsFirstTeam > GoalsSecondTeam AND FirstTeamID = team_id THEN 3
        WHEN GoalsFirstTeam < GoalsSecondTeam AND SecondTeamID = team_id THEN 3
        WHEN GoalsFirstTeam = GoalsSecondTeam AND (FirstTeamID = team_id OR SecondTeamID = team_id) THEN 1
        ELSE 0
    END) INTO team_points
    FROM matches;
    UPDATE nationalteams
    SET EarnedPoints = team_points
    WHERE NationalTeamID = team_id;
    UPDATE nationalteams
    SET EarnedPoints = IFNULL(EarnedPoints, 0)
    WHERE NationalTeamID = team_id;
END$$

DELIMITER ;



CREATE INDEX idx_match_date ON matches (MatchDate);
CREATE INDEX idx_last_name_players ON players (LastName);
CREATE INDEX idx_last_name_referees ON referees (LastName);
CREATE INDEX idx_matches_teams ON matches (FirstTeamID, SecondTeamID);
CREATE INDEX idx_scored_goals ON Players (ScoredGoals);
CREATE INDEX idx_goals_matchid ON goals (MatchID);



INSERT INTO nationalteams(Country, EarnedPoints,NationalTeamID) 
VALUES ('Katar','0','1'),('Ekwador','0','2'),('Senegal','0','3'),('Holandia','0','4');


INSERT INTO nationalteams(Country, EarnedPoints,NationalTeamID) 
VALUES ('Argentyna','0','5'),('Polska','0','6'),('Meksyk','0','7'),('Arabia Saudyjska','0','8');

INSERT INTO players(FirstName,LastName,PlayerNationality,PlayerBirthdate,Position,ScoredGoals,NationalTeamID,NumberOfRedCards,NumberOfYellowCards,JerseyNumber,PlayerID)
VALUES
('Saad','Sheeb','Katar','1990-02-19','Bramkarz','0','1','0','0','1','1'),
('Pedro','Miguel','Katar','1990-08-06','Obrońca','0','1','0','0','2','2'), ('Abdelkarim ','Fadlalla','Katar','1993-08-28','Obrońca','0','1','0','0','3','3'),
('Mohammed','Waad','Katar','1999-09-18','Pomocnik','0','1','0','0','4','4'),('Mohammed','Muntari','Katar','1993-12-20','Pomocnik','0','1','0','0','9','5'),
('Ahmed','Alaaeldin','Katar','1993-01-31','Napastnik','0','1','0','0','6','6'),('Akram ','Afif','Katar','1996-11-18','Napastnik','0','1','0','0','11','7'),
('Hernan ','Galindez','Ekawdor','1987-03-30','Bramkarz','0','2','0','0','1','8'),('Felix','Torres','Ekawdor','1997-01-11','Obrońca','0','2','0','0','2','9'),
('Romario ','Ibarra','Ekawdor','1994-08-24','Pomocnik','0','2','0','0','10','10'),('Enner','Valencia','Ekawdor','1989-11-04','Napastnik','0','2','0','0','13','11'),
('Seny ','Dieng','Senegal','1994-11-23','Bramkarz','0','3','0','0','1','12'),('Kalidou','Koulibaly','Senegal','1991-06-20','Obrońca','0','3','0','0','3','13'),
('Nampalys ','Mendy','Senegal','1992-06-23','Pomocnik','0','3','0','0','6','14'),('Boulaye','Dia','Senegal','1996-11-16','Napastnik','0','3','0','0','9','15'),
('Jasper ','Cillessen','Holandia','1989-04-22','Bramkarz','0','4','0','0','1','16'),('Lutsharel','Geertruida','Holandia','2000-07-18','Obrońca','0','4','0','0','3','17'),
('Steven ','Berghuis','Holandia','1991-12-19','Pomocnik','0','4','0','0','11','18'),('Memphis ','Depay','Holandia','1994-02-13','Napastnik','0','4','0','0','10','19');


INSERT INTO players(FirstName,LastName,PlayerNationality,PlayerBirthdate,Position,ScoredGoals,NationalTeamID,NumberOfRedCards,NumberOfYellowCards,JerseyNumber,PlayerID)
VALUES
('Franco ','Armani','Argentyna','1986-10-16','Bramkarz','0','5','0','0','1','20'),('Gonzalo','Montiel','Argentyna','1997-01-01','Obrońca','0','5','0','0','4','21'),
('Thiago ','Almada','Argentyna','2001-04-26','Pomocnik','0','5','0','0','16','22'),('Lionel ','Messi','Argentyna','1987-06-24','Napastnik','0','5','0','0','10','23'),
('Wojciech','Szczęsny','Polska','1990-04-18','Bramkarz','0','6','0','0','1','24'),('Jan','Bednarek','Polska','1996-04-12','Obrońca','0','6','0','0','5','25'),
('Sebastian','Szymański','Polska','1999-05-10','Pomocnik','0','6','0','0','19','26'),('Robert','Lewandowski','Polska','1988-08-21','Napastnik','0','6','0','0','9','27'),
('Alfredo ','Talavera','Meksyk','1982-09-18','Bramkarz','0','7','0','0','1','28'),('Hector ','Moreno','Meksyk','1988-01-17','Obrońca','0','7','0','0','15','29'),
('Luis','Romo','Meksyk','1995-06-05','Pomocnik','0','7','0','0','7','30'), ('Carlos','Rodriguez','Meksyk','1997-01-03','Napastnik','0','7','0','0','8','31'),
('Mohammed','Al-Rubaie','Arabia Saudyjska','1997-08-14','Bramkarz','0','8','0','0','1','32'),('Abdullah','Madu','Arabia Saudyjska','1993-07-15','Obrońca','0','8','0','0','3','33'),
('Salman ','Al-Faraj','Arabia Saudyjska','1989-08-01','Pomocnik','0','8','0','0','7','34'),('Saleh',' Al-Shehri','Arabia Saudyjska','1993-11-01','Napastnik','0','8','0','0','11','35');

INSERT INTO trainers(FirstName,LastName,TrainerNationality,TrainerID)
VALUES 
('Felix','Sanchez','Hiszpania','1'),('Gustavo','Alfaro','Argentyna','2'),('Aliou','Cisse','Senegal','3'),('Louis','van Gaal','Holandia','4'),('Lionel','Scaloni','Argentyna','5'),('Czesław','Michniewicz','Polska','6'),
('Gerardo','Martino','Argentyna','7'),('Herve','Renard','Francja','8');


INSERT INTO stadiums(StadiumName,StadiumLocation, Capacity,StadiumID)
VALUES
('Al Bayt Stadium','Al-Chaur','45330','1'),('Al Thumama Stadium','Doha','40000','2'),
('Lusail Stadium','Lusajl','86000','3'),('Stadium 974','Doha','44089','4');
                                                                       
INSERT INTO referees(FirstName,LastName,RefereeNationality,RefereeID)
VALUES 
('Daniele','Orsato','Włochy','1'),('Wilton','Sampaio','Brazylia','2'),('Slavko','Vinčić','Słowenia','3'),('Chris','Beath','Australia','4');

INSERT INTO groups(GroupType, GroupID)
VALUES
('A','1'),('C','2');

UPDATE nationalteams SET GroupID = '1' WHERE nationalteams.Country ='Katar' OR nationalteams.Country ='Ekwador' OR nationalteams.Country ='Senegal' OR nationalteams.Country ='Holandia'; 
UPDATE nationalteams SET GroupID = '2' WHERE nationalteams.Country ='Argentyna' OR nationalteams.Country ='Meksyk' OR nationalteams.Country ='Polska' OR nationalteams.Country ='Arabia Saudyjska';

UPDATE NationalTeams
SET TrainerID = NationalTeamID;

INSERT INTO matches(FirstTeamID,SecondTeamID,GroupID,StadiumID,MatchDate,RefereeID,FirstTeamName,SecondTeamName,MatchID)
VALUES ('1','2','1','1','2022-11-20','1','Katar','Senegal','1');

INSERT INTO goals(NationalTeamID,MatchID,PlayerID,IsOwnGoal,IsPenalty,GoalTime)
VALUES ('2','1','11','0','1','16');

INSERT INTO goals(NationalTeamID,MatchID,PlayerID,IsOwnGoal,IsPenalty,GoalTime)
VALUES ('2','1','11','0','0','31');

INSERT INTO footballwarinigs(PlayerID,MatchID,YellowCards,RedCards,FootballWarningTime)
VALUES ('7','1','1','0','78');


INSERT INTO matches(FirstTeamID,SecondTeamID,GroupID,StadiumID,MatchDate,RefereeID,FirstTeamName,SecondTeamName,MatchID)
VALUES ('3','4','1','2','2022-11-21','2','Senegal','Holandia','2');

INSERT INTO goals(NationalTeamID,MatchID,PlayerID,IsOwnGoal,IsPenalty,GoalTime) 
VALUES ('4','2','19','0','0','84'),('4','2','18','0','0','84');
INSERT INTO footballwarinigs(PlayerID,MatchID,YellowCards,RedCards,FootballWarningTime)
VALUES ('14','2','1','0','94'),('17','2','1','0','56'),('15','2','1','0','99');


INSERT INTO matches(FirstTeamID,SecondTeamID,GroupID,StadiumID,MatchDate,RefereeID,FirstTeamName,SecondTeamName,MatchID)
VALUES ('3','1','1','2','2022-11-25','3','Senegal','Katar','3');
INSERT INTO goals(NationalTeamID,MatchID,PlayerID,IsOwnGoal,IsPenalty,GoalTime) 
VALUES ('3','3','15','0','0','41'),('3','3','15','0','0','48'),('3','3','14','0','0','84'),('1','3','5','0','0','78');
INSERT INTO footballwarinigs(PlayerID,MatchID,YellowCards,RedCards,FootballWarningTime)
VALUES ('15','3','1','0','30');

INSERT INTO matches(FirstTeamID,SecondTeamID,GroupID,StadiumID,MatchDate,RefereeID,FirstTeamName,SecondTeamName,MatchID)
VALUES ('4','2','1','4','2022-11-25','4','Holandia','Ekawdor','4');
INSERT INTO goals(NationalTeamID,MatchID,PlayerID,IsOwnGoal,IsPenalty,GoalTime) 
VALUES ('4','4','17','0','0','6'),('2','4','11','0','0','49');


INSERT INTO matches(FirstTeamID,SecondTeamID,GroupID,StadiumID,MatchDate,RefereeID,FirstTeamName,SecondTeamName,MatchID)
VALUES ('4','1','1','3','2022-11-29','2','Holandia','Katar','5');
INSERT INTO goals(NationalTeamID,MatchID,PlayerID,IsOwnGoal,IsPenalty,GoalTime) 
VALUES ('4','5','18','0','0','26'),('4','5','19','0','0','49');
INSERT INTO footballwarinigs(PlayerID,MatchID,YellowCards,RedCards,FootballWarningTime)
VALUES ('1','5','1','0','33');

INSERT INTO matches(FirstTeamID,SecondTeamID,GroupID,StadiumID,MatchDate,RefereeID,FirstTeamName,SecondTeamName,MatchID)
VALUES ('2','3','1','1','2022-11-29','3','Ekwador','Senegal','6');
INSERT INTO goals(NationalTeamID,MatchID,PlayerID,IsOwnGoal,IsPenalty,GoalTime) 
VALUES ('3','6','13','0','0','34'),('3','6','14','0','0','70'),('2','6','10','0','0','67');

INSERT INTO matches(FirstTeamID,SecondTeamID,GroupID,StadiumID,MatchDate,RefereeID,FirstTeamName,SecondTeamName,MatchID)
VALUES ('6','7','2','1','2022-11-22','3','Polska','Meksyk','7');
INSERT INTO footballwarinigs(PlayerID,MatchID,YellowCards,RedCards,FootballWarningTime) 
VALUES ('29','7','1','0','56');

INSERT INTO matches(FirstTeamID,SecondTeamID,GroupID,StadiumID,MatchDate,RefereeID,FirstTeamName,SecondTeamName,MatchID)
VALUES ('5','8','2','2','2022-11-22','1','Argentyna','Arabia Saudyjska','8');
INSERT INTO goals(NationalTeamID,MatchID,PlayerID,IsOwnGoal,IsPenalty,GoalTime) 
VALUES ('5','8','23','0','0','5'),('8','8','35','0','0','48'),('8','8','34','0','0','53');


INSERT INTO matches(FirstTeamID,SecondTeamID,GroupID,StadiumID,MatchDate,RefereeID,FirstTeamName,SecondTeamName,MatchID)
VALUES ('6','8','2','1','2022-11-26','3','Polska','Arabia Saudyjska','9');
INSERT INTO goals(NationalTeamID,MatchID,PlayerID,IsOwnGoal,IsPenalty,GoalTime) 
VALUES ('6','9','27','0','0','82'),('6','9','26','0','0','39'),('6','9','25','0','0','44');

INSERT INTO matches(FirstTeamID,SecondTeamID,GroupID,StadiumID,MatchDate,RefereeID,FirstTeamName,SecondTeamName,MatchID)
VALUES ('5','7','2','4','2022-11-26','4','Argentyna','Meksyk','10');
INSERT INTO goals(NationalTeamID,MatchID,PlayerID,IsOwnGoal,IsPenalty,GoalTime) 
VALUES ('5','10','23','0','0','64'),('5','10','23','0','0','87');

INSERT INTO matches(FirstTeamID,SecondTeamID,GroupID,StadiumID,MatchDate,RefereeID,FirstTeamName,SecondTeamName,MatchID)
VALUES ('8','7','2','1','2022-11-30','2','Arabia Saudyjska','Meksyk','11');
INSERT INTO goals(NationalTeamID,MatchID,PlayerID,IsOwnGoal,IsPenalty,GoalTime) 
VALUES ('7','11','31','0','0','47'),('7','11','31','0','0','52'),('8','11','35','0','0','90');

INSERT INTO matches(FirstTeamID,SecondTeamID,GroupID,StadiumID,MatchDate,RefereeID,FirstTeamName,SecondTeamName,MatchID)
VALUES ('6','5','2','3','2022-11-30','3','Polska','Argentyna','12');
INSERT INTO goals(NationalTeamID,MatchID,PlayerID,IsOwnGoal,IsPenalty,GoalTime) 
VALUES ('5','12','22','0','0','46'),('5','12','23','0','0','67');

CALL UPDATE_EARNED_POINTS_BY_TEAM('1');
CALL UPDATE_EARNED_POINTS_BY_TEAM('2');
CALL UPDATE_EARNED_POINTS_BY_TEAM('3');
CALL UPDATE_EARNED_POINTS_BY_TEAM('4');
CALL UPDATE_EARNED_POINTS_BY_TEAM('5');
CALL UPDATE_EARNED_POINTS_BY_TEAM('6');
CALL UPDATE_EARNED_POINTS_BY_TEAM('7');
CALL UPDATE_EARNED_POINTS_BY_TEAM('8');
CALL UPDATE_GROUP_POSITIONS();


DELIMITER $$
CREATE PROCEDURE `GET_MATCH_RESULTS`()
BEGIN
SELECT
       nt1.Country AS FirstTeam,
       nt2.Country AS SecondTeam,
       CONCAT(COALESCE(SUM(CASE WHEN g.GoalTime <= 45 AND g.NationalTeamID = m.FirstTeamID THEN 1 ELSE 0 END), 0), ':', 
              COALESCE(SUM(CASE WHEN g.GoalTime <= 45 AND g.NationalTeamID = m.SecondTeamID THEN 1 ELSE 0 END), 0)
             ) AS ResultFirstHalf,
       CONCAT(COALESCE(SUM(CASE WHEN g.NationalTeamID = m.FirstTeamID THEN 1 ELSE 0 END), 0), ':', 
              COALESCE(SUM(CASE WHEN g.NationalTeamID = m.SecondTeamID THEN 1 ELSE 0 END), 0)) AS ResultFull
   FROM
       matches m
   LEFT JOIN
       goals g ON g.MatchID = m.MatchID
   JOIN
       nationalteams nt1 ON nt1.NationalTeamID = m.FirstTeamID
   JOIN
       nationalteams nt2 ON nt2.NationalTeamID = m.SecondTeamID
   GROUP BY
       m.MatchID, m.FirstTeamID, m.SecondTeamID, nt1.Country, nt2.Country;
END$$

DELIMITER ;




SELECT *
FROM players
NATURAL JOIN nationalteams
WHERE LastName LIKE 'M%';


SELECT CONCAT(players.FirstName, ' ', players.LastName) AS PlayerName, nationalteams.Country, CONCAT(trainers.FirstName, ' ', trainers.LastName) AS TrainerName
FROM players
INNER JOIN nationalteams ON players.NationalTeamID = nationalteams.NationalTeamID
INNER JOIN trainers ON nationalteams.TrainerID = trainers.TrainerID;


SELECT nationalteams.Country, groups.GroupType
FROM nationalteams
LEFT OUTER JOIN groups ON nationalteams.GroupID = groups.GroupID;


SELECT *
FROM players 
RIGHT OUTER JOIN nationalteams ON players.NationalTeamID = nationalteams.NationalTeamID
RIGHT OUTER JOIN groups ON nationalteams.GroupID = groups.GroupID;


SELECT m.FirstTeamName, m.SecondTeamName, CONCAT(m.GoalsSecondTeam, ':', m.GoalsFirstTeam) AS Wynik, s.StadiumName, r.FirstName, r.LastName 
FROM matches m 
NATURAL JOIN stadiums s 
NATURAL JOIN referees r;


SELECT m.MatchDate, t1.Country AS FirstTeam, t2.Country AS SecondTeam, m.GoalsFirstTeam, m.GoalsSecondTeam, r.FirstName AS  RefereeFirstName, r.LastName AS RefereeLastName
FROM matches m
JOIN nationalteams t1 ON t1.NationalTeamID  = m.FirstTeamID
JOIN nationalteams t2 ON t2.NationalTeamID  = m.SecondTeamID
JOIN referees r ON r.RefereeID = m.RefereeID;


SELECT t.Country, nt.TotalTeamGoals, nt.BestScorerGoals, CONCAT(p.FirstName, ' ', p.LastName) AS BestScorerName
FROM nationalteams t
LEFT JOIN (
    SELECT p.NationalTeamID, SUM(p.ScoredGoals) AS TotalTeamGoals, MAX(p.ScoredGoals) AS BestScorerGoals
    FROM players p
    GROUP BY p.NationalTeamID
) nt ON t.NationalTeamID = nt.NationalTeamID
LEFT JOIN players p ON nt.NationalTeamID = p.NationalTeamID AND nt.BestScorerGoals = p.ScoredGoals
ORDER BY nt.TotalTeamGoals DESC, t.Country ASC;


SELECT players.FirstName, players.LastName, players.JerseyNumber, nationalteams.Country
FROM players
INNER JOIN nationalteams ON players.NationalTeamID = nationalteams.NationalTeamID;

SELECT nt.Country AS Country, COUNT(*) AS player_count
FROM players p
JOIN nationalteams nt ON nt.NationalTeamID = p.NationalTeamID
GROUP BY p.NationalTeamID, nt.Country;


SELECT LastName, SUM(ScoredGoals) AS scored_goals
FROM players
GROUP BY LastName ASC
HAVING scored_goals > 2;


SELECT *
FROM matches
WHERE MatchDate BETWEEN '2022-11-01' AND '2022-11-25'
ORDER BY MatchDate;


SELECT players.LastName, players.PlayerBirthdate, nationalteams.Country
FROM players
INNER JOIN nationalteams ON players.NationalTeamID = nationalteams.NationalTeamID
WHERE players.PlayerBirthdate BETWEEN '2000-01-01' AND '2022-12-31'
ORDER BY players.PlayerBirthdate DESC;


SELECT Country, COUNT(*) AS player_count
FROM players
JOIN nationalteams ON players.NationalTeamID = nationalteams.NationalTeamID
WHERE Country LIKE 'P%'
GROUP BY Country;


SELECT players.LastName, DATE_FORMAT(NOW(), '%Y') - DATE_FORMAT(players.PlayerBirthdate, '%Y') - (DATE_FORMAT(NOW(), '00-%m-%d') < DATE_FORMAT(players.PlayerBirthdate, '00-%m-%d')) AS Age, nationalteams.Country
FROM players
INNER JOIN nationalteams ON players.NationalTeamID = nationalteams.NationalTeamID
ORDER BY Age DESC;


SELECT players.FirstName, players.LastName, nationalteams.Country,
    CASE
        WHEN nationalteams.Country = groups.FirstPosition OR nationalteams.Country = groups.SecondPosition THEN 'Awans'
        ELSE 'Brak awansu'
    END AS Status
FROM players
INNER JOIN nationalteams ON players.NationalTeamID = nationalteams.NationalTeamID
JOIN groups ON nationalteams.GroupID = groups.GroupID
ORDER BY players.LastName, players.FirstName;
