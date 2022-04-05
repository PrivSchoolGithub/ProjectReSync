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
    Description             Debugging command for ReSync

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
	local function reverse(tbl)
		local length = #tbl
		local newTable = {}
		for key,value in pairs(tbl) do
			newTable[length] = value
			length -= 1
		end
		return newTable
	end
	
	local function getPath(module)
		local path = {}
		if typeof(module) == 'Instance' then
			table.insert(path,module.Name)
			local parent = module.Parent
			if module:IsDescendantOf(CoreAPI:GetCoreFolder()) then
				while parent:IsDescendantOf(CoreAPI:GetCoreFolder()) do
					table.insert(path,parent.Name)
					parent = parent.Parent
				end
				return 'Core.'..table.concat(reverse(path),'/'),true
			elseif module:IsDescendantOf(CoreAPI:GetPluginsFolder()) then
				while parent:IsDescendantOf(CoreAPI:GetPluginsFolder()) do
					table.insert(path,parent.Name)
					parent = parent.Parent
				end
				return 'Plugins.'..table.concat(reverse(path),'/'),false
			end
		elseif type(module) == 'string' then -- Other types???
			return module,false
		end
	end
	
	CoreAPI('ErrorLog').Create({
		Description = 'Displays a list of errors the system has encountered.',
		PermissionLevel = 0,
		Shorthand = {'PluginErrors','CmdErrors','CommandErrors','PluginProblems','ErrorList','CmdErr'},
		Parameters = 'optional:show-core',
		Run = function(main,user,showHidden)
			local function generateList()
				local toDisplay = ''
				local errors = CoreAPI:ReturnErrorList()

				-- Normal
				for iteration,log in pairs(errors) do
					local location,issue,isCritical = table.unpack(log)
					local path,isCore = getPath(location)
					if not isCritical and not isCore then
						local color = '255,150,0'
						local icon = 'Warning'

						toDisplay = toDisplay..'<INSERT TEXT BOX &COLOR:'..color..' &IMAGE:'..icon..'>\n'
						toDisplay = toDisplay..'<EDIT FONT &SIZE:18>\n'..path..'\n<RESET FONT>\n'
						toDisplay = toDisplay..'<INSERT LINE &COLOR:'..color..'>\n'
						toDisplay = toDisplay..issue..'\n<EXIT TEXT BOX>\n'
					end
				end

				-- Critical
				if showHidden and showHidden:lower() == 'show-core' then
					if CoreAPI:CheckSupportStaff(user) then
						for iteration,log in pairs(errors) do
							local location,issue,isCritical = table.unpack(log)
							local path,isCore = getPath(location)
							if isCritical or isCore then
								local color = '255,0,0'
								local icon = 'Critical'

								toDisplay = toDisplay..'<INSERT TEXT BOX &COLOR:'..color..' &IMAGE:'..icon..'>\n'
								toDisplay = toDisplay..'<EDIT FONT &SIZE:18>\n'..path..'\n<RESET FONT>\n'
								toDisplay = toDisplay..'<INSERT LINE &COLOR:'..color..'>\n'
								toDisplay = toDisplay..issue..'\n<EXIT TEXT BOX>\n'
							end
						end
					else
						for iteration,log in pairs(errors) do
							local location,issue,isCritical = table.unpack(log)
							local path,isCore = getPath(location)
							if isCritical or isCore then
								local color = '255,0,0'
								local icon = 'Critical'

								toDisplay = toDisplay..'<INSERT TEXT BOX &COLOR:'..color..' &IMAGE:'..icon..'>\n'
								toDisplay = toDisplay..'For security reasons, you do not have permission to view the internal errors.\nPlease contact support staff so they can help you.'
								break
							end
						end
					end
				else
					local criticalNum = 0
					for iteration,log in pairs(errors) do
						local location,issue,isCritical = table.unpack(log)
						local path,isCore = getPath(location)
						if isCritical or isCore then
							criticalNum += 1
						end
					end
					if criticalNum ~= 0 then -- > or just leave for possible bugs
						local color = '255,0,0'
						local icon = 'Critical'

						toDisplay = toDisplay..'<INSERT TEXT BOX &COLOR:'..color..' &IMAGE:'..icon..'>\n'
						toDisplay = toDisplay..tostring(criticalNum)..' internal system errors are hidden.\nUse "'..SyncAPI.Prefix..'ErrorLog show-core" to view these errors.'
					end
				end
				return toDisplay
			end
			
			CoreAPI:DisplaySystemNotification(user,{
				Type = 'List',
				Title = 'ERROR LOG',
				OnRefresh = generateList,
				Text = generateList(),
			})
		end,
	})
end
