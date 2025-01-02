return function()
	local GlobalData = {
	ESPs = {};
	GunESP = {};
	TrapESP = {};
	OriginalSheriff = nil;
	PlayerRoles = nil;
	Connections = {};
	PlayerWalkspeed = game:GetService("Players").LocalPlayer.Character:FindFirstChild("Humanoid").WalkSpeed;
	PlayerJumppower = game:GetService("Players").LocalPlayer.Character:FindFirstChild("Humanoid").JumpPower;
	ReloadESP = Signal.new();
	ChamTypeChanged = Signal.new();
	FlingTarget = nil;
	CoinsESP = {};
	GunDropped = Signal.new();
	GunTook = Signal.new();
	ChamType = "Box"
}

  local private = {}

function private.findHero()
	if GlobalData.PlayerRoles then
		for player, data in GlobalData.PlayerRoles do
			if data.Role == "Hero" then
				if game:GetService("Players"):FindFirstChild(player) then
					if game:GetService("Players"):FindFirstChild(player).Character then
						return game:GetService("Players"):FindFirstChild(player)
					end
				end
			end
		end
	end
end

function private.findSheriff()
	for i, player in pairs(game:GetService("Players"):GetPlayers()) do
		if player then
			if player ~= private.findHero() then
				if player:FindFirstChild("Backpack") then
					if player.Backpack:FindFirstChild("Gun") then
						return player
					end
				end
			end
		end
	end

	for i, player in pairs(game:GetService("Players"):GetPlayers()) do
		if player then
			if player ~= private.findHero() then
				if player.Character then
					if player:FindFirstChild("HumanoidRootPart") then
						if player.Character:FindFirstChild("Gun") then
							return player
						end
					end
				end
			end
		end
	end

	if GlobalData.PlayerRoles then
		for player, data in GlobalData.PlayerRoles do
			if data.Role == "Sheriff" then
				if game:GetService("Players"):FindFirstChild(player) then
					if game:GetService("Players"):FindFirstChild(player).Character then
						return game:GetService("Players"):FindFirstChild(player)
					end
				end
			end
		end
	end
end

function private.findMurderer()
	for i, player in pairs(game:GetService("Players"):GetPlayers()) do
		if player then
			if player:FindFirstChild("Backpack") then
				if player.Backpack:FindFirstChild("Knife") then
					return player
				end
			end
		end
	end

	for i, player in pairs(game:GetService("Players"):GetPlayers()) do
		if player then
			if player.Character then
				if player:FindFirstChild("HumanoidRootPart") then
					if player.Character:FindFirstChild("Knife") then
						return player
					end
				end
			end
		end
	end

	if GlobalData.PlayerRoles then
		for player, data in GlobalData.PlayerRoles do
			if data.Role == "Murderer" then
				if game:GetService("Players"):FindFirstChild(player) then
					if game:GetService("Players"):FindFirstChild(player).Character then
						return game:GetService("Players"):FindFirstChild(player)
					end
				end
			end
		end
	end
end

function private.getMap()
	for _, possibleMap in ipairs(workspace:GetChildren()) do
		if possibleMap:FindFirstChild("CoinContainer") and possibleMap:FindFirstChild("Spawns") then
			return possibleMap
		end
	end
	return nil
end

function private.fling(TargetPlayer)
	local Character = Player.Character
	local Humanoid = Character and Character:FindFirstChildOfClass("Humanoid")
	local RootPart = Humanoid and Humanoid.RootPart

	local data = {}

	local TCharacter = TargetPlayer.Character
	local THumanoid
	local TRootPart
	local THead
	local Accessory
	local Handle

	if TCharacter:FindFirstChildOfClass("Humanoid") then
		THumanoid = TCharacter:FindFirstChildOfClass("Humanoid")
	end
	if THumanoid and THumanoid.RootPart then
		TRootPart = THumanoid.RootPart
	end
	if TCharacter:FindFirstChild("Head") then
		THead = TCharacter.Head
	end
	if TCharacter:FindFirstChildOfClass("Accessory") then
		Accessory = TCharacter:FindFirstChildOfClass("Accessory")
	end
	if Accessory and Accessory:FindFirstChild("Handle") then
		Handle = Accessory.Handle
	end

	if Character and Humanoid and RootPart then
		if RootPart.Velocity.Magnitude < 50 then
			data.OldPos = RootPart.CFrame
		end

		if THumanoid and THumanoid.Sit then
		end

		if THead then
			if THead.Velocity.Magnitude > 500 then
				Management:notice(Enums.NoticeType.Alert, 3,"Player is already flinged", "ERROR")
				return
			end
		elseif not THead and Handle then
			if Handle.Velocity.Magnitude > 500 then
				Management:notice(Enums.NoticeType.Alert, 3,"Player is already flinged", "ERROR")
				return
			end
		end

		if THead then
			workspace.CurrentCamera.CameraSubject = THead
		elseif not THead and Handle then
			workspace.CurrentCamera.CameraSubject = Handle
		elseif THumanoid and TRootPart then
			workspace.CurrentCamera.CameraSubject = THumanoid
		end
		if not TCharacter:FindFirstChildWhichIsA("BasePart") then
			return
		end

		local FPos = function(BasePart, Pos, Ang)
			RootPart.CFrame = CFrame.new(BasePart.Position) * Pos * Ang
			Character:SetPrimaryPartCFrame(CFrame.new(BasePart.Position) * Pos * Ang)
			RootPart.Velocity = Vector3.new(9e7, 9e7 * 10, 9e7)
			RootPart.RotVelocity = Vector3.new(9e8, 9e8, 9e8)
		end

		local SFBasePart = function(BasePart)
			local TimeToWait = 2
			local Time = tick()
			local Angle = 0

			repeat
				if RootPart and THumanoid then
					if BasePart.Velocity.Magnitude < 50 then
						Angle = Angle + 100

						FPos(BasePart, CFrame.new(0, 1.5, 0) + THumanoid.MoveDirection * BasePart.Velocity.Magnitude / 1.25, CFrame.Angles(math.rad(Angle),0 ,0))
						task.wait()

						FPos(BasePart, CFrame.new(0, -1.5, 0) + THumanoid.MoveDirection * BasePart.Velocity.Magnitude / 1.25, CFrame.Angles(math.rad(Angle), 0, 0))
						task.wait()

						FPos(BasePart, CFrame.new(2.25, 1.5, -2.25) + THumanoid.MoveDirection * BasePart.Velocity.Magnitude / 1.25, CFrame.Angles(math.rad(Angle), 0, 0))
						task.wait()

						FPos(BasePart, CFrame.new(-2.25, -1.5, 2.25) + THumanoid.MoveDirection * BasePart.Velocity.Magnitude / 1.25, CFrame.Angles(math.rad(Angle), 0, 0))
						task.wait()

						FPos(BasePart, CFrame.new(0, 1.5, 0) + THumanoid.MoveDirection,CFrame.Angles(math.rad(Angle), 0, 0))
						task.wait()

						FPos(BasePart, CFrame.new(0, -1.5, 0) + THumanoid.MoveDirection,CFrame.Angles(math.rad(Angle), 0, 0))
						task.wait()
					else
						FPos(BasePart, CFrame.new(0, 1.5, THumanoid.WalkSpeed), CFrame.Angles(math.rad(90), 0, 0))
						task.wait()

						FPos(BasePart, CFrame.new(0, -1.5, -THumanoid.WalkSpeed), CFrame.Angles(0, 0, 0))
						task.wait()

						FPos(BasePart, CFrame.new(0, 1.5, THumanoid.WalkSpeed), CFrame.Angles(math.rad(90), 0, 0))
						task.wait()

						FPos(BasePart, CFrame.new(0, 1.5, TRootPart.Velocity.Magnitude / 1.25), CFrame.Angles(math.rad(90), 0, 0))
						task.wait()

						FPos(BasePart, CFrame.new(0, -1.5, -TRootPart.Velocity.Magnitude / 1.25), CFrame.Angles(0, 0, 0))
						task.wait()

						FPos(BasePart, CFrame.new(0, 1.5, TRootPart.Velocity.Magnitude / 1.25), CFrame.Angles(math.rad(90), 0, 0))
						task.wait()

						FPos(BasePart, CFrame.new(0, -1.5, 0), CFrame.Angles(math.rad(90), 0, 0))
						task.wait()

						FPos(BasePart, CFrame.new(0, -1.5, 0), CFrame.Angles(0, 0, 0))
						task.wait()

						FPos(BasePart, CFrame.new(0, -1.5 ,0), CFrame.Angles(math.rad(-90), 0, 0))
						task.wait()

						FPos(BasePart, CFrame.new(0, -1.5, 0), CFrame.Angles(0, 0, 0))
						task.wait()
					end
				else
					break
				end
			until BasePart.Velocity.Magnitude > 500 or BasePart.Parent ~= TargetPlayer.Character or TargetPlayer.Parent ~= game:GetService("Players") or TargetPlayer.Character ~= TCharacter or THumanoid.Sit or Humanoid.Health <= 0 or tick() > Time + TimeToWait
			Management:notice(Enums.NoticeType.Notification, 3, "Successfully flinged player.", "SUCCESS")	
		end

		workspace.FallenPartsDestroyHeight = 0/0

		local BV = Instance.new("BodyVelocity")
		BV.Name = "EpixVel"
		BV.Parent = RootPart
		BV.Velocity = Vector3.new(9e8, 9e8, 9e8)
		BV.MaxForce = Vector3.new(1/0, 1/0, 1/0)

		Humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, false)

		if TRootPart and THead then
			if (TRootPart.CFrame.p - THead.CFrame.p).Magnitude > 5 then
				SFBasePart(THead)
			else
				SFBasePart(TRootPart)
			end
		elseif TRootPart and not THead then
			SFBasePart(TRootPart)
		elseif not TRootPart and THead then
			SFBasePart(THead)
		elseif not TRootPart and not THead and Accessory and Handle then
			SFBasePart(Handle)
		else
			Management:notice(Enums.NoticeType.Alert, 3,"Can't find a part from the player's character to fling.", "ERROR")
		end

		BV:Destroy()
		Humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, true)
		workspace.CurrentCamera.CameraSubject = Humanoid

		repeat
			RootPart.CFrame = data.OldPos * CFrame.new(0, .5, 0)
			Character:SetPrimaryPartCFrame(data.OldPos * CFrame.new(0, .5, 0))
			Humanoid:ChangeState("GettingUp")
			for i, x in pairs(Character:GetChildren()) do
				if x:IsA("BasePart") then
					x.Velocity, x.RotVelocity = Vector3.new(), Vector3.new()
				end
			end
			task.wait()
		until (RootPart.Position - data.OldPos.p).Magnitude < 25
		workspace.FallenPartsDestroyHeight = data.FPDH
	else
		Management:notice(Enums.NoticeType.Alert, 3,"Player might have died, target player has no character.", "ERROR")
	end
end

if game:GetService("ReplicatedStorage"):FindFirstChild("Remotes") then
	GlobalData.Connections["HookRoles"] = game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("Gameplay"):WaitForChild("PlayerDataChanged", 5).OnClientEvent:Connect(function(RoleData)
		GlobalData.PlayerRoles = RoleData
		GlobalData.ReloadESP:Fire()		
		GlobalData.OriginalSheriff = private.findSheriff();		
	end)
	
	GlobalData.Connections["RoundEnding"] = game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("Gameplay"):WaitForChild("RoundEndFade", 5).OnClientEvent:Connect(function()
		GlobalData.ReloadESP:Fire()		
	end)
end

workspace.DescendantAdded:Connect(function(Child)
	if Child.Name == "GunDrop" then
		GlobalData.GunDropped:Fire(Child)
	end
end)

Management.newContent("Game")
	:setSideButtonTitle("MM2")
	:addWindowTitle("Features")
	:addSpacialLine()
	:addWindowSubtitle("Chams")
	:addUnit("Player Chams", Enums.UnitType.Switch, {
		onActivated = function(MainUnit, Value)			
			local function InitializeESP()
				for i, esp in pairs(GlobalData.ESPs) do
					esp:Destroy();
				end;

				if GlobalData.ChamType == "Highlight" then
					for i, Player in pairs(game:GetService("Players"):GetPlayers()) do
						local newHighlight = Instance.new("Highlight", Storage)
						newHighlight.Name = Player.Name
						newHighlight.FillColor = Color3.fromRGB(157, 255, 111)
						newHighlight.FillTransparency = 0.35
						newHighlight.OutlineColor = Color3.fromRGB(157, 255, 111)
						newHighlight.OutlineTransparency = 0.4
						newHighlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop

						table.insert(GlobalData.ESPs, newHighlight);
					end
				else
					for i, Player in pairs(game:GetService("Players"):GetPlayers()) do
						local Character = Player.Character
						if Character then
							for i, bodyPart in pairs(Character:GetChildren()) do
								if bodyPart:IsA("BasePart") then
									for i, _BoxCham in pairs(Assets:WaitForChild("ChamBox"):GetChildren()) do
										local newChammer = _BoxCham:Clone()
										newChammer.Parent = bodyPart
										newChammer.Name = newChammer.Name..Player.Name
										newChammer.PSE.BackgroundColor3 = Color3.fromRGB(157, 255, 111)
										newChammer.Adornee = nil;

										table.insert(GlobalData.ESPs, newChammer);
									end
								end
							end
						end
					end
				end
			end

			local function loadEsp()
				InitializeESP()
				if GlobalData.ChamType == "Highlight" then
					for i, player in pairs(game:GetService("Players"):GetPlayers()) do
						if player == private.findSheriff() then
							local esp = Storage:FindFirstChild(player.Name)
							esp.Adornee = player.Character
							esp.FillColor = Color3.fromRGB(105, 125, 255)
							esp.OutlineColor = Color3.fromRGB(105, 125, 255)
						elseif player == private.findMurderer() then
							local esp = Storage:FindFirstChild(player.Name)
							esp.Adornee = player.Character
							esp.FillColor = Color3.fromRGB(255, 97, 97)
							esp.OutlineColor = Color3.fromRGB(255, 97, 97)
						elseif Player == private.findHero() then
							local esp = Storage:FindFirstChild(player.Name)
							esp.Adornee = player.Character
							esp.FillColor = Color3.fromRGB(255, 237, 98)
							esp.OutlineColor = Color3.fromRGB(255, 237, 98)
						else
							local esp = Storage:FindFirstChild(player.Name)
							esp.Adornee = player.Character
							esp.FillColor = Color3.fromRGB(157, 255, 111)
							esp.OutlineColor = Color3.fromRGB(157, 255, 111)
						end
					end
				else
					for i, player in pairs(game:GetService("Players"):GetPlayers()) do
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

			GlobalData.Connections["Reset"] = game:GetService("Players").LocalPlayer.CharacterAdded:Connect(function()
				game:GetService("Players").LocalPlayer.CharacterAppearanceLoaded:Connect(function()
					loadEsp()
				end)
			end)

			loadEsp()

			GlobalData.Connections["PlayerAdd"] = game:GetService("Players").ChildAdded:Connect(function()
				loadEsp()
			end)

			GlobalData.Connections["ReceiveReload"] = GlobalData.ReloadESP:Connect(function()
				loadEsp()
			end)

			GlobalData.Connections["PlayerRemove"] = game:GetService("Players").ChildRemoved:Connect(function()
				loadEsp()
			end)
		end,
		onDeactivated = function(MainUnit, Value)
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
			for i, esp in pairs(GlobalData.ESPs) do
				esp:Destroy();
			end;
		end,
		defaultValue = false,
		cooldown = 0.2,
	})
	:addUnit("Dropped Gun Cham", Enums.UnitType.Switch, {
		onActivated = function(MainUnit, Value)
			--local function TrackGunActions(GunDrop)
			--	if GunDrop then
			--		GunDrop.Touched:Connect(function(Hit)
			--			if game.Players:GetPlayers(Hit.Parent) then
			--				GlobalData["GunGetting"] = true
			--			end
			--		end)
			--	end
			--end

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
					local newHighlight = Assets:WaitForChild("ChamBox"):Clone()
					newHighlight.Parent = Storage;
					newHighlight.Size = Vector3.new(1.5, 1.5, 1.5)
					newHighlight.Name = "GunDrop";
					newHighlight.Position = location:IsA("BasePart") and location.Position or location:IsA("Model") and location:GetPivot().Position or location:IsA("Attachment") and location.WorldPosition;
					for i, v in pairs(newHighlight:GetDescendants()) do
						if v.Name == "PSE" then
							v.BackgroundColor3 = Color3.fromRGB(188, 133, 255)
						end
					end

					table.insert(GlobalData.GunESP, newHighlight)
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

			GlobalData.Connections["GunRemoval"] = workspace.DescendantRemoving:Connect(function(Child)
				if Child.Name == "GunDrop" then
					GlobalData.GunTook:Fire()
					--if GlobalData.GunGetting == true then
					GlobalData.ReloadESP:Fire()
					--end
					for i, v in pairs(GlobalData.GunESP) do
						v:Destroy()
					end
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
	})
	:addUnit("Trap Chams", Enums.UnitType.Switch, {
		onActivated = function(MainUnit, Value)
			local function CreateTrapESP(location)
				for i, v in pairs(GlobalData.TrapESP) do
					v:Destroy()
				end

				if GlobalData.ChamType == "Highlight" then
					local newHighlight = Instance.new("Highlight", Storage)
					newHighlight.Name = "Trap"
					newHighlight.FillColor = Color3.fromRGB(180, 53, 83)
					newHighlight.FillTransparency = 0.35
					newHighlight.OutlineColor = Color3.fromRGB(180, 53, 83)
					newHighlight.OutlineTransparency = 0.4
					newHighlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop

					newHighlight.Adornee = location
					table.insert(GlobalData.TrapESP, newHighlight)
				else
					local newHighlight = Assets:WaitForChild("ChamBox"):Clone()
					newHighlight.Parent = Storage;
					newHighlight.Name = "Trap";
					newHighlight.Size = Vector3.new(2, 0.8, 2)
					newHighlight.Position = location:IsA("BasePart") and location.Position or location:IsA("Model") and location:GetPivot().Position or location:IsA("Attachment") and location.WorldPosition;
					for i, v in pairs(newHighlight:GetDescendants()) do
						if v.Name == "PSE" then
							v.BackgroundColor3 = Color3.fromRGB(180, 53, 83)
						end
					end

					table.insert(GlobalData.TrapESP, newHighlight)
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
	})
	:addUnit("Coin Chams", Enums.UnitType.Switch, {
		onActivated = function(MainUnit, Value)
			local function CreateCoinESP()
				for i, v in pairs(GlobalData.CoinsESP) do
					v:Destroy()
				end

				if GlobalData.ChamType == "Highlight" then
					for i, Coin in pairs(workspace:GetDescendants()) do
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
				else
					for i, Coin in pairs(workspace:GetDescendants()) do
						if Coin.Name == "CoinVisual" then
							if Coin.Transparency == 0 then
								local newHighlight = Assets:WaitForChild("ChamBox"):Clone()
								newHighlight.Parent = Storage;
								newHighlight.Name = "CoinVisual";
								newHighlight.Position = Coin:IsA("BasePart") and Coin.Position or Coin:IsA("Model") and Coin:GetPivot().Position or Coin:IsA("Attachment") and Coin.WorldPosition;
								for i, v in pairs(newHighlight:GetDescendants()) do
									if v.Name == "PSE" then
										v.BackgroundColor3 = Color3.fromRGB(180, 170, 29)
									end
								end

								table.insert(GlobalData.CoinsESP, newHighlight)
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
	})
	:addUnit("Cham Type", Enums.UnitType.Dropdown, {
		Initialize = function(Unit)
			print("?")
			Unit.OnValueChanged:Connect(function(Value)
				print("e?")
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

	})
	:addSpacial()
	:addWindowSubtitle("Innocent")
	:addUnit("Get Dropped Gun", Enums.UnitType.Toggle, {
		onActivated = function()
			if Character then
				local FindGun = private.getMap():FindFirstChild("GunDrop")
				local GunFetchedSuccess = false
				local CancelGunFetch = false

				if FindGun then
					local KeptOriginalCFrame = Character:WaitForChild("HumanoidRootPart").CFrame
					local KeptOriginalC0 = Character:WaitForChild("LowerTorso"):WaitForChild("Root").C0
					Character:WaitForChild("HumanoidRootPart").Anchored = true;
					Character:WaitForChild("LowerTorso"):WaitForChild("Root").C0 = Character:WaitForChild("LowerTorso"):WaitForChild("Root").C0 * CFrame.new(0,-10,0)
					Character:PivotTo(FindGun:GetPivot())
					task.delay(3, function()
						if GunFetchedSuccess == false then
							CancelGunFetch = true
						end
					end)
					Player.Backpack.ChildAdded:Connect(function(child)
						if child:IsA("Tool") and child.Name == "Gun" then
							GunFetchedSuccess = true
						end
					end)
					repeat task.wait(0.1) until GunFetchedSuccess == true or CancelGunFetch == true
					if CancelGunFetch then
						Management:notice(Enums.NoticeType.Alert, 3, "Un unknown error occured when fetching gun.", "UNKNOWN ERROR")
					end
					Character:PivotTo(KeptOriginalCFrame)
					Character:WaitForChild("LowerTorso"):WaitForChild("Root").C0 = KeptOriginalC0
					Character:WaitForChild("HumanoidRootPart").Anchored = false;
					Character:FindFirstChild("Humanoid"):ChangeState("GettingUp")
				else
					Management:notice(Enums.NoticeType.Alert, 3, "No gun found anywhere, action not completed.", "ERROR")
				end
			end
		end,
		cooldown = 0.2,
	})
	:addUnit("Auto Grab Gun", Enums.UnitType.Switch, {
		onActivated = function()
			if Character then
				local FindGun = private.getMap():FindFirstChild("GunDrop")
				local GunFetchedSuccess = false
				local CancelGunFetch = false

				if FindGun then
					local KeptOriginalCFrame = Character:WaitForChild("HumanoidRootPart").CFrame
					local KeptOriginalC0 = Character:WaitForChild("LowerTorso"):WaitForChild("Root").C0
					Character:WaitForChild("HumanoidRootPart").Anchored = true;
					Character:WaitForChild("LowerTorso"):WaitForChild("Root").C0 = Character:WaitForChild("LowerTorso"):WaitForChild("Root").C0 * CFrame.new(0,-10,0)
					Character:PivotTo(FindGun:GetPivot())
					task.delay(3, function()
						if GunFetchedSuccess == false then
							CancelGunFetch = true
						end
					end)
					Player.Backpack.ChildAdded:Connect(function(child)
						if child:IsA("Tool") and child.Name == "Gun" then
							GunFetchedSuccess = true
						end
					end)
					repeat task.wait(0.1) until GunFetchedSuccess == true or CancelGunFetch == true
					if CancelGunFetch then
						Management:notice(Enums.NoticeType.Alert, 3, "Un unknown error occured when fetching gun.", "UNKNOWN ERROR")
					end
					Character:PivotTo(KeptOriginalCFrame)
					Character:WaitForChild("LowerTorso"):WaitForChild("Root").C0 = KeptOriginalC0
					Character:WaitForChild("HumanoidRootPart").Anchored = false;
					Character:FindFirstChild("Humanoid"):ChangeState("GettingUp")
				else
					Management:notice(Enums.NoticeType.Alert, 3, "No gun found anywhere, action not completed. Will automatically teleport you when found.", "ERROR")
				end
			end
			
			GlobalData.Connections["GunGrabber"] = GlobalData.GunDropped:Connect(function(gunDrop)
				if Character then
					local FindGun = private.getMap():FindFirstChild("GunDrop")
					local GunFetchedSuccess = false
					local CancelGunFetch = false

					if FindGun then
						local KeptOriginalCFrame = Character:WaitForChild("HumanoidRootPart").CFrame
						local KeptOriginalC0 = Character:WaitForChild("LowerTorso"):WaitForChild("Root").C0
						Character:WaitForChild("HumanoidRootPart").Anchored = true;
						Character:WaitForChild("LowerTorso"):WaitForChild("Root").C0 = Character:WaitForChild("LowerTorso"):WaitForChild("Root").C0 * CFrame.new(0,-10,0)
						Character:PivotTo(FindGun:GetPivot())
						task.delay(3, function()
							if GunFetchedSuccess == false then
								CancelGunFetch = true
							end
						end)
						Player.Backpack.ChildAdded:Connect(function(child)
							if child:IsA("Tool") and child.Name == "Gun" then
								GunFetchedSuccess = true
							end
						end)
						repeat task.wait(0.1) until GunFetchedSuccess == true or CancelGunFetch == true
						if CancelGunFetch then
							Management:notice(Enums.NoticeType.Alert, 3, "Un unknown error occured when fetching gun.", "UNKNOWN ERROR")
						end
						Character:PivotTo(KeptOriginalCFrame)
						Character:WaitForChild("LowerTorso"):WaitForChild("Root").C0 = KeptOriginalC0
						Character:WaitForChild("HumanoidRootPart").Anchored = false;
						Character:FindFirstChild("Humanoid"):ChangeState("GettingUp")
					else
						Management:notice(Enums.NoticeType.Alert, 3, "No gun found anywhere, action not completed.", "ERROR")
					end
				end
			end)
		end,
		onDeactivated = function()
			if GlobalData.Connections["GunGrabber"] ~= nil then
				GlobalData.Connections["GunGrabber"]:Disconnect()
			end
		end,
		defaultValue = false,
	})
	:addUnit("GunStatus", Enums.UnitType.Info, {
		Initialize = function(Unit)
			GlobalData.Connections["CheckGunDropped"] = GlobalData.GunDropped:Connect(function()
				Unit.UiInfo.Text = `<font color="rgb(110, 255, 139)">Gun dropped:</font> <font family="rbxasset://fonts/families/Balthazar.json" color="rgb(255, 198, 15)"><b>true</b></font>` 
			end)

			GlobalData.Connections["CheckGunTake"] = GlobalData.GunTook:Connect(function()
				Unit.UiInfo.Text = `<font color="rgb(255, 82, 82)">Gun dropped:</font> <font family="rbxasset://fonts/families/Balthazar.json" color="rgb(255, 198, 15)"><b>false</b></font>` 
			end)
		end,
		Text = `<font color="rgb(255, 82, 82)">Gun dropped:</font> <font family="rbxasset://fonts/families/Balthazar.json" color="rgb(255, 198, 15)"><b>false</b></font>` 
	})
	:addSpacial()
	:addWindowSubtitle("Murderer")
	:addUnit("Kill everyone", Enums.UnitType.Toggle, {
		onActivated = function(MainUnit, Value)
			if Player == private.findMurderer() then
				if not Character:FindFirstChild("Knife") then
					local Humanoid = Character:FindFirstChild("Humanoid")
					if Humanoid then
						if Player.Backpack:FindFirstChild("Knife") then
							Humanoid:EquipTool(Player.Backpack:FindFirstChild("Knife"))
						else
							if private.findMurderer() == Player then
								Management:notice(Enums.NoticeType.Alert, 3, "Wait for your knife. Action cannot be completed.", "KNIFE NEEDED")
								return
							else
								Management:notice(Enums.NoticeType.Alert, 3, "You do not have a knife. Action cannot be completed.", "KNIFE NEEDED")
								return
							end
						end
					end
				end

				for i, v in pairs(game:GetService("Players"):GetPlayers()) do
					if v ~= Player then
						if v.Character then
							if v.Character:FindFirstChild("HumanoidRootPart") then
								v.Character:PivotTo(Character:GetPivot() + Character:GetPivot().LookVector*1)
							end
						end
					end
				end

				local Arguments = {
					[1] = "Slash"
				}

				pcall(function()
					Character:FindFirstChild("Knife").Stab:FireServer(Arguments);
				end)
			else
				Management:notice(Enums.NoticeType.Alert, 3, "You are not the murderer, you cannot perform this action.", "ROLE MISMATCH")
				return
			end
		end,
		cooldown = 0.2,
	})
	:addSpacial()
	:addWindowSubtitle("Player")
	:addUnit("WalkSpeed", Enums.UnitType.Slider, {
		Initialize = function(Unit)
			Unit.OnValueChanged:Connect(function(Value)
				pcall(function()
					game:GetService("Players").LocalPlayer.Character:FindFirstChild("Humanoid").WalkSpeed = Value
					GlobalData.PlayerWalkspeed = Value;
				end)
			end)
		end,
		defaultValue = 16,
		Min = 16,
		Max = 30,
		Increment = 1,
	})
	:addUnit("Loop WalkSpeed", Enums.UnitType.Switch, {
		onActivated = function(MainUnit, Value)	
			GlobalData.Connections["KeepWalkspeed"] = game:GetService("Players").LocalPlayer.Character:FindFirstChild("Humanoid"):GetPropertyChangedSignal("WalkSpeed"):Connect(function()
				if GlobalData.PlayerWalkspeed then
					game:GetService("Players").LocalPlayer.Character:FindFirstChild("Humanoid").WalkSpeed = GlobalData.PlayerWalkspeed
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
	})
	:addUnit("JumpPower", Enums.UnitType.Slider, {
		Initialize = function(Unit)
			Unit.OnValueChanged:Connect(function(Value)
				if game:GetService("Players").LocalPlayer.Character:FindFirstChild("Humanoid").UseJumpPower == false then
					game:GetService("Players").LocalPlayer.Character:FindFirstChild("Humanoid").UseJumpPower = true;
				end;
				pcall(function()
					game:GetService("Players").LocalPlayer.Character:FindFirstChild("Humanoid").JumpPower = Value
					GlobalData.PlayerJumppower = Value
				end)
			end)
		end,
		defaultValue = 50,
		Min = 0,
		Max = 100,
		Increment = 1,
	})
	:addUnit("Loop JumpPower", Enums.UnitType.Switch, {
		onActivated = function(MainUnit, Value)	
			GlobalData.Connections["KeepJumppower"] = game:GetService("Players").LocalPlayer.Character:FindFirstChild("Humanoid"):GetPropertyChangedSignal("JumpPower"):Connect(function()
				if GlobalData.PlayerJumppower then
					game:GetService("Players").LocalPlayer.Character:FindFirstChild("Humanoid").JumpPower = GlobalData.PlayerJumppower
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
	})
	:addSpacial()
	:addWindowTitle("Trolling")
	:addSpacialLine()
	:addWindowSubtitle("Fling")
	:addUnit("Fling Target", Enums.UnitType.Dropdown, {
		Initialize = function(Unit)
			Unit.OnValueChanged:Connect(function(Player)
				if game.Players:FindFirstChild(Player.Name) then
					GlobalData.FlingTarget = game.Players:FindFirstChild(Player.Name)
				end
			end)
		end,
		createEnums = function(Creator)
			local refresh = function()
				local CurrentDrops = {}
				for i, v in pairs(game:GetService("Players"):GetPlayers()) do
					if v ~= game:GetService("Players").LocalPlayer then
						CurrentDrops[v.Name] = {
							Name = v.Name;
							Value = i - 1;
							Color = v == private.findHero() and Color3.fromRGB(255, 237, 98) or v == private.findSheriff() and Color3.fromRGB(105, 125, 255) or v == private.findMurderer() and Color3.fromRGB(255, 97, 97) or Color3.fromRGB(255, 255, 255)
						}
					end
				end
				Creator(CurrentDrops)
			end

			refresh()

			GlobalData.Connections["PlayerRolesChanging"] = GlobalData.ReloadESP:Connect(function()
				refresh()
			end)

			GlobalData.Connections["PlayerRemovingTargetEnum1"] = game:GetService("Players").ChildRemoved:Connect(function()
				refresh()
			end)

			GlobalData.Connections["PlayerAddingTargetEnum1"] = game:GetService("Players").ChildAdded:Connect(function()
				refresh()
			end)

			GlobalData.Connections["PlayerRespawn"] = workspace.ChildAdded:Connect(function(Child)
				if game:GetService("Players"):GetPlayerFromCharacter(Child) then
					refresh()
				end
			end)
		end,
		cooldown = 0.2,

	})
	:addUnit("Fling", Enums.UnitType.Toggle, {
		onActivated = function(MainUnit, Value)
			if GlobalData.FlingTarget ~= nil then
				if GlobalData.FlingTarget.Character then
					private.fling(GlobalData.FlingTarget)
				end
			end
		end,
		cooldown = 0.2,
	})
	:addUnit("Anti-Fling", Enums.UnitType.Switch, {
		onActivated = function(MainUnit, Value)
			--local function miniFling(playerToFling)
			--	local a=game.Players.LocalPlayer;local b=a:GetMouse()local c={playerToFling}local d=game:GetService("Players")local e=d.LocalPlayer;local f=false;local g=function(h)local i=e.Character or e.CharacterAdded:Wait();local j=i and i:FindFirstChildOfClass("Humanoid")local k=j and j.RootPart;local l=h.Character;local m;local n;local o;local p;local q;if l:FindFirstChildOfClass("Humanoid")then m=l:FindFirstChildOfClass("Humanoid")end;if m and m.RootPart then n=m.RootPart end;if l:FindFirstChild("Head")then o=l.Head end;if l:FindFirstChildOfClass("Accessory")then p=l:FindFirstChildOfClass("Accessory")end;if p and p:FindFirstChild("Handle")then q=p.Handle end;if i and j and k then if k.Velocity.Magnitude<50 then getgenv().OldPos=k.CFrame end;if m and m.Sit and not f then end;if o then if o.Velocity.Magnitude>500 then print("warn here: flung") end elseif not o and q then if q.Velocity.Magnitude>500 then print("warn here: flung already") end end;if o then workspace.CurrentCamera.CameraSubject=o elseif not o and q then workspace.CurrentCamera.CameraSubject=q elseif m and n then workspace.CurrentCamera.CameraSubject=m end;if not l:FindFirstChildWhichIsA("BasePart")then return end;local r=function(s,t,u)k.CFrame=CFrame.new(s.Position)*t*u;i:SetPrimaryPartCFrame(CFrame.new(s.Position)*t*u)k.Velocity=Vector3.new(9e7,9e7*10,9e7)k.RotVelocity=Vector3.new(9e8,9e8,9e8)end;local v=function(s)local w=2;local x=tick()local y=0;repeat if k and m then if s.Velocity.Magnitude<50 then y=y+100;r(s,CFrame.new(0,1.5,0)+m.MoveDirection*s.Velocity.Magnitude/1.25,CFrame.Angles(math.rad(y),0,0))task.wait()r(s,CFrame.new(0,-1.5,0)+m.MoveDirection*s.Velocity.Magnitude/1.25,CFrame.Angles(math.rad(y),0,0))task.wait()r(s,CFrame.new(2.25,1.5,-2.25)+m.MoveDirection*s.Velocity.Magnitude/1.25,CFrame.Angles(math.rad(y),0,0))task.wait()r(s,CFrame.new(-2.25,-1.5,2.25)+m.MoveDirection*s.Velocity.Magnitude/1.25,CFrame.Angles(math.rad(y),0,0))task.wait()r(s,CFrame.new(0,1.5,0)+m.MoveDirection,CFrame.Angles(math.rad(y),0,0))task.wait()r(s,CFrame.new(0,-1.5,0)+m.MoveDirection,CFrame.Angles(math.rad(y),0,0))task.wait()else r(s,CFrame.new(0,1.5,m.WalkSpeed),CFrame.Angles(math.rad(90),0,0))task.wait()r(s,CFrame.new(0,-1.5,-m.WalkSpeed),CFrame.Angles(0,0,0))task.wait()r(s,CFrame.new(0,1.5,m.WalkSpeed),CFrame.Angles(math.rad(90),0,0))task.wait()r(s,CFrame.new(0,1.5,n.Velocity.Magnitude/1.25),CFrame.Angles(math.rad(90),0,0))task.wait()r(s,CFrame.new(0,-1.5,-n.Velocity.Magnitude/1.25),CFrame.Angles(0,0,0))task.wait()r(s,CFrame.new(0,1.5,n.Velocity.Magnitude/1.25),CFrame.Angles(math.rad(90),0,0))task.wait()r(s,CFrame.new(0,-1.5,0),CFrame.Angles(math.rad(90),0,0))task.wait()r(s,CFrame.new(0,-1.5,0),CFrame.Angles(0,0,0))task.wait()r(s,CFrame.new(0,-1.5,0),CFrame.Angles(math.rad(-90),0,0))task.wait()r(s,CFrame.new(0,-1.5,0),CFrame.Angles(0,0,0))task.wait()end else break end until s.Velocity.Magnitude>500 or s.Parent~=h.Character or h.Parent~=d or h.Character~=l or m.Sit or j.Health<=0 or tick()>x+w end;workspace.FallenPartsDestroyHeight=0/0;local z=Instance.new("BodyVelocity")z.Name="Bozo"z.Parent=k;z.Velocity=Vector3.new(9e8,9e8,9e8)z.MaxForce=Vector3.new(1/0,1/0,1/0)j:SetStateEnabled(Enum.HumanoidStateType.Seated,false)if n and o then if(n.CFrame.p-o.CFrame.p).Magnitude>5 then v(o)else v(n)end elseif n and not o then v(n)elseif not n and o then v(o)elseif not n and not o and p and q then v(q)else print("warn here no valid fling body part target") end;z:Destroy()j:SetStateEnabled(Enum.HumanoidStateType.Seated,true)workspace.CurrentCamera.CameraSubject=j;repeat k.CFrame=getgenv().OldPos*CFrame.new(0,.5,0)i:SetPrimaryPartCFrame(getgenv().OldPos*CFrame.new(0,.5,0))j:ChangeState("GettingUp")table.foreach(i:GetChildren(),function(A,B)if B:IsA("BasePart")then B.Velocity,B.RotVelocity=Vector3.new(),Vector3.new()end end)task.wait()until(k.Position-getgenv().OldPos.p).Magnitude<25;workspace.FallenPartsDestroyHeight=getgenv().FPDH else print("warn here: player is not found, mightve died?") end end;g(c[1])
			--end

			--miniFling(GlobalData.FlingTarget)
		end,
		onDeactivated = function(MainUnit, Value)
			--local function miniFling(playerToFling)
			--	local a=game.Players.LocalPlayer;local b=a:GetMouse()local c={playerToFling}local d=game:GetService("Players")local e=d.LocalPlayer;local f=false;local g=function(h)local i=e.Character or e.CharacterAdded:Wait();local j=i and i:FindFirstChildOfClass("Humanoid")local k=j and j.RootPart;local l=h.Character;local m;local n;local o;local p;local q;if l:FindFirstChildOfClass("Humanoid")then m=l:FindFirstChildOfClass("Humanoid")end;if m and m.RootPart then n=m.RootPart end;if l:FindFirstChild("Head")then o=l.Head end;if l:FindFirstChildOfClass("Accessory")then p=l:FindFirstChildOfClass("Accessory")end;if p and p:FindFirstChild("Handle")then q=p.Handle end;if i and j and k then if k.Velocity.Magnitude<50 then getgenv().OldPos=k.CFrame end;if m and m.Sit and not f then end;if o then if o.Velocity.Magnitude>500 then print("warn here: flung") end elseif not o and q then if q.Velocity.Magnitude>500 then print("warn here: flung already") end end;if o then workspace.CurrentCamera.CameraSubject=o elseif not o and q then workspace.CurrentCamera.CameraSubject=q elseif m and n then workspace.CurrentCamera.CameraSubject=m end;if not l:FindFirstChildWhichIsA("BasePart")then return end;local r=function(s,t,u)k.CFrame=CFrame.new(s.Position)*t*u;i:SetPrimaryPartCFrame(CFrame.new(s.Position)*t*u)k.Velocity=Vector3.new(9e7,9e7*10,9e7)k.RotVelocity=Vector3.new(9e8,9e8,9e8)end;local v=function(s)local w=2;local x=tick()local y=0;repeat if k and m then if s.Velocity.Magnitude<50 then y=y+100;r(s,CFrame.new(0,1.5,0)+m.MoveDirection*s.Velocity.Magnitude/1.25,CFrame.Angles(math.rad(y),0,0))task.wait()r(s,CFrame.new(0,-1.5,0)+m.MoveDirection*s.Velocity.Magnitude/1.25,CFrame.Angles(math.rad(y),0,0))task.wait()r(s,CFrame.new(2.25,1.5,-2.25)+m.MoveDirection*s.Velocity.Magnitude/1.25,CFrame.Angles(math.rad(y),0,0))task.wait()r(s,CFrame.new(-2.25,-1.5,2.25)+m.MoveDirection*s.Velocity.Magnitude/1.25,CFrame.Angles(math.rad(y),0,0))task.wait()r(s,CFrame.new(0,1.5,0)+m.MoveDirection,CFrame.Angles(math.rad(y),0,0))task.wait()r(s,CFrame.new(0,-1.5,0)+m.MoveDirection,CFrame.Angles(math.rad(y),0,0))task.wait()else r(s,CFrame.new(0,1.5,m.WalkSpeed),CFrame.Angles(math.rad(90),0,0))task.wait()r(s,CFrame.new(0,-1.5,-m.WalkSpeed),CFrame.Angles(0,0,0))task.wait()r(s,CFrame.new(0,1.5,m.WalkSpeed),CFrame.Angles(math.rad(90),0,0))task.wait()r(s,CFrame.new(0,1.5,n.Velocity.Magnitude/1.25),CFrame.Angles(math.rad(90),0,0))task.wait()r(s,CFrame.new(0,-1.5,-n.Velocity.Magnitude/1.25),CFrame.Angles(0,0,0))task.wait()r(s,CFrame.new(0,1.5,n.Velocity.Magnitude/1.25),CFrame.Angles(math.rad(90),0,0))task.wait()r(s,CFrame.new(0,-1.5,0),CFrame.Angles(math.rad(90),0,0))task.wait()r(s,CFrame.new(0,-1.5,0),CFrame.Angles(0,0,0))task.wait()r(s,CFrame.new(0,-1.5,0),CFrame.Angles(math.rad(-90),0,0))task.wait()r(s,CFrame.new(0,-1.5,0),CFrame.Angles(0,0,0))task.wait()end else break end until s.Velocity.Magnitude>500 or s.Parent~=h.Character or h.Parent~=d or h.Character~=l or m.Sit or j.Health<=0 or tick()>x+w end;workspace.FallenPartsDestroyHeight=0/0;local z=Instance.new("BodyVelocity")z.Name="Bozo"z.Parent=k;z.Velocity=Vector3.new(9e8,9e8,9e8)z.MaxForce=Vector3.new(1/0,1/0,1/0)j:SetStateEnabled(Enum.HumanoidStateType.Seated,false)if n and o then if(n.CFrame.p-o.CFrame.p).Magnitude>5 then v(o)else v(n)end elseif n and not o then v(n)elseif not n and o then v(o)elseif not n and not o and p and q then v(q)else print("warn here no valid fling body part target") end;z:Destroy()j:SetStateEnabled(Enum.HumanoidStateType.Seated,true)workspace.CurrentCamera.CameraSubject=j;repeat k.CFrame=getgenv().OldPos*CFrame.new(0,.5,0)i:SetPrimaryPartCFrame(getgenv().OldPos*CFrame.new(0,.5,0))j:ChangeState("GettingUp")table.foreach(i:GetChildren(),function(A,B)if B:IsA("BasePart")then B.Velocity,B.RotVelocity=Vector3.new(),Vector3.new()end end)task.wait()until(k.Position-getgenv().OldPos.p).Magnitude<25;workspace.FallenPartsDestroyHeight=getgenv().FPDH else print("warn here: player is not found, mightve died?") end end;g(c[1])
			--end

			--miniFling(GlobalData.FlingTarget)
		end,
		cooldown = 0.2,
		defaultValue = false
	})
	:addSpacial()
end
