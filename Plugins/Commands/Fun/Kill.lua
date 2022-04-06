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
    Description             wham bam thank u ma'am
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
	SyncAPI('Kill').Create({
		Description = 'Kills the specified user(s) with optional method. If no user is specified, will result in suicide.',
		PermissionLevel = 1,
		Shorthand = {'Murder','Off'},
		Parameters = 'optional:user(s) optional:method',
		Run = function(main,user,users,...)
			if not users then
				users = {user}
			end
			local list = {}
			local method
			if ... ~= nil then
				method = table.concat({...},' ')
			else
				method = 'killed'
			end
			for iteration,target in pairs(users) do
				table.insert(list,target.DisplayName)
				local character = target.Character
				if character ~= nil then
					character:BreakJoints()
				end
			end
			return true,'You '..method..' '..table.concat(list,', ')..'.',8,users,'You have been '..method..' by '..user.DisplayName..'.',8
		end,
	})
end
