return function()
	print("Loaded MM2")

	local MainAPI = getgenv().NebulaHub.API

	local RunService = getgenv().Services.RunService;
	local TweenService = getgenv().Services.TweenService;
	local Players = getgenv().Services.Players;

	local Enums = getgenv().NebulaHub.Dependencies.Manager.Enums;
	local Signal = getgenv().NebulaHub.Dependencies.Manager.Signal;

	local Management = getgenv().NebulaHub.Dependencies.Manager.Management;

	getgenv().NebulaHub.Loaded["MM2"] = {}

	getgenv().NebulaHub.Loaded["MM2"].GlobalData = {
		ESPs = {};
		GunESP = {};
		TrapESP = {};
		OriginalSheriff = nil;
		PlayerRoles = nil;
		Connections = {};
		PlayerWalkspeed = getgenv().LocalPlayer.Character:FindFirstChild("Humanoid").WalkSpeed;
		PlayerJumppower = getgenv().LocalPlayer.Character:FindFirstChild("Humanoid").JumpPower;
		ReloadESP = Signal.new();
		ChamTypeChanged = Signal.new();
		FlingTarget = nil;
		CoinsESP = {};
		GunDropped = Signal.new();
		GunTook = Signal.new();
		ChamType = "Box";
		InRound = true;
		GunGetDeb = false;
	}
	
	local GlobalData = getgenv().NebulaHub.Loaded["MM2"].GlobalData
	local private = {}
	
	function private.findHero()
		if GlobalData.PlayerRoles then
			for player, data in GlobalData.PlayerRoles do
				if data.Role == "Hero" then
					if getgenv().Services.Players:FindFirstChild(player) then
						if getgenv().Services.Players:FindFirstChild(player).Character then
							return getgenv().Services.Players:FindFirstChild(player)
						end
					end
				end
			end
		end
	end

	function private.findSheriff()
		for i, player in pairs(getgenv().Services.Players:GetPlayers()) do
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

		for i, player in pairs(getgenv().Services.Players:GetPlayers()) do
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
					if getgenv().Services.Players:FindFirstChild(player) then
						if getgenv().Services.Players:FindFirstChild(player).Character then
							return getgenv().Services.Players:FindFirstChild(player)
						end
					end
				end
			end
		end
	end

	function private.findMurderer()
		for i, player in pairs(getgenv().Services.Players:GetPlayers()) do
			if player then
				if player:FindFirstChild("Backpack") then
					if player.Backpack:FindFirstChild("Knife") then
						return player
					end
				end
			end
		end

		for i, player in pairs(getgenv().Services.Players:GetPlayers()) do
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
					if getgenv().Services.Players:FindFirstChild(player) then
						if getgenv().Services.Players:FindFirstChild(player).Character then
							return getgenv().Services.Players:FindFirstChild(player)
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
				until BasePart.Velocity.Magnitude > 500 or BasePart.Parent ~= TargetPlayer.Character or TargetPlayer.Parent ~= getgenv().Services.Players or TargetPlayer.Character ~= TCharacter or THumanoid.Sit or Humanoid.Health <= 0 or tick() > Time + TimeToWait
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
			Management:notice(Enums.NoticeType.Alert, 3,"You might have died, you have no character.", "ERROR")
		end
	end

	if getgenv().Services.ReplicatedStorage:FindFirstChild("Remotes") then
		GlobalData.Connections["HookRoles"] = getgenv().Services.ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Gameplay"):WaitForChild("PlayerDataChanged", 5).OnClientEvent:Connect(function(RoleData)
			GlobalData.PlayerRoles = RoleData
			GlobalData.ReloadESP:Fire()		
			GlobalData.OriginalSheriff = private.findSheriff();		
		end)

		GlobalData.Connections["RoundEnding"] = getgenv().Services.ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Gameplay"):WaitForChild("RoundEndFade", 5).OnClientEvent:Connect(function()
			GlobalData.ReloadESP:Fire()	
			GlobalData.GunTook:Fire()
		end)
	end

	print(private)
	getgenv().NebulaHub.Loaded["MM2"].private = private
	
	workspace.DescendantAdded:Connect(function(Child)
		if Child.Name == "GunDrop" then
			GlobalData.GunDropped:Fire(Child)
		end
	end)

	workspace.DescendantRemoving:Connect(function(child)
		if child.Name == "GunDrop" then
			GlobalData.GunTook:Fire();
		end
	end)

	local Path = "https://raw.githubusercontent.com/yaj1skrow/Nebula-Hub/refs/heads/main/NebulaHub/Games/MurderMystery2/LogicAPI/"

	local MainLogic = {
		{
			Add = "Subtitle";
			Value = "Chams";
		};
		"PlayerChams.lua";
		"DroppedGunCham.lua";
		"TrapChams.lua";
		"CoinChams.lua";
		"ChamType.lua";
		"Spacial";
		{
			Add = "Title";
			Value = "Player";
		};
		"SpacialLine";
		{
			Add = "Subtitle";
			Value = "Innocent";
		};
		"GetDroppedGun.lua";
		"AutoGrabGun.lua";
		"GunStatus.lua";
		"Spacial";
		{
			Add = "Subtitle";
			Value = "Murderer";
		};
		"KillEveryone.lua";
		"Spacial";
		{
			Add = "Subtitle";
			Value = "Misc";
		};
		"Walkspeed.lua";
		"Jumppower.lua";
		"Spacial";
		{
			Add = "Title";
			Value = "Trolling";
		};
		"SpacialLine";
		{
			Add = "Subtitle";
			Value = "Fling";
		};
		"Fling.lua";
		"Spacial";

	}

	local MainContent = Management.newContent("Game")
	MainContent:setSideButtonTitle("MM2")
		:addWindowTitle("Visual")
		:addSpacialLine()

	local function Init()
		print("test?")
		for val, logicApi in pairs(MainLogic) do
			print("here goes nothing.")
			if logicApi == "Spacial" then
				MainContent:addSpacial()
			elseif logicApi == "SpacialLine" then
				MainContent:addSpacialLine()
			elseif typeof(logicApi) == "table" then
				if logicApi.Add == "Subtitle" then
					MainContent:addWindowSubtitle(logicApi.Value)
				elseif logicApi.Add == "Title" then
					MainContent:addWindowTitle(logicApi.Value)
				end
			elseif string.find(logicApi, "lua") then
				print("here goes nothing. found directory.. now initializing.")
				loadstring(game:HttpGet(Path..logicApi, false))()(MainContent)
			end

		end
	end

	Init()
end
