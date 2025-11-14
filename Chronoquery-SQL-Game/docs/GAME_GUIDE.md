# ChronoQuery Game Guide

Complete guide to playing and mastering ChronoQuery.

## Table of Contents
1. [Game Overview](#game-overview)
2. [How to Play](#how-to-play)
3. [Mission Phases](#mission-phases)
4. [Scoring System](#scoring-system)
5. [Achievements](#achievements)
6. [Tips & Strategies](#tips--strategies)

## Game Overview

### The Story
You are a newly recruited agent at the **Time Bureau**, an organization dedicated to maintaining the integrity of the space-time continuum. Reality itself is stored in a massive temporal database, and your job is to detect and fix temporal anomalies using SQL queries.

### Game Objective
Progress through 30 missions across 4 difficulty phases, detecting temporal paradoxes, displaced objects, duplicate entities, and timeline violations.

## How to Play

### Mission Structure
Each mission consists of:
- **Briefing**: Story context and your objective
- **Success Criteria**: What your query should return
- **3 Hints**: Available if you get stuck (costs points)
- **Solution Validation**: Submit your query for scoring

### Basic Workflow
```sql
-- 1. Read the mission briefing
SELECT briefing FROM missions WHERE mission_number = 1;

-- 2. Explore the relevant tables
SELECT * FROM people;
SELECT * FROM events;
SELECT * FROM objects;

-- 3. Write your query
SELECT ... FROM ... WHERE ...

-- 4. Submit for validation
EXEC sp_submit_query @player_id = 1, @mission_id = 1, 
     @submitted_query = 'YOUR QUERY';
```

## Mission Phases

### Phase 1: Academy (Missions 1-5)
**Rank:** Cadet  
**Skills:** Basic SELECT, WHERE, ORDER BY, NULL handling  
**Focus:** Single-table queries and obvious anomalies

**Example Concepts:**
- Finding records with specific criteria
- Date comparisons
- Handling NULL values
- Basic sorting and limiting

### Phase 2: Field Agent (Missions 6-12)
**Rank:** Agent  
**Skills:** JOINs (INNER, LEFT, RIGHT), GROUP BY, HAVING, aggregates  
**Focus:** Multi-table investigations

**Example Concepts:**
- Joining related tables
- Counting, summing, averaging
- Finding missing relationships
- Grouping and filtering groups

### Phase 3: Senior Investigator (Missions 13-20)
**Rank:** Senior Agent  
**Skills:** Subqueries, CTEs, window functions, complex date math  
**Focus:** Subtle anomalies requiring deep analysis

**Example Concepts:**
- Correlated subqueries
- Common Table Expressions
- ROW_NUMBER, RANK, LAG, LEAD
- Complex temporal calculations
- NOT EXISTS / NOT IN

### Phase 4: Time Lord (Missions 21-30)
**Rank:** Time Lord  
**Skills:** Advanced everything, optimization, complex set operations  
**Focus:** Reality-threatening paradoxes

**Example Concepts:**
- UNION, INTERSECT, EXCEPT
- Recursive CTEs
- Complex self-joins
- Multi-level aggregations
- Query optimization

## Scoring System

### Base Score
- **Mission completion**: 100-1000 points (based on difficulty)
- **Speed bonus**: Complete faster for extra points
- **Efficiency bonus**: Optimized queries score higher

### Penalties
- **Hint usage**:
  - Hint 1: -10 points
  - Hint 2: -25 points
  - Hint 3: -50 points
- **Failed attempts**: -5 points per incorrect submission

### Multipliers
- **No hints used**: 1.5x multiplier
- **Perfect run** (no failed attempts): 1.25x multiplier
- **Speed run** (under time limit): 1.25x multiplier

## Achievements

| Achievement | Requirements | Points |
|-------------|--------------|--------|
| 🎓 First Steps in Time | Complete Mission 1 | 100 |
| 🎖️ Academy Graduate | Complete Missions 1-5 | 500 |
| 🔍 Paradox Hunter | Find 10 anomalies | 250 |
| ⚡ Speed Demon | Complete mission < 60 sec | 300 |
| 💎 Perfect Detective | Complete without hints | 200 |
| 🧠 SQL Master | Use all query types | 400 |
| 👑 Time Lord | Complete all 30 missions | 5000 |

## Tips & Strategies

### General Tips
1. **Read the briefing carefully** - It tells you exactly what to look for
2. **Explore the schema** - Know what tables and columns exist
3. **Start simple** - Build your query incrementally
4. **Use table aliases** - Makes queries cleaner: `SELECT p.name FROM people p`
5. **Test small first** - Use `TOP 10` to test before running full query

### SQL Writing Tips
```sql
-- ✅ GOOD: Clear, readable, uses aliases
SELECT 
    p.person_name,
    e.event_date,
    l.location_name
FROM people p
INNER JOIN person_events pe ON p.person_id = pe.person_id
INNER JOIN events e ON pe.event_id = e.event_id
INNER JOIN locations l ON e.location_id = l.location_id
WHERE e.event_date < p.birth_date;

-- ❌ BAD: Hard to read, no structure
SELECT people.person_name,events.event_date FROM people,person_events,events WHERE people.person_id=person_events.person_id AND person_events.event_id=events.event_id
```

### Debugging Tips
1. **Break complex queries into parts**
```sql
   -- Test the JOIN first
   SELECT * FROM people p
   INNER JOIN person_events pe ON p.person_id = pe.person_id;
   
   -- Then add the WHERE clause
```

2. **Use comments to plan**
```sql
   -- Step 1: Get all events
   -- Step 2: Join to people
   -- Step 3: Filter for paradoxes
```

3. **Check row counts**
```sql
   SELECT COUNT(*) FROM your_query;
```

### Mission-Specific Tips

**For JOIN missions:**
- Start with INNER JOIN, switch to LEFT JOIN if you need to find missing matches
- Always specify the ON condition clearly

**For aggregate missions:**
- Remember: WHERE filters before grouping, HAVING filters after
- Use meaningful aliases: `COUNT(*) as event_count`

**For date missions:**
- Use DATEADD, DATEDIFF for calculations
- Remember time zones don't matter in this game

**For window function missions:**
- ROW_NUMBER() for ranking
- LAG()/LEAD() for comparing to previous/next row
- PARTITION BY to reset calculations per group

## Common Anomaly Types

| Anomaly | Description | Example Query Pattern |
|---------|-------------|----------------------|
| Age Paradox | Birth > Death | `WHERE birth_date > death_date` |
| Temporal Displacement | Object in wrong era | `WHERE creation_date > current_time_period` |
| Impossible Encounter | Event before birth | `WHERE event_date < birth_date` |
| Duplicate Entity | Same person twice | `GROUP BY ... HAVING COUNT(*) > 1` |
| Missing Causality | Effect before cause | Complex JOIN with date logic |

## Advanced Techniques

### Using Views
The game includes helpful views:
```sql
-- See all active problems
SELECT * FROM vw_active_anomalies;

-- Check your stats
SELECT * FROM vw_player_stats;

-- Find timeline violations
SELECT * FROM vw_timeline_violations;
```

### Using Functions
```sql
-- Get person's age at event
SELECT dbo.fn_age_at_event(1, '1861-03-08');

-- Check if location valid for date
SELECT dbo.fn_is_valid_location_date(1, '1800-01-01');
```

## Need Help?

- 💡 Use hints (but they cost points!)
- 📚 Review SQL tutorials online
- 🤝 Join the community discussions
- 📖 Check [DATABASE_SCHEMA.md](DATABASE_SCHEMA.md) for table details

## Next Steps

Once you've mastered the basics:
1. Try completing missions without hints
2. Optimize your queries for speed
3. Challenge yourself with time limits
4. Create your own missions (see [MISSION_DESIGN.md](MISSION_DESIGN.md))

---

**Good luck, Agent! The timeline is counting on you. ⏰**