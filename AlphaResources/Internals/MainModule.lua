return function()
	--//Main System Files
	io.open('rs/system.sys')
	file:write({
		Permissions = {
			Moderators = {1,{}},
			Administrators = {2,{}},
			SuperAdministrators = {3,{}},
		},
	})
	io.flush()
	io.close()
	
	--//Libraries
	--/Metatable Library
	io.open('rs/libraries/meta.index')
	file:write({
		encrypttable = function(securityContext)
			local userdata,metaData

			userdata = newproxy(true)
			metaData = getmetatable(userdata)

			for field,value in pairs(securityContext) do
				metaData[field] = value
			end

			return userdata
		end,
	})
	file:flush()
	file:close()
	
	--/Web Library
	io.open('rs/libraries/http.index')
	file:close()

	--/Data Storage
	io.open('rs/libraries/datastore.index')
	file:close()

	--/Environment Library
	io.open('rs/libraries/environment.index')
	file:write({
		SyncAPI = {},
		CoreAPI = {},
	})
	file:close()
	
	--//Modules
	--/Settings Retrieval
	io.open('rs/modules/settingsloader.exe')
	file:write(function()
		-- Retrieves saved settings
	end)
	file:close()

	--/Sentry
	io.open('rs/modules/sentry.exe')
	file:write(function()
		
	end)
	file:close()

	--/Main Network
	io.open('rs/modules/network.exe')
	file:write({
		vxk = function()
			print('HELLO')
		end,
	})
	file:flush()
	os.execute('rs/modules/network.exe/vxk')
end
