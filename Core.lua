local _G = getfenv(0)
local ADDON_NAME, addon = ...
addon.addonName = "PersonalPlayerBlacklist"
addon.addonTitle = "Personal Player Blacklist"
PersonalPlayerBlacklist = LibStub("AceAddon-3.0"):NewAddon(addon.addonName, "AceConsole-3.0", "AceHook-3.0",
    "AceEvent-3.0", "AceTimer-3.0")
local LDB = LibStub("LibDataBroker-1.1"):NewDataObject("PersonalPlayerBlacklist", {
    type = "data source",
    text = "PPB",
    icon = "Interface\\Icons\\INV_Chest_Cloth_17",
    OnClick = function() Settings.OpenToCategory("PersonalPlayerBlacklist") end,
})
local icon = LibStub("LibDBIcon-1.0")
PersonalPlayerBlacklist:RegisterChatCommand("rl", "Reload")

function PersonalPlayerBlacklist:Reload()
    ReloadUI();
end

local options = {
    name = "Personal Player Blacklist",
    handler = PersonalPlayerBlacklist,
    type = 'group',
    args = {
        headerGeneralOptions = {
            order = 0,
            type = "header",
            name = "General Options",
        },
        blacklistPopup = {
            type = 'toggle',
            name = 'Detail popup',
            desc = 'Shows a popup when blacklisting a player that allows you to write extra details.',
            set = "SetShowPopup",
            get = "GetShowPopup",
        },
        minimapIcon = {
            type = 'toggle',
            name = 'Minimap icon',
            desc = 'Toggles the minimap icon.',
            set = "SetShowIcon",
            get = "GetShowIcon",
        },
    },
}

local defaults = {
    global = {
        blacklistedPlayers = {},
        previousGroupSize = 0,
        blacklistPopupWindowOptions = {
            "All",
            "Bad player",
            "Quitter",
            "AFKer",
            "Toxic",
            "Scammer",
            "Bigot",
            "Other"
        }
    },
    profile = {
        showPopup = true,
        minimap = {
            hide = false,
        },
        blacklistPopupFrame = {
            point = "TOP",
            relativeFrame = nil,
            relativePoint = "TOP",
            ofsx = 0,
            ofsy = -50,
        },
        blacklistWarningFrame = {
            point = "TOP",
            relativeFrame = nil,
            relativePoint = "TOP",
            ofsx = 0,
            ofsy = -100,
        },
        listFrame = {
            point = "CENTER",
            relativeFrame = nil,
            relativePoint = "CENTER",
            ofsx = 0,
            ofsy = 0,
        },
    }
}


LibStub("AceConfig-3.0"):RegisterOptionsTable(addon.addonName, options, { "PPB", "ppb" })

local aceDialog = LibStub("AceConfigDialog-3.0");

local blacklistPopupWindow = nil;
local blacklistPopupWarning = nil;
local playerInfo = {}
function PersonalPlayerBlacklist:OnInitialize()
    self:RegisterChatCommand("personalplayerblacklist", "SlashCommand")
    self:RegisterChatCommand("ppb", "SlashCommand")
    self.db = LibStub("AceDB-3.0"):New("PersonalPlayerBlacklistDB", defaults)
    LibStub("AceConfig-3.0"):RegisterOptionsTable(addon.addonName, options)
    self.optionsFrame = aceDialog:AddToBlizOptions(addon.addonName, addon.addonName)
    self:RegisterEvent("GROUP_ROSTER_UPDATE", "CheckPlayersOnGroupUpdate");
    icon:Register("PersonalPlayerBlacklist", LDB, PersonalPlayerBlacklist.db.profile.minimap)
end

function PersonalPlayerBlacklist:OnEnable()
    blacklistPopupWindow = PersonalPlayerBlacklist:CreateBlacklistPopupWindow();
    blacklistPopupWarning = PersonalPlayerBlacklist:CreateBlacklistWarningWindow();
end

function PersonalPlayerBlacklist:CheckPlayersOnGroupUpdate()
    local groupCount = GetNumGroupMembers()
    local name, realm;
    if groupCount > PersonalPlayerBlacklist.db.global.previousGroupSize then
        for i = 1, groupCount do
            if groupCount < 6 then
                name, realm = UnitName("party" .. i)
            else
                name, realm = UnitName("raid" .. i)
            end
            if not realm then realm = GetRealmName() end
            if name and realm then
                local fullname = name .. "-" .. realm;
                if PersonalPlayerBlacklist:IsPlayerInList(fullname) then
                    blacklistPopupWarning.title:SetText("The following player is in your blacklist:\n\n |cffd80000" ..
                        fullname ..
                        "|r\n\nReason: " .. PersonalPlayerBlacklist.db.global.blacklistedPlayers[fullname]["reason"])
                    blacklistPopupWarning:Show()
                end
            end
        end
    end
    PersonalPlayerBlacklist.db.global.previousGroupSize = groupCount;
end

function PersonalPlayerBlacklist:SlashCommand(msg)
    if not msg or msg:trim() == "" then
        Settings.OpenToCategory("PersonalPlayerBlacklist")
    else
        PersonalPlayerBlacklist:CreateListFrame()
    end
end

function PersonalPlayerBlacklist:PrintPlayers()
    if not PersonalPlayerBlacklist.db.global.blacklistedPlayers then return end
    for key, value in pairs(PersonalPlayerBlacklist.db.global.blacklistedPlayers) do
        local name = "";
        local server = "";
        local class = "";
        local reason = "";
        local note = "";
        local date = "";
        if value["name"] then
            name = value["name"]
        end
        if value["server"] then
            server = value["server"]
        end
        if value["class"] then
            class = value["class"]
        end
        if value["reason"] then
            reason = value["reason"]
        end
        if value["notes"] then
            note = value["notes"]
        end
        if value["date"] then
            date = value["date"]
        end
        print(key .. " : " .. name .. " - " .. server .. " - " .. class ..
            " - " .. reason .. " - " .. note .. " - " .. date);
    end
end

function PersonalPlayerBlacklist:GetShowPopup(info)
    return PersonalPlayerBlacklist.db.profile.showPopup;
end

function PersonalPlayerBlacklist:SetShowPopup(info, value)
    PersonalPlayerBlacklist.db.profile.showPopup = value;
end

function PersonalPlayerBlacklist:GetShowIcon(info)
    return not PersonalPlayerBlacklist.db.profile.minimap.hide;
end

function PersonalPlayerBlacklist:SetShowIcon(info, value)
    value = not value
    PersonalPlayerBlacklist.db.profile.minimap.hide = value;
    if value then
        icon:Hide("PersonalPlayerBlacklist")
    else
        icon:Show("PersonalPlayerBlacklist")
    end
end

function PersonalPlayerBlacklist:SavePlayerInfoValue(key, value)
    playerInfo[key] = value;
end

function PersonalPlayerBlacklist:WritePlayerToDisk()
    PersonalPlayerBlacklist.db.global.blacklistedPlayers[playerInfo["playerName"] .. "-" .. playerInfo["playerServer"]] = {
        ["name"] = playerInfo["playerName"],
        ["server"] = playerInfo["playerServer"],
        ["class"] = playerInfo["playerClass"],
        ["reason"] = playerInfo["reason"],
        ["notes"] = playerInfo["notes"],
        ["date"] = date("%m/%d/%y"),
    }
    print("|cffFF0000" .. playerInfo["playerName"] .. "-" .. playerInfo["playerServer"] .. "|r added to blacklist.")
    playerInfo = {}
end

function PersonalPlayerBlacklist:BlacklistButton()
    if PersonalPlayerBlacklist.db.profile.showPopup then
        blacklistPopupWindow.playerName:SetText(playerInfo["playerName"] .. "-" .. playerInfo["playerServer"])
        blacklistPopupWindow.dropdown:SetValue(1)
        PersonalPlayerBlacklist:SavePlayerInfoValue("reason",
        PersonalPlayerBlacklist.db.global.blacklistPopupWindowOptions[1])
        blacklistPopupWindow.editbox:SetText("")
        blacklistPopupWindow:Show()
    else
        PersonalPlayerBlacklist:SavePlayerInfoValue("reason",
            PersonalPlayerBlacklist.db.global.blacklistPopupWindowOptions[1])
        PersonalPlayerBlacklist:SavePlayerInfoValue("notes", "")
        PersonalPlayerBlacklist:WritePlayerToDisk();
    end
end

function PersonalPlayerBlacklist:RemovePlayer(name)
    if not PersonalPlayerBlacklist.db.global.blacklistedPlayers then PersonalPlayerBlacklist.db.global.blacklistedPlayers = {} end
    PersonalPlayerBlacklist.db.global.blacklistedPlayers[name] = nil;
end

function PersonalPlayerBlacklist:IsPlayerInList(name)
    if not PersonalPlayerBlacklist.db.global.blacklistedPlayers or not PersonalPlayerBlacklist.db.global.blacklistedPlayers[name] then
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
        local realm;
        local name;
        local localizedClass;
        local _;
        if not contextData then
            if rootDescription.tag == "MENU_LFG_FRAME_SEARCH_ENTRY" or rootDescription.tag == "MENU_LFG_FRAME_MEMBER_APPLY" then
                name, realm, localizedClass= self:GetLFGInfo(owner)
            end
        else
            if not IsValidName(contextData) then return end
            if not contextData.server then
                realm = GetRealmName()
            else
                realm = contextData.server
            end
            name = contextData.name
            local guid

            if contextData.lineID then
                guid = C_ChatInfo.GetChatLineSenderGUID(contextData.lineID)
            elseif contextData.unit then
                guid = UnitGUID(contextData.unit)
            else
                return
            end
    
            localizedClass, _, _, _, _, _ = GetPlayerInfoByGUID(guid)
        end



        local popupText = "";


        PersonalPlayerBlacklist:SavePlayerInfoValue("playerServer", realm)
        PersonalPlayerBlacklist:SavePlayerInfoValue("playerName", name)
        local fullName = playerInfo["playerName"] .. "-" .. playerInfo["playerServer"]
        local isOnList = PersonalPlayerBlacklist:IsPlayerInList(fullName);
        local playername = UnitName("player")
        if fullName == playername .. "-" .. realm then return end

        PersonalPlayerBlacklist:SavePlayerInfoValue("playerClass", localizedClass)
        if not isOnList then
            popupText = "|cffd80000Blacklist player|r"
        else
            popupText = "|cFF00FF00Remove from blacklist|r"
        end

        rootDescription:CreateDivider();
        rootDescription:CreateTitle(addon.addonTitle);
        rootDescription:CreateButton(popupText, function()
            if not isOnList then
                PersonalPlayerBlacklist:BlacklistButton()
            else
                PersonalPlayerBlacklist:RemovePlayer(fullName)
                print("|cFF00FF00" .. fullName .. "|r removed from blacklist.")
            end
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
            ["MENU_LFG_FRAME_MEMBER_APPLY"] = true,
        }

        for tag, enabled in pairs(menuTags) do
            Menu.ModifyMenu(tag, GenerateClosure(self.MenuHandler, self))
        end
    end

    function module:GetLFGInfo(owner)
        local resultID = owner.resultID
        if resultID then
            local searchResultInfo = C_LFGList.GetSearchResultInfo(resultID)
            local name, realm = self:FormatName(searchResultInfo.leaderName)
            local _, localizedClass, isLeader
            for i = 1, searchResultInfo.numMembers do
                _, _, localizedClass, _, isLeader = C_LFGList.GetSearchResultMemberInfo(resultID, i)
                if isLeader then
                    break
                end
            end
            return name, realm, localizedClass
        end
        local memberIdx = owner.memberIdx
        if not memberIdx then
            return
        end
        local parent = owner:GetParent()
        if not parent then
            return
        end
        local applicantID = parent.applicantID
        if not applicantID then
            return
        end
        local fullName, class, localizedClass = C_LFGList.GetApplicantMemberInfo(applicantID, memberIdx)
        local name, realm = self:FormatName(fullName)

        return name, realm, localizedClass
    end

    function module:FormatName(fullname)
        local name, realm
        if fullname:find("-", nil, true) then
            name, realm = strsplit("-", fullname)
        else
            name = fullname
        end
        if not realm or realm == "" then
            realm = GetRealmName()
        end

        return name, realm
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
