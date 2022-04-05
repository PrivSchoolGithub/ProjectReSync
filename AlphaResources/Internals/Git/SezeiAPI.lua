return function(token)
  local SezeiAPI = {}

  local httpService = game:GetService('HttpService')
  
  local baseURL = 'http://api.sezei.me'
  
  local function checkHttp()
    -- Returns success,issue
    return pcall(function()
        -- If Google is down then we have a totally separate issue
        -- The world is likely burning
        httpService:GetAsync('https://google.com')
    end)
  end
  
  local function verifyAPIStatus()
    -- Checks if api.sezei.me is running
    if not checkHttp() then
      return false
    end
    local result
    local success,issue = pcall(function()
        result = httpService:Geta
    end)
  end

  function SezeiAPI:RetrieveAsset()
  end

  function SezeiAPI:Post()
  end

  return SezeiAPI
end
