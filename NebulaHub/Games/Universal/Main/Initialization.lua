return function()
  local MainAPI = getgenv().NebulaHub.API
  	
  local RunService = getgenv().Services.RunService;
  local TweenService = getgenv().Services.TweenService;
  local Players = getgenv().Services.Players;
  	
  local Enums = getgenv().NebulaHub.Dependencies.Manager.Enums;
  local Signal = getgenv().NebulaHub.Dependencies.Manager.Signal;
  	
  local Management = getgenv().NebulaHub.Dependencies.Manager.Management;
  	
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
  
   getgenv().NebulaHub.Loaded["MM2"].private = {}

  MainLogic = {
    "https://raw.githubusercontent.com/yaj1skrow/Nebula-Hub/refs/heads/main/NebulaHub/Games/MurderMystery2/LogicAPI/PlayerChams.lua"
  }

 local MainContent = Management.newContent("Universal")
	MainContent:setSideButtonTitle("Universal")

  local function Init()
    for _, logicApi in pairs(MainLogic) do
      game:HttpGet(logicApi, false)()(MainContent)
    end
  end

  Init()
   
end
