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
    Description             Command to audit all command actions.
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
	local auditLog = SyncAPI:GetAuditLog()

	SyncAPI('AuditLog').Create({
		Description = 'Displays a list of all commands run in the current server.',
		PermissionLevel = 1,
		Shorthand = {'Audit','Logs','Log','ModLog','ModLogs','AdminLog','AdminLogs'},
		Parameters = 'optional:search optional:terms',
		Run = function(main,user,option,...)
			local toDisplay = auditLog
			if option and option:lower() == 'search' then
				local selectedEntries = {}
				local term = table.concat({...},' ')
				for iteration,log in next,auditLog do
					if string.find(log:lower(),term:lower()) then
						table.insert(selectedEntries,log)
					end
				end
				if #selectedEntries < 1 then
					return false,'Search term "'..term..'" was not found.',10
				else
					table.insert(selectedEntries,1,'<EDIT FONT &SIZE:18>\nSearching for "'..term..'"\n<RESET FONT>')
				end
				toDisplay = selectedEntries
			end

			if #auditLog < 1 then
				return false,'There are no available entries to display in this log.',10
			end

			SyncAPI:DisplayNotification(user,{
				Type = 'List',
				Title = 'Audit Log',
				Text = table.concat(toDisplay,'\n'),
				CloseButtonText = 'CLOSE',
			})

			return nil
		end,
	})
end
