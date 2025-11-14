# Database Schema Documentation

Complete reference for all tables, columns, and relationships in ChronoQuery.

## Overview

ChronoQuery uses 17 tables across two categories:
- **9 Core Game Tables**: Store timeline, location, people, and event data
- **8 Game Mechanics Tables**: Handle players, missions, progress tracking

## Table of Contents
1. [Core Game Tables](#core-game-tables)
2. [Game Mechanics Tables](#game-mechanics-tables)
3. [Relationships](#relationships)
4. [Views](#views)
5. [Stored Procedures](#stored-procedures)
6. [Functions](#functions)

---

## Core Game Tables

### `timelines`
Stores different timeline versions (prime timeline and alternate branches).

| Column | Type | Description |
|--------|------|-------------|
| timeline_id | INT (PK) | Unique identifier |
| timeline_name | VARCHAR(100) | Name of timeline |
| branch_date | DATETIME | When timeline diverged |
| parent_timeline_id | INT (FK) | Parent timeline reference |
| is_primary | BIT | TRUE if prime timeline |
| created_date | DATETIME | When created |

**Example:**
```sql
SELECT * FROM timelines WHERE is_primary = 1;
-- Returns: Prime Timeline
```

---

### `locations`
Physical places with temporal validity periods.

| Column | Type | Description |
|--------|------|-------------|
| location_id | INT (PK) | Unique identifier |
| location_name | VARCHAR(200) | Name of location |
| latitude | DECIMAL(10,8) | GPS coordinate |
| longitude | DECIMAL(11,8) | GPS coordinate |
| time_period_start | DATETIME | When location begins existing |
| time_period_end | DATETIME | When location stops existing (NULL = ongoing) |
| location_type | VARCHAR(50) | city, colony, building, etc. |
| timeline_version | INT (FK) | Which timeline |

**Example:**
```sql
-- Find all locations that existed in 1850
SELECT * FROM locations 
WHERE '1850-01-01' BETWEEN time_period_start 
  AND ISNULL(time_period_end, '9999-12-31');
```

**Anomaly Potential:** Events occurring before `time_period_start` or after `time_period_end`

---

### `people`
Individuals with birth/death information.

| Column | Type | Description |
|--------|------|-------------|
| person_id | INT (PK) | Unique identifier |
| person_name | VARCHAR(200) | Full name |
| birth_date | DATETIME | When born |
| death_date | DATETIME | When died (NULL = still alive) |
| birth_location_id | INT (FK) | Where born |
| death_location_id | INT (FK) | Where died |
| timeline_version | INT (FK) | Which timeline |
| occupation | VARCHAR(100) | Job/role |
| notes | NVARCHAR(MAX) | Additional info |

**Example:**
```sql
-- Find people who lived in the 1800s
SELECT * FROM people 
WHERE birth_date >= '1800-01-01' 
  AND birth_date < '1900-01-01';
```

**Anomaly Potential:** 
- `birth_date > death_date` (age paradox)
- Multiple people with same name/birth_date (duplicates)
- Person at event before birth or after death

---

### `events`
Temporal occurrences at specific locations.

| Column | Type | Description |
|--------|------|-------------|
| event_id | INT (PK) | Unique identifier |
| event_type | VARCHAR(100) | coronation, meeting, invention, etc. |
| event_date | DATETIME | When occurred |
| location_id | INT (FK) | Where occurred |
| description | NVARCHAR(MAX) | Details |
| timeline_version | INT (FK) | Which timeline |
| duration_minutes | INT | How long it lasted |
| impact_level | INT | Significance (1-10) |

**Example:**
```sql
-- Find all meetings in 1891
SELECT * FROM events 
WHERE event_type = 'meeting' 
  AND YEAR(event_date) = 1891;
```

**Anomaly Potential:**
- Events at locations before they exist
- Events involving people who aren't alive yet

---

### `person_events`
Junction table linking people to events (who attended what).

| Column | Type | Description |
|--------|------|-------------|
| person_event_id | INT (PK) | Unique identifier |
| person_id | INT (FK) | Who attended |
| event_id | INT (FK) | What event |
| role | VARCHAR(50) | participant, witness, victim, etc. |
| arrival_time | DATETIME | When they arrived |
| departure_time | DATETIME | When they left |

**Example:**
```sql
-- Find all events Marcus Aurelius attended
SELECT e.* 
FROM events e
JOIN person_events pe ON e.event_id = pe.event_id
JOIN people p ON pe.person_id = p.person_id
WHERE p.person_name = 'Marcus Aurelius';
```

**Anomaly Potential:**
- `departure_time < arrival_time`
- Person at event before birth/after death
- Same person at multiple events simultaneously

---

### `objects`
Physical items that can be displaced in time.

| Column | Type | Description |
|--------|------|-------------|
| object_id | INT (PK) | Unique identifier |
| object_name | VARCHAR(200) | Name/description |
| object_type | VARCHAR(100) | artifact, technology, document, etc. |
| creation_date | DATETIME | When created/made |
| destruction_date | DATETIME | When destroyed (NULL = still exists) |
| current_location_id | INT (FK) | Where it is now |
| current_time_period | DATETIME | When it is now |
| timeline_version | INT (FK) | Which timeline |
| creator_person_id | INT (FK) | Who made it |
| material | VARCHAR(100) | What it's made of |

**Example:**
```sql
-- Find all technology objects
SELECT * FROM objects WHERE object_type = 'technology';
```

**Anomaly Potential:**
- Object exists before `creation_date`
- Object used after `destruction_date`
- Modern objects in ancient times
- Object at location before location exists

---

### `object_movements`
Tracks when objects move between locations.

| Column | Type | Description |
|--------|------|-------------|
| movement_id | INT (PK) | Unique identifier |
| object_id | INT (FK) | What moved |
| from_location_id | INT (FK) | Starting location |
| to_location_id | INT (FK) | Ending location |
| movement_date | DATETIME | When moved |
| carrier_person_id | INT (FK) | Who carried it (NULL = unknown) |
| transport_method | VARCHAR(100) | horse, ship, teleport, etc. |
| distance_km | DECIMAL(10,2) | Distance traveled |

**Example:**
```sql
-- Track an object's journey
SELECT 
    om.movement_date,
    l1.location_name as from_location,
    l2.location_name as to_location,
    p.person_name as carrier
FROM object_movements om
LEFT JOIN locations l1 ON om.from_location_id = l1.location_id
LEFT JOIN locations l2 ON om.to_location_id = l2.location_id
LEFT JOIN people p ON om.carrier_person_id = p.person_id
WHERE om.object_id = 1
ORDER BY om.movement_date;
```

**Anomaly Potential:**
- Movement before object creation
- Impossible travel times (distance too far for time period)
- Carrier person didn't exist yet

---

### `relationships`
Connections between people (family, friends, etc.).

| Column | Type | Description |
|--------|------|-------------|
| relationship_id | INT (PK) | Unique identifier |
| person1_id | INT (FK) | First person |
| person2_id | INT (FK) | Second person |
| relationship_type | VARCHAR(50) | parent, child, friend, enemy, etc. |
| start_date | DATETIME | When relationship began |
| end_date | DATETIME | When ended (NULL = ongoing) |
| timeline_version | INT (FK) | Which timeline |

**Example:**
```sql
-- Find all of Sherlock Holmes's relationships
SELECT 
    p2.person_name,
    r.relationship_type,
    r.start_date
FROM relationships r
JOIN people p1 ON r.person1_id = p1.person_id
JOIN people p2 ON r.person2_id = p2.person_id
WHERE p1.person_name = 'Sherlock Holmes';
```

**Anomaly Potential:**
- Relationships starting before birth
- Parent-child age inconsistencies
- Relationship with self (`person1_id = person2_id`)

---

### `temporal_rules`
Defines the laws of time that must not be violated.

| Column | Type | Description |
|--------|------|-------------|
| rule_id | INT (PK) | Unique identifier |
| rule_type | VARCHAR(50) | causality, consistency, physics, logic |
| rule_name | NVARCHAR(MAX) | Name of rule |
| description | NVARCHAR(MAX) | What the rule enforces |
| sql_check | NVARCHAR(MAX) | Query to validate rule |
| severity | INT | How serious (1-10) |
| is_active | BIT | Whether currently enforced |

**Example:**
```sql
SELECT * FROM temporal_rules WHERE severity >= 9;
```

---

### `anomalies`
Detected violations of temporal rules.

| Column | Type | Description |
|--------|------|-------------|
| anomaly_id | INT (PK) | Unique identifier |
| anomaly_type | VARCHAR(100) | Type of violation |
| severity | INT | How serious (1-10) |
| time_period | DATETIME | When anomaly occurs |
| related_entity_type | VARCHAR(50) | person, object, event, location |
| related_entity_id | INT | ID of affected entity |
| description | NVARCHAR(MAX) | What's wrong |
| status | VARCHAR(20) | active, resolved, investigating |
| detected_date | DATETIME | When discovered |
| resolved_date | DATETIME | When fixed (NULL = not fixed) |
| timeline_version | INT (FK) | Which timeline |

**Example:**
```sql
-- View all unresolved anomalies
SELECT * FROM anomalies WHERE status = 'active';
```

---

## Game Mechanics Tables

### `players`
Registered players of the game.

| Column | Type | Description |
|--------|------|-------------|
| player_id | INT (PK) | Unique identifier |
| username | VARCHAR(100) | Display name |
| email | VARCHAR(200) | Email address |
| password_hash | VARCHAR(255) | Encrypted password |
| rank | VARCHAR(50) | Cadet, Agent, Senior, Time Lord |
| total_score | INT | Cumulative points |
| current_level | INT | Highest unlocked mission |
| created_date | DATETIME | When joined |
| last_login | DATETIME | Last activity |

---

### `missions`
Available challenges for players.

| Column | Type | Description |
|--------|------|-------------|
| mission_id | INT (PK) | Unique identifier |
| mission_number | INT | Sequential order (1-30) |
| mission_name | VARCHAR(200) | Display name |
| phase | VARCHAR(50) | Academy, Field Agent, Senior, Time Lord |
| difficulty_level | INT | 1-10 difficulty |
| description | NVARCHAR(MAX) | Short summary |
| briefing | NVARCHAR(MAX) | Full story/context |
| success_criteria | NVARCHAR(MAX) | What to find |
| solution_query | NVARCHAR(MAX) | Official answer |
| min_score | INT | Points to pass |
| time_limit_seconds | INT | Optional speed requirement |
| is_active | BIT | Available to play |

---

### `mission_hints`
Help text for stuck players.

| Column | Type | Description |
|--------|------|-------------|
| hint_id | INT (PK) | Unique identifier |
| mission_id | INT (FK) | Which mission |
| hint_level | INT | 1, 2, or 3 |
| hint_text | NVARCHAR(MAX) | Hint content |
| score_penalty | INT | Points deducted |

---

### `player_progress`
Tracks individual player advancement.

| Column | Type | Description |
|--------|------|-------------|
| progress_id | INT (PK) | Unique identifier |
| player_id | INT (FK) | Which player |
| mission_id | INT (FK) | Which mission |
| status | VARCHAR(20) | locked, available, in_progress, completed |
| attempts | INT | Submission count |
| hints_used | INT | Hints requested |
| score | INT | Points earned |
| completion_time_seconds | INT | How long it took |
| submitted_query | NVARCHAR(MAX) | Final answer |
| started_date | DATETIME | When began |
| completed_date | DATETIME | When finished |

---

### `query_submissions`
Log of all player query attempts.

| Column | Type | Description |
|--------|------|-------------|
| submission_id | INT (PK) | Unique identifier |
| player_id | INT (FK) | Who submitted |
| mission_id | INT (FK) | For which mission |
| submitted_query | NVARCHAR(MAX) | The SQL code |
| is_correct | BIT | Pass/fail |
| execution_time_ms | INT | Performance metric |
| rows_returned | INT | Result count |
| score_earned | INT | Points awarded |
| feedback | NVARCHAR(MAX) | Validation message |
| submission_date | DATETIME | When submitted |

---

### `achievements`
Available badges to unlock.

| Column | Type | Description |
|--------|------|-------------|
| achievement_id | INT (PK) | Unique identifier |
| achievement_name | NVARCHAR(MAX) | Badge name |
| description | NVARCHAR(MAX) | How to unlock |
| badge_icon | VARCHAR(200) | Image filename |
| unlock_criteria | NVARCHAR(MAX) | Conditions |
| points | INT | Bonus points |

---

### `player_achievements`
Tracks which players earned which badges.

| Column | Type | Description |
|--------|------|-------------|
| player_achievement_id | INT (PK) | Unique identifier |
| player_id | INT (FK) | Who unlocked |
| achievement_id | INT (FK) | Which badge |
| unlocked_date | DATETIME | When earned |

---

### `leaderboard`
Rankings of all players.

| Column | Type | Description |
|--------|------|-------------|
| rank_position | INT | Current rank |
| player_id | INT (FK) | Player reference |
| username | NVARCHAR(MAX) | Display name |
| total_score | INT | Total points |
| missions_completed | INT | Count of finished missions |
| average_time | DECIMAL(10,2) | Avg completion time |
| last_updated | DATETIME | When refreshed |

---

## Relationships

### Entity Relationship Diagram