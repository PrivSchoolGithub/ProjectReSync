--[[
                          _____       _____                  
                         |  __ \     / ____|                 
                         | |__) |___| (___  _   _ _ __   ___ 
                         |  _  // _ \\___ \| | | | '_ \ / __|
                         | | \ \  __/____) | |_| | | | | (__ 
                         |_|  \_\___|_____/ \__, |_| |_|\___|
                                             __/ |           
                                            |___/            
                        
            
            @Description: The revival of SyncAdmin.
            @Authors:
            -    Anna [VolcanoINC]
            -    Marcy [ForPizzaSake]
            -    Engi [EngiAdurite][Sezei#3061]
            -    Scoot [MasterScootScoot][MasterKingSirPlease#6533]
            
            Intellectual Property of Sezei.me
    ======================================================================================
    
    This Script
    -----------
    Authors                 MasterScootScoot
    Description             Refs specified user(s)
    --------------------------------------------------------------------------------------
    
    >> Developer Notice <<
    Please refer to the Documentation script for a full comprehensive guide
    on how to create custom plugins.
    IMPORTANT REMINDERS:
    !! | Don't worry if something appears as an unknown global variable (Like SyncAPI)!
    It will have no issues running, provided you use the correct syntax.
    !! | We're here to help!
    If you need support creating a custom plugin, feel free to DM MasterKingSirPlease#6533 or Sezei#3061.
    Alternatively, you could join the community server here: https://discord.gg/Y9cu3ZcvvG   
--]]

return function()
	SyncAPI('Refresh').Create({
		Description = 'Respawns the specified user(s) and then places them back at their previous CFrame coordinate. If no user is specified, will refresh your own avatar.',
		PermissionLevel = 1,
		Shorthand = 'Ref',
		Parameters = 'optional:user(s)',
		Run = function(main,user,users)
			if not users then
				users = {user}
			end
			local list = {}
			for iteration,target in pairs(users) do
				table.insert(list,target.DisplayName)
				local cFrame = target.Character:FindFirstChild('HumanoidRootPart').CFrame
				wait()
				target:LoadCharacter()
				repeat
					wait()
				until target.Character ~= nil and target.Character:FindFirstChild('HumanoidRootPart') or target == nil
				target.Character:FindFirstChild('HumanoidRootPart').CFrame = cFrame
			end
			return true,'Refreshed '..table.concat(list,', ')..'.',8,users,user.DisplayName..' has refreshed your avatar.',8
		end,
	})
end
