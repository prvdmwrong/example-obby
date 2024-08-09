local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")
local Workspace = game:GetService("Workspace")

local Runtime = ServerScriptService.Runtime
local NetProvider = require(Runtime.NetProvider)
local prvd = require(ReplicatedStorage.Packages.prvd)

export type PlayerSession = {
  checkpoint: number,
  hasObjects: boolean,

  startedAt: number,
  leaderstats: Folder & {
    Stage: IntValue,
    Time: IntValue,
  },
}

local IS_LOCAL_DEV = RunService:IsStudio()
local CHECKPOINTS = Workspace:WaitForChild("Checkpoints") :: Folder
local DEFAULT_PLAYER_SESSION = {
  checkpoint = 0,
  hasObjects = false,
} :: PlayerSession

local PlayerProvider = {}
type Self = typeof(PlayerProvider)
PlayerProvider.players = {} :: { [Player]: PlayerSession }
PlayerProvider.netProvider = prvd.use(NetProvider)

function PlayerProvider.onInit(self: Self)
  local function registerPlayer(newPlayer: Player)
    if self.players[newPlayer] ~= nil then
      return
    end
    if IS_LOCAL_DEV then
      print("Greetings", newPlayer)
    end

    local session = table.clone(DEFAULT_PLAYER_SESSION)
    session.startedAt = os.clock()

    local leaderstats = Instance.new("Folder")
    leaderstats.Name = "leaderstats"

    local stage = Instance.new("IntValue")
    stage.Name = "Stage"
    stage.Value = 1
    stage.Parent = leaderstats

    local sessionTime = Instance.new("IntValue")
    sessionTime.Name = "Time"
    sessionTime.Value = 0
    sessionTime.Parent = leaderstats

    leaderstats.Parent = newPlayer
    session.leaderstats = leaderstats :: any

    -- luau-lsp tripping so hard bro
    newPlayer.CharacterAdded:Connect(function(character)
      local currentCheckpoint: Instance = CHECKPOINTS:FindFirstChild(tostring(session.checkpoint)) :: any
        or CHECKPOINTS:FindFirstChild("1")
      if not currentCheckpoint:IsA("BasePart") then
        return
      end
      -- vvvv ????????????????????????
      RunService.Heartbeat:Wait()
      character:PivotTo(currentCheckpoint.CFrame + Vector3.new(0, 3, 0))
    end)

    self.players[newPlayer] = session
  end

  Players.PlayerAdded:Connect(registerPlayer)
  for _, existingPlayer in pairs(Players:GetPlayers()) do
    registerPlayer(existingPlayer)
  end

  Players.PlayerRemoving:Connect(function(leavingPlayer)
    if IS_LOCAL_DEV then
      print("Farewell", leavingPlayer)
    end
    self.players[leavingPlayer] = nil
  end)

  local nextCheckpointEvent = self.netProvider:getEvent("NextCheckpoint")

  for _, checkpoint in ipairs(CHECKPOINTS:GetChildren()) do
    if not checkpoint:IsA("BasePart") then
      continue
    end
    local thisCheckpoint =
      assert(tonumber(checkpoint.Name), `Checkpoint {checkpoint:GetFullName()} must be named a number`)
    checkpoint.Touched:Connect(function(otherPart)
      local model = otherPart.Parent :: Model
      if not model then
        return
      end
      local player = Players:GetPlayerFromCharacter(model)
      if not player then
        return
      end
      -- typecast required for some weirdd reason
      -- https://discord.com/channels/385151591524597761/1031990829474131998/1267461127038701618
      local session = self:getSession(player) :: PlayerSession
      local nextCheckpoint = session.checkpoint + 1
      if nextCheckpoint ~= thisCheckpoint then
        return
      end
      self:setSession(player, "checkpoint", nextCheckpoint)
      session.leaderstats.Stage.Value = nextCheckpoint
      nextCheckpointEvent:FireClient(player, nextCheckpoint)
    end)
  end

  RunService.PostSimulation:Connect(function()
    for _, session in pairs(self.players) do
      if session.checkpoint == 4 then
        continue
      end
      session.leaderstats.Time.Value = math.floor(os.clock() - session.startedAt)
    end
  end)
end

function PlayerProvider.getSession(self: Self, player: Player)
  return self.players[player]
end

function PlayerProvider.setSession(self: Self, player: Player, key: string, value: unknown)
  self.players[player][key] = value
end

return prvd.new("PlayerProvider", PlayerProvider)
