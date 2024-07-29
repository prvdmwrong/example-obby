local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Types = require(script.Parent.Parent.Types)

local DamageLevel = table.freeze {
  Normal = "DamageLevel.Normal" :: "DamageLevel.Normal",
  Ouch = "DamageLevel.Ouch" :: "DamageLevel.Ouch",
  Instakill = "DamageLevel.Instakill" :: "DamageLevel.Instakill",
}

local function getFolder(): Folder
  return assert(
    ReplicatedStorage:WaitForChild("Remotes", 10) :: Folder,
    "Could not retrieve remotes folder (bad connection?)"
  )
end

local function getEvent(name: string): RemoteEvent
  local folder = getFolder()
  local event = folder:WaitForChild(name)
  assert(event, "Could not retrieve remote event " .. name)
  assert(event:IsA("RemoteEvent"), name .. " is not a remote event")
  return event
end

local DamageBricks = {} :: Types.ObjectScript
DamageBricks.type = "ObjectScript"

function DamageBricks:runner(object, scope)
  local damageSelf = getEvent("DamageSelf")
  local function processDamageBrick(brick: BasePart)
    print("processing", brick)
    local level = assert(DamageLevel[brick.Name], `{brick:GetFullName()} is not a valid damage level`)
    table.insert(scope, {
      brick.Touched:Connect(function(otherPart)
        local model = otherPart.Parent :: Model
        if not model then
          return
        end
        local player = Players:GetPlayerFromCharacter(model)
        if not player or player ~= Players.LocalPlayer then
          return
        end
        print("fired damageself w", level)
        print(damageSelf)
        damageSelf:FireServer(level)
      end),
    })
  end

  for _, instance in ipairs(object:GetDescendants()) do
    if not instance:IsA("BasePart") then
      continue
    end
    processDamageBrick(instance)
  end
end

return DamageBricks
