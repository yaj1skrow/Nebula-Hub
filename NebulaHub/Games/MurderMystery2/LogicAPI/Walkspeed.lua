local Signal = getgenv().NebulaHub.Dependencies.Manager.Signal
local Enums = getgenv().NebulaHub.Dependencies.Manager.Enums
local GlobalData = getgenv().NebulaHub.Loaded["MM2"].GlobalData

local Player = getgenv().LocalPlayer;
local Character = Player.Character or Player.CharacterAdded:Wait();
  
local Assets = getgenv().NebulaHub.MainUI:WaitForChild("Dependencies"):WaitForChild("Assets");
local Storage = getgenv().NebulaHub.Storage

return function(Content)
  Content:addUnit("WalkSpeed", Enums.UnitType.Slider, {
		Initialize = function(Unit)
			Unit.OnValueChanged:Connect(function(Value)
				pcall(function()
					getgenv().Services.Players.LocalPlayer.Character:FindFirstChild("Humanoid").WalkSpeed = Value
					GlobalData.PlayerWalkspeed = Value;
				end)
			end)
		end,
		defaultValue = 16,
		Min = 16,
		Max = 30,
		Increment = 1,
	}, "Top")
	:addUnit("Loop WalkSpeed", Enums.UnitType.Switch, {
		onActivated = function(MainUnit, Value)	
			GlobalData.Connections["KeepWalkspeed"] = getgenv().Services.Players.LocalPlayer.Character:FindFirstChild("Humanoid"):GetPropertyChangedSignal("WalkSpeed"):Connect(function()
				if GlobalData.PlayerWalkspeed then
					getgenv().Services.Players.LocalPlayer.Character:FindFirstChild("Humanoid").WalkSpeed = GlobalData.PlayerWalkspeed
				end
			end)
		end,
		onDeactivated = function(MainUnit, Value)
			if GlobalData.Connections["KeepWalkspeed"] ~= nil then
				GlobalData.Connections["KeepWalkspeed"]:Disconnect()
			end
		end,
		defaultValue = false,
		cooldown = 0.2,
	}, "Bottom")
end
