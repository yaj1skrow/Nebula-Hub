while task.wait() do
	if game:GetService("Players").LocalPlayer.Character then
		break
	end
end

task.wait(2)

local NewNebulaHub = game:GetObjects("rbxassetid://77426361425256")[1].NebulaHub
NewNebulaHub.Parent = game:GetService("CoreGui")

local Dependencies = NewNebulaHub.Dependencies;

local RunService = game:GetService("RunService");
local TweenService = game:GetService("TweenService");
local Players = game:GetService("Players");

local Connection = {};
Connection.__index = Connection;

function Connection.new(callback : (...any) -> ...any)
	return setmetatable({
		Connected = true;
		Callback = callback;
	}, Connection);
end

function Connection:Disconnect()
	self.Connected = false;
end

local Signal = {};
Signal.__index = Signal;

function Signal.new()
	return setmetatable({
		destroyed = false;
		connections = {}::{Connection};
		parallel_connections = {};
	}, Signal);
end

function Signal:Connect(func)
	if (self.destroyed) then
		error("[Signal] Cannot connect signal while destroyed", 2);
	end
	local connection = Connection.new(func);

	table.insert(self.connections, connection);

	return connection;
end

function Signal:ConnectParallel(func)
	if (self.destroyed) then
		error("[Signal] Cannot connect signal while destroyed", 2);
	end
	local connection = Connection.new(func);

	table.insert(self.parallel_connections, connection);

	return connection;
end

function Signal:Fire(...)
	if (self.destroyed) then
		error("[Signal] Cannot call signal while destroyed", 2);
	end
	for _, connection in self.parallel_connections do
		if (connection.Connected) then
			task.spawn(function(...)
				task.desynchronize();
				connection.Callback(...);
			end, ...)
		end
	end
	for _, connection in self.connections do
		if (connection.Connected) then
			task.spawn(connection.Callback, ...);
		end
	end

	for i = #self.connections, 1, -1 do
		local connection = self.connections[i];
		if (not connection.Connected) then
			table.remove(self.connections, i);
		end
	end

	for i = #self.parallel_connections, 1, -1 do
		local connection = self.parallel_connections[i];
		if (not connection.Connected) then
			table.remove(self.parallel_connections, i);
		end
	end
end

function Signal:Wait().
	local thread = coroutine.running();
	self:Once(function(...)
		coroutine.resume(thread, ...);
	end)
	return coroutine.yield();
end

function Signal:Once(func)
	local connection;
	connection = self:Connect(function(... : T...)
		if (connection and connection.Connected) then
			connection:Disconnect();
		end
		func(...);
	end)
	return connection;
end

function Signal:Clone()
	if (self.destroyed) then
		error("[Signal] Cannot clone signal while destroyed", 2);
	end
	return Signal.new();
end

function Signal:Destroy()
	self.destroyed = true;
	table.clear(self.parallel_connections);
	table.clear(self.connections);
end

local Slider = {Sliders = {}}

local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local SliderFuncs = {}

function SliderFuncs.snapToScale(val, step)
	return math.clamp(math.round(val / step) * step, 0, 1)
end

function lerp(start, finish, percent)
	return (1 - percent) * start + percent * finish
end

function SliderFuncs.map(value, start, stop, newStart, newEnd, constrain)
	local newVal = lerp(newStart, newEnd, SliderFuncs.getAlphaBetween(start, stop, value))
	if not constrain then
		return newVal
	end

	if newStart < newEnd then
		newStart, newEnd = newEnd, newStart
	end

	return math.max(math.min(newVal, newStart), newEnd)
end

function SliderFuncs.getNewPosition(self)
	local absoluteSize = self._data.Button.AbsoluteSize[self._config.Axis]
	local holderSize = self._holder.AbsoluteSize[self._config.Axis]

	local anchorPoint = self._data.Button.AnchorPoint[self._config.Axis]

	local paddingScale = (self._config.Padding / holderSize)

	local minScale = ((anchorPoint * absoluteSize) / holderSize + paddingScale)
	local decrement = ((2 * absoluteSize) * anchorPoint) - absoluteSize
	local maxScale = (1 - minScale) + (decrement / holderSize)

	local newPercent = SliderFuncs.map(self._data._percent, 0, 1, minScale, maxScale, true)

	return 
		if self._config.Axis == "X" then UDim2.fromScale(newPercent, self._data.Button.Position.Y.Scale)
		else UDim2.fromScale(self._data.Button.Position.X.Scale, newPercent)
end

function SliderFuncs.getScaleIncrement(self)
	return 1 / ((self._config.SliderData.End - self._config.SliderData.Start) / self._config.SliderData.Increment)
end

function SliderFuncs.getAlphaBetween(a, b, c)
	return (c - a) / (b - a)
end

function SliderFuncs.getNewValue(self)
	local newValue = lerp(self._config.SliderData.Start, self._config.SliderData.End, self._data._percent)
	local incrementScale = (1 / self._config.SliderData.Increment)

	newValue = math.round(newValue * incrementScale) / incrementScale
	return newValue
end

Slider.__index = function(object, indexed)
	local deprecated = {
		{".OnChange", ".Changed", rawget(object, "Changed")}
	}

	for _, tbl in ipairs(deprecated) do
		local deprecatedStr = string.sub(tbl[1], 2)

		if deprecatedStr == indexed then
			warn(string.format("%s is deprecated, please use %s instead", tbl[1], tbl[2]))
			return tbl[3]	
		end
	end

	return Slider[indexed]
end
	
function Slider.new(holder, config)
	assert(pcall(function()
		return holder.AbsoluteSize, holder.AbsolutePosition
	end), "Holder argument does not have an AbsoluteSize/AbsolutePosition")

	local duplicate = false
	for _, slider in ipairs(Slider.Sliders) do
		if slider._holder == holder then
			duplicate = true
			break
		end
	end

	assert(not duplicate, "Cannot set two sliders with same frame!")
	assert(config.SliderData.Increment ~= nil, "Failed to find Increment in SliderData table")
	assert(config.SliderData.Start ~= nil, "Failed to find Start in SliderData table")
	assert(config.SliderData.End ~= nil, "Failed to find End in SliderData table")
	assert(config.SliderData.Increment > 0, "SliderData.Increment must be greater than 0")
	assert(config.SliderData.End > config.SliderData.Start, string.format("Slider end value must be greater than its start value! (%.1f <= %.1f)", config.SliderData.End, config.SliderData.Start))

	local self = setmetatable({}, Slider)
	self._holder = holder
	self._data = {
		-- Buttons
		Button = nil,
		HolderButton = nil,

		-- Clicking
		_clickOverride = false,

		_mainConnection = nil,
		_clickConnections = {},
		_otherConnections = {},

		_inputPos = nil,

		-- Internal
		_percent = 0,
		_value = 0,
		_scaleIncrement = 0,
		_currentTween = nil,
		_allowBackgroundClick = if config.AllowBackgroundClick == false then false else true
	}

	self._config = config
	self._config.Axis = string.upper(config.Axis or "X")
	self._config.Padding = config.Padding or 5
	self._config.MoveInfo = config.MoveInfo or TweenInfo.new(0.2)
	self._config.MoveType = config.MoveType or "Tween"
	self.IsHeld = false

	local sliderBtn = holder:FindFirstChild("Slider")
	assert(sliderBtn ~= nil, "Failed to find slider button.")
	assert(sliderBtn:IsA("GuiButton"), "Slider is not a GuiButton")

	self._data.Button = sliderBtn

	-- Holder button --
	if self._data._allowBackgroundClick then
		local holderClickButton = Instance.new("TextButton")
		holderClickButton.BackgroundTransparency = 1
		holderClickButton.Text = ""
		holderClickButton.AnchorPoint = Vector2.new(0.5, 0.5)
		holderClickButton.Name = "HolderClickButton"
		holderClickButton.Size = UDim2.fromScale(1, 3.6)
		holderClickButton.Position = UDim2.fromScale(0.5,0.5)
		holderClickButton.ZIndex = -1
		holderClickButton.Parent = self._holder
		self._data.HolderButton = holderClickButton
	end

	-- Finalise --

	self._data._percent = 0
	if config.SliderData.DefaultValue then
		config.SliderData.DefaultValue = math.clamp(config.SliderData.DefaultValue, config.SliderData.Start, config.SliderData.End)
		self._data._percent = SliderFuncs.getAlphaBetween(config.SliderData.Start, config.SliderData.End, config.SliderData.DefaultValue) 
	end

	self._data._percent = math.clamp(self._data._percent, 0, 1)

	self._data._value = SliderFuncs.getNewValue(self)
	self._data._increment = config.SliderData.Increment
	self._data._scaleIncrement = SliderFuncs.getScaleIncrement(self)

	self.Changed = Signal.new()
	self.Dragged = Signal.new()
	self.Released = Signal.new()

	self._data._percent = SliderFuncs.snapToScale(self._data._percent, self._data._scaleIncrement)
	self:Move()

	table.insert(self._data._otherConnections, sliderBtn:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
		self:Move("Instant")
	end))

	table.insert(Slider.Sliders, self)

	return self
end

function Slider:Track()
	for _, connection in ipairs(self._data._clickConnections) do
		connection:Disconnect()
	end

	table.insert(self._data._clickConnections, self._data.Button.MouseButton1Down:Connect(function()
		self.IsHeld = true
	end))

	table.insert(self._data._clickConnections, self._data.Button.MouseButton1Up:Connect(function()
		if self.IsHeld then
			self.Released:Fire(self._data._value)
		end
		self.IsHeld = false
	end))

	if self._data._allowBackgroundClick then
		table.insert(self._data._clickConnections, self._data.HolderButton.Activated:Connect(function(inputObject: InputObject)
			if inputObject.UserInputType == Enum.UserInputType.MouseButton1 or inputObject.UserInputType == Enum.UserInputType.Touch then
				self._data._inputPos = inputObject.Position
				self._data._clickOverride = true
				self:Update()
				self.Released:Fire()
				self._data._clickOverride = false
			end
		end))
	end

	if self.Changed then
		self.Changed:Fire(self._data._value)
	end

	if self._data._mainConnection then
		self._data._mainConnection:Disconnect()
	end

	self._data._mainConnection = UserInputService.InputChanged:Connect(function(inputObject, gameProcessed)
		if inputObject.UserInputType == Enum.UserInputType.MouseMovement or inputObject.UserInputType == Enum.UserInputType.Touch then
			self._data._inputPos = inputObject.Position
			self:Update()
		end
	end)
end

function Slider:Update()
	if (self.IsHeld or self._data._clickOverride) and self._data._inputPos then
		local sliderSize = self._holder.AbsoluteSize[self._config.Axis]
		local sliderPos = self._holder.AbsolutePosition[self._config.Axis]

		local mousePos = self._data._inputPos[self._config.Axis]

		if mousePos then
			local relativePos = (mousePos - sliderPos)
			local newPos = SliderFuncs.snapToScale(relativePos / sliderSize, self._data._scaleIncrement)

			local percent = math.clamp(newPos, 0, 1)
			self._data._percent = percent
			self.Dragged:Fire(self._data._value)
			self:Move()
		end
	end
end

function Slider:Untrack()
	for _, connection in ipairs(self._data._clickConnections) do
		connection:Disconnect()
	end
	if self._data._mainConnection then
		self._data._mainConnection:Disconnect()
	end
	self.IsHeld = false
end

function Slider:Reset()
	for _, connection in ipairs(self._data._clickConnections) do
		connection:Disconnect()
	end
	if self._data._mainConnection then
		self._data._mainConnection:Disconnect()
	end

	self.IsHeld = false

	self._data._percent = 0
	if self._config.SliderData.DefaultValue then 
		self._data._percent = SliderFuncs.getAlphaBetween(self._config.SliderData.Start, self._config.SliderData.End, self._config.SliderData.DefaultValue)
	end
	self._data._percent = math.clamp(self._data._percent, 0, 1)
	self:Move()
end

function Slider:OverrideValue(newValue)
	self.IsHeld = false
	self._data._percent = SliderFuncs.getAlphaBetween(self._config.SliderData.Start, self._config.SliderData.End, newValue)
	self._data._percent = math.clamp(self._data._percent, 0, 1)
	self._data._percent = SliderFuncs.snapToScale(self._data._percent, self._data._scaleIncrement)
	self:Move()
end

function Slider:Move(override)
	self._data._value = SliderFuncs.getNewValue(self)

	local moveType = if override ~= nil then override else self._config.MoveType
	if moveType == "Tween" or moveType == nil then
		if self._data._currentTween then
			self._data._currentTween:Cancel()
		end
		self._data._currentTween = TweenService:Create(self._data.Button, self._config.MoveInfo, {
			Position = SliderFuncs.getNewPosition(self)
		})
		self._data._currentTween:Play()
	elseif moveType == "Instant" then
		self._data.Button.Position = SliderFuncs.getNewPosition(self)
	end
	self.Changed:Fire(self._data._value)
end

function Slider:OverrideIncrement(newIncrement)
	self._config.SliderData.Increment = newIncrement
	self._data._increment = newIncrement
	self._data._scaleIncrement = SliderFuncs.getScaleIncrement(self)
	self._data._percent = math.clamp(self._data._percent, 0, 1)
	self._data._percent = SliderFuncs.snapToScale(self._data._percent, self._data._scaleIncrement)
	self:Move()
end

function Slider:GetValue()
	return self._data._value
end

function Slider:GetIncrement()
	return self._data._increment
end

function Slider:Destroy()
	for _, connection in ipairs(self._data._clickConnections) do
		connection:Disconnect()
	end
	for _, connection in ipairs(self._data._otherConnections) do
		connection:Disconnect()
	end

	if self._data._mainConnection then
		self._data._mainConnection:Disconnect()
	end

	if self._data.HolderButton then
		self._data.HolderButton:Destroy()
		self._data.HolderButton = nil
	end

	self.Changed:Destroy()
	self.Dragged:Destroy()
	self.Released:Destroy()

	for index = 1, #Slider.Sliders do
		if Slider.Sliders[index] == self then
			table.remove(Slider.Sliders, index)
		end
	end

	setmetatable(self, nil)
	self = nil
end

UserInputService.InputEnded:Connect(function(inputObject: InputObject, internallyProcessed: boolean)
	if inputObject.UserInputType == Enum.UserInputType.MouseButton1 or inputObject.UserInputType == Enum.UserInputType.Touch then
		for _, slider in ipairs(Slider.Sliders) do
			if slider.IsHeld then
				slider.Released:Fire(slider._data._value)
			end
			slider.IsHeld = false
		end
	end 
end);

local Assets = Dependencies:WaitForChild("Assets");

local MainUI = Dependencies.Parent.MainUI;
local Contents = MainUI:WaitForChild("Content");

local SideBar = Contents:WaitForChild("SideBar");
local MainContents = Contents:WaitForChild("MainContents");

local Management = {};
Management.__index = Management;
Management.Methods = {};
Management.Enums = {
	["UnitType"] = {
		["Switch"] = {
			["Value"] = 0;
			["Name"] = "Switch";
		};
		["Dropdown"] = {
			["Value"] = 1;
			["Name"] = "Switch";
		};
		["Slider"] = {
			["Value"] = 2;
			["Name"] = "Switch";
		};
		["String"] = {
			["Value"] = 3;
			["Name"] = "Switch";
		};
		["Toggle"] = {
			["Value"] = 4;
			["Name"] = "Toggle";
		};
	};
	["NoticeType"] = {
		["Notice"] = {
			["Value"] = 0;
			["Name"] = "Notice";
		};
		["Alert"] = {
			["Value"] = 1;
			["Name"] = "Alert";
		};
		["Notification"] = {
			["Value"] = 2;
			["Name"] = "Notification";
		};
	};
};
local Enums = Management.Enums;
local Methods = Management.Methods;
Methods.__index = Methods;

local MainHub = {
	Contents = {

	}
}

local Units = {

}

local Tweenings = {
	Fading = nil;
}

local Player = game:GetService("Players").LocalPlayer
local Mouse = Player:GetMouse()

local isMinimized = false

local Hovered = false
local Holding = false
local MoveCon = nil

local InitialX, InitialY, UIInitialPos

local ViewPortSize = workspace.Camera.ViewportSize

local MoveTween = nil

local Syntax = 0;

local LoadedIn = Signal.new()

--[[ Creator ]] do
	function Management.initialize()
		TweenService:Create(MainUI.Stroke.UIGradient, TweenInfo.new(1.2, Enum.EasingStyle.Quint, Enum.EasingDirection.InOut), {Offset = Vector2.new(0,0.5)}):Play()
		task.delay(1.2, function()
			TweenService:Create(MainUI, TweenInfo.new(0.7, Enum.EasingStyle.Quint), {GroupTransparency = 0}):Play()
			TweenService:Create(MainUI, TweenInfo.new(2, Enum.EasingStyle.Quint), {Position = UDim2.fromScale(0.25, 0.05)}):Play()
			TweenService:Create(MainUI.Stroke, TweenInfo.new(0.7, Enum.EasingStyle.Quint), {Transparency = 1}):Play()
		end)

		MainUI.Parent.Dependencies.Audios.Opening:Play();

		local function makeDraggable()
			local function Drag()
				if Holding == false then MoveCon:Disconnect(); return end
				local distanceMovedX = InitialX - Mouse.X
				local distanceMovedY = InitialY - Mouse.Y

				MoveTween = TweenService:Create(MainUI, TweenInfo.new(0.3, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {Position = UIInitialPos - UDim2.new(0, distanceMovedX, 0, distanceMovedY)}):Play()
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

		TweenService:Create(MainUI.Sizer, TweenInfo.new(1.7, Enum.EasingStyle.Quint), {AspectRatio = 1.5}):Play();
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
						if isMinimized == false then
							isMinimized = true
							TweenService:Create(MainUI.Sizer, TweenInfo.new(1.7, Enum.EasingStyle.Quint, Enum.EasingDirection.InOut), {AspectRatio = 18}):Play();
						else
							isMinimized = false
							TweenService:Create(MainUI.Sizer, TweenInfo.new(1.7, Enum.EasingStyle.Quint, Enum.EasingDirection.InOut), {AspectRatio = 1.5}):Play();
						end
					end)

					task.wait(0.3)
					TweenService:Create(MainUI.Loading, TweenInfo.new(1, Enum.EasingStyle.Quint), {GroupTransparency = 1}):Play();
				end)	
			end)
		end)		
	end

	function Management.newContent(ContentName)
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

		local newWindow = Assets:WaitForChild("WindowTemplate"):Clone();
		newWindow.Parent = MainContents;
		newWindow.Name = ContentName.."Window"
		newWindow.Visible = false

		self.SideButton = newSideButton;
		self.SelectionStroke = newSelectedStroke;
		self.Window = newWindow.Window;

		newSideButton.Activator.Activated:Connect(function()
			if newWindow.Visible == false then
				if Tweenings.Fading ~= nil then
					Tweenings.Fading:Pause();
				end;
				Tweenings.Fading = TweenService:Create(MainUI.Fader, TweenInfo.new(0.5, Enum.EasingStyle.Linear), {GroupTransparency = 0}):Play();
				task.delay(0.5, function()
					Tweenings.Fading = TweenService:Create(MainUI.Fader, TweenInfo.new(0.5, Enum.EasingStyle.Linear), {GroupTransparency = 1}):Play();
					for i, v in pairs(MainHub.Contents) do
						if v.Window ~= newWindow then
							v.Window.Visible = false
						end
					end
					newWindow.Visible = true
				end)
			end
		end)

		MainHub.Contents[ContentName] = {
			SideButton = newSideButton;
			Window = newWindow;
		};

		return self;
	end;

	function Management.setOpenedWindow(ContentName)
		if MainHub.Contents[ContentName] ~= nil then
			if MainHub.Contents[ContentName].Window.Visible == false then
				if Tweenings.Fading ~= nil then
					Tweenings.Fading:Pause();
				end;
				Tweenings.Fading = TweenService:Create(MainUI.Fader, TweenInfo.new(0.5, Enum.EasingStyle.Linear), {GroupTransparency = 0}):Play();
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

	function Management.notice(self, NoticeType, LifeTime, Content_, Header)
		if NoticeType == Enums.NoticeType.Notice then
			local noticeClosed = false

			if LifeTime == nil then
				LifeTime = 3
			end

			local newNotice = Assets:WaitForChild("NoticeTemplate"):Clone();
			newNotice.Parent = MainUI.Parent:WaitForChild("SystemNotices")
			newNotice.Visible = true
			newNotice.Main.SmallNotice.Content.AlertContent.Text = Content_;
			newNotice.Main.Position = UDim2.fromScale(1.6,1)
			if Header ~= nil then
				newNotice.Main.SmallNotice.Topbar.Title.Text = Header;
			end
			TweenService:Create(newNotice.Main, TweenInfo.new(.5, Enum.EasingStyle.Quint, Enum.EasingDirection.InOut), {Position = UDim2.fromScale(0.5,1)}):Play()

			local newConnect = nil
			newConnect = newNotice.Main.SmallNotice.Topbar.Actions.Close.CloseButton.Activator.Activated:Connect(function()
				if noticeClosed == false then
					noticeClosed = true
					TweenService:Create(newNotice.Sizer, TweenInfo.new(3.5, Enum.EasingStyle.Quint, Enum.EasingDirection.InOut), {AspectRatio = 600}):Play()
					TweenService:Create(newNotice.Main.Sizer, TweenInfo.new(3.5, Enum.EasingStyle.Quint, Enum.EasingDirection.InOut), {AspectRatio = 600}):Play()
					task.delay(1.2, function()
						TweenService:Create(newNotice.Main, TweenInfo.new(.5, Enum.EasingStyle.Quint), {GroupTransparency = 1}):Play()
					end)
					game:GetService("Debris"):AddItem(newNotice, 3.6)
				end
			end)

			task.delay(.6, function()
				TweenService:Create(newNotice.Main.SmallNotice.ClosingIn, TweenInfo.new(LifeTime, Enum.EasingStyle.Linear), {Size = UDim2.new(0, 0, 0, 2)}):Play()
				task.wait(LifeTime)
				if noticeClosed == false then
					noticeClosed = true
					TweenService:Create(newNotice.Sizer, TweenInfo.new(3.5, Enum.EasingStyle.Quint, Enum.EasingDirection.InOut), {AspectRatio = 600}):Play()
					TweenService:Create(newNotice.Main.Sizer, TweenInfo.new(3.5, Enum.EasingStyle.Quint, Enum.EasingDirection.InOut), {AspectRatio = 600}):Play()
					task.delay(2.2, function()
						TweenService:Create(newNotice.Main, TweenInfo.new(.5, Enum.EasingStyle.Quint), {GroupTransparency = 1}):Play()
					end)
					game:GetService("Debris"):AddItem(newNotice, 3.6)
				end
			end)
		elseif NoticeType == Enums.NoticeType.Alert then
			local noticeClosed = false

			if LifeTime == nil then
				LifeTime = 3
			end

			local newNotice = Assets:WaitForChild("AlertTemplate"):Clone();
			newNotice.Parent = MainUI.Parent:WaitForChild("SystemNotices")
			newNotice.Visible = true
			newNotice.Main.Alert.Content.AlertContent.Text = Content_;
			newNotice.Main.Position = UDim2.fromScale(1.6,1)
			if Header ~= nil then
				newNotice.Main.Alert.Topbar.Title.Text = Header;
			end
			TweenService:Create(newNotice.Main, TweenInfo.new(.5, Enum.EasingStyle.Quint, Enum.EasingDirection.InOut), {Position = UDim2.fromScale(0.5,1)}):Play()

			local newConnect = nil
			newConnect = newNotice.Main.Alert.Topbar.Actions.Close.CloseButton.Activator.Activated:Connect(function()
				if noticeClosed == false then
					noticeClosed = true
					TweenService:Create(newNotice.Sizer, TweenInfo.new(3.5, Enum.EasingStyle.Quint, Enum.EasingDirection.InOut), {AspectRatio = 600}):Play()
					TweenService:Create(newNotice.Main.Sizer, TweenInfo.new(3.5, Enum.EasingStyle.Quint, Enum.EasingDirection.InOut), {AspectRatio = 600}):Play()
					task.delay(1.2, function()
						TweenService:Create(newNotice.Main, TweenInfo.new(.5, Enum.EasingStyle.Quint), {GroupTransparency = 1}):Play()
					end)
					game:GetService("Debris"):AddItem(newNotice, 3.6)
				end
			end)

			task.delay(.6, function()
				TweenService:Create(newNotice.Main.Alert.ClosingIn, TweenInfo.new(LifeTime, Enum.EasingStyle.Linear), {Size = UDim2.new(0, 0, 0, 2)}):Play()
				task.wait(LifeTime)
				if noticeClosed == false then
					noticeClosed = true
					TweenService:Create(newNotice.Sizer, TweenInfo.new(3.5, Enum.EasingStyle.Quint, Enum.EasingDirection.InOut), {AspectRatio = 600}):Play()
					TweenService:Create(newNotice.Main.Sizer, TweenInfo.new(3.5, Enum.EasingStyle.Quint, Enum.EasingDirection.InOut), {AspectRatio = 600}):Play()
					task.delay(2.2, function()
						TweenService:Create(newNotice.Main, TweenInfo.new(.5, Enum.EasingStyle.Quint), {GroupTransparency = 1}):Play()
					end)
					game:GetService("Debris"):AddItem(newNotice, 3.6)
				end
			end)
		elseif NoticeType == Enums.NoticeType.Notification then
			local noticeClosed = false

			if LifeTime == nil then
				LifeTime = 3
			end

			local newNotice = Assets:WaitForChild("NotificationTemplate"):Clone();
			newNotice.Parent = MainUI.Parent:WaitForChild("SystemNotices")
			newNotice.Visible = true
			newNotice.Main.Notification.Content.AlertContent.Text = Content_;
			newNotice.Main.Position = UDim2.fromScale(1.6,1)
			if Header ~= nil then
				newNotice.Main.Notification.Topbar.Title.Text = Header;
			end
			TweenService:Create(newNotice.Main, TweenInfo.new(.5, Enum.EasingStyle.Quint, Enum.EasingDirection.InOut), {Position = UDim2.fromScale(0.5,1)}):Play()

			local newConnect = nil
			newConnect = newNotice.Main.Notification.Topbar.Actions.Close.CloseButton.Activator.Activated:Connect(function()
				if noticeClosed == false then
					noticeClosed = true
					TweenService:Create(newNotice.Sizer, TweenInfo.new(3.5, Enum.EasingStyle.Quint, Enum.EasingDirection.InOut), {AspectRatio = 600}):Play()
					TweenService:Create(newNotice.Main.Sizer, TweenInfo.new(3.5, Enum.EasingStyle.Quint, Enum.EasingDirection.InOut), {AspectRatio = 600}):Play()
					task.delay(1.2, function()
						TweenService:Create(newNotice.Main, TweenInfo.new(.5, Enum.EasingStyle.Quint), {GroupTransparency = 1}):Play()
					end)
					game:GetService("Debris"):AddItem(newNotice, 3.6)
				end
			end)

			task.delay(.6, function()
				TweenService:Create(newNotice.Main.Notification.ClosingIn, TweenInfo.new(LifeTime, Enum.EasingStyle.Linear), {Size = UDim2.new(0, 0, 0, 2)}):Play()
				task.wait(LifeTime)
				if noticeClosed == false then
					noticeClosed = true
					TweenService:Create(newNotice.Sizer, TweenInfo.new(3.5, Enum.EasingStyle.Quint, Enum.EasingDirection.InOut), {AspectRatio = 600}):Play()
					TweenService:Create(newNotice.Main.Sizer, TweenInfo.new(3.5, Enum.EasingStyle.Quint, Enum.EasingDirection.InOut), {AspectRatio = 600}):Play()
					task.delay(2.2, function()
						TweenService:Create(newNotice.Main, TweenInfo.new(.5, Enum.EasingStyle.Quint), {GroupTransparency = 1}):Play()
					end)
					game:GetService("Debris"):AddItem(newNotice, 3.6)
				end
			end)
		end
	end
end;

--[[ Methods ]] do

	-- Side Button
	function Methods.setSideButtonTitle(self, SideTitle)
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
			if Tweenings.Fading ~= nil then
				Tweenings.Fading:Pause();
			end;
			Tweenings.Fading = TweenService:Create(MainUI.Fader, TweenInfo.new(0.5, Enum.EasingStyle.Linear), {GroupTransparency = 0}):Play();
			task.delay(0.5, function()
				for i, v in pairs(MainHub.Contents) do
					if v.Window ~= self.Window.Parent then
						v.Window.Visible = false
					end
				end
				Tweenings.Fading = TweenService:Create(MainUI.Fader, TweenInfo.new(0.5, Enum.EasingStyle.Linear), {GroupTransparency = 1}):Play();
				self.Window.Parent.Visible = true;
			end)
		end
		return self;
	end;

	function Methods.addWindowTitle(self, Title)
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

	function Methods.addUnit(self, UnitName, UnitType, Data})
		Syntax += 1
		if UnitType == Enums.UnitType.Switch then
			local newSwitchAction = Assets:WaitForChild("UnitSwitch"):Clone();
			newSwitchAction.Parent = self.Window;
			newSwitchAction.Visible = true;
			newSwitchAction.LayoutOrder = Syntax;
			newSwitchAction.UnitTitle.Text = UnitName

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

local Storage = Instance.new("Folder", Dependencies)
Storage.Name = "Storage"

local function InitializeStringRandomizer(length)
	local characters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789~!@#$%^&*/`()|-=+";
	local RanStr = "";
	for i = 1, length do
		local randomIndex = math.random(1, #characters);
		RanStr = string.format("%s%s", RanStr, string.sub(characters, randomIndex, randomIndex));
	end;
	return RanStr;
end

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

Management.initialize()

LoadedIn:Connect(function()
			
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
end

workspace.DescendantAdded:Connect(function(Child)
	if Child.Name == "GunDrop" then
		GlobalData.GunDropped:Fire(Child)
	end
end)

Management:notice(Enums.NoticeType.Notice, 3,"Welcome to Nebula Hub!", "WELCOME")

Management.newContent("Game")
	:setSideButtonTitle("Game")
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
				loadEsp()
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

			GlobalData.Connections["PlayerRespawn"] = workspace.ChildAdded:Connect(function(Child)
				if game:GetService("Players"):GetPlayerFromCharacter(Child) then
					loadEsp()
				end
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
			if GlobalData.Connections["PlayerRespawn"] ~= nil then
				GlobalData.Connections["PlayerRespawn"]:Disconnect()
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

	Management.setOpenedWindow("Home")
end)

Dependencies.Parent.Name = InitializeStringRandomizer(7)
