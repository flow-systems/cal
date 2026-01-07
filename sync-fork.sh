#!/bin/bash

# Sync Fork Script
# Automatically syncs fork with upstream repository
# Logs all operations for monitoring

# Configuration
REPO_DIR="/Users/Mo/Library/CloudStorage/OneDrive-inside360.studio/Repos/cal"
LOG_DIR="$REPO_DIR/.sync-logs"
LOG_FILE="$LOG_DIR/sync-$(date +%Y-%m-%d_%H-%M-%S).log"
UPSTREAM_REMOTE="upstream"
UPSTREAM_URL="https://github.com/calcom/cal.com.git"
BRANCHES=("main" "staging")  # Branches to sync

# Create log directory if it doesn't exist
mkdir -p "$LOG_DIR"

# Function to log messages
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Function to log errors
log_error() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $1" | tee -a "$LOG_FILE" >&2
}

# Start logging
log "===== Starting Fork Sync ====="
log "Repository: $REPO_DIR"

# Change to repository directory
cd "$REPO_DIR" || {
    log_error "Failed to change to repository directory: $REPO_DIR"
    exit 1
}

# Check if we're in a git repository
if [ ! -d .git ]; then
    log_error "Not a git repository: $REPO_DIR"
    exit 1
fi

# Record original branch and stash state
ORIGINAL_BRANCH="$(git rev-parse --abbrev-ref HEAD 2>/dev/null)"
STASH_CREATED=false
STASH_REF=""

# Safely handle uncommitted changes by auto-stashing
if ! git diff-index --quiet HEAD --; then
    log "Uncommitted changes detected on '$ORIGINAL_BRANCH'. Stashing before sync..."
    if STASH_REF=$(git stash push -u -m "auto-sync-$(date +%Y-%m-%d_%H-%M-%S)" 2>&1 | tee -a "$LOG_FILE"); then
        STASH_CREATED=true
        log "Changes stashed. Reference:"
        echo "$STASH_REF" | tee -a "$LOG_FILE"
    else
        log_error "Failed to stash changes. Aborting."
        git status --short | tee -a "$LOG_FILE"
        exit 1
    fi
fi

# Add upstream remote if it doesn't exist
if ! git remote | grep -q "^${UPSTREAM_REMOTE}$"; then
    log "Adding upstream remote: $UPSTREAM_URL"
    if git remote add "$UPSTREAM_REMOTE" "$UPSTREAM_URL"; then
        log "Successfully added upstream remote"
    else
        log_error "Failed to add upstream remote"
        exit 1
    fi
else
    log "Upstream remote already exists"
fi

# Fetch from upstream
log "Fetching from upstream..."
if git fetch "$UPSTREAM_REMOTE"; then
    log "Successfully fetched from upstream"
else
    log_error "Failed to fetch from upstream"
    exit 1
fi

# Fetch from origin
log "Fetching from origin..."
if git fetch origin; then
    log "Successfully fetched from origin"
else
    log_error "Failed to fetch from origin"
    exit 1
fi

# Sync each branch
SYNC_SUCCESS=true
for BRANCH in "${BRANCHES[@]}"; do
    log "--- Syncing branch: $BRANCH ---"
    
    # Check if branch exists locally
    if git show-ref --verify --quiet "refs/heads/$BRANCH"; then
        log "Branch $BRANCH exists locally"
        
        # Checkout the branch
        if git checkout "$BRANCH" 2>&1 | tee -a "$LOG_FILE"; then
            log "Checked out $BRANCH"
        else
            log_error "Failed to checkout $BRANCH"
            SYNC_SUCCESS=false
            continue
        fi
    else
        # Check if branch exists on upstream
        if git show-ref --verify --quiet "refs/remotes/$UPSTREAM_REMOTE/$BRANCH"; then
            log "Branch $BRANCH exists on upstream, creating local branch"
            if git checkout -b "$BRANCH" "$UPSTREAM_REMOTE/$BRANCH" 2>&1 | tee -a "$LOG_FILE"; then
                log "Created and checked out $BRANCH from upstream"
            else
                log_error "Failed to create branch $BRANCH from upstream"
                SYNC_SUCCESS=false
                continue
            fi
        else
            log "Branch $BRANCH does not exist on upstream, skipping"
            continue
        fi
    fi
    
    # Get current commit
    BEFORE_COMMIT=$(git rev-parse HEAD)
    log "Current commit: $BEFORE_COMMIT"
    
    # Merge upstream changes with conflict resolution strategy
    log "Merging upstream/$BRANCH into $BRANCH..."
    
    # Try merge with strategy that prefers our changes for known files
    MERGE_OUTPUT=$(git merge "$UPSTREAM_REMOTE/$BRANCH" --no-edit -X ours 2>&1)
    MERGE_EXIT_CODE=$?
    echo "$MERGE_OUTPUT" | tee -a "$LOG_FILE"
    
    # Check if merge had conflicts
    if [ $MERGE_EXIT_CODE -ne 0 ]; then
        log "Merge conflict detected. Attempting automatic resolution..."
        
        # Resolve conflicts for known files by keeping our version
        CONFLICT_FILES=$(git diff --name-only --diff-filter=U 2>/dev/null || true)
        
        if [ -n "$CONFLICT_FILES" ]; then
            log "Conflicted files: $CONFLICT_FILES"
            
            # For Dockerfile and .dockerignore, always keep our version (Dokploy optimized)
            for file in Dockerfile .dockerignore; do
                if echo "$CONFLICT_FILES" | grep -q "^$file$"; then
                    log "Resolving conflict in $file by keeping our version..."
                    git checkout --ours "$file" 2>&1 | tee -a "$LOG_FILE"
                    git add "$file" 2>&1 | tee -a "$LOG_FILE"
                fi
            done
            
            # Try to complete the merge
            if git commit --no-edit 2>&1 | tee -a "$LOG_FILE"; then
                log "Successfully resolved conflicts and completed merge"
                MERGE_EXIT_CODE=0
            else
                log_error "Failed to resolve conflicts automatically. Manual intervention required."
                log "Aborting merge..."
                git merge --abort 2>&1 | tee -a "$LOG_FILE"
                SYNC_SUCCESS=false
                continue
            fi
        else
            log_error "Merge failed for unknown reason. Aborting..."
            git merge --abort 2>&1 | tee -a "$LOG_FILE"
            SYNC_SUCCESS=false
            continue
        fi
    fi
    
    # If merge succeeded, check if anything changed
    if [ $MERGE_EXIT_CODE -eq 0 ]; then
        AFTER_COMMIT=$(git rev-parse HEAD)
        
        if [ "$BEFORE_COMMIT" = "$AFTER_COMMIT" ]; then
            log "Branch $BRANCH is already up to date"
        else
            log "Successfully merged upstream/$BRANCH"
            log "New commit: $AFTER_COMMIT"
            
            # Show summary of changes
            log "Changes summary:"
            git log --oneline "$BEFORE_COMMIT..$AFTER_COMMIT" | head -20 | tee -a "$LOG_FILE"
            
            # Push to origin
            log "Pushing $BRANCH to origin..."
            if git push origin "$BRANCH" 2>&1 | tee -a "$LOG_FILE"; then
                log "Successfully pushed $BRANCH to origin"
            else
                log_error "Failed to push $BRANCH to origin"
                SYNC_SUCCESS=false
            fi
        fi
    fi
    
    log ""
done

# Restore original branch and any stashed changes
if [ -n "$ORIGINAL_BRANCH" ] && git show-ref --verify --quiet "refs/heads/$ORIGINAL_BRANCH"; then
    if [ "$(git rev-parse --abbrev-ref HEAD)" != "$ORIGINAL_BRANCH" ]; then
        log "Returning to original branch: $ORIGINAL_BRANCH"
        git checkout "$ORIGINAL_BRANCH" 2>&1 | tee -a "$LOG_FILE"
    fi
fi

if [ "$STASH_CREATED" = true ]; then
    log "Restoring previously stashed changes..."
    if git stash list | grep -q "auto-sync-"; then
        # Pop the most recent auto-sync stash
        if git stash pop 2>&1 | tee -a "$LOG_FILE"; then
            log "Stashed changes restored successfully."
        else
            log_error "Failed to auto-restore stashed changes. Leaving stash in place. Resolve manually with 'git stash list' and 'git stash pop'."
            SYNC_SUCCESS=false
        fi
    else
        log "No matching auto-sync stash found. Nothing to restore."
    fi
fi

# Cleanup old logs (keep last 30 days)
log "Cleaning up old logs..."
find "$LOG_DIR" -name "sync-*.log" -type f -mtime +30 -delete
log "Old logs cleaned up"

# Final status
log "===== Fork Sync Complete ====="
if [ "$SYNC_SUCCESS" = true ]; then
    log "Status: SUCCESS"
    exit 0
else
    log_error "Status: FAILED (check logs for details)"
    exit 1
fi

