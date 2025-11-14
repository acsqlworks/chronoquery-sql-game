# Mission Design Guide

Learn how to create custom missions for ChronoQuery.

## Table of Contents
1. [Mission Structure](#mission-structure)
2. [Difficulty Guidelines](#difficulty-guidelines)
3. [Creating a Mission](#creating-a-mission)
4. [Writing Hints](#writing-hints)
5. [Testing Your Mission](#testing-your-mission)
6. [Submission Guidelines](#submission-guidelines)

---

## Mission Structure

Every mission needs:
1. **Narrative briefing** - Story context
2. **Clear objective** - What to find
3. **Success criteria** - What the query should return
4. **Solution query** - Official answer
5. **3 hints** - Progressively detailed help
6. **Test data** - Anomalies that prove the mission works

---

## Difficulty Guidelines

### Level 1-5: Academy (Cadet)
**SQL Concepts:**
- Basic SELECT statements
- WHERE clause filtering
- Simple comparisons (>, <, =, !=)
- IS NULL / IS NOT NULL
- ORDER BY, TOP/LIMIT
- Single table queries only

**Anomaly Characteristics:**
- Obvious violations (birth > death)
- Single-table problems
- Clear patterns

**Example:**
```sql
-- Find people born after they died
SELECT * FROM people 
WHERE death_date IS NOT NULL 
  AND birth_date > death_date;
```

---

### Level 6-12: Field Agent
**SQL Concepts:**
- INNER JOIN, LEFT JOIN, RIGHT JOIN
- Basic aggregates (COUNT, SUM, AVG, MIN, MAX)
- GROUP BY and HAVING
- Multiple table queries
- Date functions (DATEDIFF, DATEADD, YEAR, MONTH)

**Anomaly Characteristics:**
- Requires correlating data across tables
- Missing relationships
- Aggregate-based problems

**Example:**
```sql
-- Find events with no participants
SELECT e.* 
FROM events e
LEFT JOIN person_events pe ON e.event_id = pe.event_id
WHERE pe.person_event_id IS NULL;
```

---

### Level 13-20: Senior Investigator
**SQL Concepts:**
- Subqueries (correlated and non-correlated)
- Common Table Expressions (CTEs)
- Window functions (ROW_NUMBER, RANK, LAG, LEAD)
- NOT EXISTS / NOT IN
- Complex date calculations
- CASE statements

**Anomaly Characteristics:**
- Subtle violations
- Requires multiple steps of logic
- Pattern detection across time

**Example:**
```sql
-- Find people who attended events in impossible sequence
WITH event_sequence AS (
    SELECT 
        pe.person_id,
        e.event_date,
        e.location_id,
        LAG(e.location_id) OVER (
            PARTITION BY pe.person_id 
            ORDER BY e.event_date
        ) as prev_location_id,
        LAG(e.event_date) OVER (
            PARTITION BY pe.person_id 
            ORDER BY e.event_date
        ) as prev_event_date
    FROM person_events pe
    JOIN events e ON pe.event_id = e.event_id
)
SELECT * FROM event_sequence
WHERE prev_location_id IS NOT NULL
  AND location_id != prev_location_id
  AND DATEDIFF(HOUR, prev_event_date, event_date) < 1;
```

---

### Level 21-30: Time Lord
**SQL Concepts:**
- UNION, INTERSECT, EXCEPT
- Recursive CTEs
- Complex self-joins
- Advanced window functions
- Query optimization
- Dynamic pivoting

**Anomaly Characteristics:**
- Reality-threatening paradoxes
- Multi-layered problems
- Requires all previous skills
- Open-ended investigation

**Example:**
```sql
-- Find circular ancestry (grandfather paradox)
WITH RECURSIVE ancestry AS (
    -- Base case: direct parents
    SELECT 
        person1_id as descendant_id,
        person2_id as ancestor_id,
        1 as generation_distance
    FROM relationships
    WHERE relationship_type = 'parent'
    
    UNION ALL
    
    -- Recursive case: ancestors of ancestors
    SELECT 
        a.descendant_id,
        r.person2_id,
        a.generation_distance + 1
    FROM ancestry a
    JOIN relationships r ON a.ancestor_id = r.person1_id
    WHERE r.relationship_type = 'parent'
      AND a.generation_distance < 10
)
SELECT * FROM ancestry
WHERE descendant_id = ancestor_id;  -- Person is their own ancestor!
```

---

## Creating a Mission

### Step 1: Choose a SQL Concept
Pick ONE main concept to teach:
- ✅ GOOD: "This mission teaches LEFT JOIN"
- ❌ BAD: "This mission teaches JOINs, subqueries, and window functions"

### Step 2: Create the Anomaly Data
Add test data that demonstrates the problem:
```sql
-- Example: Mission about impossible encounters
INSERT INTO people (person_name, birth_date, timeline_version)
VALUES ('Time Traveler', '2100-01-01', 1);

INSERT INTO events (event_type, event_date, location_id, timeline_version)
VALUES ('ancient_meeting', '1500-01-01', 1, 1);

INSERT INTO person_events (person_id, event_id, role)
VALUES (
    (SELECT person_id FROM people WHERE person_name = 'Time Traveler'),
    (SELECT event_id FROM events WHERE event_type = 'ancient_meeting'),
    'participant'
);
```

### Step 3: Write the Narrative
Create an engaging story:
```sql
INSERT INTO missions (
    mission_number, 
    mission_name, 
    phase, 
    difficulty_level,
    description,
    briefing
) VALUES (
    X,
    'The Impossible Meeting',
    'Field Agent',
    7,
    'Find people who attended events before they were born',
    'Agent, we''ve detected a temporal anomaly at the Ancient Rome summit. 
    According to our records, someone who shouldn''t have been born yet 
    was present at the meeting. This is a clear causality violation.
    
    Your task: Write a query that finds all person_events where the 
    person attended an event BEFORE their birth_date. This requires 
    joining the people, person_events, and events tables.
    
    Return: person_name, birth_date, event_date, event_type'
);
```

### Step 4: Define Success Criteria
Be specific about what the query should return:
```sql
UPDATE missions SET success_criteria = 
'Query must return:
- All people who attended events before birth
- Columns: person_name, birth_date, event_date, event_type
- Must use JOINs across people, person_events, events
- Must have WHERE clause comparing event_date < birth_date'
WHERE mission_number = X;
```

### Step 5: Write the Solution
Create the official answer:
```sql
UPDATE missions SET solution_query = 
'SELECT 
    p.person_name,
    p.birth_date,
    e.event_date,
    e.event_type
FROM people p
INNER JOIN person_events pe ON p.person_id = pe.person_id
INNER JOIN events e ON pe.event_id = e.event_id
WHERE e.event_date < p.birth_date;'
WHERE mission_number = X;
```

---

## Writing Hints

Hints should follow a 3-tier system:

### Hint Level 1: Gentle Nudge (10 point penalty)
Point to the right tables without giving away the approach.

**Example:**
```sql
INSERT INTO mission_hints (mission_id, hint_level, hint_text, score_penalty)
VALUES (
    X,
    1,
    'You''ll need to look at three tables: people, person_events, and events. 
    Think about how these tables relate to each other.',
    10
);
```

### Hint Level 2: Approach Guidance (25 point penalty)
Explain the technique needed without showing the code.

**Example:**
```sql
INSERT INTO mission_hints (mission_id, hint_level, hint_text, score_penalty)
VALUES (
    X,
    2,
    'Use INNER JOINs to connect people -> person_events -> events. 
    Then use a WHERE clause to compare the event_date with the person''s birth_date.
    You''re looking for cases where the event happened BEFORE the birth.',
    25
);
```

### Hint Level 3: Nearly the Solution (50 point penalty)
Provide the query structure with placeholders.

**Example:**
```sql
INSERT INTO mission_hints (mission_id, hint_level, hint_text, score_penalty)
VALUES (
    X,
    3,
    'SELECT p.person_name, p.birth_date, e.event_date, e.event_type
    FROM people p
    INNER JOIN person_events pe ON p.person_id = pe.person_id
    INNER JOIN events e ON pe.event_id = e.event_id
    WHERE e.event_date < p.birth_date;',
    50
);
```

---

## Testing Your Mission

### Checklist
- [ ] Run your solution query on fresh database
- [ ] Verify it returns the expected anomalies
- [ ] Test that similar-but-wrong queries DON'T work
- [ ] Ensure hints actually help (test on non-SQL friend)
- [ ] Check that mission fits difficulty level
- [ ] Verify no SQL syntax errors
- [ ] Confirm anomaly data is inserted correctly

### Test Queries
```sql
-- Does your solution work?
-- [Run your solution query]

-- Are there false positives?
SELECT * FROM [your result] 
WHERE [shouldn't be included];

-- Are there false negatives?
SELECT * FROM [expected table]
WHERE [conditions]
  AND NOT EXISTS (SELECT 1 FROM [your result] WHERE ...);

-- Do the hints lead to the solution?
-- [Follow each hint and see if you can solve it]
```

---

## Submission Guidelines

### File Structure
Create a new file: `missions/phase_X_name/mission_XX.sql`
```sql
-- =====================================================
-- MISSION XX: [Mission Name]
-- Phase: [Phase Name]
-- Difficulty: X/10
-- Concept: [Main SQL concept taught]
-- =====================================================

-- Step 1: Create anomaly data
INSERT INTO people ...
INSERT INTO events ...
-- etc.

-- Step 2: Insert mission definition
INSERT INTO missions (...) VALUES (...);

-- Step 3: Add hints
INSERT INTO mission_hints (...) VALUES (...);

-- Step 4: (Optional) Add to anomalies table
INSERT INTO anomalies (...) VALUES (...);

-- Step 5: Verification query
SELECT * FROM missions WHERE mission_number = XX;
SELECT * FROM mission_hints WHERE mission_id = (
    SELECT mission_id FROM missions WHERE mission_number = XX
);

-- Step 6: Test the solution
-- [Your solution query here]

PRINT 'Mission XX setup complete!';
```

### Pull Request Template
When submitting to GitHub:

**Title:** `feat: Add Mission XX - [Mission Name]`

**Description:**