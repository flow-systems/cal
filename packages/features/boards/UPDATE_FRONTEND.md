# Update Your Frontend to Use New API

## Current Status

Your debug logs show you're already using an API that returns `affectedCards`. Now we need to update it to use the new atomic endpoint: `trpc.viewer.boards.moveCard`

## Find Your Current Code

Look for files that contain:
- `apiMoveSuccess` (from your debug logs)
- `handleDragEnd` or `onDragEnd`
- Card move API calls

Common locations:
- Kanban board component
- Board detail page
- Card drag handler

## Update Pattern

### Before (Old API)

```typescript
// Old way - whatever you're currently using
const moveCard = async (cardId, targetColumnId, targetPosition, boardId) => {
  const response = await fetch('/api/move-card', {
    method: 'POST',
    body: JSON.stringify({ cardId, targetColumnId, targetPosition, boardId })
  })
  const data = await response.json()
  // Handle affectedCards
}
```

### After (New tRPC Endpoint)

```typescript
import { trpc } from '@calcom/trpc/react'

const moveCardMutation = trpc.viewer.boards.moveCard.useMutation({
  onSuccess: (data) => {
    // data.affectedCards contains all cards that were updated
    // data.affectedCardsCount is the number
    console.log('Moved successfully!', data.affectedCards)
    
    // Update your UI state with all affected cards
    updateCardsInState(data.affectedCards)
  },
  onError: (error) => {
    console.error('Move failed:', error.message)
    // Handle error (maybe revert optimistic update)
  }
})

// In your drag handler:
const handleDragEnd = async (result) => {
  if (!result.destination) return
  
  const { draggableId, destination } = result
  const cardId = draggableId
  const targetColumnId = destination.droppableId
  const targetPosition = destination.index
  const boardId = currentBoardId
  
  try {
    await moveCardMutation.mutateAsync({
      cardId,
      targetColumnId,
      targetPosition,
      boardId
    })
  } catch (error) {
    // Error already handled in onError
  }
}
```

## Key Benefits

1. **Atomic Operation**: All position updates happen in one transaction
2. **Returns All Affected Cards**: No need to manually calculate which cards moved
3. **Type-Safe**: Full TypeScript support
4. **Single Realtime Event**: Better scalability

## Response Format

The new endpoint returns:

```typescript
{
  success: true,
  affectedCardsCount: 5,
  affectedCards: [
    {
      id: "uuid",
      title: "Card Title",
      column_id: "uuid",
      position: 0,
      updated_at: "2026-01-26T22:09:33Z"
    },
    // ... more affected cards
  ]
}
```

## Update Your State

After a successful move, update your state with all affected cards:

```typescript
const updateCardsInState = (affectedCards: Array<{
  id: string
  title: string
  column_id: string
  position: number
  updated_at: string
}>) => {
  setCards(prevCards => {
    const updated = [...prevCards]
    
    // Update all affected cards
    affectedCards.forEach(affectedCard => {
      const index = updated.findIndex(c => c.id === affectedCard.id)
      if (index >= 0) {
        updated[index] = {
          ...updated[index],
          column_id: affectedCard.column_id,
          position: affectedCard.position,
          updated_at: affectedCard.updated_at
        }
      }
    })
    
    // Sort by column and position
    return updated.sort((a, b) => {
      if (a.column_id !== b.column_id) {
        return a.column_id.localeCompare(b.column_id)
      }
      return a.position - b.position
    })
  })
}
```

## Testing

After updating:
1. ✅ Move a card within the same column
2. ✅ Move a card between columns
3. ✅ Move multiple cards rapidly (test race conditions)
4. ✅ Verify all affected cards update correctly
5. ✅ Check browser console for any errors

---

**Need help finding your frontend code?** Share the file path where you handle card moves and I can help update it!