local Signal = getgenv().NebulaHub.Dependencies.Manager.Signal
local Enums = getgenv().NebulaHub.Dependencies.Manager.Enums
local GlobalData = getgenv().NebulaHub.Loaded["MM2"].GlobalData

local Player = getgenv().LocalPlayer;
local Character = Player.Character or Player.CharacterAdded:Wait();
  
local Assets = getgenv().NebulaHub.MainUI:WaitForChild("Dependencies"):WaitForChild("Assets");
local Storage = getgenv().NebulaHub.Storage

local private = getgenv().NebulaHub.Loaded["MM2"].private
local MM2Save = getgenv().NebulaHub.Loaded["MM2"].ConfigData
local Readable = getgenv().NebulaHub.API.getGameConfig("MurderMystery2")

return function(Content)
	local API_Save_PlayerChams = Readable["PlayerChams"]
	local DefaultValue = false
	if API_Save_PlayerChams ~= nil then
		print("Init..ing Data")
		print("PlayerChams", DefaultValue, API_Save_PlayerChams.Value) 
		DefaultValue = API_Save_PlayerChams.Value or false
	else
		print("SavingNewData")
		MM2Save:addBatch("PlayerChams", {
				Value = false
		})
	end
 	Content:addUnit("Player Chams", Enums.UnitType.Switch, {
		onActivated = function(MainUnit, Value)	
			MM2Save:addBatch("PlayerChams", {
				Value = true
			})
			local function createEsp(Player_)
				if GlobalData.ChamType == "Highlight" then
					task.spawn(function()
						local newHighlight = Instance.new("Highlight", Storage)
						newHighlight.Name = Player_.Name
						newHighlight.FillColor = Color3.fromRGB(157, 255, 111)
						newHighlight.FillTransparency = 0.35
						newHighlight.OutlineColor = Color3.fromRGB(157, 255, 111)
						newHighlight.OutlineTransparency = 0.4
						newHighlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop

						table.insert(GlobalData.ESPs, newHighlight);

						if Player_ == private.findSheriff() then
							if newHighlight then
								newHighlight.Adornee = Player_.Character
								newHighlight.FillColor = Color3.fromRGB(105, 125, 255)
								newHighlight.OutlineColor = Color3.fromRGB(105, 125, 255)
							end
						elseif Player_ == private.findMurderer() then
							if newHighlight then
								newHighlight.Adornee = Player_.Character
								newHighlight.FillColor = Color3.fromRGB(255, 97, 97)
								newHighlight.OutlineColor = Color3.fromRGB(255, 97, 97)
							end
						elseif Player_ == private.findHero() then
							if newHighlight then
								newHighlight.Adornee = Player_.Character
								newHighlight.FillColor = Color3.fromRGB(255, 237, 98)
								newHighlight.OutlineColor = Color3.fromRGB(255, 237, 98)
							end
						else
							if newHighlight then
								newHighlight.Adornee = Player_.Character
								newHighlight.FillColor = Color3.fromRGB(157, 255, 111)
								newHighlight.OutlineColor = Color3.fromRGB(157, 255, 111)
							end
						end
					end)
				else
					local Character = Player_.Character
					if Character then
						for i, bodyPart in pairs(Character:GetChildren()) do
							if bodyPart:IsA("BasePart") then
								for i, _BoxCham in pairs(Assets:WaitForChild("ChamBox"):GetChildren()) do
									task.spawn(function()
										local newChammer = _BoxCham:Clone()
										newChammer.Enabled = true
										newChammer.Parent = bodyPart
										newChammer.Name = newChammer.Name..Player_.Name
										if Player_ == private.findSheriff() then
											newChammer.PSE.BackgroundColor3 = Color3.fromRGB(105, 125, 255)
										elseif Player_ == private.findMurderer() then
											newChammer.PSE.BackgroundColor3 = Color3.fromRGB(255, 97, 97)
										elseif Player_ == private.findHero() then
											newChammer.PSE.BackgroundColor3 = Color3.fromRGB(255, 237, 98)
										else
											newChammer.PSE.BackgroundColor3 = Color3.fromRGB(157, 255, 111)
										end
										newChammer.Adornee = nil;

										table.insert(GlobalData.ESPs, newChammer);
									end)
								end
							end
						end
					end
				end
			end

			local function InitializeESP()
				for i, esp in pairs(GlobalData.ESPs) do
					esp:Destroy();
				end;

				for i, Player_ in pairs(getgenv().Services.Players:GetPlayers()) do
					if Player_ == Player then continue end
					task.spawn(function()
						createEsp(Player_)
					end)
				end
			end

			local function loadEsp()
				InitializeESP()
				if GlobalData.ChamType == "Highlight" then
					for i, player in pairs(getgenv().Services.Players:GetPlayers()) do
						if player == private.findSheriff() then
							local esp = Storage:FindFirstChild(player.Name)
							if esp then
								esp.Adornee = player.Character
								esp.FillColor = Color3.fromRGB(105, 125, 255)
								esp.OutlineColor = Color3.fromRGB(105, 125, 255)
							end
						elseif player == private.findMurderer() then
							local esp = Storage:FindFirstChild(player.Name)
							if esp then
								esp.Adornee = player.Character
								esp.FillColor = Color3.fromRGB(255, 97, 97)
								esp.OutlineColor = Color3.fromRGB(255, 97, 97)
							end
						elseif Player == private.findHero() then
							local esp = Storage:FindFirstChild(player.Name)
							if esp then
								esp.Adornee = player.Character
								esp.FillColor = Color3.fromRGB(255, 237, 98)
								esp.OutlineColor = Color3.fromRGB(255, 237, 98)
							end
						else
							local esp = Storage:FindFirstChild(player.Name)
							if esp then
								esp.Adornee = player.Character
								esp.FillColor = Color3.fromRGB(157, 255, 111)
								esp.OutlineColor = Color3.fromRGB(157, 255, 111)
							end
						end
					end
				else
					for i, player in pairs(getgenv().Services.Players:GetPlayers()) do
						if player == private.findSheriff() then
							if not player.Character then
								return
							end
							for i, PSE in pairs(player.Character:GetDescendants()) do
								if PSE:GetAttribute("ESP_BoxType") == true then
									PSE.PSE.BackgroundColor3 = Color3.fromRGB(105, 125, 255)
								end
							end
						elseif player == private.findMurderer() then
							if not player.Character then
								return
							end
							for i, PSE in pairs(player.Character:GetDescendants()) do
								if PSE:GetAttribute("ESP_BoxType") == true then
									PSE.PSE.BackgroundColor3 = Color3.fromRGB(255, 97, 97)
								end
							end
						elseif Player == private.findHero() then
							if not player.Character then
								return
							end
							for i, PSE in pairs(player.Character:GetDescendants()) do
								if PSE:GetAttribute("ESP_BoxType") == true then
									PSE.PSE.BackgroundColor3 = Color3.fromRGB(255, 237, 98)
								end
							end
						else
							if not player.Character then
								return
							end
							for i, PSE in pairs(player.Character:GetDescendants()) do
								if PSE:GetAttribute("ESP_BoxType") == true then
									PSE.PSE.BackgroundColor3 = Color3.fromRGB(157, 255, 111)
								end
							end
						end
					end
				end
			end

			GlobalData.Connections["ChamChanged_player"] = GlobalData.ChamTypeChanged:Connect(function()
				loadEsp()
			end)

			GlobalData.Connections["Reset"] = getgenv().Services.Players.LocalPlayer.CharacterAdded:Connect(function()
				getgenv().Services.Players.LocalPlayer.CharacterAppearanceLoaded:Connect(function()
					loadEsp()
				end)
			end)

			loadEsp()

			GlobalData.Connections["PlayerAdd"] = getgenv().Services.Players.ChildAdded:Connect(function(child)
				loadEsp(child)
			end)

			GlobalData.Connections["ReceiveReload"] = GlobalData.ReloadESP:Connect(function()
				loadEsp()
			end)

			GlobalData.Connections["WorkspaceAdded"] = workspace.ChildAdded:Connect(function(child)
				if getgenv().Services.Players:FindFirstChild(child.Name) then
					createEsp(getgenv().Services.Players:FindFirstChild(child.Name))
				end
			end)

			GlobalData.Connections["PlayerRemove"] = getgenv().Services.Players.ChildRemoved:Connect(function()
				loadEsp()
			end)
		end,
		onDeactivated = function(MainUnit, Value)
			MM2Save:addBatch("PlayerChams", {
				Value = false
			})
			if GlobalData.Connections["Reset"] ~= nil then
				GlobalData.Connections["Reset"]:Disconnect();
			end
			if GlobalData.Connections["ChamChanged_player"] ~= nil then
				GlobalData.Connections["ChamChanged_player"]:Disconnect();
			end
			if GlobalData.Connections["PlayerRemove"] ~= nil then
				GlobalData.Connections["PlayerRemove"]:Disconnect();
			end				
			if GlobalData.Connections["PlayerAdd"] ~= nil then
				GlobalData.Connections["PlayerAdd"]:Disconnect();
			end
			if GlobalData.Connections["ReceiveReload"] ~= nil then
				GlobalData.Connections["ReceiveReload"]:Disconnect();
			end
			if GlobalData.Connections["WorkspaceAdded"] ~= nil then
				GlobalData.Connections["WorkspaceAdded"]:Disconnect();
			end
			for i, esp in pairs(GlobalData.ESPs) do
				esp:Destroy();
			end;
		end,
		defaultValue = DefaultValue,
		cooldown = 0.2,
	}, "Top")
end
