local _G = getfenv(0)
local ADDON_NAME, addon = ...
addon.addonName = "PersonalPlayerBlacklist"
addon.addonTitle = "Personal Player Blacklist"
local PersonalPlayerBlacklist = LibStub("AceAddon-3.0"):NewAddon(addon.addonName, "AceConsole-3.0", "AceHook-3.0",
    "AceEvent-3.0", "AceTimer-3.0")

PersonalPlayerBlacklist:RegisterChatCommand("rl", "Reload")

function PersonalPlayerBlacklist:Reload()
    ReloadUI();
end

local options = {
    name = "Personal Player Blacklist",
    handler = PersonalPlayerBlacklist,
    type = 'group',
    args = {
        reasonPopup = {
            type = 'toggle',
            name = 'Always show popup',
            desc = 'Shows a popup when adding a new player to allow you to write a reason',
            set = "SetShowPopup",
            get = "GetShowPopup",
        },
    },
}

local defaults = {
    global = {
        blacklistedPlayers = {},
        previousGroupSize = 0
    },
}

local BlacklistPopupWindowOptions = {
    "All",
    "Bad player",
    "Quitter",
    "AFKer",
    "Toxic",
    "Scammer",
    "Bigot",
    "Other"
}

LibStub("AceConfig-3.0"):RegisterOptionsTable(addon.addonName, options, { "PPB", "ppb" })

local aceDialog = LibStub("AceConfigDialog-3.0");
local AceGUI = LibStub("AceGUI-3.0")

function PersonalPlayerBlacklist:OnInitialize()
    self:RegisterChatCommand("personalplayerblacklist", "SlashCommand")
    self:RegisterChatCommand("ppb", "SlashCommand")
    self.db = LibStub("AceDB-3.0"):New("PersonalPlayerBlacklistDB", defaults)
    LibStub("AceConfig-3.0"):RegisterOptionsTable(addon.addonName, options)
    self.optionsFrame = aceDialog:AddToBlizOptions(addon.addonName, addon.addonName)
    self:RegisterEvent("GROUP_ROSTER_UPDATE", "CheckPlayersOnGroupUpdate");
end

function PersonalPlayerBlacklist:CheckPlayersOnGroupUpdate()
    local groupCount = GetNumGroupMembers()
    if groupCount > self.db.global.previousGroupSize then
        for i = 1, groupCount do
            if groupCount < 6 then
                name, realm = UnitName("party" .. i)
            else
                name, realm = UnitName("raid" .. i)
            end
            if not realm then realm = GetRealmName() end
            if name and realm and PersonalPlayerBlacklist:IsPlayerInList(name .. "-" .. realm) then
                print(name .. "-" .. realm .. " is on your blacklist.");
            end
        end
    end
    self.db.global.previousGroupSize = groupCount;
end

function PersonalPlayerBlacklist:SlashCommand(msg)
    if not msg or msg:trim() == "" then
        Settings.OpenToCategory("PersonalPlayerBlacklist")
    else
        PersonalPlayerBlacklist:ShowBlacklistPopupWindow()
        --PersonalPlayerBlacklist:PrintPlayers()
    end
end

function PersonalPlayerBlacklist:ShowBlacklistPopupWindow()
    local container = CreateFrame("Frame", "BlacklistPopupWindow", UIParent,
        BackdropTemplateMixin and "BackdropTemplate")
    container:SetFrameStrata("DIALOG")
    container:SetToplevel(true)
    container:SetWidth(250)
    container:SetHeight(200)
    container:SetPoint("CENTER", UIParent)
    container:SetScale(1 / UIParent:GetScale())
    container:SetBackdrop(
        {
            bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
            tile = true,
            tileSize = 32,
            edgeSize = 15,
            insets = { left = 2, right = 2, top = 2, bottom = 2 }
        })
    container:SetBackdropColor(0, 0, 0, 1)
    container:SetMovable(true)
    container:RegisterForDrag("LeftButton")
    container:SetScript("OnDragStart",
        function(this, button)
            this:StartMoving()
        end)
    container:SetScript("OnDragStop",
        function(this)
            this:StopMovingOrSizing()
        end)
    container:EnableMouse(true)

    local savebutton = CreateFrame("Button", nil, container, "UIPanelButtonTemplate")
    savebutton:SetText("Save")
    savebutton:SetWidth(100)
    savebutton:SetHeight(20)
    savebutton:SetPoint("BOTTOM", container, "BOTTOM", -60, 20)
    savebutton:SetScript("OnClick",
        function(this)
            this:GetParent():Hide()
        end)
    local colorR, colorG, colorB, colorA = savebutton:GetNormalFontObject():GetTextColor()

    local cancelbutton = CreateFrame("Button", nil, container, "UIPanelButtonTemplate")
    cancelbutton:SetText("Cancel")
    cancelbutton:SetWidth(100)
    cancelbutton:SetHeight(20)
    cancelbutton:SetPoint("BOTTOM", container, "BOTTOM", 60, 20)
    cancelbutton:SetScript("OnClick", function(this) this:GetParent():Hide(); end)


    local title = container:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    title:SetPoint("TOP", container, "TOP", 0, -10)
    title:SetText("Add to Blacklist")
    title:SetTextColor(1.0, 1.0, 1.0, 1.0)



    local drop = {}
    drop = AceGUI:Create("Dropdown")
    drop:SetList(BlacklistPopupWindowOptions)
    drop:SetRelativeWidth(0.5)
    drop:SetValue(1)
    drop:SetLabel("Reason:")
    drop:SetCallback("OnValueChanged", function(this, event, item)
        print(item)
    end
    )
    drop.frame:SetParent(container)
    drop.frame:Show()
    drop.frame:SetPoint("LEFT", container, "TOPLEFT", 20, -40)

    local noteLabel = container:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    noteLabel:SetPoint("LEFT", drop.frame, "LEFT", 0, -30)
    noteLabel:SetTextColor(colorR, colorG, colorB, colorA)
    noteLabel:SetText("Note (optional):")

    local editBoxContainer = CreateFrame("Frame", nil, container, BackdropTemplateMixin and "BackdropTemplate")
    editBoxContainer:SetPoint("TOPLEFT", noteLabel, "BOTTOMLEFT", 0, -5)
    editBoxContainer:SetPoint("BOTTOMRIGHT", container, "BOTTOMRIGHT", -20, 49)
    editBoxContainer:SetBackdrop(
        {
            bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true,
            tileSize = 16,
            edgeSize = 16,
            insets = { left = 4, right = 3, top = 4, bottom = 3 }
        })
    editBoxContainer:SetBackdropColor(0, 0, 0, 0.9)

    local editbox = CreateFrame("EditBox", "NoteEditBox", container)
    editbox:SetPoint("TOPLEFT", editBoxContainer, "TOPLEFT", 5, -6)
    editbox:SetPoint("BOTTOMRIGHT", editBoxContainer, "BOTTOMRIGHT", 0, 0)
    editbox:SetFontObject("ChatFontNormal")
    editbox:SetMultiLine(true)
    editbox:SetAutoFocus(true)
    editbox:SetMaxLetters(112)
    editbox:SetScript("OnShow", function(this) editbox:SetFocus() end)
end

function PersonalPlayerBlacklist:PrintPlayers()
    if not self.db.global.blacklistedPlayers then return end
    for key, value in pairs(self.db.global.blacklistedPlayers) do
        local name = "";
        local server = "";
        local reason = "";
        if value["name"] then
            name = value["name"]
        end
        if value["server"] then
            server = value["server"]
        end
        if value["reason"] then
            reason = value["reason"]
        end
        print(key .. " : " .. name .. "-" .. server .. ":" .. reason);
    end
end

function PersonalPlayerBlacklist:GetShowPopup(info)
    return self.db.profile.ShowPopup;
end

function PersonalPlayerBlacklist:SetShowPopup(info, value)
    self.db.profile.ShowPopup = value;
end

function PersonalPlayerBlacklist:SavePlayer(playerName, playerServer)
    if not self.db.global.blacklistedPlayers then self.db.global.blacklistedPlayers = {} end
    if self.db.profile.ShowPopup then
        PersonalPlayerBlacklist:ShowBlacklistPopupWindow()
    else
        self.db.global.blacklistedPlayers[playerName .. "-" .. playerServer] = {
            ["name"] = playerName,
            ["server"] = playerServer,
            ["reason"] = ""
        }
    end
end

function PersonalPlayerBlacklist:RemovePlayer(name)
    if not self.db.global.blacklistedPlayers then self.db.global.blacklistedPlayers = {} end
    self.db.global.blacklistedPlayers[name] = nil;
end

function PersonalPlayerBlacklist:IsPlayerInList(name)
    if not self.db.global.blacklistedPlayers or not self.db.global.blacklistedPlayers[name] then
        return false
    else
        return true
    end
end

do
    local module = PersonalPlayerBlacklist:NewModule("UnitPopupMenus")
    module.enabled = false

    function module:HasMenu()
        return Menu and Menu.ModifyMenu
    end

    local function IsValidName(contextData)
        return contextData.name and strsub(contextData.name, 1, 1) ~= "|"
    end



    function module:MenuHandler(owner, rootDescription, contextData)
        if not IsValidName(contextData) then return end
        rootDescription:CreateDivider();
        rootDescription:CreateTitle(addon.addonTitle);
        local popupText = "";
        local notification = "";
        -- for key, value in pairs(contextData) do
        --      print(key..":"..tostring(value))
        -- end
        local realm = GetRealmName()
        if not contextData.server then contextData.server = realm end
        local playername = contextData.name .. "-" .. contextData.server;
        local isOnList = PersonalPlayerBlacklist:IsPlayerInList(playername);
        if not isOnList then
            popupText = "|cffFF0000Blacklist player|r"
            notification = "|cffFF0000" .. playername .. "|r added to blacklist.";
        else
            popupText = "|cFF00FF00Remove from blacklist|r"
            notification = "|cFF00FF00" .. playername .. "|r removed from blacklist.";
        end
        rootDescription:CreateButton(popupText, function()
            if not isOnList then
                PersonalPlayerBlacklist:SavePlayer(contextData.name, contextData.server);
            else
                PersonalPlayerBlacklist:RemovePlayer(playername)
            end
            print(notification);
            --PrintTableContents(contextData)
        end)
    end

    function module:AddItemsWithMenu()
        if not self:HasMenu() then return end

        -- Find via /run Menu.PrintOpenMenuTags()
        local menuTags = {
            ["MENU_UNIT_PLAYER"] = true,
            ["MENU_UNIT_ENEMY_PLAYER"] = true,
            ["MENU_UNIT_PARTY"] = true,
            ["MENU_UNIT_RAID_PLAYER"] = true,
            ["MENU_UNIT_FRIEND"] = true,
            ["MENU_UNIT_COMMUNITIES_GUILD_MEMBER"] = true,
            ["MENU_UNIT_COMMUNITIES_MEMBER"] = true,
            ["MENU_LFG_FRAME_SEARCH_ENTRY"] = true,
        }

        for tag, enabled in pairs(menuTags) do
            Menu.ModifyMenu(tag, GenerateClosure(self.MenuHandler, self))
        end
    end

    function module:Setup()
        if self:HasMenu() then
            self:AddItemsWithMenu()
        end
        self.enabled = true
    end

    function module:OnEnable()
        self:Setup()
    end
end
