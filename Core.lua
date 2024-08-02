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
    local container = CreateFrame("Frame", "BlacklistPopupWindow", _UIParent, BackdropTemplateMixin and "BackdropTemplate")
	container:SetFrameStrata("DIALOG")
	container:SetToplevel(true)
	container:SetWidth(250)
	container:SetHeight(150)
	container:SetPoint("CENTER", UIParent)
	container:SetBackdrop(
		{bgFile="Interface\\ChatFrame\\ChatFrameBackground",
	    edgeFile="Interface\\DialogFrame\\UI-DialogBox-Border", tile=true,
		tileSize=32, edgeSize=32, insets={left=11, right=12, top=12, bottom=11}})
    container:SetBackdropColor(0,0,0,1)

	local savebutton = CreateFrame("Button", nil, container, "UIPanelButtonTemplate")
	savebutton:SetText("Save")
	savebutton:SetWidth(100)
	savebutton:SetHeight(20)
	savebutton:SetPoint("BOTTOM", container, "BOTTOM", -60, 20)
	savebutton:SetScript("OnClick",
	    function(this)
	        this:GetParent():Hide()
	    end)

	local cancelbutton = CreateFrame("Button", nil, container, "UIPanelButtonTemplate")
	cancelbutton:SetText("Cancel")
	cancelbutton:SetWidth(100)
	cancelbutton:SetHeight(20)
	cancelbutton:SetPoint("BOTTOM", container, "BOTTOM", 60, 20)
	cancelbutton:SetScript("OnClick", function(this) this:GetParent():Hide(); end)


    local title = container:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    title:SetPoint("TOP", container, "TOP", 0, -20)
    title:SetText("Add to blacklist")

    local dropdownLabel = container:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	dropdownLabel:SetPoint("LEFT", container, "LEFT", 20, 0)
	dropdownLabel:SetTextColor(1.0,1.0,1.0,1)
    dropdownLabel:SetText("Reason:")
    
    local dropdown = CreateFrame("Button", "ReasonDropDown", container, "UIDropDownMenuTemplate")
    dropdown:ClearAllPoints()
    dropdown:SetPoint("TOPLEFT", dropdownLabel, "TOPRIGHT", 7, 5)
    dropdown:Show()
    UIDropDownMenu_Initialize(dropdown, function(self, level)
        local info = nil
        for i = 1,#BlacklistPopupWindowOptions, 1 do
            info = UIDropDownMenu_CreateInfo()
            info.text = BlacklistPopupWindowOptions[i]
            info.value = i
            info.func = function(self)
                UIDropDownMenu_SetSelectedValue(dropdown, self.value)
            end
            UIDropDownMenu_AddButton(info, level)
        end
    end)
    UIDropDownMenu_SetWidth(dropdown, 100);
    UIDropDownMenu_SetButtonWidth(dropdown, 124)
    UIDropDownMenu_SetSelectedValue(dropdown, 0)
    UIDropDownMenu_JustifyText(dropdown, "LEFT")
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
    self.db.global.blacklistedPlayers[playerName .. "-" .. playerServer] = {
        ["name"] = playerName,
        ["server"] =
            playerServer,
        ["reason"] = ""
    }
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
