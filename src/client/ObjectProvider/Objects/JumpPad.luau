local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Types = require(script.Parent.Parent.Types)

local MAX_FORCE = Vector3.new(0, math.huge, 0)
-- unpopular opinion tween service apis suck
local TWEEN_INFO = TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, 1, true)

local JumpPad = {} :: Types.ObjectScript
JumpPad.type = "ObjectScript"

function JumpPad:runner(object, scope)
  assert(object:IsA("BasePart"), `JumpPad {object:GetFullName()} must be a BasePart`)

  local power = 0
  local config = object:FindFirstChildOfClass("Configuration")
  if config then
    local powerValue = config:FindFirstChild("Power")
    if powerValue and powerValue:IsA("NumberValue") then
      power = powerValue.Value
    end
  end

  local originalPosition = object.CFrame

  local touchDebounce = false
  table.insert(scope, {
    object.Touched:Connect(function(otherPart)
      if touchDebounce then
        return
      end
      local model = otherPart.Parent :: Model
      if not model then
        return
      end
      local player = Players:GetPlayerFromCharacter(model)
      if not player or player ~= Players.LocalPlayer then
        return
      end
      touchDebounce = true

      TweenService:Create(object, TWEEN_INFO, {
        CFrame = originalPosition + originalPosition.LookVector * 1,
      }):Play()

      -- screw you roblox
      -- local linearVelocity = Instance.new("LinearVelocity")
      -- linearVelocity.MaxForce = math.huge
      -- linearVelocity.VectorVelocity = Vector3.new(0, power * 500, 0)
      -- linearVelocity.VelocityConstraintMode = Enum.VelocityConstraintMode.Vector
      -- linearVelocity.Parent = model:WaitForChild("HumanoidRootPart")
      -- Debris:AddItem(linearVelocity, 0.15)
      local bodyVelocity = Instance.new("BodyVelocity")
      bodyVelocity.MaxForce = MAX_FORCE
      bodyVelocity.Velocity = Vector3.new(0, power, 0)
      bodyVelocity.Parent = otherPart
      Debris:AddItem(bodyVelocity, 0.15)
      touchDebounce = false
    end),
  })
end

return JumpPad
