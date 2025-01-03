local Signal = getgenv().NebulaHub.Dependencies.Manager.Signal
local Enums = getgenv().NebulaHub.Dependencies.Manager.Enums
local GlobalData = getgenv().NebulaHub.Loaded["Universal"].GlobalData

local Player = getgenv().LocalPlayer;
local Character = Player.Character or Player.CharacterAdded:Wait();
  
local Assets = getgenv().NebulaHub.MainUI:WaitForChild("Dependencies"):WaitForChild("Assets");
local Storage = getgenv().NebulaHub.Storage

local Config = getgenv().NebulaHub.Loaded["Universal"].ConfigData

return function(Content)
  print("ran test.lua, and also:")
  print(Content)
  Content:addUnit("Test", Enums.UnitType.Info, {Text = "If you can see this, it means that it worked.";Initialize = function()print("success");end;});
  Config:addBatch("TestSave", {
      Name = "Test";
      Value = 100;
  })
end
