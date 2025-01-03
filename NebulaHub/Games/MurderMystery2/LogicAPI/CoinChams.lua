local Signal = getgenv().NebulaHub.Dependencies.Manager.Signal
local Enums = getgenv().NebulaHub.Dependencies.Manager.Enums
local GlobalData = getgenv().NebulaHub.Loaded["MM2"].GlobalData

local Player = getgenv().LocalPlayer;
local Character = Player.Character or Player.CharacterAdded:Wait();
  
local Assets = getgenv().NebulaHub.MainUI:WaitForChild("Dependencies"):WaitForChild("Assets");
local Storage = getgenv().NebulaHub.Storage

local private = getgenv().NebulaHub.Loaded["MM2"].private

return function(Content)
  Content:addUnit("Coin Chams", Enums.UnitType.Switch, {
		onActivated = function(MainUnit, Value)
			local function CreateCoinESP()
				for i, v in pairs(GlobalData.CoinsESP) do
					v:Destroy()
				end

				if GlobalData.ChamType == "Highlight" then
					for i, Coin in pairs(workspace:GetDescendants()) do
						if Coin.Parent.Name ~= "CoinVisual" then
							if Coin.Name == "CoinVisual" then
								local newHighlight = Instance.new("Highlight", Storage)
								newHighlight.Name = "CoinVisual"
								newHighlight.FillColor = Color3.fromRGB(180, 170, 29)
								newHighlight.FillTransparency = 0.35
								newHighlight.OutlineColor = Color3.fromRGB(180, 170, 29)
								newHighlight.OutlineTransparency = 0.4
								newHighlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop

								newHighlight.Adornee = Coin
								table.insert(GlobalData.CoinsESP, newHighlight)
							end
						end
					end
				else
					for i, Coin in pairs(workspace:GetDescendants()) do
						if Coin.Name == "CoinVisual" then
							if Coin.Transparency == 0 then
								for i, _BoxCham in pairs(Assets:WaitForChild("ChamBox"):GetChildren()) do
									task.spawn(function()
										local newChammer = _BoxCham:Clone()
										newChammer.Enabled = true
										newChammer.Parent = Coin.Parent
										newChammer.Name = newChammer.Name.."Coin"
										newChammer.PSE.BackgroundColor3 = Color3.fromRGB(255, 204, 0)
										newChammer.Adornee = nil;

										table.insert(GlobalData.CoinsESP, newChammer);
									end)
								end
							end
						end
					end
				end
			end

			CreateCoinESP()

			GlobalData.Connections["ChamChanged_coins"] = GlobalData.ChamTypeChanged:Connect(function()
				CreateCoinESP()
			end)

			GlobalData.Connections["CoinESP"] = workspace.DescendantAdded:Connect(function(Child)
				if Child.Name == "CoinVisual" then
					CreateCoinESP()
				end
			end)

			GlobalData.Connections["CoinESPRemove"] = workspace.DescendantRemoving:Connect(function(Child)
				if Child.Name == "CoinVisual" then
					CreateCoinESP()
				end
			end)
		end,
		onDeactivated = function(MainUnit, Value)
			if GlobalData.Connections["CoinESP"] ~= nil then
				GlobalData.Connections["CoinESP"]:Disconnect();
			end
			if GlobalData.Connections["ChamChanged_coins"] ~= nil then
				GlobalData.Connections["ChamChanged_coins"]:Disconnect();
			end
			if GlobalData.Connections["CoinESPRemove"] ~= nil then
				GlobalData.Connections["CoinESPRemove"]:Disconnect();
			end

			for i, v in pairs(GlobalData.CoinsESP) do
				v:Destroy()
			end
		end,
		defaultValue = false,
		cooldown = 0.2,
	}, "Middle")
end
