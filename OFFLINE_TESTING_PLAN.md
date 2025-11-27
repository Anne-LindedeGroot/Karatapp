# Offline Functionality Testing Plan

## Overview
This document outlines the comprehensive testing plan for offline functionality in the Karate Flutter app.

## Test Environment Setup
- App is running in debug mode
- Supabase backend is connected
- Local storage (Hive) is initialized
- Offline services are configured

## Test Cases

### 1. Likes Persistence Offline (Katas & Ohyos)

**Objective:** Verify that likes persist when offline and sync when back online.

**Steps:**
1. Ensure app has internet connection
2. Load katas and ohyos from server
3. Like several katas and ohyos
4. Verify likes are immediately reflected in UI
5. Disconnect internet connection
6. Verify likes still show as liked in offline mode
7. Try to like/unlike additional items while offline
8. Verify new likes are queued for sync
9. Reconnect internet
10. Verify offline likes sync to server

**Expected Results:**
- Likes persist in local storage when offline
- UI correctly shows liked state from cache
- New likes are queued in offline queue service
- Likes sync successfully when connection restored
- No data loss during offline/online transitions

### 2. Image/Media Caching Offline

**Objective:** Verify that kata and ohyo images display from cache when offline.

**Steps:**
1. Ensure comprehensive cache is completed (or trigger it)
2. Check cache directory has media files
3. Disconnect internet connection
4. Navigate to kata and ohyo detail screens
5. Verify images load from cache
6. Check image loading performance (should be instant)
7. Verify placeholder/error handling for uncached images

**Expected Results:**
- Images display immediately from cache
- No network requests made for cached images
- Proper fallback for missing images
- Cached images maintain quality and aspect ratio

### 3. Forum Posts Offline Display

**Objective:** Verify forum posts display from cached data when offline.

**Steps:**
1. Load forum posts with internet connection
2. Verify posts are cached locally
3. Disconnect internet connection
4. Navigate to forum screen
5. Verify posts load from cache
6. Open forum post details
7. Verify post content displays correctly
8. Test forum post interactions (if available offline)

**Expected Results:**
- Forum posts load instantly from cache
- Post content, titles, and metadata preserved
- No network dependency for basic post viewing
- Offline indicator shows when appropriate

### 4. Comprehensive Offline Sync

**Objective:** Test full offline sync functionality including media caching.

**Steps:**
1. Clear all local caches
2. Trigger comprehensive cache operation
3. Monitor sync progress and status
4. Verify all data types are cached:
   - Katas with metadata and likes
   - Ohyos with metadata and likes
   - Forum posts
   - Media files (images and videos)
5. Check local storage sizes
6. Verify cache cleanup functionality

**Expected Results:**
- All content types sync successfully
- Progress indication works correctly
- Media files are cached appropriately
- Storage usage is reasonable
- Cache can be cleared when needed

### 5. Full Offline App Operation

**Objective:** Run app completely offline and verify all functionality.

**Steps:**
1. Ensure comprehensive cache is complete
2. Disconnect all internet connections
3. Restart app (or simulate app restart)
4. Verify app starts without network
5. Test all major features:
   - Browse katas and ohyos
   - View cached images
   - Read forum posts
   - Access favorites
   - Use search functionality
6. Test offline interactions:
   - Like/unlike content
   - Add comments (should queue)
   - Navigate between screens
7. Reconnect and verify sync works

**Expected Results:**
- App functions normally without internet
- Cached content loads quickly
- Offline interactions are queued properly
- No crashes or errors due to network unavailability
- Sync works seamlessly when connection restored

## Testing Tools & Verification

### Manual Verification Points
- UI state reflects cached data
- Network indicators show offline status
- Error handling for network-dependent features
- Performance metrics (loading times)

### Data Verification
- Local storage contains expected data
- Cache files exist and are readable
- Offline queue contains pending operations
- Sync status updates correctly

### Edge Cases to Test
- App restart while offline
- Network interruption during sync
- Cache corruption handling
- Storage space limitations
- Multiple offline sessions

## Success Criteria
- All cached data displays correctly offline
- Likes persist and sync properly
- Images load instantly from cache
- App remains functional without internet
- Sync process works reliably
- No data loss during offline/online transitions
