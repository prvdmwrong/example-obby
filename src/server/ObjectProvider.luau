--!nolint LocalShadow

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")

local Runtime = ServerScriptService.Runtime
local NetProvider = require(Runtime.NetProvider)
local PlayerProvider = require(Runtime.PlayerProvider)
local prvd = require(ReplicatedStorage.Packages.ohmyprvd)
local t = require(ReplicatedStorage.Packages.t)

local OBJECTS_FOLDER = assert(Workspace:WaitForChild("Objects", 10), "Cannot find objects folder")

local DamageLevel = table.freeze {
  Normal = "DamageLevel.Normal" :: "DamageLevel.Normal",
  Ouch = "DamageLevel.Ouch" :: "DamageLevel.Ouch",
  Instakill = "DamageLevel.Instakill" :: "DamageLevel.Instakill",
}

local healthPerLevel = table.freeze({
  [DamageLevel.Normal] = 5,
  [DamageLevel.Ouch] = 20,
  [DamageLevel.Instakill] = math.huge,
} :: { [string]: number })

local ObjectProvider = {}
type Self = typeof(ObjectProvider)
ObjectProvider.netProvider = prvd.use(NetProvider)
ObjectProvider.playerProvider = prvd.use(PlayerProvider)

function ObjectProvider.start(self: Self)
  OBJECTS_FOLDER.Parent = ServerStorage
  self.netProvider:connectToEvent("GetObjects", function(player)
    local player = player :: Player
    if self.playerProvider:getSession(player).hasObjects then
      return
    end
    self.playerProvider:getSession(player).hasObjects = true
    local objects = OBJECTS_FOLDER:Clone()
    objects.Parent = player
  end)

  local isDamageLevel = t.union(
    t.numberPositive,
    t.union(t.literal("DamageLevel.Normal"), t.literal("DamageLevel.Ouch"), t.literal("DamageLevel.InstaKill"))
  )

  local damageDebounce: { [Player]: true } = {}
  self.netProvider:connectToEvent("DamageSelf", function(player, level)
    local player = player :: Player
    if not isDamageLevel(level) then
      return
    elseif damageDebounce[player] then
      return
    end
    local character = player.Character
    if not character then
      return
    end
    damageDebounce[player] = true
    local humanoid = character:WaitForChild("Humanoid") :: Humanoid
    if typeof(level) == "number" then
      humanoid:TakeDamage(level)
    else
      local level = level :: string
      humanoid:TakeDamage(healthPerLevel[level] or healthPerLevel[DamageLevel.Normal])
    end
    task.wait(0.05)
    damageDebounce[player] = nil
  end)
end

return prvd.new("ObjectProvider", ObjectProvider)
