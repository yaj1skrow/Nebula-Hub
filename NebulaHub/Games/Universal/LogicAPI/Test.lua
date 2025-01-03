-- print(getgenv().NebulaHub)
-- print(getgenv().NebulaHub.Dependencies)
-- print(getgenv().NebulaHub.Loaded["Universal"])
-- print(getgenv().NebulaHub.Loaded["Universal"].GlobalData)

-- local Signal = getgenv().NebulaHub.Dependencies.Manager.Signal
-- local Enums = getgenv().NebulaHub.Dependencies.Manager.Enums
-- local GlobalData = getgenv().NebulaHub.Loaded["Universal"].GlobalData

-- local Player = getgenv().LocalPlayer;
-- local Character = Player.Character or Player.CharacterAdded:Wait();
  
-- local Assets = getgenv().NebulaHub.MainUI:WaitForChild("Dependencies"):WaitForChild("Assets");
-- local Storage = getgenv().NebulaHub.Storage

-- local Enums = {
--   ["UnitType"] = {Name = "UnitType", Value = 5};
-- }

-- return function(Content)
--   print("ran test.lua, and also:")
--   print(Content)
--   Content:addUnit("Test", Enums.UnitType.Info, {
--       Text = "If you can see this, it means that it worked.";
--       Initialize = function()
--         print("success");
--       end;
--     });
-- end

return function ()
  print("hi?")
end
