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
    Description             Shinyyyyy :P
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
	SyncAPI('Sparkle').Create({
		Description = 'Gives a user(s) sparkles. If no user is specified, will give you sparkles. Aren\'t you special?',
		PermissionLevel = 1,
		Parameters = 'optional:user(s)',
		Run = function(main,user,users)
			if not users then
				users = {user}
			end
			local list = {}
			for iteration,target in pairs(users) do
				if target.Character then
					Instance.new('Sparkles',target.Character:FindFirstChild('HumanoidRootPart'))
					table.insert(list,target.DisplayName)
				end
			end
			return true,'Gave sparkles to '..table.concat(list,', ')..'.',8,users,user.DisplayName..' has given you sparkles!',8
		end,
	})
	SyncAPI('UnSparkle').Create({
		Description = 'Removes sparkles from the specified user(s). If no user is specified, will remove your own sparkles.',
		PermissionLevel = 1,
		Parameters = 'optional:user(s)',
		Run = function(main,user,users)
			if not users then
				users = {user}
			end
			local list = {}
			for iteration,target in pairs(users) do
				if target.Character and target.Character:FindFirstChild('HumanoidRootPart') then
					for _,sparkler in pairs(target.Character:FindFirstChild('HumanoidRootPart'):GetChildren()) do
						if sparkler:IsA('Sparkles') then
							sparkler:Destroy()
						end
					end
					table.insert(list,target.DisplayName)
				end
			end
			return true,'Removed sparkles from '..table.concat(list,', ')..'.',8,users,user.DisplayName..' has removed your sparkles.',8
		end,
	})
end
