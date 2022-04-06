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
    Description             Gives sword to user
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
	SyncAPI('Sword').Create({
		Description = 'Gives the specified user(s) a sword. If no user is specified, gives a sword to you.',
		PermissionLevel = 1,
		Shorthand = {'Arm','GiveSword'},
		Parameters = 'optional:user(s)',
		Run = function(main,user,users)
			if not users then
				users = {user}
			end
			-- The following is the gear ID for the sword. Feel free to check it
			-- out. Since it's made by Roblox, it's completely safe to insert into
			-- your game.
			local gear = game:GetService('InsertService'):LoadAsset(125013769):GetChildren()
			
			if #gear < 1 then
				return false,'Sword could not be loaded.',5
			end
			
			gear = gear[1]
			if not gear:IsA('Tool') then
				return false,'Sword is not a tool.',5
			end
			
			local list = {}
			for iteration,target in pairs(users) do
				table.insert(list,target.DisplayName)
				gear:Clone().Parent = target.Backpack
			end
			
			return true,'Gave a sword to '..table.concat(list,', ')..'.',8,users,user.DisplayName..' has given you a sword. Use it wisely.',8
		end,
	})
end
