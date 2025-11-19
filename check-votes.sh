#!/bin/bash

echo "============================================"
echo "  Odilia Vote Counts - McDonald's"
echo "============================================"
echo ""

# Get votes from database (using correct column name: count)
echo "Ì≥ä Current Vote Counts:"
echo "--------------------------------------------"

docker exec mcdonalds-yelb-db psql -U postgres -d yelbdatabase -t -c "
SELECT 
    RPAD(name, 20) || ' | Votes: ' || count 
FROM restaurants 
ORDER BY count DESC;
"

echo "--------------------------------------------"
echo ""

# Get total votes (using correct column name: count)
TOTAL=$(docker exec mcdonalds-yelb-db psql -U postgres -d yelbdatabase -t -c "SELECT COALESCE(SUM(count), 0) FROM restaurants;" | tr -d ' ')
echo "ÌæØ Total Votes Cast: $TOTAL"
echo ""

# Get timestamp
echo "‚è∞ Checked at: $(date)"
echo "============================================"
