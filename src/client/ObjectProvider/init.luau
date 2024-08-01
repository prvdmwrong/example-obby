local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Runtime = script.Parent
local NetProvider = require(Runtime.NetProvider)
local PlayerProvider = require(Runtime.PlayerProvider)
local Types = require(Runtime.ObjectProvider.Types)
local prvd = require(ReplicatedStorage.Packages.prvd)
local t = require(ReplicatedStorage.Packages.t)

type ObjectScript = Types.ObjectScript

local OBJECT_SCRIPTS_FOLDER = script:WaitForChild("Objects")
local RUNNER_THREADS_FOLDER = Instance.new("Folder")
RUNNER_THREADS_FOLDER.Name = "ObjectRunnerThreads"
RUNNER_THREADS_FOLDER.Parent = script

local scriptCache = {} :: { [string]: { instance: ModuleScript, script: ObjectScript } }

local ObjectProvider = {}
type Self = typeof(ObjectProvider)
ObjectProvider.netProvider = prvd.use(NetProvider)
ObjectProvider.playerProvider = prvd.use(PlayerProvider)
ObjectProvider.assertObjectScript = t.strict(t.strictInterface {
  type = t.literal("ObjectScript"),
  runner = t.callback,
})

local function runObjectThread(module: ModuleScript, object: Instance): typeof(script.runnerThread)
  local newThread = script.runnerThread:Clone()
  newThread.Name = HttpService:GenerateGUID(false)

  local targetValue = newThread:WaitForChild("target") :: ObjectValue
  targetValue.Value = module
  print(targetValue, module)

  local objectValue = newThread:WaitForChild("object") :: ObjectValue
  objectValue.Value = object
  print(objectValue, object)

  -- vvvv ?????????????????
  newThread.Parent = RUNNER_THREADS_FOLDER :: any
  newThread.Enabled = true
  return newThread
end

function ObjectProvider.onStart(self: Self)
  -- If there are already runner threads present, delete them
  RUNNER_THREADS_FOLDER:ClearAllChildren()

  self.netProvider:getEvent("GetObjects"):FireServer()
  local objects = assert(self.playerProvider.player:WaitForChild("Objects", 10), "Cannot get objects (bad connection?)")
  objects.Parent = Workspace
  for _, object in ipairs(objects:GetDescendants()) do
    if object:HasTag("Object") then
      local scriptValue = object:GetAttribute("Script")
      assert(scriptValue, `Object {object:GetFullName()} is missing a Script attribute`)
      assert(typeof(scriptValue) == "string", `Script attribute for {object:GetFullName()} must be a string`)

      local scriptToRun = scriptCache[scriptValue]
      if scriptToRun == nil then
        local foundScript = OBJECT_SCRIPTS_FOLDER:FindFirstChild(scriptValue, true)
        assert(foundScript, `Missing script {scriptValue}`)
        assert(foundScript:IsA("ModuleScript"), `Script {scriptValue} is not a ModuleScript`)

        local ok, result = pcall(require, foundScript)
        assert(ok, result)
        self.assertObjectScript(result)

        local pack = {
          instance = foundScript,
          script = result,
        }
        scriptCache[scriptValue] = pack
        scriptToRun = pack
      end

      runObjectThread(scriptToRun.instance, object)
      continue
    end
  end
end

return prvd.new("ObjectProvider", ObjectProvider)
