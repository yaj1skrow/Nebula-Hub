local RunService = getgenv().Services.RunService;
local TweenService = getgenv().Services.TweenService;
local Players = getgenv().Services.Players;

local UserInputService = getgenv().Services.UserInputService
local Slider = getgenv().NebulaHub.Dependencies.Services.Slider

local Assets = getgenv().NebulaHub.MainUI:WaitForChild("Dependencies"):WaitForChild("Assets");
local Signal = getgenv().NebulaHub.Dependencies.Manager.Signal;
local MainUI = getgenv().NebulaHub.MainUI.MainUI;
local Contents = MainUI:WaitForChild("Content");

local SideBar = Contents:WaitForChild("SideBar");
local MainContents = Contents:WaitForChild("MainContents");

local Management = {};
Management.__index = Management;
Management.Methods = {};
Management.Enums = getgenv().NebulaHub.Dependencies.Manager.Enums
local Enums = Management.Enums;
local Methods = Management.Methods;
Methods.__index = Methods;

local isMinimized = false
local isClosed = false

local MainHub = {
	Contents = {

	}
}

local Units = {

}

local Tweenings = {
	Fading = nil;
}

local Player = Players.LocalPlayer
local Mouse = Player:GetMouse()

local Hovered = false
local Holding = false
local MoveCon = nil

local InitialX, InitialY, UIInitialPos

local ViewPortSize = workspace.Camera.ViewportSize

local MoveTween = nil

local Syntax = 0;

getgenv().NebulaHub.GlobalVars.LoadedIn = Signal.new()
local LoadedIn = getgenv().NebulaHub.GlobalVars.LoadedIn

--[[ Creator ]] do
	function Management.initialize()
		MainUI.GroupTransparency = 1
		MainUI.Size = UDim2.fromOffset(60, 60)
		MainUI.Position = UDim2.fromScale(0.5, 0.45)
		MainUI.Sizer.AspectRatio = 1
		TweenService:Create(MainUI.Stroke.UIGradient, TweenInfo.new(1.2, Enum.EasingStyle.Quint), {Offset = Vector2.new(0,0.5)}):Play()
		TweenService:Create(MainUI.Stroke, TweenInfo.new(1.2, Enum.EasingStyle.Quint), {Thickness = 2}):Play()
		TweenService:Create(MainUI, TweenInfo.new(1.7, Enum.EasingStyle.Quint), {Size = UDim2.fromOffset(32, 32)}):Play()
		task.delay(1, function()
			TweenService:Create(MainUI, TweenInfo.new(1.7, Enum.EasingStyle.Quint), {GroupTransparency = 0}):Play()
			TweenService:Create(MainUI.Stroke, TweenInfo.new(1.2, Enum.EasingStyle.Quint), {Transparency = 1}):Play()
		end)
		task.delay(1.9, function()
			TweenService:Create(MainUI.Sizer, TweenInfo.new(2.7, Enum.EasingStyle.Quint), {AspectRatio = 18}):Play()
			TweenService:Create(MainUI, TweenInfo.new(2.7, Enum.EasingStyle.Quint), {Size = UDim2.fromOffset(609, 430)}):Play()
		end)
		task.delay(2.8, function()
			TweenService:Create(MainUI, TweenInfo.new(3, Enum.EasingStyle.Quint), {Position = UDim2.fromScale(0.25, 0.05)}):Play()
			TweenService:Create(MainUI.Sizer, TweenInfo.new(2.7, Enum.EasingStyle.Quint), {AspectRatio = 1.5}):Play()
		end)

		MainUI.Parent.Dependencies.Audios.Opening:Play();

		local function makeDraggable()
			local function Drag()
				if Holding == false then MoveCon:Disconnect(); return end
				local distanceMovedX = InitialX - Mouse.X
				local distanceMovedY = InitialY - Mouse.Y

				MainUI.Position = UIInitialPos - UDim2.new(0, distanceMovedX, 0, distanceMovedY)
			end

			MainUI.Topbar.DragActivator.MouseEnter:Connect(function()
				Hovered = true
			end)

			MainUI.Topbar.DragActivator.MouseLeave:Connect(function()
				Hovered = false
			end)

			UserInputService.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
					Holding = Hovered
					if Holding then
						InitialX, InitialY = Mouse.X, Mouse.Y
						UIInitialPos = MainUI.Position

						MoveCon = RunService.PreRender:Connect(Drag)
					end
				end
			end)

			UserInputService.InputEnded:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
					Holding = false
				end
			end)
		end

		task.wait(2.5)

		local sizeTween = nil
		local aspectSizeTween = nil;

		task.delay(0.6, function()
			TweenService:Create(MainUI.Loading.LoadingContent.Bar, TweenInfo.new(1, Enum.EasingStyle.Quint), {Size = UDim2.fromScale(1,0.05)}):Play();

			task.delay(0.5, function()
				TweenService:Create(MainUI.Loading.LoadingContent.Bar.MainBar.Slider, TweenInfo.new(0.2, Enum.EasingStyle.Linear), {Offset = Vector2.new(-0.32,0)}):Play();
				task.wait(math.random(1, 3)/5)
				TweenService:Create(MainUI.Loading.LoadingContent.Bar.MainBar.Slider, TweenInfo.new(0.2, Enum.EasingStyle.Linear), {Offset = Vector2.new(0.1,0)}):Play();
				task.wait(math.random(1, 3)/2)
				TweenService:Create(MainUI.Loading.LoadingContent.Bar.MainBar.Slider, TweenInfo.new(1.3, Enum.EasingStyle.Quint), {Offset = Vector2.new(0.6,0)}):Play();

				task.delay(1.3, function()
					makeDraggable()
					MainUI.Parent.Dependencies.Audios.Loaded:Play();
					LoadedIn:Fire()

					MainUI.Topbar.Actions.Minimize.Activator.Activated:Connect(function()
						if sizeTween then
							sizeTween:Pause()
						end
						if aspectSizeTween then
							aspectSizeTween:Pause()
						end
						if isMinimized == false then
							isMinimized = true
							aspectSizeTween = TweenService:Create(MainUI.Sizer, TweenInfo.new(1.7, Enum.EasingStyle.Quint, Enum.EasingDirection.InOut), {AspectRatio = 18}):Play();
							sizeTween = TweenService:Create(MainUI, TweenInfo.new(1.7, Enum.EasingStyle.Quint, Enum.EasingDirection.InOut), {Size = UDim2.fromOffset(609, 430)}):Play();
						else
							isMinimized = false
							aspectSizeTween = TweenService:Create(MainUI.Sizer, TweenInfo.new(1.7, Enum.EasingStyle.Quint, Enum.EasingDirection.InOut), {AspectRatio = 1.5}):Play();
							sizeTween = TweenService:Create(MainUI, TweenInfo.new(1.7, Enum.EasingStyle.Quint, Enum.EasingDirection.InOut), {Size = UDim2.fromOffset(609, 430)}):Play();
						end
					end)
					
					MainUI.Topbar.Actions.Close.Activator.Activated:Connect(function()
						if isClosed == false then
							if sizeTween then
								sizeTween:Pause()
							end
							if aspectSizeTween then
								aspectSizeTween:Pause()
							end
							isClosed = true
							isMinimized = false
							aspectSizeTween = TweenService:Create(MainUI.Sizer, TweenInfo.new(1.7, Enum.EasingStyle.Quint, Enum.EasingDirection.InOut), {AspectRatio = 1}):Play();
							sizeTween = TweenService:Create(MainUI, TweenInfo.new(1.7, Enum.EasingStyle.Quint, Enum.EasingDirection.InOut), {Size = UDim2.fromOffset(32, 32)}):Play();
						end
					end)
					
					MainUI.Topbar.DragActivator.Activated:Connect(function()
						if isClosed == true then
							if sizeTween then
								sizeTween:Pause()
							end
							if aspectSizeTween then
								aspectSizeTween:Pause()
							end
							isClosed = false
							if isMinimized == true then
								isMinimized = false
							end
							aspectSizeTween = TweenService:Create(MainUI.Sizer, TweenInfo.new(1.7, Enum.EasingStyle.Quint, Enum.EasingDirection.InOut), {AspectRatio = 1.5}):Play();
							sizeTween = TweenService:Create(MainUI, TweenInfo.new(1.7, Enum.EasingStyle.Quint, Enum.EasingDirection.InOut), {Size = UDim2.fromOffset(609, 430)}):Play();
						end
					end)

					task.wait(0.3)
					TweenService:Create(MainUI.Loading, TweenInfo.new(1, Enum.EasingStyle.Quint), {GroupTransparency = 1}):Play();
				end)	
			end)
		end)		
	end

	function Management.newContent(ContentName : string, preset)
		local self = setmetatable({
			ContentName = ContentName;
		}, Methods);

		local newSideButton = Assets:WaitForChild("SideButtonTemplate"):Clone();
		newSideButton.Parent = SideBar;
		newSideButton.Name = ContentName.."SideButton"
		newSideButton.Visible = true

		local newSelectedStroke = Assets:WaitForChild("SelectedSideButtonStroke"):Clone();
		newSelectedStroke.Parent = newSideButton;

		newSideButton.Name = ContentName;

		local newWindow
		if preset then
			newWindow = preset:Clone();
			newWindow.Parent = MainContents;
			newWindow.Name = ContentName.."Window"
			newWindow.Visible = false
		else
			newWindow = Assets:WaitForChild("WindowTemplate"):Clone();
			newWindow.Parent = MainContents;
			newWindow.Name = ContentName.."Window"
			newWindow.Visible = false
		end

		self.SideButton = newSideButton;
		self.SelectionStroke = newSelectedStroke;
		self.Window = newWindow.Window;
		
		newSideButton.Activator.Activated:Connect(function()
			if newWindow.Visible == false then
				newSelectedStroke.UIGradient.Rotation = -232;
				TweenService:Create(newSelectedStroke.UIGradient, TweenInfo.new(1.5, Enum.EasingStyle.Quint, Enum.EasingDirection.InOut), {Rotation = -53}):Play()
				if Tweenings.Fading ~= nil then
					Tweenings.Fading:Pause();
				end;
				Tweenings.Fading = TweenService:Create(MainUI.Fader, TweenInfo.new(0.5, Enum.EasingStyle.Linear), {GroupTransparency = 0}):Play();
				for i, v in pairs(MainHub.Contents) do
					if v.Window ~= newWindow.Window then
						TweenService:Create(v.Selection, TweenInfo.new(.5), {Transparency = 1}):Play()
					end
				end
				TweenService:Create(newSelectedStroke, TweenInfo.new(.5, Enum.EasingStyle.Quint, Enum.EasingDirection.InOut), {Transparency = 0}):Play()
				task.delay(0.5, function()
					for i, v in pairs(MainHub.Contents) do
						if v.Window ~= newWindow.Window then
							v.Window.Visible = false
						end
					end
					newWindow.Visible = true
					Tweenings.Fading = TweenService:Create(MainUI.Fader, TweenInfo.new(0.5, Enum.EasingStyle.Linear), {GroupTransparency = 1}):Play();
				end)
			end
		end)

		MainHub.Contents[ContentName] = {
			SideButton = newSideButton;
			Window = newWindow;
			Selection = newSelectedStroke;
		};

		return self;
	end;

	function Management.setOpenedWindow(ContentName : string)
		if MainHub.Contents[ContentName] ~= nil then
			MainHub.Contents[ContentName].Selection.UIGradient.Rotation = -232;
			if MainHub.Contents[ContentName].Window.Visible == false then
				TweenService:Create(MainHub.Contents[ContentName].Selection.UIGradient, TweenInfo.new(1.5, Enum.EasingStyle.Quint, Enum.EasingDirection.InOut), {Rotation = -53}):Play()
				if Tweenings.Fading ~= nil then
					Tweenings.Fading:Pause();
				end;
				Tweenings.Fading = TweenService:Create(MainUI.Fader, TweenInfo.new(0.5, Enum.EasingStyle.Linear), {GroupTransparency = 0}):Play();
				for i, v in pairs(MainHub.Contents) do
					if v.Window ~= MainHub.Contents[ContentName].Window then
						TweenService:Create(v.Selection, TweenInfo.new(.5), {Transparency = 1}):Play()
					end
				end
				TweenService:Create(MainHub.Contents[ContentName].Selection, TweenInfo.new(.5, Enum.EasingStyle.Quint, Enum.EasingDirection.InOut), {Transparency = 0}):Play()
				task.delay(0.5, function()
					for i, v in pairs(MainHub.Contents) do
						if v.Window ~= MainHub.Contents[ContentName].Window then
							v.Window.Visible = false
						end
					end
					Tweenings.Fading = TweenService:Create(MainUI.Fader, TweenInfo.new(0.5, Enum.EasingStyle.Linear), {GroupTransparency = 1}):Play();
					MainHub.Contents[ContentName].Window.Visible = true;
				end)
			end
		end;
	end

	function Management.notice(self, NoticeType, LifeTime, Content_, Header : Optional)
		if NoticeType == Enums.NoticeType.Notice then
			local noticeClosed = false

			if LifeTime == nil then
				LifeTime = 3
			end

			local newNotice = Assets:WaitForChild("NoticeTemplate"):Clone();
			newNotice.Parent = MainUI.Parent:WaitForChild("SystemNotices").Container
			newNotice.Visible = true
			newNotice.Main.SmallNotice.Content.AlertContent.Text = Content_;
			newNotice.Main.Position = UDim2.fromScale(1.6,1)
			if Header ~= nil then
				newNotice.Main.SmallNotice.Topbar.Title.Text = Header;
			end
			TweenService:Create(newNotice.Main, TweenInfo.new(.5, Enum.EasingStyle.Quint, Enum.EasingDirection.InOut), {Position = UDim2.fromScale(0.5,1)}):Play()
			TweenService:Create(newNotice.Sizer, TweenInfo.new(0.8, Enum.EasingStyle.Quint, Enum.EasingDirection.InOut), {AspectRatio = 2.5}):Play()

			local newConnect = nil
			newConnect = newNotice.Main.SmallNotice.Topbar.Actions.Close.CloseButton.Activator.Activated:Connect(function()
				if noticeClosed == false then
					noticeClosed = true
					TweenService:Create(newNotice.Sizer, TweenInfo.new(3.5, Enum.EasingStyle.Quint, Enum.EasingDirection.InOut), {AspectRatio = 600}):Play()
					TweenService:Create(newNotice.Main.Sizer, TweenInfo.new(3.5, Enum.EasingStyle.Quint, Enum.EasingDirection.InOut), {AspectRatio = 600}):Play()
					task.delay(.8, function()
						TweenService:Create(newNotice.Main.Stroke, TweenInfo.new(.5, Enum.EasingStyle.Quint, Enum.EasingDirection.InOut), {Transparency = 1}):Play()
						TweenService:Create(newNotice.Main, TweenInfo.new(.5, Enum.EasingStyle.Quint), {GroupTransparency = 1}):Play()
					end)
					getgenv().Services.Debris:AddItem(newNotice, 3.6)
				end
			end)

			task.delay(.6, function()
				TweenService:Create(newNotice.Main.SmallNotice.ClosingIn, TweenInfo.new(LifeTime, Enum.EasingStyle.Linear), {Size = UDim2.new(0, 0, 0, 2)}):Play()
				task.wait(LifeTime)
				if noticeClosed == false then
					noticeClosed = true
					TweenService:Create(newNotice.Sizer, TweenInfo.new(3.5, Enum.EasingStyle.Quint, Enum.EasingDirection.InOut), {AspectRatio = 600}):Play()
					TweenService:Create(newNotice.Main.Sizer, TweenInfo.new(3.5, Enum.EasingStyle.Quint, Enum.EasingDirection.InOut), {AspectRatio = 600}):Play()
					task.delay(.8, function()
						TweenService:Create(newNotice.Main.Stroke, TweenInfo.new(.5, Enum.EasingStyle.Quint, Enum.EasingDirection.InOut), {Transparency = 1}):Play()
						TweenService:Create(newNotice.Main, TweenInfo.new(.5, Enum.EasingStyle.Quint), {GroupTransparency = 1}):Play()
					end)
					getgenv().Services.Debris:AddItem(newNotice, 3.6)
				end
			end)
		elseif NoticeType == Enums.NoticeType.Alert then
			local noticeClosed = false

			if LifeTime == nil then
				LifeTime = 3
			end

			local newNotice = Assets:WaitForChild("AlertTemplate"):Clone();
			newNotice.Parent = MainUI.Parent:WaitForChild("SystemNotices").Container
			newNotice.Visible = true
			newNotice.Main.Alert.Content.AlertContent.Text = Content_;
			newNotice.Main.Position = UDim2.fromScale(1.6,1)
			if Header ~= nil then
				newNotice.Main.Alert.Topbar.Title.Text = Header;
			end
			TweenService:Create(newNotice.Main, TweenInfo.new(.5, Enum.EasingStyle.Quint, Enum.EasingDirection.InOut), {Position = UDim2.fromScale(0.5,1)}):Play()
			TweenService:Create(newNotice.Sizer, TweenInfo.new(0.8, Enum.EasingStyle.Quint, Enum.EasingDirection.InOut), {AspectRatio = 2}):Play()

			local newConnect = nil
			newConnect = newNotice.Main.Alert.Topbar.Actions.Close.CloseButton.Activator.Activated:Connect(function()
				if noticeClosed == false then
					noticeClosed = true
					TweenService:Create(newNotice.Sizer, TweenInfo.new(3.5, Enum.EasingStyle.Quint, Enum.EasingDirection.InOut), {AspectRatio = 600}):Play()
					TweenService:Create(newNotice.Main.Sizer, TweenInfo.new(3.5, Enum.EasingStyle.Quint, Enum.EasingDirection.InOut), {AspectRatio = 600}):Play()
					task.delay(.8, function()
						TweenService:Create(newNotice.Main.Stroke, TweenInfo.new(.5, Enum.EasingStyle.Quint, Enum.EasingDirection.InOut), {Transparency = 1}):Play()
						TweenService:Create(newNotice.Main, TweenInfo.new(.5, Enum.EasingStyle.Quint), {GroupTransparency = 1}):Play()
					end)
					getgenv().Services.Debris:AddItem(newNotice, 3.6)
				end
			end)

			task.delay(.6, function()
				TweenService:Create(newNotice.Main.Alert.ClosingIn, TweenInfo.new(LifeTime, Enum.EasingStyle.Linear), {Size = UDim2.new(0, 0, 0, 2)}):Play()
				task.wait(LifeTime)
				if noticeClosed == false then
					noticeClosed = true
					TweenService:Create(newNotice.Sizer, TweenInfo.new(3.5, Enum.EasingStyle.Quint, Enum.EasingDirection.InOut), {AspectRatio = 600}):Play()
					TweenService:Create(newNotice.Main.Sizer, TweenInfo.new(3.5, Enum.EasingStyle.Quint, Enum.EasingDirection.InOut), {AspectRatio = 600}):Play()
					task.delay(.8, function()
						TweenService:Create(newNotice.Main.Stroke, TweenInfo.new(.5, Enum.EasingStyle.Quint, Enum.EasingDirection.InOut), {Transparency = 1}):Play()
						TweenService:Create(newNotice.Main, TweenInfo.new(.5, Enum.EasingStyle.Quint), {GroupTransparency = 1}):Play()
					end)
					getgenv().Services.Debris:AddItem(newNotice, 3.6)
				end
			end)
		elseif NoticeType == Enums.NoticeType.Notification then
			local noticeClosed = false

			if LifeTime == nil then
				LifeTime = 3
			end

			local newNotice = Assets:WaitForChild("NotificationTemplate"):Clone();
			newNotice.Parent = MainUI.Parent:WaitForChild("SystemNotices").Container
			newNotice.Visible = true
			newNotice.Main.Notification.Content.AlertContent.Text = Content_;
			newNotice.Main.Position = UDim2.fromScale(1.6,1)
			if Header ~= nil then
				newNotice.Main.Notification.Topbar.Title.Text = Header;
			end
			TweenService:Create(newNotice.Main, TweenInfo.new(.5, Enum.EasingStyle.Quint, Enum.EasingDirection.InOut), {Position = UDim2.fromScale(0.5,1)}):Play()
			TweenService:Create(newNotice.Sizer, TweenInfo.new(0.8, Enum.EasingStyle.Quint, Enum.EasingDirection.InOut), {AspectRatio = 2}):Play()

			local newConnect = nil
			newConnect = newNotice.Main.Notification.Topbar.Actions.Close.CloseButton.Activator.Activated:Connect(function()
				if noticeClosed == false then
					noticeClosed = true
					TweenService:Create(newNotice.Sizer, TweenInfo.new(3.5, Enum.EasingStyle.Quint, Enum.EasingDirection.InOut), {AspectRatio = 600}):Play()
					TweenService:Create(newNotice.Main.Sizer, TweenInfo.new(3.5, Enum.EasingStyle.Quint, Enum.EasingDirection.InOut), {AspectRatio = 600}):Play()
					task.delay(.8, function()
						TweenService:Create(newNotice.Main.Stroke, TweenInfo.new(.5, Enum.EasingStyle.Quint, Enum.EasingDirection.InOut), {Transparency = 1}):Play()
						TweenService:Create(newNotice.Main, TweenInfo.new(.5, Enum.EasingStyle.Quint), {GroupTransparency = 1}):Play()
					end)
					getgenv().Services.Debris:AddItem(newNotice, 3.6)
				end
			end)

			task.delay(.6, function()
				TweenService:Create(newNotice.Main.Notification.ClosingIn, TweenInfo.new(LifeTime, Enum.EasingStyle.Linear), {Size = UDim2.new(0, 0, 0, 2)}):Play()
				task.wait(LifeTime)
				if noticeClosed == false then
					noticeClosed = true
					TweenService:Create(newNotice.Sizer, TweenInfo.new(3.5, Enum.EasingStyle.Quint, Enum.EasingDirection.InOut), {AspectRatio = 600}):Play()
					TweenService:Create(newNotice.Main.Sizer, TweenInfo.new(3.5, Enum.EasingStyle.Quint, Enum.EasingDirection.InOut), {AspectRatio = 600}):Play()
					task.delay(.8, function()
						TweenService:Create(newNotice.Main.Stroke, TweenInfo.new(.5, Enum.EasingStyle.Quint, Enum.EasingDirection.InOut), {Transparency = 1}):Play()
						TweenService:Create(newNotice.Main, TweenInfo.new(.5, Enum.EasingStyle.Quint), {GroupTransparency = 1}):Play()
					end)
					getgenv().Services.Debris:AddItem(newNotice, 3.6)
				end
			end)
		end
	end
end;

--[[ Methods ]] do

	-- Side Button
	function Methods.setSideButtonTitle(self, SideTitle : string)
		self.SideButton.ButtonTitle.Text = SideTitle;
		return self;
	end;

	function Methods.setSideButtonLogo(self, Logo : string)
		self.SideButton.Icon.ImageLabel.Image = Logo;
		return self;
	end;

	-- Window
	function Methods.openWindow(self)
		if self.Window.Parent.Visible == false then
			self.Selection.UIGradient.Rotation = -232
			TweenService:Create(self.Selection.UIGradient, TweenInfo.new(1.5, Enum.EasingStyle.Quint, Enum.EasingDirection.InOut), {Rotation = -53}):Play()
			if Tweenings.Fading ~= nil then
				Tweenings.Fading:Pause();
			end;
			Tweenings.Fading = TweenService:Create(MainUI.Fader, TweenInfo.new(0.5, Enum.EasingStyle.Linear), {GroupTransparency = 0}):Play();
			for i, v in pairs(MainHub.Contents) do
				if v.Window ~= self.Window then
					TweenService:Create(v.Selection, TweenInfo.new(.5), {Transparency = 1}):Play()
				end
			end
			TweenService:Create(self.Selection, TweenInfo.new(.5, Enum.EasingStyle.Quint, Enum.EasingDirection.InOut), {Transparency = 0}):Play()
			task.delay(0.5, function()
				for i, v in pairs(MainHub.Contents) do
					if v.Window ~= self.Window then
						v.Window.Visible = false
					end
				end
				Tweenings.Fading = TweenService:Create(MainUI.Fader, TweenInfo.new(0.5, Enum.EasingStyle.Linear), {GroupTransparency = 1}):Play();
				self.Window.Parent.Visible = true;
			end)
		end
		return self;
	end;

	function Methods.addWindowTitle(self, Title : string)
		Syntax += 1;
		local newTitle = Assets:WaitForChild("WindowTitle"):Clone()
		newTitle.Parent = self.Window;
		newTitle.Text = Title;
		newTitle.LayoutOrder = Syntax;
		newTitle.Visible = true;
		return self;
	end

	function Methods.addSpacial(self)
		Syntax += 1;
		local newSpacial = Assets:WaitForChild("Spacial"):Clone()
		newSpacial.Parent = self.Window;
		newSpacial.Visible = true;
		newSpacial.LayoutOrder = Syntax
		return self;
	end

	function Methods.addSpacialLine(self)
		Syntax += 1;
		local newSpacial = Assets:WaitForChild("SpacialLine"):Clone()
		newSpacial.Parent = self.Window;
		newSpacial.Visible = true;
		newSpacial.LayoutOrder = Syntax
		return self;
	end

	function Methods.addWindowSubtitle(self, Subtitle : string)
		Syntax += 1;
		local newTitle = Assets:WaitForChild("Subtitle"):Clone()
		newTitle.Parent = self.Window;
		newTitle.Text = Subtitle..":";
		newTitle.LayoutOrder = Syntax;
		newTitle.Visible = true;
		return self;
	end

	function Methods.addUnit(self, UnitName, UnitType, Data : {any}, Connection)
		Syntax += 1
		if UnitType == Enums.UnitType.Switch then
			local newSwitchAction = Assets:WaitForChild("UnitSwitch"):Clone();
			newSwitchAction.Parent = self.Window;
			newSwitchAction.Visible = true;
			newSwitchAction.LayoutOrder = Syntax;
			newSwitchAction.UnitTitle.Text = UnitName
			
			if Connection == "Middle" then
				local newType = Assets:WaitForChild("TypeMiddle"):Clone()
				newType.Parent = newSwitchAction.Connection;
				newType.Visible = true
			elseif Connection == "Top" then
				local newType = Assets:WaitForChild("TypeBottom"):Clone()
				newType.Parent = newSwitchAction.Connection;
				newType.Visible = true
			elseif Connection == "Bottom" then
				local newType = Assets:WaitForChild("TypeTop"):Clone()
				newType.Parent = newSwitchAction.Connection;
				newType.Visible = true
			end

			newSwitchAction:WaitForChild("Action"):WaitForChild("MainSwitch"):WaitForChild("SwitchButtonView")

			Units[UnitName] = {
				Data = Data;
				Connections = {};
				TurnedOn = Data.defaultValue or false;
				Debounce = false;
				OnValueChanged = Signal.new();
			};

			local MainUnit = Units[UnitName]

			local function Run()
				if MainUnit.TurnedOn == false then
					MainUnit.TurnedOn = true;

					Data.onDeactivated(MainUnit, false);
					TweenService:Create(newSwitchAction.Action.MainSwitch.SwitchButtonView, TweenInfo.new(0.2, Enum.EasingStyle.Back), {BackgroundColor3 = Color3.fromRGB(50, 64, 126), Position = UDim2.fromScale(0.2,0.5)}):Play()
					TweenService:Create(newSwitchAction.Action.MainSwitch.SwitchButtonView.Up, TweenInfo.new(0.2, Enum.EasingStyle.Back), {BackgroundColor3 = Color3.fromRGB(101, 129, 255)}):Play()
				else
					MainUnit.TurnedOn = false;

					Data.onActivated(MainUnit, true);
					TweenService:Create(newSwitchAction.Action.MainSwitch.SwitchButtonView, TweenInfo.new(0.2, Enum.EasingStyle.Back), {BackgroundColor3 = Color3.fromRGB(62, 111, 58), Position = UDim2.fromScale(0.8,0.5)}):Play()
					TweenService:Create(newSwitchAction.Action.MainSwitch.SwitchButtonView.Up, TweenInfo.new(0.2, Enum.EasingStyle.Back), {BackgroundColor3 = Color3.fromRGB(142, 255, 134)}):Play()
				end;
			end

			Run()

			MainUnit.Connections["SwitchActivated"] = newSwitchAction.Activator.Activated:Connect(function()
				if MainUnit.Debounce == false then
					Run()
					MainUnit.OnValueChanged:Fire(MainUnit.TurnedOn)
					MainUnit.Debounce = true;
					task.wait(Data.cooldown)
					MainUnit.Debounce = false;
				end
			end);

			if Data.Initialize then
				Data.Initialize(MainUnit)
			end
		elseif UnitType == Enums.UnitType.String then
			local newStringAction = Assets:WaitForChild("UnitString"):Clone();
			newStringAction.Parent = self.Window;
			newStringAction.Visible = true;
			newStringAction.LayoutOrder = Syntax;
			newStringAction.UnitTitle.Text = UnitName
			
			if Connection == "Middle" then
				local newType = Assets:WaitForChild("TypeMiddle"):Clone()
				newType.Parent = newStringAction.Connection;
				newType.Visible = true
			elseif Connection == "Top" then
				local newType = Assets:WaitForChild("TypeBottom"):Clone()
				newType.Parent = newStringAction.Connection;
				newType.Visible = true
			elseif Connection == "Bottom" then
				local newType = Assets:WaitForChild("TypeTop"):Clone()
				newType.Parent = newStringAction.Connection;
				newType.Visible = true
			end
			
			newStringAction:WaitForChild("Action"):WaitForChild("MainString"):WaitForChild("TextBox")

			Units[UnitName] = {
				Data = Data;
				Connections = {};
				InitialValue = Data.defaultValue;
				Debounce = false;
				OnValueChanged = Signal.new();
			};

			local MainUnit = Units[UnitName]

			local function Run()
				newStringAction.Action.MainString.TextBox.Text = MainUnit.InitialValue;
				Data.onEntered(MainUnit, MainUnit.InitialValue);
			end

			Run()

			MainUnit.Connections["EnteredNumber"] = newStringAction.Action.MainString.TextBox.FocusLost:Connect(function()
				if MainUnit.Debounce == false then
					MainUnit.InitialValue = newStringAction.Action.MainString.TextBox.Text
					Run()
					MainUnit.OnValueChanged:Fire(MainUnit.InitialValue)
					MainUnit.Debounce = true
					task.wait(Data.cooldown);
					MainUnit.Debounce = false;
				end;
			end);

			if Data.Initialize then
				Data.Initialize(MainUnit)
			end
		elseif UnitType == Enums.UnitType.Dropdown then
			local newDropdownAction = Assets:WaitForChild("UnitDropdown"):Clone();
			newDropdownAction.Parent = self.Window;
			newDropdownAction.Visible = true;
			newDropdownAction.LayoutOrder = Syntax;
			newDropdownAction.UnitTitle.Text = UnitName
			
			if Connection == "Middle" then
				local newType = Assets:WaitForChild("TypeMiddle"):Clone()
				newType.Parent = newDropdownAction.Connection;
				newType.Visible = true
			elseif Connection == "Top" then
				local newType = Assets:WaitForChild("TypeBottom"):Clone()
				newType.Parent = newDropdownAction.Connection;
				newType.Visible = true
			elseif Connection == "Bottom" then
				local newType = Assets:WaitForChild("TypeTop"):Clone()
				newType.Parent = newDropdownAction.Connection;
				newType.Visible = true
			end
			
			Syntax += 1
			local newSpatialDropper = Assets:WaitForChild("Spacial"):Clone()
			newSpatialDropper.Parent = self.Window
			newSpatialDropper.Visible = true;
			newSpatialDropper.Size = UDim2.fromScale(0.95,0)
			newSpatialDropper.LayoutOrder = Syntax;

			newDropdownAction:WaitForChild("Action"):WaitForChild("DropdownInt"):WaitForChild("Container"):WaitForChild("DropdownMenu")

			local CreatedEnums = {};
			Data.createEnums(function(EnumItems : {})
				CreatedEnums = EnumItems;
			end);

			Units[UnitName] = {
				Data = Data;
				Connections = {};
				Selected = nil;
				DropdownOpen = false;
				Debounce = false;
				OnValueChanged = Signal.new();
				SelectionUIs = {}
			};

			local MainUnit = Units[UnitName];

			if Data.setDefault then
				Data.setDefault(function(Value)
					MainUnit.Selected = CreatedEnums[Value]
					MainUnit.OnValueChanged:Fire(CreatedEnums[Value])
					newDropdownAction.Action.MainDropdown.SelectedPreview.Text = CreatedEnums[Value].Name;
					if CreatedEnums[Value].Color ~= nil then
						newDropdownAction.Action.MainDropdown.SelectedPreview.TextColor3 = CreatedEnums[Value].Color;
					end			
				end)
			end
			MainUnit.Connections["DropConnects"] = {}

			MainUnit.Connections["OpenedDropdown"] = newDropdownAction.Activator.Activated:Connect(function()
				if MainUnit.Debounce == false then
					MainUnit.Debounce = true;
					if MainUnit.DropdownOpen == false then
						MainUnit.DropdownOpen = true
						for i, v in pairs(MainUnit.SelectionUIs) do
							if v ~= nil then
								v:Destroy()
							end
						end
						for i, v in pairs(CreatedEnums) do
							local newDropEnum = Assets:WaitForChild("DropdownOption"):Clone();
							newDropEnum.DropdownTitle.Text = v.Name;
							newDropEnum.DropdownTitle.TextColor3 = v.Color;
							newDropEnum.Parent = newDropdownAction.Action.DropdownInt.Container.DropdownMenu;
							newDropEnum.Visible = true;

							table.insert(MainUnit.SelectionUIs, newDropEnum)

							MainUnit.Connections["DropConnects"]["DropdownSelect"..v.Name] = newDropEnum.Activator.Activated:Connect(function()
								if MainUnit.Selected ~= nil then
									if MainUnit.Selected.Value ~= v.Value then
										MainUnit.OnValueChanged:Fire(CreatedEnums[v.Name])
									end
								else
									MainUnit.OnValueChanged:Fire(CreatedEnums[v.Name])
								end
								MainUnit.Selected = CreatedEnums[v.Name];

								newDropdownAction.Action.MainDropdown.SelectedPreview.Text = v.Name;
								if v.Color ~= nil then
									newDropdownAction.Action.MainDropdown.SelectedPreview.TextColor3 = v.Color;
								end
							end);
						end;
						local newSpacial = Assets:WaitForChild("Spacial"):Clone()
						newSpacial.Size = Assets:WaitForChild("DropdownOption").Size
						newSpacial.Parent = newDropdownAction.Action.DropdownInt.Container.DropdownMenu
						newSpacial.Visible = true
						newSpacial.LayoutOrder = 1000000;
						table.insert(MainUnit.SelectionUIs, newSpacial)
						newDropdownAction.Action.DropdownInt.Container.Visible = true;
						TweenService:Create(newDropdownAction.Action.DropdownInt.Container.Slider, TweenInfo.new(.3, Enum.EasingStyle.Quint), {Offset = Vector2.new(0,1)}):Play();
						TweenService:Create(newSpatialDropper, TweenInfo.new(.3, Enum.EasingStyle.Quint), {Size = UDim2.fromScale(0.95, 0.15)}):Play();
					else
						for i, v in pairs(MainUnit.Connections["DropConnects"]) do
							if v ~= nil then
								v:Disconnect()
								v = nil
							end
						end
						MainUnit.DropdownOpen = false;
						TweenService:Create(newDropdownAction.Action.DropdownInt.Container.Slider, TweenInfo.new(.3, Enum.EasingStyle.Quint), {Offset = Vector2.new(0,-1)}):Play();
						TweenService:Create(newSpatialDropper, TweenInfo.new(.3, Enum.EasingStyle.Quint), {Size = UDim2.fromScale(0.95, 0)}):Play();
						task.delay(.3, function()
							newDropdownAction.Action.DropdownInt.Container.Visible = false;
						end);
					end;
					task.delay(0.3 + Data.cooldown, function()
						MainUnit.Debounce = false;
					end)
				end;
			end);

			if Data.Initialize then
				Data.Initialize(MainUnit)
			end
		elseif UnitType == Enums.UnitType.Slider then
			local newSliderAction = Assets:WaitForChild("UnitSliderValue"):Clone();
			newSliderAction.Parent = self.Window;
			newSliderAction.Visible = true;
			newSliderAction.LayoutOrder = Syntax;
			newSliderAction.UnitTitle.Text = UnitName;
			
			if Connection == "Middle" then
				local newType = Assets:WaitForChild("TypeMiddle"):Clone()
				newType.Parent = newSliderAction.Connection;
				newType.Visible = true
			elseif Connection == "Top" then
				local newType = Assets:WaitForChild("TypeBottom"):Clone()
				newType.Parent = newSliderAction.Connection;
				newType.Visible = true
			elseif Connection == "Bottom" then
				local newType = Assets:WaitForChild("TypeTop"):Clone()
				newType.Parent = newSliderAction.Connection;
				newType.Visible = true
			end
			
			local NewSliderSystem = Slider.new(newSliderAction.Action.SliderBase, {
				SliderData = {
					Start = Data.Min, End = Data.Max, Increment = Data.Increment
				};
				MoveInfo = TweenInfo.new(0.1, Enum.EasingStyle.Quint);
			});

			Units[UnitName] = {
				Data = Data;
				Connections = {};
				CurrentValue = Data.defaultValue or Data.Min;
				Debounce = false;
				OnValueChanged = Signal.new();
			};

			local MainUnit = Units[UnitName]

			newSliderAction.Action.MainString.TextBox.Text = MainUnit.CurrentValue;

			NewSliderSystem:Track()
			MainUnit.Connections["SliderValueChange"] = NewSliderSystem.Changed:Connect(function(Value)
				newSliderAction.Action.MainString.TextBox.Text = Value;
			end)

			MainUnit.Connections["SliderReleased"] = NewSliderSystem.Released:Connect(function()
				MainUnit.OnValueChanged:Fire(NewSliderSystem:GetValue());
			end);

			MainUnit.Connections["TextboxChange"] = newSliderAction.Action.MainString.TextBox.FocusLost:Connect(function(Entered)
				if MainUnit.Debounce == false then
					if Entered then
						local success, number = pcall(tonumber, newSliderAction.Action.MainString.TextBox.Text)

						if success then
							pcall(function()
								NewSliderSystem:OverrideValue(number)
								MainUnit.OnValueChanged:Fire(NewSliderSystem:GetValue());
							end)
						end
					end
				end
			end)

			if Data.Initialize then
				Data.Initialize(MainUnit)
			end
		elseif UnitType == Enums.UnitType.Toggle then
			local newToggleAction = Assets:WaitForChild("UnitToggle"):Clone();
			newToggleAction.Parent = self.Window;
			newToggleAction.Visible = true;
			newToggleAction.LayoutOrder = Syntax;
			newToggleAction.UnitTitle.Text = UnitName
			
			if Connection == "Middle" then
				local newType = Assets:WaitForChild("TypeMiddle"):Clone()
				newType.Parent = newToggleAction.Connection;
				newType.Visible = true
			elseif Connection == "Top" then
				local newType = Assets:WaitForChild("TypeBottom"):Clone()
				newType.Parent = newToggleAction.Connection;
				newType.Visible = true
			elseif Connection == "Bottom" then
				local newType = Assets:WaitForChild("TypeTop"):Clone()
				newType.Parent = newToggleAction.Connection;
				newType.Visible = true
			end
			
			newToggleAction:WaitForChild("Action"):WaitForChild("Activator")

			Units[UnitName] = {
				Data = Data;
				Connections = {};
				Debounce = false;
				Toggled = Signal.new();
			};

			local MainUnit = Units[UnitName]

			local function Run()
				Data.onActivated(MainUnit, true);
			end

			MainUnit.Connections["Toggled"] = newToggleAction.Action.Activator.Activated:Connect(function()
				if MainUnit.Debounce == false then
					Run()
					MainUnit.Toggled:Fire(MainUnit.TurnedOn)
					MainUnit.Debounce = true;
					task.wait(Data.cooldown)
					MainUnit.Debounce = false;
				end
			end);

			if Data.Initialize then
				Data.Initialize(MainUnit)
			end
		elseif UnitType == Enums.UnitType.Info then
			local newInfo = Assets:WaitForChild("UnitInfo"):Clone();
			newInfo.Parent = self.Window;
			newInfo.Visible = true;
			newInfo.LayoutOrder = Syntax;
			
			if Connection == "Middle" then
				local newType = Assets:WaitForChild("TypeMiddle"):Clone()
				newType.Parent = newInfo.Connection;
				newType.Visible = true
			elseif Connection == "Top" then
				local newType = Assets:WaitForChild("TypeBottom"):Clone()
				newType.Parent = newInfo.Connection;
				newType.Visible = true
			elseif Connection == "Bottom" then
				local newType = Assets:WaitForChild("TypeTop"):Clone()
				newType.Parent = newInfo.Connection;
				newType.Visible = true
			end
			
			Units[UnitName] = {
				Data = Data;
				Text = Data.Text;
				UiInfo = newInfo;
				Connections = {};
			};

			local MainUnit = Units[UnitName]
			
			newInfo.UnitTitle.Text = Data.Text
			
			if Data.Initialize then
				Data.Initialize(MainUnit)
			end
		end;

		return self;
	end;
end;

getgenv().NebulaHub.Dependencies.Manager.Management = Management;
