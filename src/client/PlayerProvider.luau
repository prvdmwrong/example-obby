local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local prvd = require(ReplicatedStorage.Packages.prvd)

export type Character = Model & {
  ["Body Colors"]: BodyColors,
  HumanoidRootPart: Part,
  Humanoid: Humanoid & {
    HumanoidDescription: HumanoidDescription,
    Animator: Animator,
  },
  Head: Part & {
    face: Decal,
    Mesh: SpecialMesh,
  },
  ["Left Arm"]: Part,
  ["Left Leg"]: Part,
  ["Right Arm"]: Part,
  ["Right Leg"]: Part,
  ["Torso"]: Part & {
    roblox: Decal,
  },
}

local PlayerProvider = {}
type Self = typeof(PlayerProvider)
PlayerProvider.player = Players.LocalPlayer

function PlayerProvider.awaitCharacter(self: Self): Character
  return (self.player.Character or self.player.CharacterAdded:Wait()) :: Character
end

return prvd.new("PlayerProvider", PlayerProvider)
