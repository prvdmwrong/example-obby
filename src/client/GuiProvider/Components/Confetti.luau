--!nolint LocalShadow
-- This is based on Fusion's Obby example, licensed under MIT

local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Fusion = require(ReplicatedStorage.Packages.Fusion)
local Children = Fusion.Children
local peek = Fusion.peek

local function Confetti(
  scope: Fusion.Scope<typeof(Fusion)>,
  props: {
    Fuzz: number,
    Force: number,
    ForceFuzz: number,

    Drag: number,
    Gravity: number,
    RotateSpeed: number,

    OnCheckpointReached: (callback: (nextCheckpoint: number) -> ()) -> () -> (),
  }
): Fusion.Child
  local scope = scope:innerScope()

  local random = Random.new()
  local stage = scope:Value(nil :: Frame?)
  local particleSet = scope:Value({})

  local function doFireConfetti(amount: number, origin: Vector2, direction: Vector2)
    local newParticleSet = peek(particleSet)

    for _ = 1, amount do
      local velocity = direction.Unit
      velocity += Vector2.new(random:NextNumber(-props.Fuzz, props.Fuzz), random:NextNumber(-props.Fuzz, props.Fuzz))
      velocity = velocity.Unit * (props.Force + random:NextNumber(-props.ForceFuzz, props.ForceFuzz))

      newParticleSet[{
        id = HttpService:GenerateGUID(),
        x = scope:Value(origin.X),
        y = scope:Value(origin.Y),
        rotation = scope:Value(random:NextInteger(0, 360)),
        life = scope:Value(5 + random:NextNumber(0, 2)),
        velocityX = velocity.X,
        velocityY = velocity.Y,
      }] =
        true
    end

    particleSet:set(newParticleSet)
  end

  table.insert(scope, {
    props.OnCheckpointReached(function(nextCheckpoint)
      if nextCheckpoint == 1 then
        return
      end
      local stage = assert(peek(stage) :: Frame, "Unreachable (stage is created prior to this fired)")
      local amount = 20
      doFireConfetti(amount, stage.AbsoluteSize * Vector2.new(0, 1), Vector2.new(1, -1))
      doFireConfetti(amount, stage.AbsoluteSize, Vector2.new(-1, -1))
    end),
  })

  table.insert(scope, {
    RunService.RenderStepped:Connect(function(deltaTime)
      local newParticleSet = peek(particleSet)

      for particle in pairs(newParticleSet) do
        local newLife = peek(particle.life) - deltaTime
        if newLife <= 0 then
          newParticleSet[particle] = nil
          continue
        else
          particle.life:set(newLife)
        end
        particle.x:set(peek(particle.x) + particle.velocityX)
        particle.y:set(peek(particle.y) + particle.velocityY)
        particle.velocityX *= props.Drag
        particle.velocityY *= props.Drag
        particle.velocityY += props.Gravity
        particle.rotation:set(peek(particle.rotation) + props.RotateSpeed)
      end

      particleSet:set(newParticleSet)
    end),
  })

  local createdStage = scope:New "Frame" {
    Name = "ConfettiStage",

    Size = UDim2.fromScale(1, 1),
    BackgroundTransparency = 1,
    ClipsDescendants = true,
    ZIndex = -100,

    [Children] = scope:ForPairs(particleSet, function(_, scope: typeof(scope), particle)
      local confettiLength = random:NextNumber(10, 20)
      local confettiWidth = confettiLength * random:NextNumber(0.4, 0.6)
      local confettiColour = Color3.fromHSV(random:NextNumber(), 0.5, 1)

      return particle.id,
        -- Wrapping in a computed to not affect the confetti colors above
        scope:Computed(function(use, scope: typeof(scope))
          return scope:New "Frame" {
            Name = "Confetti",

            Position = scope:Computed(function()
              return UDim2.fromOffset(use(particle.x), use(particle.y))
            end),
            Size = UDim2.fromOffset(confettiLength, confettiWidth),
            Rotation = particle.rotation,

            BackgroundColor3 = confettiColour,
            BackgroundTransparency = scope:Computed(function()
              return 1 - math.clamp(use(particle.life), 0, 1)
            end),
          }
        end)
    end),
  }

  stage:set(createdStage)
  return createdStage
end

return Confetti
