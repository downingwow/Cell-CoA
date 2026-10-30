-- Cell-CoA role manager: clickable controls for 3.3.5a / Conquest Reborn.
-- Display overrides and LFG preferences are separate; neither claims to alter server raid roles.
local Cell = Cell
if not Cell or not Cell.SetCoARole then return end
local function db()
    if type(CellCharacterDB) ~= "table" then CellCharacterDB = {} end
    if type(CellCharacterDB.coaRoleGUI) ~= "table" then CellCharacterDB.coaRoleGUI = {} end
    return CellCharacterDB.coaRoleGUI
end
local panel = CreateFrame("Frame", "CellCoARoleManager", UIParent)
panel:SetWidth(310); panel:SetHeight(345)
panel:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
panel:SetFrameStrata("DIALOG"); panel:SetMovable(true); panel:EnableMouse(true)
panel:RegisterForDrag("LeftButton")
panel:SetScript("OnDragStart", function(self) self:StartMoving() end)
panel:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
panel:SetBackdrop({bgFile="Interface\\DialogFrame\\UI-DialogBox-Background", edgeFile="Interface\\DialogFrame\\UI-DialogBox-Border", tile=true, tileSize=32, edgeSize=32, insets={left=10,right=10,top=10,bottom=10}})
local function label(parent, text, x, y, font)
    local t=parent:CreateFontString(nil,"OVERLAY",font or "GameFontNormal")
    t:SetPoint("TOPLEFT",parent,"TOPLEFT",x,y); t:SetText(text); return t
end
label(panel,"Cell-CoA | Role Management",18,-17,"GameFontNormalLarge")
local close=CreateFrame("Button",nil,panel,"UIPanelCloseButton")
close:SetPoint("TOPRIGHT",panel,"TOPRIGHT",-4,-4)
label(panel,"Cell display role (does not change server role)",18,-53,"GameFontHighlightSmall")
local roles={{"Tank","TANK"},{"Healer","HEALER"},{"Damage","DAMAGER"},{"Support","SUPPORT"},{"Automatic","AUTO"}}
local buttons={}
local function currentRole()
    local override=Cell.GetCoARole and Cell.GetCoARole("player")
    return override or "AUTO"
end
local function refresh()
    local current=currentRole()
    for _,b in ipairs(buttons) do b:SetChecked(b.role==current) end
end
for i,entry in ipairs(roles) do
    local b=CreateFrame("CheckButton",nil,panel,"UICheckButtonTemplate")
    b:SetWidth(24); b:SetHeight(24); b:SetPoint("TOPLEFT",panel,"TOPLEFT",17,-66-(i-1)*29)
    b.role=entry[2]
    local t=label(panel,entry[1],46,-72-(i-1)*29,"GameFontHighlight")
    b:SetScript("OnClick",function(self)
        Cell.SetCoARole("player",self.role)
        refresh()
    end)
    t:SetText(entry[1]); buttons[#buttons+1]=b
end
label(panel,"LFG preference (not a shared raid role)",18,-224,"GameFontHighlightSmall")
local lfg={{"Tank","TANK"},{"Healer","HEALER"},{"Damage","DAMAGER"}}
for i,entry in ipairs(lfg) do
    local b=CreateFrame("Button",nil,panel,"UIPanelButtonTemplate")
    b:SetWidth(86); b:SetHeight(23)
    b:SetPoint("TOPLEFT",panel,"TOPLEFT",17+(i-1)*94,-242)
    b:SetText(entry[1])
    b:SetScript("OnClick",function()
        if not Cell.SetCoALFGPreference then return end
        local ok,err=Cell.SetCoALFGPreference(entry[2])
        if DEFAULT_CHAT_FRAME then
            DEFAULT_CHAT_FRAME:AddMessage(ok and ("Cell-CoA: LFG preference set to "..entry[1].." (not a raid role).") or ("Cell-CoA: "..tostring(err)))
        end
    end)
end
local share=CreateFrame("CheckButton",nil,panel,"UICheckButtonTemplate")
share:SetPoint("TOPLEFT",panel,"TOPLEFT",17,-279)
label(panel,"Share role with other Cell-CoA users",46,-286,"GameFontHighlightSmall")
share:SetScript("OnClick",function(self)
    db().shareRole=self:GetChecked() and true or false
    if Cell.CoARoles and Cell.CoARoles.Broadcast then Cell.CoARoles.Broadcast(db().shareRole and currentRole() or "AUTO") end
end)
label(panel,"Other players need Cell-CoA for shared display.",18,-315,"GameFontDisableSmall")
panel:SetScript("OnShow",function() refresh(); share:SetChecked(db().shareRole~=false) end)
panel:Hide()
-- Independent draggable launcher, visible with the default UI, DragonUI and ElvUI.
local launcher=CreateFrame("Button","CellCoARoleLauncher",UIParent,"UIPanelButtonTemplate")
launcher:SetWidth(70); launcher:SetHeight(24)
launcher:SetPoint("CENTER",Minimap,"BOTTOM",0,-28)
launcher:SetText("Cell Roles")
launcher:SetFrameStrata("HIGH")
launcher:SetMovable(true); launcher:EnableMouse(true)
launcher:RegisterForDrag("RightButton")
launcher:SetScript("OnDragStart",function(self) self:StartMoving() end)
launcher:SetScript("OnDragStop",function(self) self:StopMovingOrSizing() end)
launcher:SetScript("OnClick",function() if panel:IsShown() then panel:Hide() else panel:Show() end end)
launcher:SetScript("OnEnter",function(self)
    GameTooltip:SetOwner(self,"ANCHOR_RIGHT")
    GameTooltip:AddLine("Cell-CoA Role Manager")
    GameTooltip:AddLine("Left-click: role settings",1,1,1)
    GameTooltip:AddLine("Right-drag: move button",1,1,1)
    GameTooltip:Show()
end)
launcher:SetScript("OnLeave",function() GameTooltip:Hide() end)
Cell.CoARoles = Cell.CoARoles or {}
Cell.CoARoles.OpenManager=function() panel:Show() end
