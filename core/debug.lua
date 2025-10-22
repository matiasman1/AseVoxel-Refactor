-- core/debug.lua
-- Debug utilities for AseVoxel

local M = {}
M.enabled = false
M.logBuffer = {}
M.maxLogs = 100

-- Set debug mode on/off
function M.setEnabled(enabled)
  M.enabled = not not enabled
end

-- Log a message if debug is enabled
function M.log(message)
  if M.enabled then
    -- Get current time
    local timestamp = os.date("%H:%M:%S")
    local entry = timestamp .. ": " .. tostring(message)
    
    -- Add to buffer
    table.insert(M.logBuffer, entry)
    
    -- Trim buffer if too large
    if #M.logBuffer > M.maxLogs then
      table.remove(M.logBuffer, 1)
    end
    
    -- Also print to console for immediate feedback
    print("[AseVoxel] " .. entry)
  end
end

-- Get the entire log as a string
function M.getLog()
  return table.concat(M.logBuffer, "\n")
end

-- Clear the log
function M.clearLog()
  M.logBuffer = {}
end

-- Create a simple dialog to view logs
function M.showLogDialog()
  local dlg = Dialog("AseVoxel Debug Log")
  
  dlg:label{text="Debug Log:"}
  dlg:textarea{
    id="log",
    text=M.getLog(),
    width=400,
    height=300,
    editable=false
  }
  
  dlg:button{
    text="Refresh",
    onclick=function()
      dlg:modify{id="log", text=M.getLog()}
    end
  }
  
  dlg:button{
    text="Clear",
    onclick=function()
      M.clearLog()
      dlg:modify{id="log", text=""}
    end
  }
  
  dlg:button{
    text="Close",
    onclick=function()
      dlg:close()
    end
  }
  
  dlg:show{wait=false}
end

-- For profiling: creates a timer that reports elapsed time
function M.timer(label)
  if not M.enabled then return function() end end
  
  local startTime = os.clock()
  
  return function()
    local elapsed = os.clock() - startTime
    M.log((label or "Timer") .. ": " .. string.format("%.3f", elapsed * 1000) .. "ms")
  end
end

return M