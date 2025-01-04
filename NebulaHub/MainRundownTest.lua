local LoadService = loadstring(game:HttpGet("https://raw.githubusercontent.com/yaj1skrow/Nebula-Hub/refs/heads/main/NebulaHub/Dependencies/Manager/AllServices.lua", false))()
getgenv().LocalPlayer = game:GetService("Players").LocalPlayer

while task.wait() do
	if getgenv().LocalPlayer.Character then
		break
	end
end

getgenv().NebulaHub = {
	API = {};
	MainUI = nil;
	Loaded = {
		
	};
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

local LoadAPI = loadstring(game:HttpGet("https://raw.githubusercontent.com/yaj1skrow/Nebula-Hub/refs/heads/main/NebulaHub/Dependencies/Manager/API.lua", false))()

local NewNebulaHub = game:GetObjects("rbxassetid://77426361425256")[1].NebulaHub
local hider = get_hidden_gui or gethui
NewNebulaHub.Parent = hider()
getgenv().NebulaHub.MainUI = NewNebulaHub

local Player = getgenv().LocalPlayer

local EnumsLoad, SignalLoad, SliderLoad, ManagementLoad = loadstring(game:HttpGet("https://raw.githubusercontent.com/yaj1skrow/Nebula-Hub/refs/heads/main/NebulaHub/Dependencies/Manager/Enums.lua", false))(), loadstring(game:HttpGet("https://raw.githubusercontent.com/yaj1skrow/Nebula-Hub/refs/heads/main/NebulaHub/Dependencies/Manager/Signal.lua", false))(), loadstring(game:HttpGet("https://raw.githubusercontent.com/yaj1skrow/Nebula-Hub/refs/heads/main/NebulaHub/Dependencies/Services/Slider.lua", false))(), loadstring(game:HttpGet("https://raw.githubusercontent.com/yaj1skrow/Nebula-Hub/refs/heads/main/NebulaHub/Dependencies/Manager/Management.lua", false))()
local GameInfo = loadstring(game:HttpGet("https://raw.githubusercontent.com/yaj1skrow/Nebula-Hub/refs/heads/main/NebulaHub/GamesContent.lua", false))();
print(getgenv().Services.RunService)

task.wait(2)

local LoadedIn = getgenv().NebulaHub.GlobalVars.LoadedIn

local Assets = NewNebulaHub:WaitForChild("Dependencies"):WaitForChild("Assets")

local Storage = Instance.new("Folder", NewNebulaHub:WaitForChild("Dependencies"))
Storage.Name = "Storage"
getgenv().NebulaHub.Storage = Storage

local Enums = getgenv().NebulaHub.Dependencies.Manager.Enums;
local Management = getgenv().NebulaHub.Dependencies.Manager.Management;

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

	Assets:WaitForChild("HomeContent").Window.Information.AccountInfo.Up.User.Text = Player.Name
	Assets:WaitForChild("HomeContent").Window.Information.AccountInfo.Up.Display.Text = Player.DisplayName
		Assets:WaitForChild("HomeContent").Window.Information.PlayerThumbnail.Up.Thumbnail.ImageColor3 = Color3.fromRGB(255, 255, 255)
	Assets:WaitForChild("HomeContent").Window.Information.PlayerThumbnail.Up.Thumbnail.Image = getgenv().Services.Players:GetUserThumbnailAsync(Player.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size150x150)
		
	Management.newContent("Home", Assets:WaitForChild("HomeContent"))
	:setSideButtonTitle("Home")

	Management.setOpenedWindow("Home")

	for i, PossibleGame in pairs(GameInfo) do
		if game.PlaceId == PossibleGame.PlaceId then
			task.wait(0.1)
			loadstring(game:HttpGet(tostring(PossibleGame.Loadstring)))()(getgenv())
			break
		end
	end

	loadstring(game:HttpGet("https://raw.githubusercontent.com/yaj1skrow/Nebula-Hub/refs/heads/main/NebulaHub/Games/Universal/Main/Initialization.lua", false))()()
	
	Management.finish()
end)

getgenv().NebulaHub.MainUI.Name = InitializeStringRandomizer(7)
