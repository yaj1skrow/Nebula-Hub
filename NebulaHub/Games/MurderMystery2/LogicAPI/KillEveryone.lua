local Signal = getgenv().NebulaHub.Dependencies.Manager.Signal
local Enums = getgenv().NebulaHub.Dependencies.Manager.Enums
local GlobalData = getgenv().NebulaHub.Loaded["MM2"].GlobalData

local Player = getgenv().LocalPlayer;
local Character = Player.Character or Player.CharacterAdded:Wait();
  
local Assets = getgenv().NebulaHub.MainUI:WaitForChild("Dependencies"):WaitForChild("Assets");
local Storage = getgenv().NebulaHub.Storage

local Management = getgenv().NebulaHub.Dependencies.Manager.Management

local private = getgenv().NebulaHub.Loaded["MM2"].private

return function(Content)
  Content:addUnit("Kill everyone", Enums.UnitType.Toggle, {
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

				for i, v in pairs(getgenv().Services.Players:GetPlayers()) do
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
end
