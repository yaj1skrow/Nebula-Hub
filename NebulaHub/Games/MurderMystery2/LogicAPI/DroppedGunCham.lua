local Signal = getgenv().NebulaHub.Dependencies.Manager.Signal
local Enums = getgenv().NebulaHub.Dependencies.Manager.Enums
local GlobalData = getgenv().NebulaHub.Loaded["MM2"].GlobalData

local Player = getgenv().LocalPlayer;
local Character = Player.Character or Player.CharacterAdded:Wait();
  
local Assets = getgenv().NebulaHub.MainUI:WaitForChild("Dependencies"):WaitForChild("Assets");
local Storage = getgenv().NebulaHub.Storage

local private = getgenv().NebulaHub.Loaded["MM2"].private

return function(Content)
Content:addUnit("Dropped Gun Cham", Enums.UnitType.Switch, {
		onActivated = function(MainUnit, Value)
			local function CreateNewGunESP(location)
				for i, v in pairs(GlobalData.GunESP) do
					v:Destroy()
				end

				if GlobalData.ChamType == "Highlight" then
					local newHighlight = Instance.new("Highlight", Storage)
					newHighlight.Name = "GunDrop"
					newHighlight.FillColor = Color3.fromRGB(188, 133, 255)
					newHighlight.FillTransparency = 0.35
					newHighlight.OutlineColor = Color3.fromRGB(188, 133, 255)
					newHighlight.OutlineTransparency = 0.4
					newHighlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop

					newHighlight.Adornee = location
					table.insert(GlobalData.GunESP, newHighlight)
				else
					for i, _BoxCham in pairs(Assets:WaitForChild("ChamBox"):GetChildren()) do
						task.spawn(function()
							local newChammer = _BoxCham:Clone()
							newChammer.Enabled = true
							newChammer.Parent = location
							newChammer.Name = newChammer.Name.."GunDrop"
							newChammer.PSE.BackgroundColor3 = Color3.fromRGB(188, 133, 255)
							newChammer.Adornee = nil;

							table.insert(GlobalData.GunESP, newChammer);
						end)
					end
				end
			end

			for i, possibleGundrop in pairs(workspace:GetDescendants()) do
				if possibleGundrop.Name == "GunDrop" then
					CreateNewGunESP(possibleGundrop)
				end
			end

			GlobalData.Connections["ChamChanged_gun"] = GlobalData.ChamTypeChanged:Connect(function()
				for i, possibleGundrop in pairs(workspace:GetDescendants()) do
					if possibleGundrop.Name == "GunDrop" then
						CreateNewGunESP(possibleGundrop)
					end
				end
			end)

			GlobalData.Connections["GunESP"] = workspace.DescendantAdded:Connect(function(Child)
				if Child.Name == "GunDrop" then
					CreateNewGunESP(Child)
				end
			end)

			GlobalData.Connections["GunRemoval"] = GlobalData.GunTook:Connect(function(Child)
				--if GlobalData.GunGetting == true then
				GlobalData.ReloadESP:Fire()
				--end
				for i, v in pairs(GlobalData.GunESP) do
					v:Destroy()
				end
			end)
		end,
		onDeactivated = function(MainUnit, Value)
			if GlobalData.Connections["ChamChanged_gun"] ~= nil then
				GlobalData.Connections["ChamChanged_gun"]:Disconnect();
			end

			if GlobalData.Connections["GunESP"] ~= nil then
				GlobalData.Connections["GunESP"]:Disconnect();
			end

			if GlobalData.Connections["GunRemoval"] ~= nil then
				GlobalData.Connections["GunRemoval"]:Disconnect();
			end

			for i, v in pairs(GlobalData.GunESP) do
				v:Destroy()
			end
		end,
		defaultValue = false,
		cooldown = 0.2,
	}, "Middle")
end
