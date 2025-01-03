local Signal = getgenv().NebulaHub.Dependencies.Manager.Signal
local Enums = getgenv().NebulaHub.Dependencies.Manager.Enums
local GlobalData = getgenv().NebulaHub.Loaded["MM2"].GlobalData

return function(Content)
  Content:addUnit("Test", Enums.UnitType.Info, {
      Text = "If you can see this, it means that it worked.";
      Initialize = function()
        print("success");
      end;
    };
end
