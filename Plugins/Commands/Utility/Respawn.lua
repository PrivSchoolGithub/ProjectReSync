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
    Description             Respawns specified user(s)
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
	SyncAPI('Respawn').Create({
		Description = 'Respawns the specified user(s). If no user is specified, will respawn your own avatar.',
		PermissionLevel = 1,
		Shorthand = 'Res',
		Parameters = 'optional:user(s)',
		Run = function(main,user,users)
			if not users then
				users = {user}
			end
			local list = {}
			for iteration,target in pairs(users) do
				table.insert(list,target.DisplayName)
				target:LoadCharacter()
				game:GetService('RunService').Heartbeat:Wait()
			end
			return true,'Respawned '..table.concat(list,', '),8,users,user.DisplayName..' has respawned your avatar.',8
		end,
	})
end
