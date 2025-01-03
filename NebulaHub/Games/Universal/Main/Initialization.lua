return function()
	print("Loaded Universal")

	local MainAPI = getgenv().NebulaHub.API

	local RunService = getgenv().Services.RunService;
	local TweenService = getgenv().Services.TweenService;
	local Players = getgenv().Services.Players;

	local Enums = getgenv().NebulaHub.Dependencies.Manager.Enums;
	local Signal = getgenv().NebulaHub.Dependencies.Manager.Signal;

	local Management = getgenv().NebulaHub.Dependencies.Manager.Management;

	getgenv().NebulaHub.Loaded["Universal"] = {}

	getgenv().NebulaHub.Loaded["Universal"].GlobalData = {}

	getgenv().NebulaHub.Loaded["Universal"].private = {}

	MainLogic = {
		"https://raw.githubusercontent.com/yaj1skrow/Nebula-Hub/refs/heads/main/NebulaHub/Games/Universal/LogicAPI/Test.lua"
	}

	local MainContent = Management.newContent("Universal")
	MainContent:setSideButtonTitle("Universal")

	local function Init()
		print("Passed")
		for val, logicApi in pairs(MainLogic) do
			print("trying")
			loadstring(game:HttpGet(logicApi, false))()(MainContent)
			print("PassedSecond")
		end
	end

	Init()

end
