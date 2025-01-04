local Signal = getgenv().NebulaHub.Dependencies.Manager.Signal
local Enums = getgenv().NebulaHub.Dependencies.Manager.Enums
local GlobalData = getgenv().NebulaHub.Loaded["MM2"].GlobalData

local Player = getgenv().LocalPlayer;
local Character = Player.Character or Player.CharacterAdded:Wait();
  
local Assets = getgenv().NebulaHub.MainUI:WaitForChild("Dependencies"):WaitForChild("Assets");
local Storage = getgenv().NebulaHub.Storage

local Management = getgenv().NebulaHub.Dependencies.Manager.Management

local private = getgenv().NebulaHub.Loaded["MM2"].private

return function(Content)
  Content:addUnit("JumpPower", Enums.UnitType.Slider, {
		Initialize = function(Unit)
			Unit.OnValueChanged:Connect(function(Value)
				if getgenv().Services.Players.LocalPlayer.Character:FindFirstChild("Humanoid").UseJumpPower == false then
					getgenv().Services.Players.LocalPlayer.Character:FindFirstChild("Humanoid").UseJumpPower = true;
				end;
				pcall(function()
					getgenv().Services.Players.LocalPlayer.Character:FindFirstChild("Humanoid").JumpPower = Value
					GlobalData.PlayerJumppower = Value
				end)
			end)
		end,
		defaultValue = 50,
		Min = 0,
		Max = 100,
		Increment = 1,
	}, "Top")
	:addUnit("Loop JumpPower", Enums.UnitType.Switch, {
		onActivated = function(MainUnit, Value)	
			GlobalData.Connections["KeepJumppower"] = getgenv().Services.Players.LocalPlayer.Character:FindFirstChild("Humanoid"):GetPropertyChangedSignal("JumpPower"):Connect(function()
				if GlobalData.PlayerJumppower then
					getgenv().Services.Players.LocalPlayer.Character:FindFirstChild("Humanoid").JumpPower = GlobalData.PlayerJumppower
				end
			end)
		end,
		onDeactivated = function(MainUnit, Value)
			if GlobalData.Connections["KeepJumppower"] ~= nil then
				GlobalData.Connections["KeepJumppower"]:Disconnect()
			end
		end,
		defaultValue = false,
		cooldown = 0.2,
	}, "Bottom")
end
