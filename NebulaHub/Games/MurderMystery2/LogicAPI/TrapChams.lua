local Signal = getgenv().NebulaHub.Dependencies.Manager.Signal
local Enums = getgenv().NebulaHub.Dependencies.Manager.Enums
local GlobalData = getgenv().NebulaHub.Loaded["MM2"].GlobalData

local Player = getgenv().LocalPlayer;
local Character = Player.Character or Player.CharacterAdded:Wait();
  
local Assets = getgenv().NebulaHub.MainUI:WaitForChild("Dependencies"):WaitForChild("Assets");
local Storage = getgenv().NebulaHub.Storage

local private = getgenv().NebulaHub.Loaded["MM2"].private

return function(Content)
  Content:addUnit("Trap Chams", Enums.UnitType.Switch, {
		onActivated = function(MainUnit, Value)
			local function CreateTrapESP(location)
				for i, v in pairs(GlobalData.TrapESP) do
					v:Destroy()
				end

				if GlobalData.ChamType == "Highlight" then
					local newHighlight = Instance.new("Highlight", Storage)
					newHighlight.Name = "Trap"
					newHighlight.FillColor = Color3.fromRGB(188, 133, 255)
					newHighlight.FillTransparency = 0.35
					newHighlight.OutlineColor = Color3.fromRGB(188, 133, 255)
					newHighlight.OutlineTransparency = 0.4
					newHighlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop

					newHighlight.Adornee = location
					table.insert(GlobalData.TrapESP, newHighlight)
				else
					for i, _BoxCham in pairs(Assets:WaitForChild("ChamBox"):GetChildren()) do
						task.spawn(function()
							local newChammer = _BoxCham:Clone()
							newChammer.Enabled = true
							newChammer.Parent = location.Trigger
							newChammer.Name = newChammer.Name.."Trap"
							newChammer.PSE.BackgroundColor3 = Color3.fromRGB(141, 0, 0)
							newChammer.Adornee = nil;

							table.insert(GlobalData.TrapESP, newChammer);
						end)
					end
				end
			end

			for i, possibleTrap in pairs(workspace:GetDescendants()) do
				if possibleTrap.Name == "Trap" then
					CreateTrapESP(possibleTrap)
				end
			end

			GlobalData.Connections["ChamChanged_trap"] = GlobalData.ChamTypeChanged:Connect(function()
				for i, possibleGundrop in pairs(workspace:GetDescendants()) do
					if possibleGundrop.Name == "Trap" then
						CreateTrapESP(possibleGundrop)
					end
				end
			end)

			GlobalData.Connections["TrapESP"] = workspace.DescendantAdded:Connect(function(Child)
				if Child.Name == "Trap" then
					CreateTrapESP(Child)
				end
			end)

			GlobalData.Connections["TrapESPRemove"] = workspace.DescendantRemoving:Connect(function(Child)
				if Child.Name == "Trap" then
					for i, v in pairs(GlobalData.TrapESP) do
						v:Destroy()
					end
					for i, possibleTrap in pairs(workspace:GetDescendants()) do
						if possibleTrap.Name == "Trap" then
							CreateTrapESP(possibleTrap)
						end
					end
				end
			end)
		end,
		onDeactivated = function(MainUnit, Value)
			if GlobalData.Connections["ChamChanged_trap"] ~= nil then
				GlobalData.Connections["ChamChanged_trap"]:Disconnect();
			end

			if GlobalData.Connections["TrapESP"] ~= nil then
				GlobalData.Connections["TrapESP"]:Disconnect();
			end

			if GlobalData.Connections["TrapESPRemove"] ~= nil then
				GlobalData.Connections["TrapESPRemove"]:Disconnect();
			end

			for i, v in pairs(GlobalData.TrapESP) do
				v:Destroy()
			end
		end,
		defaultValue = false,
		cooldown = 0.2,
	}, "Middle")
end
