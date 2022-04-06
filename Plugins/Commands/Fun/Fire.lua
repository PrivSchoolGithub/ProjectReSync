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
    Description             Whooshka (dont search that up)
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
	SyncAPI('Burn').Create({
		Description = 'Sends the specified user(s) straight into hell. Do not pass GO, do not collect $200. Only kidding, they just get really HOT 🤤\nIf no users are specified, you will become h0t 🔥 (you are always hot don\'t let anyone tell you otherwise)\nThis description is too long...',
		PermissionLevel = 1,
		Shorthand = {'Fire','Blaze'},
		Parameters = 'optional:user(s)',
		Run = function(main,user,users)
			if not users then
				users = {user}
			end
			local list = {}
			for iteration,target in pairs(users) do
				if target.Character then
					Instance.new('Fire',target.Character:FindFirstChild('HumanoidRootPart'))
					table.insert(list,target.DisplayName)
				end
			end
			return true,'Set '..table.concat(list,', ')..' 🔥ablaze🔥!',8,users,user.DisplayName..' has set you on fire! You\'re SO HOT OMG! 🔥',8
		end,
	})
	SyncAPI('Extinguish').Create({
		Description = 'Cools the specified user(s) by roughly 200°C.',
		PermissionLevel = 1,
		Shorthand = {'UnFire','Cool'},
		Parameters = 'optional:user(s)',
		Run = function(main,user,users)
			if not users then
				users = {user}
			end
			local list = {}
			for iteration,target in pairs(users) do
				if target.Character and target.Character:FindFirstChild('HumanoidRootPart') then
					for _,fire in pairs(target.Character:FindFirstChild('HumanoidRootPart'):GetChildren()) do
						if fire:IsA('Fire') then
							fire:Destroy()
						end
					end
					table.insert(list,target.DisplayName)
				end
			end
			return true,'Extinguished '..table.concat(list,', ')..'.',8,users,user.DisplayName..' has extinguished the fire from your torso.',8
		end,
	})
end
