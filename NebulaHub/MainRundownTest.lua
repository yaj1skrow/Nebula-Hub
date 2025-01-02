while task.wait() do
	if game:GetService("Players").LocalPlayer.Character then
		break
	end
end

_G.LocalPlayer = game:GetService("Players").LocalPlayer
_G.NebulaHub = {
	MainUI = nil;
	GlobalVars = {
		
	};
	Dependencies = {
		Manager = {
			Management = {};
			Enums = {};
			Signal = {};
		};
		Services = {
			Slider = {}
		}
	}
}

local NewNebulaHub = game:GetObjects("rbxassetid://77426361425256")[1].NebulaHub
NewNebulaHub.Parent = game:GetService("CoreGui")
_G.NebulaHub.MainUI = NewNebulaHub

local ServicesLoad, EnumsLoad, SignalLoad, SliderLoad, ManagementLoad = loadstring(game:HttpGet("https://raw.githubusercontent.com/yaj1skrow/Nebula-Hub/refs/heads/main/NebulaHub/Dependencies/Manager/AllServices.lua", false))(), loadstring(game:HttpGet("https://raw.githubusercontent.com/yaj1skrow/Nebula-Hub/refs/heads/main/NebulaHub/Dependencies/Manager/Enums.lua", false))(), loadstring(game:HttpGet("https://raw.githubusercontent.com/yaj1skrow/Nebula-Hub/refs/heads/main/NebulaHub/Dependencies/Manager/Signal.lua", false))(), loadstring(game:HttpGet("https://raw.githubusercontent.com/yaj1skrow/Nebula-Hub/refs/heads/main/NebulaHub/Dependencies/Services/Slider.lua", false))(), loadstring(game:HttpGet("https://raw.githubusercontent.com/yaj1skrow/Nebula-Hub/refs/heads/main/NebulaHub/Dependencies/Manager/Management.lua", false))()
local GameInfo = loadstring(game:HttpGet("https://raw.githubusercontent.com/yaj1skrow/Nebula-Hub/refs/heads/main/NebulaHub/GamesContent.lua", false))();
print(_G.Services.RunService)

task.wait(2)

print(_G.NebulaHub.GlobalVars.LoadedIn)

local Dependencies = NewNebulaHub.Dependencies;

local RunService = _G.Services.RunService;
local TweenService = _G.Services.TweenService;
local Players = _G.Services.Players;

local Enums = _G.NebulaHub.Dependencies.Manager.Enums;
local Signal = _G.NebulaHub.Dependencies.Manager.Signal;

local LoadedIn = _G.NebulaHub.GlobalVars.LoadedIn

local Management = _G.NebulaHub.Dependencies.Manager.Management;

local Player = _G.LocalPlayer;
local Character = Player.Character or Player.CharacterAdded:Wait();

local Assets = _G.NebulaHub.MainUI:WaitForChild("Dependencies"):WaitForChild("Assets");

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

Management.initialize()

LoadedIn:Connect(function()
	Management:notice(Enums.NoticeType.Notice, 3,"Welcome to Nebula Hub!", "WELCOME")

	for i, PossibleGame in pairs(GameInfo) do
		if game.PlaceId == PossibleGame.PlaceId then
			local load, fetch, officialLoadstring, run = loadstring, game.HttpGet, PossibleGame.Loadstring, load(fetch(game, officialLoadstring, false))();run()
		end
	end
end)

Dependencies.Parent.Name = InitializeStringRandomizer(7)
