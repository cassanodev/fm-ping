local Settings = require 'shared.settings'

local currentResourceName = GetCurrentResourceName()
local debugIsEnabled = Settings.DebugEnabled

--- A simple debug print function that is dependent on a convar
--- will output a nice prettfied message if debugMode is on
function DebugPrint(...)
  if not debugIsEnabled then return end
  local args <const> = { ... }

  local appendStr = ''
  for _, v in ipairs(args) do
    appendStr = appendStr .. ' ' .. tostring(v)
  end
  local msgTemplate = '^3[%s]^0%s'
  local finalMsg = msgTemplate:format(currentResourceName, appendStr)
  print(finalMsg)
end

Internal = function (eventName, ...)
  TriggerEvent(currentResourceName .. eventName, ...)
end

Client = function (eventName, ...)
  TriggerClientEvent(currentResourceName .. ':client:' .. eventName, ...)
end

Server = function (eventName, ...)
  TriggerServerEvent(currentResourceName .. ':server:' .. eventName, ...)
end

Register = function (eventName, ...)
  local version = IsDuplicityVersion() and ':server:' or ':client:'

  RegisterNetEvent(currentResourceName .. version .. eventName)
  AddEventHandler(currentResourceName .. version .. eventName, ...)
end

function IsResourceActive(resourceName)
  return GetResourceState(resourceName) ~= "missing"
end

function GetTableCount(t)
    local c = 0
    for k in pairs(t) do c += 1 end
    return c
end