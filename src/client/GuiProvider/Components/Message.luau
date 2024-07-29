local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Fusion = require(ReplicatedStorage.Packages.Fusion)
local Children = Fusion.Children

local function Message(
  scope: Fusion.Scope<typeof(Fusion)>,
  props: {
    Message: Fusion.UsedAs<string>,
    Enabled: Fusion.UsedAs<boolean>,
  }
): Fusion.Child
  local transparency = scope:Spring(
    scope:Computed(function(use)
      return use(props.Enabled) and 0 or 1
    end),
    5,
    1
  )

  return scope:New "Frame" {
    BackgroundColor3 = Color3.new(0, 0, 0),
    BackgroundTransparency = transparency,
    Name = "Message",
    Size = UDim2.fromScale(1, 1),
    Visible = props.Enabled,

    [Children] = scope:New "TextLabel" {
      AnchorPoint = Vector2.new(0.5, 0.5),
      BackgroundTransparency = 1,
      FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.Medium, Enum.FontStyle.Normal),
      Position = UDim2.fromScale(0.5, 0.5),
      Size = UDim2.fromScale(0.5, 0.5),
      Text = props.Message,
      TextColor3 = Color3.new(1, 1, 1),
      TextScaled = true,

      [Children] = scope:New "UIAspectRatioConstraint" {
        AspectRatio = 2,
      },
    },
  }
end

return Message
