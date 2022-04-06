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
    Description             Performs a countdown
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

-- A note for Scoot to stop being stupid and naming his variables the same as his
-- functions. DON'T BE LIKE SCOOT!
return function()
	local chat = game:GetService('Chat')
	local function countdown(mod,timer,cdType,...)
		local users = game:GetService('Players'):GetPlayers()
		if ... ~= nil then
			if cdType == 'Sidebar' then
				for iteration,user in pairs(users) do
					SyncAPI:DisplayNotification(user,{
						Type = 'Popup',
						Title = 'Countdown!',
						Content = chat:FilterStringAsync(table.concat({...},' '),mod,user),
						Options = {},
						Icon = 'Exclamation',
						Sound = 'Message',
						Time = 10,
					})
				end
			else
				for iteration,user in pairs(users) do
					SyncAPI:DisplayNotification(user,{
						Type = cdType,
						Title = chat:FilterStringAsync(table.concat({...},' '),mod,user),
						Time = 10,
						Icon = 'Question',
						Sound = 'Message',
					})
				end
			end
		end
		while timer > 0 do
			for iteration,user in pairs(users) do
				SyncAPI:DisplayNotification(user,{
					Type = cdType,
					Title = tostring(timer),
					Icon = 'Question',
					Time = (cdType == 'Hint' and 1.5 or 3),
				})
			end
			timer -= 1
			wait(1)
		end
		for iteration,user in pairs(users) do
			SyncAPI:DisplayNotification(user,{
				Type = cdType,
				Title = 'Countdown finished!',
				Icon = 'Exclamation',
				Sound = 'Complete',
				Time = 7,
			})
		end
	end
	
	SyncAPI('Countdown').Create({
		Description = 'Displays a countdown from the notification bar. Also includes an optional message that can be customized at the start to tell people about the countdown.',
		PermissionLevel = 1,
		Shorthand = {'Cdown','Cd'},
		Parameters = 'number optional:message',
		Run = function(main,user,count,...)
			countdown(user,count,'Sidebar',...)
			return true,'Your countdown has finished.',6
		end,
	})
	SyncAPI('HintCountdown').Create({
		Description = 'Displays a countdown from the hint bar. Also includes an optional message that can be customized at the start to tell people about the countdown.',
		PermissionLevel = 1,
		Shorthand = {'HCdown','HCd','HC','HCountdown'},
		Parameters = 'number optional:message',
		Run = function(main,user,count,...)
			countdown(user,count,'Hint',...)
			return true,'Your countdown has finished.',6
		end,
	})
end
