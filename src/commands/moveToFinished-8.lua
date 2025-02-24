--[[
  Move job from active to a finished status (completed o failed)
  A job can only be moved to completed if it was active.
  The job must be locked before it can be moved to a finished status,
  and the lock must be released in this script.

    Input:
      KEYS[1] active key
      KEYS[2] completed/failed key
      KEYS[3] jobId key
      KEYS[4] wait key
      KEYS[5] priority key
      KEYS[6] event stream key
      KEYS[7] meta key
      KEYS[8] stalled key

      ARGV[1]  jobId
      ARGV[2]  timestamp
      ARGV[3]  msg property
      ARGV[4]  return value / failed reason
      ARGV[5]  target (completed/failed)
      ARGV[6]  shouldRemove
      ARGV[7]  event data (? maybe just send jobid).
      ARGV[8]  fetch next?
      ARGV[9]  keys prefix
      ARGV[10] lock token
      ARGV[11] lock duration in milliseconds
      ARGV[12] parentId
      ARGV[13] parentQueue
      ARGV[14] parentKey

    Output:
      0 OK
      -1 Missing key.
      -2 Missing lock.
      -3 Job not in active set
      -4 Job has pending dependencies

    Events:
      'completed/failed'
]]
local rcall = redis.call

-- Includes
<%= updateParentDepsIfNeeded %>
<%= destructureJobKey %>

local jobIdKey = KEYS[3]
if rcall("EXISTS",jobIdKey) == 1 then -- // Make sure job exists

    if rcall("SCARD", jobIdKey .. ":dependencies") ~= 0 then -- // Make sure it does not have pending dependencies
      return -4
    end

    if ARGV[10] ~= "0" then
      local lockKey = jobIdKey .. ':lock'
      if rcall("GET", lockKey) == ARGV[10] then
          rcall("DEL", lockKey)
          rcall("SREM", KEYS[8], ARGV[1])
      else
          return -2
      end
    end

    local jobId = ARGV[1]

    -- Remove from active list (if not active we shall return error)
    local numRemovedElements = rcall("LREM", KEYS[1], -1, jobId)

    if(numRemovedElements < 1) then
      return -3
    end
    
    -- If job has a parent we need to 
    -- 1) remove this job id from parents dependencies
    -- 2) move the job Id to parent "processed" set
    -- 3) push the results into parent "results" list
    -- 4) if parent's dependencies is empty, then move parent to "wait/paused". Note it may be a different queue!.
    -- NOTE: Priorities not supported yet for parent jobs.
    local parentId = ARGV[12]
    local parentQueueKey = ARGV[13]
    if parentId == "" and ARGV[14] ~= "" then
      parentId = getJobIdFromKey(ARGV[14])
      parentQueueKey = getJobKeyPrefix(ARGV[14], ":" .. parentId)
    end
    if parentId ~= "" and ARGV[5] == "completed" then 
        local parentKey =  parentQueueKey .. ":" .. parentId
        local dependenciesSet = parentKey .. ":dependencies"
        local result = rcall("SREM", dependenciesSet, jobIdKey)
        if result == 1 then 
          updateParentDepsIfNeeded(parentKey, parentQueueKey, dependenciesSet, parentId, jobIdKey, ARGV[4])
        end
    end
    
    -- Remove job?
    local removeJobs = tonumber(ARGV[6])
    if removeJobs ~= 1 then
        -- Add to complete/failed set
        rcall("ZADD", KEYS[2], ARGV[2], jobId)
        rcall("HMSET", jobIdKey, ARGV[3], ARGV[4], "finishedOn", ARGV[2]) -- "returnvalue" / "failedReason" and "finishedOn"

        -- Remove old jobs?
        if removeJobs and removeJobs > 1 then
            local start = removeJobs - 1
            local jobIds = rcall("ZREVRANGE", KEYS[2], start, -1)
            for i, jobId in ipairs(jobIds) do
                local jobKey = ARGV[9] .. jobId
                local jobLogKey = jobKey .. ':logs'
                local jobProcessedKey = jobKey .. ':processed'
                rcall("DEL", jobKey, jobLogKey, jobProcessedKey)
            end
            rcall("ZREMRANGEBYRANK", KEYS[2], 0, -removeJobs)
        end
    else
        local jobLogKey = jobIdKey .. ':logs'
        local jobProcessedKey = jobIdKey .. ':processed'
        rcall("DEL", jobIdKey, jobLogKey, jobProcessedKey)
    end

    rcall("XADD", KEYS[6], "*", "event", ARGV[5], "jobId", jobId, ARGV[3],
          ARGV[4])

    -- Try to get next job to avoid an extra roundtrip if the queue is not closing,
    -- and not rate limited.
    if (ARGV[8] == "1") then
        -- move from wait to active
        local jobId = rcall("RPOPLPUSH", KEYS[4], KEYS[1])
        if jobId then
            local jobKey = ARGV[9] .. jobId
            local lockKey = jobKey .. ':lock'

            -- get a lock
            if ARGV[10] ~= "0" then
              rcall("SET", lockKey, ARGV[10], "PX", ARGV[11])
            end

            rcall("ZREM", KEYS[5], jobId) -- remove from priority
            rcall("XADD", KEYS[6], "*", "event", "active", "jobId", jobId,
                  "prev", "waiting")
            rcall("HSET", jobKey, "processedOn", ARGV[2])

            return {rcall("HGETALL", jobKey), jobId} -- get job data
        end
    end

    local maxEvents = rcall("HGET", KEYS[7], "opts.maxLenEvents")
    if (maxEvents == false) then
      maxEvents = 10000
    end
    rcall("XTRIM", KEYS[6], "MAXLEN", "~", maxEvents)

    return 0
else
    return -1
end
