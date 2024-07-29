local ReplicatedStorage = game:GetService("ReplicatedStorage")
local prvd = require(ReplicatedStorage.Packages.ohmyprvd)

task.spawn(function()
  prvd.loadDescendants(script, function(module)
    return module.Name:find("Provider$") ~= nil
  end)
  prvd.ignite {
    logLevel = "verbose",
    profiling = true,
  }
end)
