#!/bin/bash

clear

echo "╔════════════════════════════════════════════╗"
echo "║   Odilia Voting Dashboard - McDonald's     ║"
echo "╚════════════════════════════════════════════╝"
echo ""

# Get vote data with rankings
echo "��� Restaurant Rankings:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

docker exec mcdonalds-yelb-db psql -U postgres -d yelbdatabase -t -c "
SELECT 
    CASE 
        WHEN ROW_NUMBER() OVER (ORDER BY count DESC) = 1 THEN '���'
        WHEN ROW_NUMBER() OVER (ORDER BY count DESC) = 2 THEN '���'
        WHEN ROW_NUMBER() OVER (ORDER BY count DESC) = 3 THEN '���'
        ELSE '  '
    END || ' ' ||
    RPAD(UPPER(name), 18) || 
    LPAD(count::text, 5) || ' votes'
FROM restaurants 
ORDER BY count DESC;
" 2>/dev/null

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Total votes
TOTAL=$(docker exec mcdonalds-yelb-db psql -U postgres -d yelbdatabase -t -c "SELECT COALESCE(SUM(count), 0) FROM restaurants;" 2>/dev/null | tr -d ' ')
echo ""
echo "��� Total Votes: $TOTAL"

# System status
echo ""
echo "��� System Status:"
REDIS_STATUS=$(docker exec mcdonalds-redis-server redis-cli -a a-very-complex-password-here PING 2>/dev/null)
DB_STATUS=$(docker exec mcdonalds-yelb-db pg_isready 2>/dev/null | grep -o "accepting connections")

if [ "$REDIS_STATUS" = "PONG" ]; then
    echo "   ✅ Redis Cache: Online"
else
    echo "   ❌ Redis Cache: Offline"
fi

if [ "$DB_STATUS" = "accepting connections" ]; then
    echo "   ✅ Database: Online"
else
    echo "   ❌ Database: Offline"
fi

echo ""
echo "⏰ Updated: $(date '+%Y-%m-%d %H:%M:%S')"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
