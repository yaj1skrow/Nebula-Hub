local FilePath = "NebulaHub"
local ConfigurationSetupPath = "Configs"

makefolder(FilePath)
makefolder(FilePath.."/"..ConfigurationSetupPath)

local NebulaHubAPI = {}
NebulaHubAPI.__index = NebulaHubAPI
NebulaHubAPI.Methods = {}
local Methods = NebulaHubAPI.Methods
Methods.__index = Methods

NebulaHubAPI.Configuration = {
	GamePath = {}
}

--[[ NEBULA HUB MAIN API ]] do
	function NebulaHubAPI.newGameConfig(GamePath)
		local self = setmetatable({
			GameStringPath = FilePath.."/"..ConfigurationSetupPath.."/"..GamePath;
			GamePath = GamePath;
			GameConfig = {
				
			};
		}, Methods)

		self.ConfigPath = self.GameStringPath.."/".."gameConfigs.txt"

		makefolder(self.GameStringPath);
		if isfile(self.ConfigPath) then
			print("data is there so idk why this isnt working???")
			self.GameConfig = readfile(self.ConfigPath)
		else
			print("data is not found apparently")
			writefile(self.ConfigPath, getgenv().Services.HttpService:JSONEncode(self.GameConfig))
		end

		NebulaHubAPI.Configuration.GamePath[self.GamePath] = {
			GameConfig = self.GameConfig
		}

		return self
	end
end

--[[ METHODS ]] do
	function Methods.addBatch(self, BatchName, BatchValue)
		self.GameConfig[BatchName] = BatchValue
		writefile(self.ConfigPath, getgenv().Services.HttpService:JSONEncode(self.GameConfig))
		return self
	end
end

-- SEND API

print("API RUNNING")
getgenv().NebulaHub.API = NebulaHubAPI
