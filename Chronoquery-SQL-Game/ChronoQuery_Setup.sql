-- =====================================================
-- ChronoQuery: Temporal Database Detective Game
-- Database Setup Script for SQL Server
-- =====================================================

-- Create the game database
IF NOT EXISTS (SELECT * FROM sys.databases WHERE name = 'ChronoQuery')
BEGIN
    CREATE DATABASE ChronoQuery;
END
GO

USE ChronoQuery;
GO

-- =====================================================
				--CORE GAME TABLE--
-- =====================================================

-- Table: timelines
CREATE TABLE timelines (
    timeline_id INT IDENTITY(1,1) PRIMARY KEY,
    timeline_name VARCHAR(100) NOT NULL,
    branch_date DATETIME,
    parent_timeline_id INT NULL,
    is_primary BIT DEFAULT 0,
    created_date DATETIME DEFAULT GETDATE(),
    CONSTRAINT FK_timelines_parent FOREIGN KEY (parent_timeline_id) 
        REFERENCES timelines(timeline_id)
);
GO

-- Table: locations
CREATE TABLE locations (
    location_id INT IDENTITY(1,1) PRIMARY KEY,
    location_name VARCHAR(200) NOT NULL,
    latitude DECIMAL(10, 8),
    longitude DECIMAL(11, 8),
    time_period_start DATETIME,
    time_period_end DATETIME,
    location_type VARCHAR(50),
    timeline_version INT DEFAULT 1,
    CONSTRAINT FK_locations_timeline FOREIGN KEY (timeline_version) 
        REFERENCES timelines(timeline_id)
);
GO

-- Table: people
CREATE TABLE people (
    person_id INT IDENTITY(1,1) PRIMARY KEY,
    person_name VARCHAR(200) NOT NULL,
    birth_date DATETIME,
    death_date DATETIME NULL,
    birth_location_id INT,
    death_location_id INT NULL,
    timeline_version INT DEFAULT 1,
    occupation VARCHAR(100),
    notes NVARCHAR(MAX),
    CONSTRAINT FK_people_birth_location FOREIGN KEY (birth_location_id) 
        REFERENCES locations(location_id),
    CONSTRAINT FK_people_death_location FOREIGN KEY (death_location_id) 
        REFERENCES locations(location_id),
    CONSTRAINT FK_people_timeline FOREIGN KEY (timeline_version) 
        REFERENCES timelines(timeline_id)
);
GO

-- Table: events
CREATE TABLE events (
    event_id INT IDENTITY(1,1) PRIMARY KEY,
    event_type VARCHAR(100) NOT NULL,
    event_date DATETIME NOT NULL,
    location_id INT,
    description NVARCHAR(MAX),
    timeline_version INT DEFAULT 1,
    duration_minutes INT NULL,
    impact_level INT DEFAULT 1,
    CONSTRAINT FK_events_location FOREIGN KEY (location_id) 
        REFERENCES locations(location_id),
    CONSTRAINT FK_events_timeline FOREIGN KEY (timeline_version) 
        REFERENCES timelines(timeline_id)
);
GO

-- Table: person_events (junction table)
CREATE TABLE person_events (
    person_event_id INT IDENTITY(1,1) PRIMARY KEY,
    person_id INT NOT NULL,
    event_id INT NOT NULL,
    role VARCHAR(50),
    arrival_time DATETIME,
    departure_time DATETIME,
    CONSTRAINT FK_person_events_person FOREIGN KEY (person_id) 
        REFERENCES people(person_id),
    CONSTRAINT FK_person_events_event FOREIGN KEY (event_id) 
        REFERENCES events(event_id),
    CONSTRAINT UQ_person_event UNIQUE (person_id, event_id, role)
);
GO

-- Table: objects
CREATE TABLE objects (
    object_id INT IDENTITY(1,1) PRIMARY KEY,
    object_name VARCHAR(200) NOT NULL,
    object_type VARCHAR(100),
    creation_date DATETIME,
    destruction_date DATETIME NULL,
    current_location_id INT,
    current_time_period DATETIME,
    timeline_version INT DEFAULT 1,
    creator_person_id INT NULL,
    material VARCHAR(100),
    CONSTRAINT FK_objects_location FOREIGN KEY (current_location_id) 
        REFERENCES locations(location_id),
    CONSTRAINT FK_objects_timeline FOREIGN KEY (timeline_version) 
        REFERENCES timelines(timeline_id),
    CONSTRAINT FK_objects_creator FOREIGN KEY (creator_person_id) 
        REFERENCES people(person_id)
);
GO

-- Table: object_movements
CREATE TABLE object_movements (
    movement_id INT IDENTITY(1,1) PRIMARY KEY,
    object_id INT NOT NULL,
    from_location_id INT,
    to_location_id INT NOT NULL,
    movement_date DATETIME NOT NULL,
    carrier_person_id INT NULL,
    transport_method VARCHAR(100),
    distance_km DECIMAL(10, 2),
    CONSTRAINT FK_movements_object FOREIGN KEY (object_id) 
        REFERENCES objects(object_id),
    CONSTRAINT FK_movements_from_location FOREIGN KEY (from_location_id) 
        REFERENCES locations(location_id),
    CONSTRAINT FK_movements_to_location FOREIGN KEY (to_location_id) 
        REFERENCES locations(location_id),
    CONSTRAINT FK_movements_carrier FOREIGN KEY (carrier_person_id) 
        REFERENCES people(person_id)
);
GO

-- Table: relationships
CREATE TABLE relationships (
    relationship_id INT IDENTITY(1,1) PRIMARY KEY,
    person1_id INT NOT NULL,
    person2_id INT NOT NULL,
    relationship_type VARCHAR(50),
    start_date DATETIME,
    end_date DATETIME NULL,
    timeline_version INT DEFAULT 1,
    CONSTRAINT FK_relationships_person1 FOREIGN KEY (person1_id) 
        REFERENCES people(person_id),
    CONSTRAINT FK_relationships_person2 FOREIGN KEY (person2_id) 
        REFERENCES people(person_id),
    CONSTRAINT FK_relationships_timeline FOREIGN KEY (timeline_version) 
        REFERENCES timelines(timeline_id),
    CONSTRAINT CHK_different_people CHECK (person1_id != person2_id)
);
GO

-- Table: temporal_rules
CREATE TABLE temporal_rules (
    rule_id INT IDENTITY(1,1) PRIMARY KEY,
    rule_type VARCHAR(50),
    rule_name NVARCHAR(MAX) NOT NULL,
    description NVARCHAR(MAX),
    sql_check NVARCHAR(MAX),
    severity INT DEFAULT 5,
    is_active BIT DEFAULT 1
);
GO

-- Table: anomalies
CREATE TABLE anomalies (
    anomaly_id INT IDENTITY(1,1) PRIMARY KEY,
    anomaly_type VARCHAR(100),
    severity INT,
    time_period DATETIME,
    related_entity_type VARCHAR(50),
    related_entity_id INT,
    description NVARCHAR(MAX),
    status VARCHAR(20) DEFAULT 'active',
    detected_date DATETIME DEFAULT GETDATE(),
    resolved_date DATETIME NULL,
    timeline_version INT DEFAULT 1,
    CONSTRAINT FK_anomalies_timeline FOREIGN KEY (timeline_version) 
        REFERENCES timelines(timeline_id)
);
GO

-- =====================================================
			--GAME MECHANICS TABLES--
-- =====================================================

-- Table: players
CREATE TABLE players (
    player_id INT IDENTITY(1,1) PRIMARY KEY,
    username VARCHAR(100) NOT NULL UNIQUE,
    email VARCHAR(200) UNIQUE,
    password_hash VARCHAR(255),
    rank VARCHAR(50) DEFAULT 'Cadet',
    total_score INT DEFAULT 0,
    current_level INT DEFAULT 1,
    created_date DATETIME DEFAULT GETDATE(),
    last_login DATETIME
);
GO

-- Table: missions
CREATE TABLE missions (
    mission_id INT IDENTITY(1,1) PRIMARY KEY,
    mission_number INT NOT NULL UNIQUE,
    mission_name VARCHAR(200) NOT NULL,
    phase VARCHAR(50),
    difficulty_level INT,
    description NVARCHAR(MAX),
    briefing NVARCHAR(MAX),
    success_criteria NVARCHAR(MAX),
    solution_query NVARCHAR(MAX),
    min_score INT DEFAULT 0,
    time_limit_seconds INT NULL,
    is_active BIT DEFAULT 1
);
GO

-- Table: mission_hints
CREATE TABLE mission_hints (
    hint_id INT IDENTITY(1,1) PRIMARY KEY,
    mission_id INT NOT NULL,
    hint_level INT,
    hint_text NVARCHAR(MAX),
    score_penalty INT DEFAULT 0,
    CONSTRAINT FK_hints_mission FOREIGN KEY (mission_id) 
        REFERENCES missions(mission_id)
);
GO

-- Table: player_progress
CREATE TABLE player_progress (
    progress_id INT IDENTITY(1,1) PRIMARY KEY,
    player_id INT NOT NULL,
    mission_id INT NOT NULL,
    status VARCHAR(20) DEFAULT 'locked',
    attempts INT DEFAULT 0,
    hints_used INT DEFAULT 0,
    score INT DEFAULT 0,
    completion_time_seconds INT NULL,
    submitted_query NVARCHAR(MAX),
    started_date DATETIME,
    completed_date DATETIME NULL,
    CONSTRAINT FK_progress_player FOREIGN KEY (player_id) 
        REFERENCES players(player_id),
    CONSTRAINT FK_progress_mission FOREIGN KEY (mission_id) 
        REFERENCES missions(mission_id),
    CONSTRAINT UQ_player_mission UNIQUE (player_id, mission_id)
);
GO

-- Table: query_submissions
CREATE TABLE query_submissions (
    submission_id INT IDENTITY(1,1) PRIMARY KEY,
    player_id INT NOT NULL,
    mission_id INT NOT NULL,
    submitted_query NVARCHAR(MAX) NOT NULL,
    is_correct BIT,
    execution_time_ms INT,
    rows_returned INT,
    score_earned INT,
    feedback NVARCHAR(MAX),
    submission_date DATETIME DEFAULT GETDATE(),
    CONSTRAINT FK_submissions_player FOREIGN KEY (player_id) 
        REFERENCES players(player_id),
    CONSTRAINT FK_submissions_mission FOREIGN KEY (mission_id) 
        REFERENCES missions(mission_id)
);
GO

-- Table: achievements
CREATE TABLE achievements (
    achievement_id INT IDENTITY(1,1) PRIMARY KEY,
    achievement_name NVARCHAR(MAX) NOT NULL,
    description NVARCHAR(MAX),
    badge_icon VARCHAR(200),
    unlock_criteria NVARCHAR(MAX),
    points INT DEFAULT 0
);
GO

-- Table: player_achievements
CREATE TABLE player_achievements (
    player_achievement_id INT IDENTITY(1,1) PRIMARY KEY,
    player_id INT NOT NULL,
    achievement_id INT NOT NULL,
    unlocked_date DATETIME DEFAULT GETDATE(),
    CONSTRAINT FK_player_achievements_player FOREIGN KEY (player_id) 
        REFERENCES players(player_id),
    CONSTRAINT FK_player_achievements_achievement FOREIGN KEY (achievement_id) 
        REFERENCES achievements(achievement_id),
    CONSTRAINT UQ_player_achievement UNIQUE (player_id, achievement_id)
);
GO

-- Table: leaderboard
CREATE TABLE leaderboard (
    rank_position INT,
    player_id INT NOT NULL,
    username NVARCHAR(MAX),
    total_score INT,
    missions_completed INT,
    average_time DECIMAL(10, 2),
    last_updated DATETIME DEFAULT GETDATE(),
    CONSTRAINT FK_leaderboard_player FOREIGN KEY (player_id) 
        REFERENCES players(player_id)
);
GO

-- =====================================================
			--INDEXES FOR PERFORMANCE--
-- =====================================================

CREATE INDEX IX_people_birth_date ON people(birth_date);
CREATE INDEX IX_people_death_date ON people(death_date);
CREATE INDEX IX_people_timeline ON people(timeline_version);
CREATE INDEX IX_events_date ON events(event_date);
CREATE INDEX IX_events_location ON events(location_id);
CREATE INDEX IX_events_timeline ON events(timeline_version);
CREATE INDEX IX_events_type ON events(event_type);
CREATE INDEX IX_person_events_person ON person_events(person_id);
CREATE INDEX IX_person_events_event ON person_events(event_id);
CREATE INDEX IX_objects_creation_date ON objects(creation_date);
CREATE INDEX IX_objects_current_location ON objects(current_location_id);
CREATE INDEX IX_objects_timeline ON objects(timeline_version);
CREATE INDEX IX_movements_object ON object_movements(object_id);
CREATE INDEX IX_movements_date ON object_movements(movement_date);
CREATE INDEX IX_relationships_person1 ON relationships(person1_id);
CREATE INDEX IX_relationships_person2 ON relationships(person2_id);
CREATE INDEX IX_relationships_type ON relationships(relationship_type);
CREATE INDEX IX_anomalies_status ON anomalies(status);
CREATE INDEX IX_anomalies_severity ON anomalies(severity);
CREATE INDEX IX_anomalies_entity_type ON anomalies(related_entity_type);
CREATE INDEX IX_anomalies_entity_id ON anomalies(related_entity_id);
CREATE INDEX IX_progress_player ON player_progress(player_id);
CREATE INDEX IX_progress_status ON player_progress(status);
GO

-- =====================================================
			--VIEWS FOR COMMON QUERIES--
-- =====================================================

GO
CREATE VIEW vw_active_anomalies AS
SELECT 
    a.anomaly_id,
    a.anomaly_type,
    a.severity,
    a.time_period,
    a.related_entity_type,
    a.description,
    a.detected_date,
    t.timeline_name
FROM anomalies a
JOIN timelines t ON a.timeline_version = t.timeline_id
WHERE a.status = 'active';
GO

GO
CREATE VIEW vw_player_stats AS
SELECT 
    p.player_id,
    p.username,
    p.rank,
    p.total_score,
    p.current_level,
    COUNT(DISTINCT pp.mission_id) as missions_completed,
    AVG(CAST(pp.completion_time_seconds AS FLOAT)) as avg_completion_time,
    SUM(pp.hints_used) as total_hints_used,
    COUNT(DISTINCT pa.achievement_id) as achievements_unlocked
FROM players p
LEFT JOIN player_progress pp ON p.player_id = pp.player_id AND pp.status = 'completed'
LEFT JOIN player_achievements pa ON p.player_id = pa.player_id
GROUP BY p.player_id, p.username, p.rank, p.total_score, p.current_level;
GO

GO
CREATE VIEW vw_timeline_violations AS
SELECT 
    'Birth after death' as violation_type,
    person_id as entity_id,
    person_name as entity_name,
    timeline_version
FROM people
WHERE death_date IS NOT NULL AND birth_date > death_date
UNION ALL
SELECT 
    'Event before location exists' as violation_type,
    e.event_id,
    e.description,
    e.timeline_version
FROM events e
JOIN locations l ON e.location_id = l.location_id
WHERE e.event_date < l.time_period_start
UNION ALL
SELECT 
    'Object used before creation' as violation_type,
    om.object_id,
    o.object_name,
    o.timeline_version
FROM object_movements om
JOIN objects o ON om.object_id = o.object_id
WHERE om.movement_date < o.creation_date;
GO

-- =====================================================
				--STORED PROCEDURES--
-- =====================================================

CREATE PROCEDURE sp_submit_query
    @player_id INT,
    @mission_id INT,
    @submitted_query NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @is_correct BIT = 0;
    DECLARE @score INT = 0;
    DECLARE @execution_time INT;
    DECLARE @rows_returned INT;
    DECLARE @start_time DATETIME = GETDATE();
    
    BEGIN TRY
        SET @execution_time = DATEDIFF(MILLISECOND, @start_time, GETDATE());
        
        INSERT INTO query_submissions (
            player_id, 
            mission_id, 
            submitted_query, 
            is_correct, 
            execution_time_ms,
            score_earned
        )
        VALUES (
            @player_id,
            @mission_id,
            @submitted_query,
            @is_correct,
            @execution_time,
            @score
        );
        
        UPDATE player_progress
        SET attempts = attempts + 1,
            submitted_query = @submitted_query,
            status = CASE WHEN @is_correct = 1 THEN 'completed' ELSE 'in_progress' END,
            score = @score,
            completed_date = CASE WHEN @is_correct = 1 THEN GETDATE() ELSE NULL END
        WHERE player_id = @player_id AND mission_id = @mission_id;
        
        SELECT @is_correct as is_correct, @score as score, @execution_time as execution_time_ms;
        
    END TRY
    BEGIN CATCH
        SELECT 0 as is_correct, ERROR_MESSAGE() as error_message;
    END CATCH
END;
GO

CREATE PROCEDURE sp_unlock_next_mission
    @player_id INT
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @current_level INT;
    DECLARE @next_mission_id INT;
    
    SELECT @current_level = current_level
    FROM players
    WHERE player_id = @player_id;
    
    SELECT TOP 1 @next_mission_id = mission_id
    FROM missions
    WHERE mission_number = @current_level + 1
    AND is_active = 1;
    
    IF @next_mission_id IS NOT NULL
    BEGIN
        IF NOT EXISTS (
            SELECT 1 FROM player_progress 
            WHERE player_id = @player_id AND mission_id = @next_mission_id
        )
        BEGIN
            INSERT INTO player_progress (player_id, mission_id, status)
            VALUES (@player_id, @next_mission_id, 'available');
        END
        ELSE
        BEGIN
            UPDATE player_progress
            SET status = 'available'
            WHERE player_id = @player_id AND mission_id = @next_mission_id;
        END
        
        UPDATE players
        SET current_level = @current_level + 1
        WHERE player_id = @player_id;
    END
    
    SELECT @next_mission_id as unlocked_mission_id;
END;
GO

CREATE PROCEDURE sp_get_hint
    @player_id INT,
    @mission_id INT,
    @hint_level INT
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @hint_text NVARCHAR(MAX);
    DECLARE @score_penalty INT;
    
    SELECT 
        @hint_text = hint_text,
        @score_penalty = score_penalty
    FROM mission_hints
    WHERE mission_id = @mission_id AND hint_level = @hint_level;
    
    UPDATE player_progress
    SET hints_used = hints_used + 1,
        score = score - @score_penalty
    WHERE player_id = @player_id AND mission_id = @mission_id;
    
    SELECT @hint_text as hint_text, @score_penalty as score_penalty;
END;
GO

CREATE PROCEDURE sp_update_leaderboard
AS
BEGIN
    SET NOCOUNT ON;
    
    TRUNCATE TABLE leaderboard;
    
    INSERT INTO leaderboard (rank_position, player_id, username, total_score, missions_completed, average_time)
    SELECT 
        ROW_NUMBER() OVER (ORDER BY total_score DESC, missions_completed DESC) as rank_position,
        player_id,
        username,
        total_score,
        missions_completed,
        avg_completion_time
    FROM vw_player_stats;
    
    UPDATE leaderboard SET last_updated = GETDATE();
END;
GO

-- =====================================================
					--FUNCTIONS--
-- =====================================================

GO
CREATE FUNCTION fn_age_at_event(@person_id INT, @event_date DATETIME)
RETURNS INT
AS
BEGIN
    DECLARE @age INT;
    DECLARE @birth_date DATETIME;
    
    SELECT @birth_date = birth_date
    FROM people
    WHERE person_id = @person_id;
    
    SET @age = DATEDIFF(YEAR, @birth_date, @event_date);
    
    RETURN @age;
END;
GO

GO
CREATE FUNCTION fn_is_valid_location_date(@location_id INT, @check_date DATETIME)
RETURNS BIT
AS
BEGIN
    DECLARE @is_valid BIT = 0;
    
    IF EXISTS (
        SELECT 1 
        FROM locations 
        WHERE location_id = @location_id 
        AND @check_date >= time_period_start 
        AND (@check_date <= time_period_end OR time_period_end IS NULL)
    )
    BEGIN
        SET @is_valid = 1;
    END
    
    RETURN @is_valid;
END;
GO

-- =====================================================
					--TRIGGERS--
-- =====================================================

CREATE TRIGGER tr_detect_person_anomalies
ON people
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    
    INSERT INTO anomalies (anomaly_type, severity, time_period, related_entity_type, related_entity_id, description, status, timeline_version)
    SELECT 
        'age_paradox',
        10,
        i.birth_date,
        'person',
        i.person_id,
        'Person born after death: ' + i.person_name,
        'active',
        i.timeline_version
    FROM inserted i
    WHERE i.death_date IS NOT NULL 
    AND i.birth_date > i.death_date
    AND NOT EXISTS (
        SELECT 1 FROM anomalies 
        WHERE related_entity_type = 'person' 
        AND related_entity_id = i.person_id 
        AND anomaly_type = 'age_paradox'
    );
END;
GO

CREATE TRIGGER tr_update_player_score
ON player_progress
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    
    IF UPDATE(status)
    BEGIN
        UPDATE p
        SET total_score = total_score + i.score
        FROM players p
        INNER JOIN inserted i ON p.player_id = i.player_id
        INNER JOIN deleted d ON i.player_id = d.player_id AND i.mission_id = d.mission_id
        WHERE i.status = 'completed' AND d.status != 'completed';
    END
END;
GO

-- =====================================================
				  --DATA INSERTION--
-- =====================================================

INSERT INTO timelines (timeline_name, is_primary) 
VALUES ('Prime Timeline', 1);

SET IDENTITY_INSERT locations ON;
INSERT INTO locations (location_id, location_name, latitude, longitude, time_period_start, time_period_end, location_type, timeline_version)
VALUES 
(1, 'Ancient Rome', 41.9028, 12.4964, '1753-04-21', '1900-09-04', 'city', 1),
(2, 'Victorian London', 51.5074, -0.1278, '1837-06-20', '1901-01-22', 'city', 1),
(3, 'New York City 1920s', 40.7128, -74.0060, '1920-01-01', '1929-12-31', 'city', 1),
(4, 'Tokyo 2024', 35.6762, 139.6503, '2024-01-01', '2024-12-31', 'city', 1),
(5, 'Mars Colony Alpha', -4.5895, 137.4417, '2157-03-15', NULL, 'colony', 1);
SET IDENTITY_INSERT locations OFF;

SET IDENTITY_INSERT people ON;
INSERT INTO people (person_id, person_name, birth_date, death_date, birth_location_id, timeline_version, occupation)
VALUES 
(1, 'Marcus Aurelius', '1821-04-26', '1880-03-17', 1, 1, 'Emperor'),
(2, 'Sherlock Holmes', '1854-01-06', NULL, 2, 1, 'Detective'),
(3, 'Ada Lovelace', '1815-12-10', '1852-11-27', 2, 1, 'Mathematician'),
(4, 'Temporal Paradox Person', '1900-01-01', '1850-01-01', 3, 1, 'Anomaly'),
(5, 'John Smith', '1920-05-15', NULL, 3, 1, 'Businessman'),
(6, 'John Smith', '1920-05-15', NULL, 3, 1, 'Businessman'),
(7, 'Future Traveler', '2157-06-20', NULL, 5, 1, 'Colonist');
SET IDENTITY_INSERT people OFF;

SET IDENTITY_INSERT events ON;
INSERT INTO events (event_id, event_type, event_date, location_id, description, timeline_version)
VALUES 
(1, 'coronation', '1861-03-08', 1, 'Marcus Aurelius becomes Emperor', 1),
(2, 'invention', '1843-01-01', 2, 'Ada Lovelace writes first algorithm', 1),
(3, 'meeting', '1891-07-04', 2, 'The Reichenbach Fall', 1),
(4, 'impossible_meeting', '1800-01-01', 2, 'Meeting before birth', 1),
(5, 'colony_founding', '2157-03-15', 5, 'Mars Colony Alpha established', 1);
SET IDENTITY_INSERT events OFF;

INSERT INTO person_events (person_id, event_id, role, arrival_time, departure_time)
VALUES 
(1, 1, 'participant', '1861-03-08 09:00', '1861-03-08 18:00'),
(2, 3, 'participant', '1891-07-04 10:00', '1891-07-04 15:00'),
(3, 2, 'participant', '1843-01-01 08:00', '1843-01-01 20:00'),
(3, 4, 'participant', '1800-01-01 12:00', '1800-01-01 14:00');

SET IDENTITY_INSERT objects ON;
INSERT INTO objects (object_id, object_name, object_type, creation_date, current_location_id, current_time_period, timeline_version)
VALUES 
(1, 'Analytical Engine Plans', 'document', '1843-01-01', 2, '1843-01-01', 1),
(2, 'Roman Eagle Standard', 'artifact', '1800-01-01', 1, '1850-01-01', 1),
(3, 'Smartphone', 'technology', '2007-06-29', 1, '1800-01-01', 1),
(4, 'Mars Terraforming Device', 'technology', '2157-01-01', 5, '2157-03-15', 1);
SET IDENTITY_INSERT objects OFF;

INSERT INTO object_movements (object_id, from_location_id, to_location_id, movement_date, carrier_person_id, distance_km)
VALUES 
(1, 2, 2, '1843-01-01', 3, 0),
(2, 1, 2, '1850-01-01', NULL, 2000),
(3, 4, 1, '1800-01-01', NULL, 999999);

INSERT INTO relationships (person1_id, person2_id, relationship_type, start_date, timeline_version)
VALUES 
(2, 3, 'friend', '1850-01-01', 1);

INSERT INTO temporal_rules (rule_type, rule_name, description, severity)
VALUES 
('causality', 'Birth Before Death', 'A person must be born before they die', 10),
('causality', 'Event Participation Age', 'A person must exist to participate in an event', 9),
('consistency', 'No Duplicates', 'Same person cannot exist twice in same timeline/period', 8),
('physics', 'Travel Time Limits', 'Travel time must be physically possible', 7),
('logic', 'Object Temporal Placement', 'Objects must exist in appropriate time periods', 6),
('causality', 'Causal Ordering', 'Effects must follow causes', 10),
('consistency', 'Relationship Validity', 'Relationships must be logically consistent', 7);

INSERT INTO anomalies (anomaly_type, severity, time_period, related_entity_type, related_entity_id, description, status)
VALUES 
('temporal_displacement', 8, '1800-01-01', 'object', 3, 'Smartphone found in Ancient Rome', 'active'),
('age_paradox', 10, '1900-01-01', 'person', 4, 'Person born after death', 'active'),
('duplicate_entity', 7, '1920-05-15', 'person', 5, 'Duplicate person detected', 'active'),
('impossible_encounter', 9, '1800-01-01', 'event', 4, 'Person at event before birth', 'active');

-- =====================================================
					--MISSION DATA--
-- =====================================================

INSERT INTO missions (mission_number, mission_name, phase, difficulty_level, description, briefing, success_criteria)
VALUES 
(1, 'The Misplaced Artifact', 'Academy', 1, 
'Find objects that exist in the wrong time period',
'Welcome to the Time Bureau, Cadet! Your first assignment is simple: we''ve detected an object that doesn''t belong in its current time period. Use a SELECT query with a WHERE clause to find objects in Ancient Rome (location_id = 1) that were created after the year 500 AD.',
'Return all objects at location_id = 1 where creation_date > 500 AD'),

(2, 'Age Paradox', 'Academy', 1,
'Find people whose birth_date is after their death_date',
'Cadet, we''ve detected a serious temporal anomaly. Someone in our database was born AFTER they died. This violates the fundamental laws of causality. Write a query to find all people where their birth_date is later than their death_date.',
'Return all people where birth_date > death_date'),

(3, 'Duplicate Detection', 'Academy', 2,
'Find temporal duplicates - same person existing twice',
'We have reports of the same person appearing twice in the same timeline. This could indicate a temporal duplication event. Find all instances where the same person_name appears more than once with the same birth_date.',
'Return person names and birth dates that appear more than once'),

(4, 'Chronological Chaos', 'Academy', 2,
'Find events happening in impossible sequences',
'Events are occurring out of order! Find all person_events where a person''s departure_time is BEFORE their arrival_time.',
'Return person_events where departure_time < arrival_time'),

(5, 'The Vanished Records', 'Academy', 2,
'Find people with missing temporal data (NULL values)',
'Some records have incomplete temporal data. Find all people who have a NULL death_date but their birth_date was more than 150 years ago (indicating they should be deceased).',
'Return people with NULL death_date and birth_date < 150 years ago');

INSERT INTO mission_hints (mission_id, hint_level, hint_text, score_penalty)
VALUES 
(1, 1, 'You''ll need to query the objects table and filter by location_id and creation_date', 10),
(1, 2, 'Use WHERE location_id = 1 AND creation_date > ''1753-01-01''', 25),
(1, 3, 'SELECT * FROM objects WHERE current_location_id = 1 AND creation_date > ''1900-01-01''', 50);

INSERT INTO mission_hints (mission_id, hint_level, hint_text, score_penalty)
VALUES 
(2, 1, 'Look at the people table and compare birth_date with death_date', 10),
(2, 2, 'Use WHERE death_date IS NOT NULL AND birth_date > death_date', 25),
(2, 3, 'SELECT * FROM people WHERE death_date IS NOT NULL AND birth_date > death_date', 50);

INSERT INTO achievements (achievement_name, description, unlock_criteria, points)
VALUES 
('First Steps in Time', 'Complete your first mission', 'Complete Mission 1', 100),
('Academy Graduate', 'Complete all Academy missions', 'Complete Missions 1-5', 500),
('Paradox Hunter', 'Find 10 temporal paradoxes', 'Detect 10 anomalies', 250),
('Speed Demon', 'Complete a mission in under 60 seconds', 'Complete any mission in < 60 seconds', 300),
('Perfect Detective', 'Complete a mission without using hints', 'Complete mission with 0 hints', 200),
('Time Lord', 'Reach the highest rank', 'Complete all 30 missions', 5000);

-- =====================================================
-- SAMPLE PLAYER DATA
-- =====================================================

INSERT INTO players (username, email, rank, current_level)
VALUES ('TestDetective', 'test@timebureau.com', 'Cadet', 1);

DECLARE @test_player_id INT = SCOPE_IDENTITY();
INSERT INTO player_progress (player_id, mission_id, status)
VALUES (@test_player_id, 1, 'available');

-- =====================================================
-- VERIFICATION QUERIES
-- =====================================================

PRINT 'Database setup complete!';
PRINT '';
PRINT 'Table counts:';
SELECT 'timelines' as table_name, COUNT(*) as row_count FROM timelines
UNION ALL SELECT 'locations', COUNT(*) FROM locations
UNION ALL SELECT 'people', COUNT(*) FROM people
UNION ALL SELECT 'events', COUNT(*) FROM events
UNION ALL SELECT 'objects', COUNT(*) FROM objects
UNION ALL SELECT 'anomalies', COUNT(*) FROM anomalies
UNION ALL SELECT 'missions', COUNT(*) FROM missions
UNION ALL SELECT 'achievements', COUNT(*) FROM achievements;

PRINT '';
PRINT 'Active anomalies:';
SELECT * FROM vw_active_anomalies;

PRINT '';
PRINT 'Setup complete! Ready to play ChronoQuery!';
GO