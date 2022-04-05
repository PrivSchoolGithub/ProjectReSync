return function()
	local CoreAPI,SyncAPI = {},{}
	
	--//CoreAPI
	function CoreAPI:RetrieveSettings()
		return SezeiAPI:RetrieveAsset('system.sys')
	end
	
	function CoreAPI:SubmitSetings(submitting)
		return SezeiAPI:Post('system.sys',submitting)
	end
	
	local pullsBlocked = {}
	
	function CoreAPI.PullBlocked(request)
		if pullsBlocked[request] then
			return true
		else
			return false
		end
	end
	
	function CoreAPI:BlockPull(request,boolean)
		if boolean then
			pullsBlocked[request] = true
		else
			pullsBlocked[request] = nil
		end
	end
	
	function CoreAPI:CheckBaseAdmin(userOrID)
	end
	
	function CoreAPI:ReturnPluginErrors()
	end
		
	--//SyncAPI
	function SyncAPI:DisplayNotification(user,infoTable)
	end
	
	SyncAPI.AntiExploitEnabled = CoreAPI:RetrieveSettings().AE
	SyncAPI.Prefix = CoreAPI:RetrieveSettings().Prefix
	
	function SyncAPI:GetPermissionLevel(userOrID)
	end
	
	return CoreAPI,SyncAPI
end
