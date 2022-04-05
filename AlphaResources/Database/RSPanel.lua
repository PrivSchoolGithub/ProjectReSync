local mainGUI = script.Parent:WaitForChild('Settings')
local user = game:GetService('Players').LocalPlayer
local mouse = user:GetMouse()
local rStore = game:GetService('ReplicatedStorage')
local dataFolder = rStore:WaitForChild('Database')
local settingsFolder = dataFolder:FindFirstChild('SyncSettings')
local gateway = settingsFolder:FindFirstChild('ControlPanel')

local settingsChanges = {}
local getCurrentSettings = settingsFolder:FindFirstChild('GetCurrentSettings')

local currentSettings

local function color(r,g,b)
	return Color3.new(r/255,g/255,b/255)
end

local settingsTabs = {
	mainGUI:FindFirstChild('GeneralSettings'),
	mainGUI:FindFirstChild('UserSettings'),
	mainGUI:FindFirstChild('GroupSettings'),
}

local settingsList = {
	GeneralSettings = {
		'Command Prefix',
		'Command Console Key',
		'Console Permission',
	},
	UserSettings = {
		'Friend Join Notifications',
		'Anti-Exploit',
		'Moderators',
		'Administrators',
		'Super Administrators',
	},
	GroupSettings = {
		'Group Permissions',
	},
}

local groupNames = {}
local function getGroupName(gID)
	if groupNames[gID] then
		return groupNames[gID]
	end
	local groupInfo = game:GetService('GroupService'):GetGroupInfoAsync(gID)
	groupNames[gID] = groupInfo.Name
	return groupInfo.Name
end

local function createDropdown(field,listFunction,generatorFunction,onClick)
	local UIs = game:GetService('UserInputService')
	local allActiveItems = {}
	
	local dropList = script:FindFirstChild('DropDownList'):Clone()
	local dropTemplate = dropList:FindFirstChild('TextButton')
	dropTemplate.Parent = nil
	dropList:ClearAllChildren()
	dropList.Parent = field
	
	local function generateList()
		dropList:ClearAllChildren()
		allActiveItems = {}
		if not field:IsFocused() then
			return
		end
		local position = 0
		for iteration,list in pairs(listFunction) do
			local text,show = generatorFunction(list,field.Text)
			if show then
				local item = list
				local button = dropTemplate:Clone()
				button.Position = UDim2.new(0,0,0,position)
				button.Visible = true
				button.ZIndex = 5
				button.Text = text
				button.Parent = dropList
				table.insert(allActiveItems,{button,item})
			end
		end
		dropList.Size = UDim2.new(1,0,0,math.min(position,100))
		dropList.CanvasSize = UDim2.new(0,0,0,position)
	end
	
	field.Focused:Connect(function()
		dropList.Visible = true
		generateList()
	end)

	field.Changed:Connect(function() 
		generateList() 
	end)

	field.FocusLost:Connect(function()
		wait()
		dropList.Visible = false
		generateList()
	end)
	
	-- Get input raw and knowing our all active elements, check if the mouse is within the bounds for the UI item.
	UIs.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			for iteration,item in pairs(allActiveItems) do
				local button = item[1]
				-- VERY VERY long if statement
				if button.Visible and button.Active and input.Position.X > button.AbsolutePosition.X and input.Position.X < button.AbsolutePosition.X + button.AbsoluteSize.X and input.Position.Y > button.AbsolutePosition.Y and input.Position.Y < button.AbsolutePosition.Y + button.AbsoluteSize.Y then
					onClick(item[2])
					field:ReleaseFocus()
				end
			end
		end
	end)
end

local function createSetting(position,name)
	local value = currentSettings[name]
	local typeOfValue = type(value)
	
	if typeOfValue == 'string' then
		local UI = script:FindFirstChild('StringSetting'):Clone()
		local nameText = UI:FindFirstChild('NameText')
		local textBox = UI:FindFirstChild('TextBox')
		local changedIndicator = UI:FindFirstChild('ChangedIndicator')
		local tabContainer = mainGUI:FindFirstChild('TabContainer')
		UI.Position = UDim2.new(0,0,0,position)
		nameText.Text = name
		textBox.Text = value
		changedIndicator.Visible = settingsChanges[name] and true or false
		UI.Visible = true
		UI.Parent = tabContainer:FindFirstChild('ScrollFrame')
		
		textBox.Changed:Connect(function(property)
			if property ~= 'Text' then
				return
			end
			string.gsub(textBox.Text,' ','')
			if textBox.Text == ' ' or textBox.Text == nil then
				textBox.BackgroundColor3 = color(125,0,0)
			else
				settingsChanges[name] = {'SET',textBox.Text}
				changedIndicator.Visible = true
				currentSettings[name] = textBox.Text
			end
		end)
		return 30
	elseif typeOfValue == 'boolean' then
		local UI = script:FindFirstChild('BoolSetting'):Clone()
		local nameText = UI:FindFirstChild('NameText')
		local button = UI:FindFirstChild('Button')
		local changedIndicator = UI:FindFirstChild('ChangedIndicator')
		local tabContainer = mainGUI:FindFirstChild('TabContainer')
		UI.Position = UDim2.new(0,0,0,position)
		nameText.Text = name
		button:FindFirstChild('CheckMark').Visible = value
		changedIndicator.Visible = settingsChanges[name] and true or false
		UI.Visible = true
		UI.Parent = tabContainer:FindFirstChild('ScrollFrame')
		
		button.MouseButton1Click:Connect(function()
			local newValue = not currentSettings[name]
			settingsChanges[name] = {'SET',newValue}
			changedIndicator.Visible = true
			button:FindFirstChild('CheckMark').Visible = newValue
			currentSettings[name] = newValue
		end)
		return 30
	elseif name == 'Moderators' or name == 'Administrators' or name == 'Super Administrators' then
		local function section()
			local UI = script:FindFirstChild('UserListSetting'):Clone()
			local changedIndicator = UI:FindFirstChild('ChangedIndicator')
			local tabContainer = mainGUI:FindFirstChild('TabContainer')
			local nameText = UI:FindFirstChild('NameText')
			local scrollingFrame = UI:FindFirstChild('ScrollingFrame')
			local addUser = UI:FindFirstChild('AddUser')
			local confirmButton = addUser:FindFirstChild('Confirm')
			local fieldUserID = addUser:FindFirstChild('ID')
			local fieldUsername = addUser:FindFirstChild('Username')
			local search = UI:FindFirstChild('Search')
			
			nameText.Text = name
			changedIndicator.Visible = settingsChanges[name] and true or false
			UI.Visible = true
			UI.Parent = tabContainer:FindFirstChild('ScrollFrame')
			
			local inputTemplate = scrollingFrame:FindFirstChild('Template')
			inputTemplate.Parent = nil
			
			local registerListItem
			
			local function drawList()
				scrollingFrame:ClearAllChildren()
				local size,number = 0,0 -- not sure what number is
				-- they had it named as "k"
				for iteration,_ in pairs(value) do
					-- _ is "v"
					-- SyncAdmin has bad names
					if search.IsFocused() then
						local term = search.Text:lower()
						if string.sub(_.Username:lower(),1,#term) == term or string.sub(tostring(_.UserId),1,#term) == term then
							number = number + 1
							local listItem = inputTemplate:Clone()
							listItem.Username.Text = _.Username
							listItem.ID.Text = _.UserID
							listItem.Visible = true
							listItem.Position = UDim2.new(0,0,0,(_-1)*20)
							listItem.Parent = scrollingFrame
							registerListItem(listItem,_.Username,_.UserID)
							size = size + 20
						end
					else
						number = number + 1
						local listItem = inputTemplate:clone()
						listItem.Username.Text = _.Username
						listItem.ID.Text = _.UserID
						listItem.Visible = true
						listItem.Position = UDim2.new(0,0,0,(_-1)*20)
						listItem.Parent = scrollingFrame
						registerListItem(listItem,_.Username,_.UserID)
						size = size + 20
					end
					if number >= 100 then
						break
					end
				end
				scrollingFrame.CanvasSize = UDim2.new(0,0,0,size+10)
			end
			registerListItem = function(list,username,userID)
				list:FindFirstChild('Remove').MouseButton1Click:Connect(function()
					for iteration,_ in pairs(value) do
						if _.UserId == userID or _.Username == username then
							table.remove(value,iteration)
							settingsChanges['REMOVE_'..name..'_'..fieldUsername.Text] = {fieldUsername.Text,fieldUserID.Text}
							break
						end
					end
					drawList()
				end)
			end
			
			fieldUserID.Changed:Connect(function()
				fieldUserID.BackgroundColor3 = (tonumber(fieldUserID.Text) or fieldUserID.Text == 'User ID') and color(50,50,50) or color(100,50,50)
			end)
			
			confirmButton.MouseButton1Click:Connect(function()
				if tonumber(fieldUserID.Text) == nil then
					return
				end
				table.insert(value,{
					Username = fieldUsername.Text,
					UserID = tonumber(fieldUserID.Text)
				})
				settingsChanges['ADD_'..name..'_'..fieldUsername.Text] = {fieldUsername.Text,fieldUserID.Text}
				drawList()
				fieldUserID.Text = 'User ID'
				fieldUsername.Text = 'Username'
			end)
			
			createDropdown(fieldUsername,function()
				return game:GetService('Players'):GetPlayers()
			end,function(person,text)
				local name = person.Name:lower()
				local text = text:lower()
				if string.sub(name,1,#text) == text then
					return person.Name,true
				else
					return '',false
				end
			end,function(person)
				fieldUsername.Text = person.Name
				fieldUserID.Text = person.UserId
			end)
			
			search.Changed:Connect(function(property)
				if property == 'Text' then
					drawList()
				end
			end)
			
			drawList()
		end
		section()
		return 165
	elseif name == 'Group Permissions' then
		local function section()
			local UI = script:FindFirstChild('GroupSetting'):Clone()
			UI.Position = UDim2.new(0,0,0,position)
			local nameText = UI:FindFirstChild('NameText')
			local changedIndicator = UI:FindFirstChild('ChangedIndicator')
			local tabContainer = mainGUI:FindFirstChild('TabContainer')
			local scrollingFrame = UI:FindFirstChild('ScrollingFrame')
			local search = UI:FindFirstChild('Search')
			
			nameText.Text = name
			changedIndicator.Visible = settingsChanges[name] and true or false
			UI.Visible = true
			UI.Parent = tabContainer:FindFirstChild('ScrollFrame')
			
			local groupTemplate = UI:FindFirstChild('ScrollingFrame').Template
			groupTemplate.Parent = nil
			
			local addGroup,fieldGroupID,modLv,adminLv,sAdminLv
			
			addGroup = UI:FindFirstChild('AddGroup')
			fieldGroupID = addGroup:FindFirstChild('ID')
			modLv = addGroup:FindFirstChild('ModLevel')
			adminLv = addGroup:FindFirstChild('AdminLevel')
			sAdminLv = addGroup:FindFirstChild('SuperAdminLevel')
			
			local registerListItem
			
			local function drawList()
				scrollingFrame:ClearAllChildren()
				local size,number = 0,0
				
				for iteration,_ in pairs(value) do
					if search.IsFocused() then
						local term = search.Text:lower()
						if string.sub(getGroupName(_.GroupID):lower(),1,#term) == term or string.sub(tostring(_.GroupID),1,#term) == term then
							number = number + 1
							local listItem = groupTemplate:Clone()
							local templateID = listItem:FindFirstChild('GroupID')
							local templateModLevel = listItem:FindFirstChild('ModLevel')
							local templateAdminLevel = listItem:FindFirstChild('AdminLevel')
							local templateSuperAdminLevel = listItem:FindFirstChild('SuperAdminLevel')
							local removeButton = listItem:FindFirstChild('Remove')
							
							local gName = getGroupName(_.GroupID)
							templateID.Text = gName..' ('.._.GroupID..')'
							templateModLevel.Text = 'Moderators: '.._.ModRank..'+'
							templateAdminLevel.Text = 'Administrators: '.._.AdminRank..'+'
							templateSuperAdminLevel.Text = 'Super Administrators: '.._.SAdminRank..'+'
							listItem.Visible = true
							listItem.Position = UDim2.new(0,0,0,(number-1)*65)
							listItem.Parent = scrollingFrame
							registerListItem(listItem,_.GroupID)
							size = size + 65
						end
					else
						number = number + 1
						local listItem = groupTemplate:Clone()
						local templateID = listItem:FindFirstChild('GroupID')
						local templateModLevel = listItem:FindFirstChild('ModLevel')
						local templateAdminLevel = listItem:FindFirstChild('AdminLevel')
						local templateSuperAdminLevel = listItem:FindFirstChild('SuperAdminLevel')
						local removeButton = listItem:FindFirstChild('Remove')
						
						templateID.Text = _.GroupID
						spawn(function()
							local gName = getGroupName(_.GroupID)
							-- It may have gotten removed during the time it took to get the group name
							
							if listItem:FindFirstChild('ID') then
								templateID.Text = gName..' ('.._.GroupID..')'
							end
						end)

						templateModLevel.Text = 'Moderators: '.._.ModRank..'+'
						templateAdminLevel.Text = 'Administrators: '.._.AdminRank..'+'
						templateSuperAdminLevel.Text = 'Super Administrators: '.._.SAdminRank..'+'
						listItem.Visible = true
						listItem.Position = UDim2.new(0,0,0,(number-1)*65)
						listItem.Parent = scrollingFrame
						registerListItem(listItem,_.GroupID)
						size = size + 65
					end
					if number >= 100 then
						break
					end
				end
				
				scrollingFrame.CanvasSize = UDim2.new(0,0,0,size+10)
				
				registerListItem = function(list,groupID)
					list:FindFirstChild('Remove').MouseButton1Click:Connect(function()
						for iteration,_ in pairs(value) do
							if _.GroupID == groupID then
								table.remove(value,iteration)
								settingsChanges['REM_'..name..'_'..fieldGroupID.Text] = {fieldGroupID.Text}
								break
							end
						end
						drawList()
					end)
				end
				
				fieldGroupID.Changed:Connect(function()
					fieldGroupID.BackgroundColor3 = tonumber(fieldGroupID.Text) or fieldGroupID.Text == 'Group ID' and color(50,50,50) or color(100,50,50)
				end)
				modLv.Changed:Connect(function()
					modLv.BackgroundColor3 = tonumber(modLv.Text) or modLv.Text == 'Mod Rank' and color(50,50,50) or color(100,50,50)
				end)
				adminLv.Changed:Connect(function()
					adminLv.BackgroundColor3 = tonumber(adminLv.Text) or adminLv.Text == 'Admin Rank' and color(50,50,50) or color(100,50,50)
				end)
				sAdminLv.Changed:Connect(function()
					sAdminLv.BackgroundColor3 = tonumber(sAdminLv.Text) or sAdminLv.Text == 'S. Admin Rank' and color(50,50,50) or color(100,50,50)
				end)
				
				addGroup:FindFirstChild('Confirm').MouseButton1Click:Connect(function()
					if tonumber(fieldGroupID.Text) == nil then
						return
					end
					if tonumber(modLv.Text) == nil then
						return
					end
					if tonumber(adminLv.Text) == nil then
						return
					end
					if tonumber(sAdminLv.Text) == nil then
						return
					end
					
					table.insert(value,{
						GroupID = tonumber(fieldGroupID.Text),
						ModRank = tonumber(modLv.Text),
						AdminRank = tonumber(adminLv.Text),
						SAdminRank = tonumber(sAdminLv.Text)
					})
					settingsChanges['ADD_'..name..'_'..fieldGroupID.Text] = {fieldGroupID.Text}
					drawList()
					fieldGroupID.Text = 'Group ID'
					modLv.Text = 'Mod Rank'
					adminLv.Text = 'Admin Rank'
					sAdminLv.Text = 'S. Admin Rank'
				end)
				
				local groupList = {}
				fieldGroupID.Focused:Connect(function()
					groupList = game:GetService('GroupService'):GetGroupsAsync(user.UserId)
					
					-- Cache group names wherever we get them to streamline name retrieval process
					for iteration,group in pairs(groupList) do
						groupNames[group.Id] = group.Name
					end
				end)
				
				createDropdown(fieldGroupID,function()
					return groupList
				end,function(group,text)
					local name = group.Name:lower()
					local gID = group.Id
					local text = text:lower()
					if string.sub(name,1,#text) == text or string.sub(tostring(gID),1,#text) == text then
						return group.Name,true
					else
						return '',false
					end
				end,function(group)
					fieldGroupID.Text = group.Id
				end)
				
				search.Changed:Connect(function(property)
					if property ~= 'Text' then
						drawList()
					end
				end)
				
				drawList()
			end
			section()
			return 185
		end
	end
	return 0
end

local currentTab

local function selectTab(tab)
	currentTab = tab

	for iteration,settingsTab in pairs(settingsTabs) do
		settingsTab.BackgroundColor3 = color(75,75,75)
		settingsTab.Size = UDim2.new(0,settingsTab.Size.X.Offset,0,24)
	end

	tab.BackgroundColor3 = color(100,100,100)
	tab.Size = UDim2.new(0,tab.Size.X.Offset,0,28)

	--Load tab
	local tabContainer = mainGUI:FindFirstChild('TabContainer'):FindFirstChild('ScrollFrame')
	tabContainer:ClearAllChildren()
	local position = 0
	for iteration,name in pairs(settingsList[tab.Name]) do
		position = position + createSetting(currentSettings,position,name)
	end
	tabContainer.CanvasSize = UDim2.new(0,0,0,position+115)
end

gateway.OnClientEvent:Connect(function()
	currentSettings = getCurrentSettings:InvokeServer()
	
	local general = mainGUI:FindFirstChild('GeneralSettings')
	local users = mainGUI:FindFirstChild('UserSettings')
	local groups = mainGUI:FindFirstChild('GroupSettings')
	
	general.MouseButton1Click:Connect(function()
		selectTab(general)
	end)
	users.MouseButton1Click:Connect(function()
		selectTab(users)
	end)
	groups.MouseButton1Click:Connect(function()
		selectTab(groups)
	end)
end)

local applyButton,saveAndCloseButton,cancelButton

applyButton = mainGUI:FindFirstChild('Apply')
saveAndCloseButton = mainGUI:FindFirstChild('SaveAndClose')
cancelButton = mainGUI:FindFirstChild('Cancel')

cancelButton.MouseButton1Click:Connect(function()
	gateway:FireServer('Close')
end)

local function updateSettings()
	local success = settingsFolder:FindFirstChild('PublishSettings'):InvokeServer(settingsChanges)
	if success then
		currentSettings = getCurrentSettings:InvokeServer() -- must re-invoke now that they are updated
		settingsChanges = {} -- resets changes
		selectTab(currentTab) -- and resets tab :)
		-- PHEW this script was a lot of work! I hope it works but I know it won't >_<
	end
end

applyButton.MouseButton1Click:Connect(function()
	updateSettings()
end)

saveAndCloseButton.MouseButton1Click:Connect(function()
	updateSettings()
	gateway:FireServer('Close')
end)

wait()
mainGUI.Position = UDim2.new(0.5,-300,0.5,-200)
