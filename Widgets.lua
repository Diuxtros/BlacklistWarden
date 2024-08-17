local AceGUI = LibStub("AceGUI-3.0")

function PersonalPlayerBlacklist:CreateStandardButton(text, width, parent)
    local button = {}
    button = AceGUI:Create("Button")
    button:SetText(text)
    button:SetWidth(width)
    button.frame:SetParent(parent)
    button.frame:Show()
    return button;
end

function PersonalPlayerBlacklist:CreateBlacklistWarningWindow()
    local container = PersonalPlayerBlacklist:CreateMainFrame("BlacklistWarningWindow", 280, 130)
    local frameConfig = PersonalPlayerBlacklist.db.profile.blacklistWarningFrame
    PersonalPlayerBlacklist:HandleFrameConfig(container, frameConfig)


    local savebutton = PersonalPlayerBlacklist:CreateStandardButton("Leave", 100, container)
    savebutton:SetCallback("OnClick", function(this)
        C_PartyInfo.LeaveParty()
        this.frame:GetParent():Hide()
    end)
    savebutton.frame:SetPoint("BOTTOM", container, "BOTTOM", -60, 20)

    local colorR, colorG, colorB, colorA = savebutton.frame:GetNormalFontObject():GetTextColor()


    local cancelbutton = PersonalPlayerBlacklist:CreateStandardButton("Stay", 100, container)
    cancelbutton:SetCallback("OnClick", function(this) this.frame:GetParent():Hide(); end)
    cancelbutton.frame:SetPoint("BOTTOM", container, "BOTTOM", 60, 20)



    local title = container:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOPLEFT", container, "TOPLEFT", 5, -10)
    title:SetPoint("BOTTOMRIGHT", container, "BOTTOMRIGHT", -5, 50)
    title:SetTextColor(colorR, colorG, colorB, colorA)

    container.title = title
    container:Hide()
    return container;
end

function PersonalPlayerBlacklist:CreateMainFrame(name, width, height)
    local container = CreateFrame("Frame", name, UIParent,
        BackdropTemplateMixin and "BackdropTemplate")
    container:SetFrameStrata("DIALOG")
    container:SetToplevel(true)
    container:SetWidth(width)
    container:SetHeight(height)
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
    container:SetBackdropColor(0, 0, 0, 0.7)
    container:SetMovable(true)
    container:RegisterForDrag("LeftButton")
    container:SetScript("OnDragStart",
        function(this, button)
            this:StartMoving()
        end)
    container:EnableMouse(true)
    return container
end

function PersonalPlayerBlacklist:HandleFrameConfig(container, frameConfig)
    container:SetPoint(frameConfig.point,
        frameConfig.relativeFrame,
        frameConfig.relativePoint,
        frameConfig.ofsx,
        frameConfig.ofsy)

    container:SetScript("OnDragStop",
        function(this)
            this:StopMovingOrSizing()
            local point, relativeFrame, relativeTo, ofsx, ofsy = container:GetPoint()
            frameConfig.point = point
            frameConfig.relativeFrame = relativeFrame
            frameConfig.relativePoint = relativeTo
            frameConfig.ofsx = ofsx
            frameConfig.ofsy = ofsy
        end)
end

function PersonalPlayerBlacklist:CreateBlacklistPopupWindow()
    local container = PersonalPlayerBlacklist:CreateMainFrame("BlacklistPopupWindow", 250, 200)
    local frameConfig = PersonalPlayerBlacklist.db.profile.blacklistPopupFrame
    PersonalPlayerBlacklist:HandleFrameConfig(container, frameConfig)


    local savebutton = PersonalPlayerBlacklist:CreateStandardButton("Save", 100, container)
    savebutton.frame:SetPoint("BOTTOM", container, "BOTTOM", -60, 15)
    savebutton:SetCallback("OnClick",
        function(this)
            PersonalPlayerBlacklist:SavePlayerInfoValue("notes", container.editbox:GetText())
            PersonalPlayerBlacklist:WritePlayerToDisk()
            this.frame:GetParent():Hide()
        end)

    local colorR, colorG, colorB, colorA = savebutton.frame:GetNormalFontObject():GetTextColor()

    local cancelbutton = PersonalPlayerBlacklist:CreateStandardButton("Cancel", 100, container)
    cancelbutton.frame:SetPoint("BOTTOM", container, "BOTTOM", 60, 15)
    cancelbutton:SetCallback("OnClick", function(this) this.frame:GetParent():Hide(); end)

    local titleBg = CreateFrame("Frame", "titleBG", container,
        BackdropTemplateMixin and "BackdropTemplate")
    titleBg:SetWidth(150)
    titleBg:SetHeight(30)
    titleBg:SetBackdrop(
        {
            bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
            tile = true,
            tileSize = 32,
            edgeSize = 15,
            insets = { left = 2, right = 2, top = 2, bottom = 2 }
        })
    titleBg:SetBackdropColor(0, 0, 0, 1)
    titleBg:SetPoint("TOP", container, "TOP", 0, 13)

    local title = titleBg:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("CENTER", titleBg, "CENTER", 0, 0)
    title:SetText("Add to Blacklist")
    title:SetTextColor(colorR, colorG, colorB, colorA)

    local playerName = container:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    playerName:SetPoint("TOP", container, "TOP", 0, -20)
    playerName:SetTextColor(216, 0, 0, 1)

    container.playerName = playerName;

    local drop = {}
    drop = AceGUI:Create("Dropdown")
    drop:SetList(PersonalPlayerBlacklist.db.global.blacklistPopupWindowOptions)
    drop:SetWidth(208)
    drop:SetValue(1)
    drop:SetLabel("Reason:")
    drop:SetCallback("OnValueChanged", function(this, event, item)
        PersonalPlayerBlacklist:SavePlayerInfoValue("reason",
            PersonalPlayerBlacklist.db.global.blacklistPopupWindowOptions[item])
    end
    )
    drop.frame:SetParent(container)
    drop.frame:Show()
    drop.frame:SetPoint("LEFT", container, "TOPLEFT", 20, -50)

    container.dropdown = drop;
    local noteLabel = container:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    noteLabel:SetPoint("LEFT", drop.frame, "LEFT", 0, -30)
    noteLabel:SetTextColor(colorR, colorG, colorB, colorA)
    noteLabel:SetText("Note (optional):")

    local editBoxContainer = CreateFrame("Frame", nil, container, BackdropTemplateMixin and "BackdropTemplate")
    editBoxContainer:SetPoint("TOPLEFT", noteLabel, "BOTTOMLEFT", 0, -1)
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
    editBoxContainer:SetBackdropColor(0, 0, 0, 0.6)

    local editbox = CreateFrame("EditBox", "NoteEditBox", container)
    editbox:SetPoint("TOPLEFT", editBoxContainer, "TOPLEFT", 5, -8)
    editbox:SetPoint("BOTTOMRIGHT", editBoxContainer, "BOTTOMRIGHT", -5, 0)
    editbox:SetFontObject("ChatFontSmall")
    editbox:SetMultiLine(true)
    editbox:SetAutoFocus(false)
    editbox:SetMaxLetters(140)
    --editbox:SetScript("OnShow", function(this) editbox:SetFocus() end)
    container.editbox = editbox;
    container:Hide()

    return container;
end
local  FilterScrollButtons = {}
function PersonalPlayerBlacklist:CreateListFrame()
    local container = PersonalPlayerBlacklist:CreateMainFrame("ListWindow", 800, 500)
    local frameConfig = PersonalPlayerBlacklist.db.profile.listFrame
    PersonalPlayerBlacklist:HandleFrameConfig(container, frameConfig)

    local heading = {}
    heading = AceGUI:Create("Heading")
    heading:SetText("List")
    heading:SetWidth(container:GetWidth() - 5)
    heading.frame:SetParent(container)
    heading.frame:SetPoint("TOP", container, "TOP", 0, -10)
    heading.frame:Show()

    local closebutton = PersonalPlayerBlacklist:CreateStandardButton("Close", 80, container)
    closebutton.frame:SetPoint("BOTTOMRIGHT", container, "BOTTOMRIGHT", -10, 10)
    closebutton:SetHeight(20)
    closebutton:SetCallback("OnClick",
        function(this)
            this.frame:GetParent():Hide()
        end)

    local tabs = {
        { value = 1, text = "Players" },
        --{value=2,text="Guilds"},
        -- {value=3,text="Realms"},
    }
    local scrollcontainer = AceGUI:Create("TabGroup")
    scrollcontainer:SetTitle("Test")
    scrollcontainer:SetTabs(tabs)
    scrollcontainer:SetLayout("Fill")
    scrollcontainer.frame:SetParent(container)
    scrollcontainer.frame:Show()
    scrollcontainer:SetPoint("TOPLEFT", container, "TOPLEFT", 10, -30)
    scrollcontainer:SetPoint("BOTTOMRIGHT", container, "BOTTOMRIGHT", -10, 30)
    scrollcontainer:SelectTab(1)




    local scroll = AceGUI:Create("ScrollFrame")
    scroll:SetLayout("List") -- probably?
    scrollcontainer:AddChild(scroll)
    scroll.frame:Show()


    
    FilterScrollButtons = {}
    --PersonalPlayerBlacklist:CreateTableButton(scrollcontainer.frame,1);
    local index = 2
    for key, value in pairs(PersonalPlayerBlacklist.db.global.blacklistedPlayers) do
        local group= AceGUI:Create("Icon")
        PersonalPlayerBlacklist:CreateTableButton(group.frame,index,value);
        scroll:AddChild( group)
        group:SetImageSize(1, 10) 
        group.frame:Show()
        index = index + 1
    end
end

function PersonalPlayerBlacklist:CreateTableLabel(text, parent, width)
    local label = AceGUI:Create("InteractiveLabel")
    label:SetText(text)
    label:SetWidth(width)
    label:SetHeight(20)
    label:SetHighlight("Interface\\Buttons\\UI-Panel-MinimizeButton-Highlight")
    parent:AddChild(label)
end

function PersonalPlayerBlacklist:CreateTableButton(parent, index,player)

    if not player then 

        player={}
        player["name"]="Name"
        player["server"]="Server"
        player["class"]="Class"
        player["reason"]="Reason"
        player["notes"]="Notes"
        player["date"]="Date"
    end
    FilterScrollButtons[index] = CreateFrame("Button", nil, parent, "IgnoreListButtonTemplate")

    if index == 1 then
        FilterScrollButtons[index]:SetPoint("TOPLEFT", parent, -1, 0)
    else
        FilterScrollButtons[index]:SetPoint("TOPLEFT", parent, -1, 0)
    end

    FilterScrollButtons[index]:SetSize(800, 20)
    FilterScrollButtons[index]:RegisterForClicks("LeftButtonUp")
    --FilterScrollButtons[index]:SetScript("OnClick", FilterScrollClick)

    -- set name style
    FilterScrollButtons[index].name:SetWidth(100)
    FilterScrollButtons[index].name:SetText(player["name"])
    -- set active style
    FilterScrollButtons[index].realm = FilterScrollButtons[index]:CreateFontString("FontString", "OVERLAY",
        "GameFontHighlight")
    FilterScrollButtons[index].realm:SetPoint("LEFT", FilterScrollButtons[index].name, "RIGHT", 10, 0)
    FilterScrollButtons[index].realm:SetWidth(100)
    FilterScrollButtons[index].realm:SetJustifyH("LEFT")
    FilterScrollButtons[index].realm:SetText(player["server"])
    -- create blocked style
    FilterScrollButtons[index].class = FilterScrollButtons[index]:CreateFontString("FontString", "OVERLAY",
        "GameFontHighlight")
    FilterScrollButtons[index].class:SetPoint("LEFT", FilterScrollButtons[index].realm, "RIGHT", 6, 0)
    FilterScrollButtons[index].class:SetWidth(100)
    FilterScrollButtons[index].class:SetJustifyH("LEFT")
    --FilterScrollButtons[index].class:SetWordWrap(false)
    FilterScrollButtons[index].class:SetText(player["class"])

    FilterScrollButtons[index].reason = FilterScrollButtons[index]:CreateFontString("FontString", "OVERLAY",
        "GameFontHighlight")
    FilterScrollButtons[index].reason:SetPoint("LEFT", FilterScrollButtons[index].class, "RIGHT", 10, 0)
    FilterScrollButtons[index].reason:SetWidth(70)
    FilterScrollButtons[index].reason:SetJustifyH("LEFT")
    FilterScrollButtons[index].reason:SetText(player["reason"])



FilterScrollButtons[index].date = FilterScrollButtons[index]:CreateFontString("FontString", "OVERLAY",
"GameFontHighlight")
FilterScrollButtons[index].date:SetPoint("LEFT", FilterScrollButtons[index].reason, "RIGHT", 10, 0)
FilterScrollButtons[index].date:SetWidth(70)
FilterScrollButtons[index].date:SetJustifyH("LEFT")
FilterScrollButtons[index].date:SetText(player["date"])

FilterScrollButtons[index].notes = FilterScrollButtons[index]:CreateFontString("FontString", "OVERLAY",
"GameFontHighlight")
FilterScrollButtons[index].notes:SetPoint("LEFT", FilterScrollButtons[index].date, "RIGHT",10, 0)
FilterScrollButtons[index].notes:SetWidth(240)
FilterScrollButtons[index].notes:SetJustifyH("LEFT")
FilterScrollButtons[index].notes:SetText(player["notes"])
    -- create filter style

end
