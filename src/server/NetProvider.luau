-- NOTE: This module should be redundant when ohmyprvd-net has released

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local prvd = require(ReplicatedStorage.Packages.prvd)

local IS_CLIENT = RunService:IsClient()

local NetProvider = {}
type Self = typeof(NetProvider)

local function getFolder(): Folder
  if IS_CLIENT then
    return assert(
      ReplicatedStorage:WaitForChild("Remotes", 10) :: Folder,
      "Could not retrieve remotes folder (bad connection?)"
    )
  else
    local existingFolder = ReplicatedStorage:FindFirstChild("Remotes")
    if existingFolder then
      return existingFolder :: Folder
    end
    local folder = Instance.new("Folder")
    folder.Name = "Remotes"
    folder.Parent = ReplicatedStorage
    return folder
  end
end

function NetProvider:getEvent(name: string): RemoteEvent
  local folder = getFolder()
  if IS_CLIENT then
    local event = folder:WaitForChild(name)
    assert(event, "Could not retrieve remote event " .. name)
    assert(event:IsA("RemoteEvent"), name .. " is not a remote event")
    return event
  else
    local event = Instance.new("RemoteEvent")
    event.Name = name
    event.Parent = folder
    return event
  end
end

function NetProvider.connectToEvent(self: Self, name: string, callback: (...unknown) -> ()): RBXScriptConnection
  local event = self:getEvent(name)
  if IS_CLIENT then
    return event.OnClientEvent:Connect(callback)
  else
    return event.OnServerEvent:Connect(callback)
  end
end

return prvd.new("NetProvider", NetProvider)
