--[[
                          _____    _____  _____              
                         |  __ \  / ____||_   _|              
                         | |__) || (___    | |
                         |  _  /  \___ \   | |
                         | | \ \  ____) | _| |_
                         |_|  \_\|_____/ |_____|
                         =======================
                            ReSync Internals
                            ================
                             >> Sezei.me <<
                            
    ------------------------------------------------------------------------------
    
    This Script
    -----------
    Authors                 MasterScootScoot                        
    Description             Displays the commands for ReSync

    ------------------------------------------------------------------------------

    >> IMPORTANT <<
	Your use of this code is subject to ReSync's Terms of Use & Service.
	See the "About" script in the main model for detailed information regarding
	the TOS.
	
	>> WARNINGS <<
	- Making changes to this script may make ReSync unstable or completely break it
	  altogether. 
	- No support will be made for custom modifications made to this
	  script.
	- Do not steal this and attempt to publish it under your name. Doing so will
	  make you subject to the penalties outlined in the TOS.
    
]]

return function()
	SyncAPI('Commands').Create({
		Description = 'Displays a list of all commands available that you can execute.',
		PermissionLevel = 0,
		Shorthand = 'Cmds',
		Parameters = 'optional:all',
		Run = function(main,user,showAll,...)
			local commands = CoreAPI:GetCommands()

			local levels = {
				[0] = {},
				[1] = {},
				[2] = {},
				[3] = {},
				[4] = {},
			}

			local filteredList,fullList = '',''

			for name,command in next,commands do
				if command.IsCore then
					table.insert(levels[4],command)
				else
					table.insert(levels[command.PermissionLevel],command)
				end
			end

			local function addToList(command)
				local color,minimumPermission

				if command.PermissionLevel == 0 then
					color = '0,221,73' -- Green
					minimumPermission = 'Standard User'
				elseif command.PermissionLevel == 1 then
					color = '165,68,221' -- Purple
					minimumPermission = 'Moderator'
				elseif command.PermissionLevel == 2 then
					color = '11,158,255' -- Blue
					minimumPermission = 'Administrator'
				elseif command.PermissionLevel == 3 then
					color = '253,79,56' -- Red-orange
					minimumPermission = 'Super Administrator'
				else
					-- Checking for possible error
					CoreAPI:AddError(script,'A critical error has occurred with the "Commands" command, and ReSync is unable to display the command list.',true)
					return false,'A critical error has occurred, and ReSync is unable to display the command list.',12
				end

				if command.IsCore then
					color = '0,0,0' -- Black
					minimumPermission = '🛡️ | Base Administrator'
				end

				-- NOTE WHEN EDITING:
				-- Line breaks are VERY important.
				local commandString = '<INSERT TEXT BOX &COLOR:'..color..'>\n'
				commandString = commandString..'<EDIT FONT &SIZE:18>\n'
				commandString = commandString..SyncAPI.Prefix..command.Name
				commandString = commandString..'\n<RESET FONT>\n'
				commandString = commandString..'<INSERT LINE &COLOR:255,255,255>\n'
				commandString = commandString..'Description: '..command.Description..'\n'
				commandString = commandString..'Required Permission: '..minimumPermission..'\n'
				commandString = commandString..'Usage: '..command.Usage..'\n'
				if #command.Shorthand > 0 then
					commandString = commandString..'Command Shorthand: '..table.concat(command.Shorthand,', ')
				else
					commandString = commandString..'Command Shorthand: N/A'
				end
				commandString = commandString..'\n<EXIT TEXT BOX>'

				local numberLevels = {}

				fullList = fullList..'\n'..commandString

				if SyncAPI:GetPermissionLevel(user) >= command.PermissionLevel then
					filteredList = filteredList..'\n'..commandString
				end
			end

			local function iterate(level) -- multiple reasons
				for iteration,command in next,levels[level] do
					addToList(command)
				end
			end

			iterate(0)
			iterate(1)
			iterate(2)
			iterate(3)
			iterate(4)

			if showAll then
				if showAll:lower() == 'all' then
					SyncAPI:DisplayNotification(user,{
						Type = 'List',
						Title = 'COMMANDS LIST [ALL]',
						Text = fullList,
						CloseButtonText = 'CLOSE',
					})
				else
					SyncAPI:DisplayNotification(user,{
						Type = 'List',
						Title = 'COMMANDS LIST',
						Text = filteredList,
						CloseButtonText = 'CLOSE',
					})
				end
			else
				SyncAPI:DisplayNotification(user,{
					Type = 'List',
					Title = 'COMMANDS LIST',
					Text = filteredList,
					CloseButtonText = 'CLOSE',
				})
			end
		end,
	})
end
