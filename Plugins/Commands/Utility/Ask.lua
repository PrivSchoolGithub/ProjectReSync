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
    Description             Asks a question
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

local chat = game:GetService('Chat')

return function()
	SyncAPI('Ask').Create({
		Description = 'Asks the specified user(s) a question. Results are automatically sent after twenty seconds.',
		PermissionLevel = 1,
		Parameters = 'user(s) options(comma-separated) message',
		Run = function(main,user,users,optionsRaw,...)
			local responses,options = {},{}
			local done=  false
			local question = table.concat({...},' ') -- Cannot use '...' outside of a vararg function
			
			for iteration,target in pairs(users) do
				do
					for option in string.gmatch(optionsRaw,'([^,]+)') do
						local filtered = chat:FilterStringAsync(option,user,target)
						table.insert(options,{
							Text = filtered,
							Clicked = function()
								if done then
									return
								end
								SyncAPI:DisplayNotification(user,{
									Type = 'Sidebar',
									Title = target.DisplayName..' responded with '..filtered,
									Icon = 'Exclamation',
									Time = 5,
								})
								table.insert(responses,filtered)
							end,
						})
					end
					local message = chat:FilterStringAsync(question,user,target)
					SyncAPI:DisplayNotification(target,{
						Type = 'Sidebar',
						Title = 'New poll from '..user.DisplayName..'. Click here to view & respond.',
						Icon = 'Exclamation',
						Time = 18, -- Give time for it to tween out. Also who's going to click this fast
						Clicked = function()
							SyncAPI:DisplayNotification(target,{
								Type = 'Popup',
								Title = user.DisplayName..' Asks',
								Content = message,
								Icon = 'Question',
								Options = options,
								Time = 20,
							})
						end,
					})
					break -- Don't remove this!! Otherwise your iteration will do 2 for each 2 targets
				end
			end
			
			task.spawn(function()
				-- Waits 20 seconds and continuously checks if all users replied
				for timer = 20,0,-1 do
					wait(1)
					if #responses == #users then
						break -- All users responded; no reason to wait around
					end
				end
				
				-- Make it ignore anyone else's input
				done = true
				
				-- Fill the rest in with "no response"
				for answer = #responses,#users-1 do
					table.insert(responses,'No response')
				end
				
				-- Prepare tables for final results display
				local finalResults = {}
				for iteration,option in pairs(options) do
					finalResults[option.Text] = 0
				end
				for iteration,response in pairs(responses) do
					if finalResults[response] == nil then
						finalResults[response] = 0
					end
					finalResults[response] = finalResults[response] + 1
				end
				
				SyncAPI:DisplayNotification(user,{
					Type = 'Sidebar',
					Title = 'Calculating results for question "'..chat:FilterStringAsync(question,user,user)..'..."',
					Icon = 'Check',
					Time = 2,
				})
				
				wait(1.5)
				
				-- Calculate percentages and output to user
				for response,calc in pairs(finalResults) do
					local percent = math.floor(calc*1000/#responses)/10 -- Round to 0.1%
					SyncAPI:DisplayNotification(user,{
						Type = 'Sidebar',
						Title = response..': '..percent..'%',
						Icon = 'Exclamation',
						Time = 120, -- In case there are a lot
					})
				end
				
				-- For stupid people
				SyncAPI:DisplayNotification(user,{
					Type = 'Sidebar',
					Title = 'Responses will automatically be cleared after two minutes. Click/tap a response to remove it manually.',
					Icon = 'Question',
					Time = 10,
				})
				
				return true,'Successfully dispatched your question to '..table.concat(users,', ')..'. Results incoming in T minus 20.',10
			end)
		end,
	})
end
