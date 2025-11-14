# Quick Start Guide

Get playing ChronoQuery in 5 minutes!

## Prerequisites

- SQL Server 2019 or higher
- SQL Server Management Studio (SSMS) or Azure Data Studio

## Installation

### Step 1: Download the Setup File
```bash
git clone https://github.com/yourusername/chronoquery-sql-game.git
cd chronoquery-sql-game
```

### Step 2: Run the Setup Script
1. Open **SQL Server Management Studio**
2. Connect to your SQL Server instance
3. Open `ChronoQuery_Setup.sql`
4. Press **F5** or click **Execute**

Wait 10-30 seconds for the database to be created and populated.

### Step 3: Verify Installation
```sql
USE ChronoQuery;

-- Check if tables exist
SELECT COUNT(*) as table_count 
FROM INFORMATION_SCHEMA.TABLES 
WHERE TABLE_TYPE = 'BASE TABLE';
-- Should return 17

-- View active anomalies
SELECT * FROM vw_active_anomalies;
-- Should return 4 anomalies
```

## Your First Mission

### Mission 1: The Misplaced Artifact

**Read the briefing:**
```sql
SELECT briefing 
FROM missions 
WHERE mission_number = 1;
```

**Your task:** Find objects in Ancient Rome that were created after 500 AD.

**Try this query:**
```sql
SELECT 
    object_name,
    creation_date,
    current_location_id
FROM objects
WHERE current_location_id = 1 
  AND creation_date > '0500-01-01';
```

**Expected result:** You should find a Smartphone in Ancient Rome!

### Getting Hints

Stuck? Request a hint (costs points):
```sql
EXEC sp_get_hint 
    @player_id = 1, 
    @mission_id = 1, 
    @hint_level = 1;
```

### Submitting Your Answer
```sql
EXEC sp_submit_query 
    @player_id = 1,
    @mission_id = 1,
    @submitted_query = 'YOUR QUERY HERE';
```

## Next Steps

- View all missions: `SELECT * FROM missions ORDER BY mission_number;`
- Check your progress: `SELECT * FROM vw_player_stats;`
- See the leaderboard: `SELECT * FROM leaderboard;`

## Troubleshooting

**Error: Database already exists**
```sql
DROP DATABASE ChronoQuery;
-- Then re-run ChronoQuery_Setup.sql
```

**Error: Permission denied**
- Make sure you're running SSMS as Administrator
- Verify you have CREATE DATABASE permissions

**No anomalies showing up**
```sql
-- Manually check anomalies table
SELECT * FROM anomalies WHERE status = 'active';
```

## Need Help?

- 📖 Read the [Game Guide](GAME_GUIDE.md)
- 🐛 [Report a bug](https://github.com/yourusername/chronoquery-sql-game/issues)
- 💬 [Ask a question](https://github.com/yourusername/chronoquery-sql-game/discussions)

---

**Now start your temporal investigation! ⏰**