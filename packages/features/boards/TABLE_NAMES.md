# Table Names Configuration

## Important: Update Table Names

The implementation assumes the following table names:
- `cards` (for the Card table)
- `boards` (for the Board table)  
- `columns` (for the Column table)

**If your actual table names are different, you MUST update:**

1. **Migration SQL** (`packages/prisma/migrations/20260126204203_transaction_based_card_move/migration.sql`):
   - Replace all instances of `cards` with your actual table name
   - Replace all instances of `boards` with your actual table name
   - Replace all instances of `columns` with your actual table name

2. **Handler** (`packages/trpc/server/routers/viewer/boards/moveCard.handler.ts`):
   - Update raw SQL queries to use your actual table names
   - Update column names if they differ (e.g., `column_id` vs `columnId`)

## Finding Your Actual Table Names

To find your actual table names, check:
1. Your Prisma schema (`packages/prisma/schema.prisma`) for model definitions
2. Database migrations that create these tables
3. Existing code that queries these tables

## Column Names

The implementation assumes:
- `id` (UUID)
- `column_id` (UUID) 
- `board_id` (UUID)
- `position` (INTEGER)
- `title` (TEXT)
- `updated_at` (TIMESTAMP)

If your columns use different names (e.g., camelCase like `columnId`), update the SQL queries accordingly.