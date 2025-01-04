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
  Content:addUnit("Cham Type", Enums.UnitType.Dropdown, {
		Initialize = function(Unit)
			Unit.OnValueChanged:Connect(function(Value)
				GlobalData.ChamType = Value.Name
				GlobalData.ChamTypeChanged:Fire()
			end)
		end,
		createEnums = function(Creator)
			Creator({
				["Highlight"] = {
					Name = "Highlight";
					Value = 0,
					Color = Color3.fromRGB(201, 255, 178)
				};
				["Box"] = {
					Name = "Box";
					Value = 1,
					Color = Color3.fromRGB(255, 234, 128)
				}
			})
		end,
		setDefault = function(Setter)
			Setter("Box")
		end,
		cooldown = 0.2,

	}, "Bottom")
end
