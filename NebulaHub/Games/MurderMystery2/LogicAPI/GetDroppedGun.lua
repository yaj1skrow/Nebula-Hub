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
  Content:addUnit("Get Dropped Gun", Enums.UnitType.Toggle, {
		onActivated = function(Unit, Value)
			if GlobalData["GunGetDeb"] == false then
				if Character then
					if private.getMap() == nil then Management:notice(Enums.NoticeType.Alert, 3, "Round not started, action can not be completed.", "NO ROUND") return end
					local FindGun = private.getMap():FindFirstChild("GunDrop")
					local GunFetchedSuccess = false
					local CancelGunFetch = false

					if FindGun then
						GlobalData["GunGetDeb"] = true
						local KeptOriginalCFrame = Character:WaitForChild("HumanoidRootPart").CFrame
						local KeptOriginalC1 = Character:WaitForChild("LowerTorso"):WaitForChild("Root").C1
						Character:WaitForChild("HumanoidRootPart").Anchored = true;
						Character:WaitForChild("LowerTorso"):WaitForChild("Root").C1 = CFrame.new(0,10,0)
						Character.PrimaryPart.CFrame = CFrame.new(FindGun:GetPivot().Position)
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
						Character.PrimaryPart.CFrame = KeptOriginalCFrame
						Character:WaitForChild("LowerTorso"):WaitForChild("Root").C1 = KeptOriginalC1
						Character:WaitForChild("HumanoidRootPart").Anchored = false;
						Character:FindFirstChild("Humanoid"):ChangeState("GettingUp")
						GlobalData["GunGetDeb"] = false
					else
						Management:notice(Enums.NoticeType.Alert, 3, "No gun found anywhere, action not completed.", "ERROR")
					end
				end
			end
		end,
		cooldown = 0.2,
	}, "Top")
end
