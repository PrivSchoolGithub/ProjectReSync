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
    Description             Displays message to everyone in all servers
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
	local messageService = game:GetService('MessagingService')
	local subSuccess,subScribeConnection = false
	local function try()
		subSuccess,subscribeConnection = pcall(function()
			return messageService:SubscribeAsync('RS_SysBroadcasts',function(receiving)
				for iteration,target in pairs(game:GetService('Players'):GetPlayers()) do
					SyncAPI:DisplayNotification(target,{
						Type = 'Sidebar',
						Title = 'Broadcast from '..receiving.Data.Admin..'. Click here to view.',
						Icon = 'Exclamation',
						Clicked = function()
							SyncAPI:DisplayNotification(target,{
								Type = 'Popup',
								Title = receiving.Data.Admin,
								Content = receiving.Data.Message,
								Options = {'CLOSE'}
							})
						end,
					})
				end
			end)
		end)
	end
	repeat
		try()
	until subSuccess
	
	SyncAPI('SystemAnnouncement').Create({
		Description = 'Sends your message to everyone ALL servers.',
		PermissionLevel = 2,
		Shorthand = {'SystemMessage','SM','Broadcast','Bc'},
		Parameters = 'message',
		Run = function(main,user,...)
			local sending = table.concat({...},' ') -- Cannot use ... outside vararg func
			local success,issue = pcall(function()
				messageService:PublishAsync('RS_SysBroadcasts',{
					Admin = user.DisplayName,
					Message = sending,
				})
			end)
			if success then
				return true,'Broadcasting your message to all servers now. (Give it a moment)',10
			else
				return false,issue,10
			end
		end,
	})
end
