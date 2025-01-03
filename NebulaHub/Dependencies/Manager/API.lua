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
		writefile(self.ConfigPath, getgenv().Services.HttpService:JSONEncode(self.GameConfig))

		NebulaHubAPI.Configuration.GamePath[self.GamePath] = {
			GameConfig = self.GameConfig
		}

		return self
	end

	function NebulaHubAPI.getGameConfig(GameFile)
		if NebulaHubAPI.Configuration.GamePath[GameFile] then
			return getgenv().Services.HttpService:JSONDecode(readfile(FilePath.."/"..ConfigurationSetupPath.."/"..GameFile.."/".."gameConfigs.txt"))
		else
			warn(GameFile.." does not exist on local database")
		end
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
