--!nolint LocalShadow

type ObjectScript = {
  type: "ObjectScript",
  runner: (self: ObjectScript, object: Instance, scope: { unknown }) -> (),
}

local GENERIC_CLEANUP_METHODS = {
  "destroy",
  "Destroy",
  "disconnect",
  "Disconnect",
}

local alreadyDestroying: { [unknown]: true } = {}
local defer = task.defer

local object = assert(script:FindFirstChild("object") :: ObjectValue, "Cannot find target object")
local target = assert(script:FindFirstChild("target") :: ObjectValue, "Cannot find target script")
local exports: ObjectScript = require(target.Value) :: any

local function doCleanup(...: unknown): ()
  local tasks = select("#", ...)
  for i = 1, tasks do
    local task = select(i, ...)
    assert(not alreadyDestroying[task], "Cannot destroy scoped task twice")
    alreadyDestroying[task] = true

    if typeof(task) == nil then
      -- nothing to be done
    elseif typeof(task) == "Instance" then
      task:Destroy()
    elseif typeof(task) == "function" then
      task()
    elseif typeof(task) == "RBXScriptConnection" then
      local task = task :: RBXScriptConnection
      if task.Connected == true then
        task:Disconnect()
      end
    elseif typeof(task) == "thread" then
      local cancelled = false
      if task ~= coroutine.running() then
        cancelled = coroutine.close(task)
      end
      if not cancelled then
        local toCancel = task
        defer(function()
          coroutine.close(toCancel)
        end)
      end
    elseif typeof(task) == "table" then
      local task: { [unknown]: unknown } = task :: any

      local destroyed = false
      for _, method in ipairs(GENERIC_CLEANUP_METHODS) do
        if typeof(task[method]) == "function" then
          local destructor = task[method] :: (self: typeof(task)) -> ()
          destroyed = pcall(destructor, task)
          break
        end
      end

      if not destroyed and task[1] ~= nil then
        local task = task :: { unknown }
        -- It is important to iterate backwards through the table, since
        -- objects are added in order of construction.
        for index = #task, 1, -1 do
          doCleanup(task[index])
          task[index] = nil
        end
      end
    end

    alreadyDestroying[task] = nil
  end
end

local scope = {}
script.Destroying:Once(function()
  doCleanup(scope)
end)
exports:runner(assert(object.Value, "Missing object for worker thread"), scope)
