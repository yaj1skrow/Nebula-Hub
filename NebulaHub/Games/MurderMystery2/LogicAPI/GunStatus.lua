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
  Content:addUnit("GunStatus", Enums.UnitType.Info, {
		Initialize = function(Unit)
			GlobalData.Connections["CheckGunDropped"] = GlobalData.GunDropped:Connect(function()
				Unit.UiInfo.UnitTitle.Text = `<font color="rgb(110, 255, 139)">Gun dropped:</font> <font family="rbxasset://fonts/families/Balthazar.json" color="rgb(255, 198, 15)"><b>true</b></font>` 
			end)

			GlobalData.Connections["CheckGunTake"] = GlobalData.GunTook:Connect(function()
				Unit.UiInfo.UnitTitle.Text = `<font color="rgb(255, 82, 82)">Gun dropped:</font> <font family="rbxasset://fonts/families/Balthazar.json" color="rgb(255, 198, 15)"><b>false</b></font>` 
			end)
		end,
		Text = workspace:FindFirstChild("GunDrop", true) and `<font color="rgb(110, 255, 139)">Gun dropped:</font> <font family="rbxasset://fonts/families/Balthazar.json" color="rgb(255, 198, 15)"><b>true</b></font>` or `<font color="rgb(255, 82, 82)">Gun dropped:</font> <font family="rbxasset://fonts/families/Balthazar.json" color="rgb(255, 198, 15)"><b>false</b></font>` 
	})
end
