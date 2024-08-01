--!nolint LocalShadow

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterPack = game:GetService("StarterPack")
local prvd = require(ReplicatedStorage.Packages.prvd)

local studioTools = script:WaitForChild("StudioTools")

local DebugProvider = {}
type Self = typeof(DebugProvider)

function DebugProvider:onStart()
  if RunService:IsStudio() then
    for _, tool in ipairs(studioTools:GetChildren()) do
      if not tool:IsA("Tool") then
        continue
      end
      local clone = tool:Clone()
      clone.Parent = StarterPack
    end
  end
end

return prvd.new("DebugProvider", DebugProvider)
