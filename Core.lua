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

LibStub("AceConfig-3.0"):RegisterOptionsTable(addon.addonName, options, { "PPB", "ppb" })

function PersonalPlayerBlacklist:OnInitialize()
    self:RegisterChatCommand("personalplayerblacklist", "SlashCommand")
    self:RegisterChatCommand("ppb", "SlashCommand")
    self.db = LibStub("AceDB-3.0"):New("PersonalPlayerBlacklistDB")
    LibStub("AceConfig-3.0"):RegisterOptionsTable(addon.addonName, options)
    self.optionsFrame = LibStub("AceConfigDialog-3.0"):AddToBlizOptions(addon.addonName, addon.addonName)
end

function PersonalPlayerBlacklist:SlashCommand(msg)
    if not msg or msg:trim() == "" then
        -- https://github.com/Stanzilla/WoWUIBugs/issues/89
        Settings.OpenToCategory("PersonalPlayerBlacklist")
    else
        PersonalPlayerBlacklist:PrintPlayers()
    end
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
    self.db.global.blacklistedPlayers[playerName .. "-" .. playerServer] = { ["name"] = playerName, ["server"] =
    playerServer, ["reason"] = "" }
end

function PersonalPlayerBlacklist:RemovePlayer(name)
    if not self.db.global.blacklistedPlayers then self.db.global.blacklistedPlayers = {} end
    self.db.global.blacklistedPlayers[name] = nil;
end

function PersonalPlayerBlacklist:CheckPlayerInList(name)
    if not self.db.global.blacklistedPlayers or not self.db.global.blacklistedPlayers[name] then
        return false
    else
        return true
    end
end

do
    local module = PersonalPlayerBlacklist:NewModule("UnitPopupMenus")
    module.enabled = false


    local dropDownTypes = {
        ARENAENEMY = true,
        BN_FRIEND = true,
        CHAT_ROSTER = true,
        COMMUNITIES_GUILD_MEMBER = true,
        COMMUNITIES_WOW_MEMBER = true,
        FOCUS = true,
        FRIEND = true,
        GUILD = true,
        GUILD_OFFLINE = true,
        PARTY = true,
        PLAYER = true,
        RAID = true,
        RAID_PLAYER = true,
        SELF = true,
        TARGET = true,
        WORLD_STATE_SCORE = true
    }

    local function IsUnitDropDown(dropdown)
        return type(dropdown.which) == "string" and dropDownTypes[dropdown.which]
    end

    local function GetName(dropdown)
        local unit = dropdown.unit
        if _G.UnitExists(unit) and _G.UnitIsPlayer(unit) then
            return _G.GetUnitName(unit, true)
        end
        return nil
    end


    ---@type LibDropDownExtension
    local LibDropDownExtension = LibStub and LibStub:GetLibrary("LibDropDownExtension-1.0", true)

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
        local name, realm = UnitFullName("player")
        if not contextData.server then contextData.server = realm end
        local playername = contextData.name .. "-" .. contextData.server;
        local isOnList=PersonalPlayerBlacklist:CheckPlayerInList(playername);
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
