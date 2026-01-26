# Check Network Tab - No API Call Showing

## Possible Reasons

### 1. Network Tab Filters
Check if filters are hiding the request:
- Look for filter buttons (XHR, Fetch, JS, etc.)
- Click "All" to show everything
- Check if "Preserve log" is enabled (should be ON)

### 2. Request Happening But Not Visible
- The request might be very fast
- Check "Preserve log" checkbox (top of Network tab)
- Try moving the card slowly

### 3. Optimistic Update Only
The frontend might be doing optimistic updates without waiting for API response.

## How to Find It

1. **Enable Preserve Log**
   - Check the "Preserve log" checkbox in Network tab
   - This keeps requests even after navigation

2. **Clear and Watch**
   - Clear the log
   - Move the card
   - Look for ANY new requests (not just the move endpoint)

3. **Check Console Tab**
   - Look for errors or logs
   - Check if there's a failed request

4. **Check Response Tab**
   - If you see the request, check the Response tab
   - See if it's returning an error

## Next Steps

If you still don't see the API call:
- The frontend might be broken
- Or it's using a different method (WebSocket, Server-Sent Events, etc.)

Let me know what you see in the Network tab!