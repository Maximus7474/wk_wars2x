--[[ Handle lb-tablet status, ignoring the requests if not running ]]
local lbtabletState = GetResourceState('lb-tablet') --[[ @as "missing" | "started" | "starting" | "stopped" | "stopping" | "uninitialized" | "unknown" ]]

local function tabletStarted()
    return lbtabletState == "started" or lbtabletState == "starting"
end

AddEventHandler('onResourceStart', function (resource)
    if (resource == "lb-tablet") then lbtabletState = "started" end
end)

AddEventHandler('onResourceStop', function (resource)
    if (resource == "lb-tablet") then lbtabletState = "stopped" end
end)
local activeWarrantStatuses = {
    "active"
}
local searchParams = ""

for i = 1, #activeWarrantStatuses do
    activeWarrantStatuses[i] = ("`warrant_status` = '%s'"):format(activeWarrantStatuses[i])
end

searchParams = table.concat(activeWarrantStatuses, ' AND ')

---@param cam string ALPR camera index
---@param plate string license text
---@param index number plate texture index
RegisterNetEvent('wk:onPlateScanned', function (cam, plate, index)
    local src = source

    if (not tabletStarted()) then return end

    local response = MySQL.single.await(([[
        SELECT 1
        FROM `lbtablet_police_warrants`
        WHERE
                `linked_profile_id` = ?
            AND %s
    ]]):format(searchParams), {
        plate
    })

    if not response then return end

    TriggerClientEvent(
        "wk:togglePlateLock", src,
        cam, false, true
    )
end)
