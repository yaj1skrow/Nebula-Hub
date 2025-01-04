local Signal = getgenv().NebulaHub.Dependencies.Manager.Signal
local Enums = getgenv().NebulaHub.Dependencies.Manager.Enums
local GlobalData = getgenv().NebulaHub.Loaded["Universal"].GlobalData

local Player = getgenv().LocalPlayer;
local Character = Player.Character or Player.CharacterAdded:Wait();
  
local Assets = getgenv().NebulaHub.MainUI:WaitForChild("Dependencies"):WaitForChild("Assets");
local Storage = getgenv().NebulaHub.Storage

local Management = getgenv().NebulaHub.Dependencies.Manager.Management

local private = getgenv().NebulaHub.Loaded["Universal"].private

local UniversalSave = getgenv().NebulaHub.Loaded["Universal"].ConfigData
local Readable = getgenv().NebulaHub.API.getGameConfig("Universal")

print(Readable)

return function(Content)
	local API_Save_PlayerChams = Readable["TestValue"]
	local DefaultValue = false
	if API_Save_PlayerChams then
		print("DATA FOUND")
		DefaultValue = API_Save_PlayerChams.Value
	else
		print("DATA NOT FOUND")
		DefaultValue = false
		MM2Save:addBatch("TestValue", {
			Value = false
		})
		print("CREATED DATA")
	end
   	Content:addUnit("Test Switch", Enums.UnitType.Switch, {
		onActivated = function(MainUnit, Value)	
			MM2Save:addBatch("TestValue", {
				Value = true
			})
		end,
		onDeactivated = function(MainUnit, Value)
			MM2Save:addBatch("TestValue", {
				Value = false
			})
		end,
		defaultValue = DefaultValue,
		cooldown = 0.2,
	}, "Top")
end
