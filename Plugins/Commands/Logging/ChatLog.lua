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
    Description             Command to log all chats.
    --------------------------------------------------------------------------------------
    
    >> Developer Notice <<
    Please refer to the Documentation script for a full comprehensive guide
    on how to create custom plugins.
    IMPORTANT REMINDERS:
    !! | Don't worry if something appears as an unknown global variable (Like SyncAPI)!
    It will have no issues running, provided you use the correct syntax and include it in the imports.
    !! | We're here to help!
    If you need support creating a custom plugin, feel free to DM MasterKingSirPlease#6533 or Sezei#3061.
    Alternatively, you could join the community server here: https://discord.gg/Y9cu3ZcvvG   
--]]

return function()
	local users = game:GetService('Players')

	local chatLog = {}

	local function manageUser(user)
		user.Chatted:Connect(function(message)
			local filteredMessage = game:GetService('Chat'):FilterStringForBroadcast(message,user)
			table.insert(chatLog,user.DisplayName..': '..filteredMessage)
		end)
	end

	users.PlayerAdded:Connect(function(user)
		manageUser(user)
	end)

	for iteration,user in ipairs(users:GetPlayers()) do
		manageUser(user)
	end

	SyncAPI('ChatLog').Create({
		Description = 'Displays all of the chat history for this server.',
		PermissionLevel = 1,
		Shorthand = {'CLog','ChatLogs','CLogs','ChatHistory','Chats'},
		Parameters = 'optional:search optional:terms',
		Run = function(main,user,option,...)
			local toDisplay = chatLog
			if option and option:lower() == 'search' then
				local selectedChats = {}
				local term = table.concat({...},' ')
				for iteration,chat in next,chatLog do
					if string.find(chat:lower(),term:lower()) then
						table.insert(selectedChats,chat)
					end
				end
				if #selectedChats < 1 then
					return false,'Search term "'..term..'" was not found.',10
				else
					table.insert(selectedChats,1,'<EDIT FONT &SIZE:18>\nSearching for "'..term..'"\n<RESET FONT>')
				end
				toDisplay = selectedChats
			end

			if #chatLog < 1 then
				return false,'There are no chats in this server yet.',10
			end

			SyncAPI:DisplayNotification(user,{
				Type = 'List',
				Title = 'Chat Log',
				Text = table.concat(toDisplay,'\n'),
				CloseButtonText = 'CLOSE',
			})

			return nil
		end,
	})
end
