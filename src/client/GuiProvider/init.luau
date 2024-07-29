local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Runtime = script.Parent
local Confetti = require(Runtime.GuiProvider.Components.Confetti)
local Message = require(Runtime.GuiProvider.Components.Message)
local NetProvider = require(Runtime.NetProvider)
local PlayerProvider = require(Runtime.PlayerProvider)

local Fusion = require(ReplicatedStorage.Packages.Fusion)
local prvd = require(ReplicatedStorage.Packages.ohmyprvd)
local t = require(ReplicatedStorage.Packages.t)
local Child, Children = Fusion.Child, Fusion.Children

local WIN_MESSAGE = [[
Thanks for playing!

This is a demo of the Oh My Prvd framework. The source code for both this game
and the framework can be found on GitHub at znotfireman/ohmyprvd-obby and
team-fireworks/ohmyprvd respectively.
]]

local GuiProvider = {}
type Self = typeof(GuiProvider)
GuiProvider.netProvider = prvd.use(NetProvider)
GuiProvider.playerProvider = prvd.use(PlayerProvider)

function GuiProvider.start(self: Self)
  local scope = Fusion:scoped {
    Confetti = Confetti,
    Message = Message,
  }

  -- Watch for when the next checkpoint has reached
  local checkpointReached: { [{}]: (nextCheckpoint: number) -> () } = {}
  local function onCheckpointReached(callback: (nextCheckpoint: number) -> ())
    assert(t.callback(callback))
    local id = table.freeze {}
    checkpointReached[id] = callback
    return function()
      checkpointReached[id] = nil
    end
  end

  local function doCheckpointReached(nextCheckpoint: number)
    for _, callback in pairs(checkpointReached) do
      task.spawn(callback, nextCheckpoint)
    end
  end

  local currentCheckpoint = scope:Value(1)
  print(self.netProvider:connectToEvent("NextCheckpoint", function(nextCheckpoint)
    assert(t.numberPositive(nextCheckpoint))
    currentCheckpoint:set(nextCheckpoint :: number)
    doCheckpointReached(nextCheckpoint :: number)
  end))

  onCheckpointReached(function(nextCheckpoint)
    print("NEXT", nextCheckpoint)
  end)

  local isFinalCheckpoint = scope:Computed(function(use)
    return use(currentCheckpoint) == 4
  end)

  -- Mount main user interface
  scope:New "ScreenGui" {
    IgnoreGuiInset = true,
    Parent = self.playerProvider.player.PlayerGui,
    ResetOnSpawn = false,

    [Children] = Child {
      scope:Confetti {
        Fuzz = 0.2,
        Force = 30,
        ForceFuzz = 20,

        Drag = 0.95,
        Gravity = 0.2,
        RotateSpeed = 1,

        OnCheckpointReached = onCheckpointReached,
      },
      scope:Message {
        Enabled = isFinalCheckpoint,
        Message = WIN_MESSAGE,
      },
    },
  }
end

return prvd.new("GuiProvider", GuiProvider)
