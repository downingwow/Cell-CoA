-- Cell-CoA: cooperative role hints. Does not modify Blizzard's assigned role.
local Cell = Cell
if not Cell or not Cell.SetCoARole or not Cell.GetCoARole then return end
local PREFIX = "CellCoARole"
local roles = {TANK=true, HEALER=true, DAMAGER=true, SUPPORT=true, AUTO=true}
Cell.CoARoles = Cell.CoARoles or {}
Cell.CoARoles.peerRoles = {}
local peers = Cell.CoARoles.peerRoles
local function groupChannel()
    if GetNumRaidMembers and GetNumRaidMembers() > 0 then return "RAID" end
    if GetNumPartyMembers and GetNumPartyMembers() > 0 then return "PARTY" end
end
local function broadcast(role)
    if CellCharacterDB and CellCharacterDB.coaRoleGUI and CellCharacterDB.coaRoleGUI.shareRole == false and role ~= "AUTO" then return end
    local channel = groupChannel()
    if channel and SendAddonMessage then SendAddonMessage(PREFIX, role, channel) end
end
Cell.CoARoles.Broadcast = broadcast
local originalSet = Cell.SetCoARole
Cell.SetCoARole = function(unit, role)
    local ok = originalSet(unit, role)
    if ok and UnitIsUnit(unit, "player") then broadcast(string.upper(role or "AUTO")) end
    return ok
end
local originalGet = Cell.GetCoARole
Cell.GetCoARole = function(unit)
    local own = originalGet(unit)
    if own then return own end
    if not unit or not UnitExists(unit) or UnitIsUnit(unit, "player") then return nil end
    local name = UnitName(unit)
    return name and peers[name] or nil
end
local function isMember(name)
    if not name then return false end
    if UnitName("player") == name then return true end
    local prefix, count = "party", (GetNumPartyMembers and GetNumPartyMembers() or 0)
    if GetNumRaidMembers and GetNumRaidMembers() > 0 then
        prefix, count = "raid", GetNumRaidMembers()
    end
    for i=1,count do
        if UnitName(prefix..i) == name then return true end
    end
    return false
end
local frame = CreateFrame("Frame")
frame:RegisterEvent("CHAT_MSG_ADDON")
frame:RegisterEvent("PARTY_MEMBERS_CHANGED")
frame:RegisterEvent("RAID_ROSTER_UPDATE")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:SetScript("OnEvent", function(self, event, prefix, message, channel, sender)
    if event == "CHAT_MSG_ADDON" then
        if prefix ~= PREFIX or not roles[message] or not isMember(sender) then return end
        if CellCharacterDB and CellCharacterDB.coaRoleGUI and CellCharacterDB.coaRoleGUI.shareRole == false then return end
        peers[sender] = message ~= "AUTO" and message or nil
        if Cell.CoARoles.Refresh then Cell.CoARoles.Refresh() end
        return
    end
    for name in pairs(peers) do if not isMember(name) then peers[name] = nil end end
    if event == "PLAYER_ENTERING_WORLD" or event == "PARTY_MEMBERS_CHANGED" or event == "RAID_ROSTER_UPDATE" then
        local own = originalGet("player")
        if own then broadcast(own) end
    end
end)
-- This API changes LFG preference only, not the server-assigned raid role.
function Cell.SetCoALFGPreference(role)
    role = type(role)=="string" and string.upper(role) or ""
    if role == "DAMAGE" or role == "DPS" then role = "DAMAGER" end
    if not (role == "TANK" or role == "HEALER" or role == "DAMAGER") then return false, "Choose tank, healer or damage" end
    if type(SetLFGRoles) ~= "function" or type(GetLFGRoles) ~= "function" then return false, "LFG API unavailable" end
    local leader = GetLFGRoles()
    local ok, err = pcall(SetLFGRoles, leader and true or false, role=="TANK", role=="HEALER", role=="DAMAGER")
    if not ok then return false, tostring(err) end
    local _,tank,healer,damage = GetLFGRoles()
    if (role=="TANK" and tank) or (role=="HEALER" and healer) or (role=="DAMAGER" and damage) then return true end
    return false, "Client did not retain preference"
end
