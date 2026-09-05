--File that handles the frames

-- lib
local AceGUI = LibStub("AceGUI-3.0")

-- rgb class colors
local classColor = {
    ["WARRIOR"] = { 0.78, 0.61, 0.43 },
    ["PALADIN"] = { 0.96, 0.55, 0.73 },
    ["HUNTER"] = { 0.67, 0.83, 0.45 },
    ["ROGUE"] = { 1.00, 0.96, 0.41 },
    ["PRIEST"] = { 1, 1, 1 },
    ["SHAMAN"] = { 0.00, 0.44, 0.87 },
    ["MAGE"] = { 0.25, 0.78, 0.92 },
    ["WARLOCK"] = { 0.53, 0.53, 0.93 },
    ["MONK"] = { 0.00, 1.00, 0.59 },
    ["DRUID"] = { 1.00, 0.49, 0.04 },
    ["DEMONHUNTER"] = { 0.64, 0.19, 0.79 },
    ["DEATHKNIGHT"] = { 0.77, 0.12, 0.23 },
    ["EVOKER"] = { 0.20, 0.58, 0.50 },
}

-- class names to display
local className = {
    ["WARRIOR"] = "Warrior",
    ["PALADIN"] = "Paladin",
    ["HUNTER"] = "Hunter",
    ["ROGUE"] = "Rogue",
    ["PRIEST"] = "Priest",
    ["SHAMAN"] = "Shaman",
    ["MAGE"] = "Mage",
    ["WARLOCK"] = "Warlock",
    ["MONK"] = "Monk",
    ["DRUID"] = "Druid",
    ["DEMONHUNTER"] = "Demon Hunter",
    ["DEATHKNIGHT"] = "Death Knight",
    ["EVOKER"] = "Evoker",
}

-- Safely turns a saved player's class field into a valid classColor/className
-- key, tolerating a missing or unrecognized value
local DEFAULT_CLASS = "WARRIOR"
function BlacklistWarden:NormalizeClass(player)
    local raw = player and player["class"]
    if type(raw) ~= "string" then
        return DEFAULT_CLASS
    end
    local class = string.upper(raw:gsub("%s+", ""))
    if not classColor[class] then
        return DEFAULT_CLASS
    end
    return class
end

-- Color palette 
local Colors = {
    panelBg      = { 0.05, 0.05, 0.08, 0.96 },
    panelBorder  = { 0.80, 0.65, 0.22, 1 },
    headerBg     = { 0.09, 0.09, 0.12, 1 },
    inputBg      = { 0.03, 0.03, 0.05, 0.9 },
    tabGroupBg   = { 0.05, 0.05, 0.08, 0.4  },
    accent       = { 0.90, 0.75, 0.35, 1 },
    accentDim    = { 0.80, 0.65, 0.22, 0.55 },
    text         = { 0.92, 0.92, 0.95, 1 },
    textDim      = { 0.68, 0.68, 0.72, 1 },
    danger       = { 0.92, 0.38, 0.38, 1 },
    success      = { 0.36, 0.80, 0.58, 1 },
    rowBaseA     = { 1, 1, 1, 0.015 },
    rowBaseB     = { 0, 0, 0, 0.10 },
    rowHighlight = { 0.90, 0.75, 0.35, 0.10 },
}

-- Hides a button's default art.
local function StripButtonArt(frame)
    local normalTex = frame.GetNormalTexture and frame:GetNormalTexture()
    if normalTex then
        normalTex:SetTexture(nil)
        normalTex:SetAlpha(0)
    end
    local pushedTex = frame.GetPushedTexture and frame:GetPushedTexture()
    if pushedTex then
        pushedTex:SetTexture(nil)
        pushedTex:SetAlpha(0)
    end
    local disabledTex = frame.GetDisabledTexture and frame:GetDisabledTexture()
    if disabledTex then
        disabledTex:SetTexture(nil)
        disabledTex:SetAlpha(0)
    end

    local function StripRegionsOf(owner)
        for _, region in ipairs({ owner:GetRegions() }) do
            if region.GetObjectType and region:GetObjectType() == "Texture" and region ~= normalTex
                and region ~= pushedTex and region ~= disabledTex and region.flatSkinPart == nil then
                region:SetTexture(nil)
            end
        end
    end

    StripRegionsOf(frame)
    for _, child in ipairs({ frame:GetChildren() }) do
        StripRegionsOf(child)
    end
end

-- Strips the legacy grey 3-slice Blizzard button art from an AceGUI 
function BlacklistWarden:SkinFlatButton(button)
    if button.skinned then return end
    button.skinned = true

    local frame = button.frame

    StripButtonArt(frame)
    if C_Timer and C_Timer.After then
        C_Timer.After(0, function() StripButtonArt(frame) end)
    end
    frame:HookScript("OnShow", function() StripButtonArt(frame) end)
    frame:HookScript("OnMouseDown", function() StripButtonArt(frame) end)
    frame:HookScript("OnMouseUp", function() StripButtonArt(frame) end)
    frame:HookScript("OnClick", function() StripButtonArt(frame) end)

    local bg = frame:CreateTexture(nil, "BACKGROUND")
    bg:SetPoint("TOPLEFT", 1, -1)
    bg:SetPoint("BOTTOMRIGHT", -1, 1)
    bg:SetColorTexture(unpack(Colors.headerBg))
    bg.flatSkinPart = true
    button.skinBg = bg

    local top = frame:CreateTexture(nil, "BORDER")
    top:SetColorTexture(unpack(Colors.accentDim))
    top:SetPoint("TOPLEFT")
    top:SetPoint("TOPRIGHT")
    top:SetHeight(1)
    top.flatSkinPart = true

    local bottom = frame:CreateTexture(nil, "BORDER")
    bottom:SetColorTexture(unpack(Colors.accentDim))
    bottom:SetPoint("BOTTOMLEFT")
    bottom:SetPoint("BOTTOMRIGHT")
    bottom:SetHeight(1)
    bottom.flatSkinPart = true

    local left = frame:CreateTexture(nil, "BORDER")
    left:SetColorTexture(unpack(Colors.accentDim))
    left:SetPoint("TOPLEFT")
    left:SetPoint("BOTTOMLEFT")
    left:SetWidth(1)
    left.flatSkinPart = true

    local right = frame:CreateTexture(nil, "BORDER")
    right:SetColorTexture(unpack(Colors.accentDim))
    right:SetPoint("TOPRIGHT")
    right:SetPoint("BOTTOMRIGHT")
    right:SetWidth(1)
    right.flatSkinPart = true

    frame:SetHighlightTexture("Interface\\Buttons\\WHITE8x8")
    local highlight = frame:GetHighlightTexture()
    if highlight then
        highlight:SetVertexColor(unpack(Colors.rowHighlight))
        highlight:ClearAllPoints()
        highlight:SetPoint("TOPLEFT", 1, -1)
        highlight:SetPoint("BOTTOMRIGHT", -1, 1)
        highlight.flatSkinPart = true
    end

    frame:HookScript("OnMouseDown", function()
        bg:SetColorTexture(0.03, 0.03, 0.05, 1)
    end)
    frame:HookScript("OnMouseUp", function()
        bg:SetColorTexture(unpack(Colors.headerBg))
    end)

    if button.text then
        button.text:SetTextColor(unpack(Colors.text))
    end
end

-- Strips the legacy stone-textured checkbox art from an AceGUI
function BlacklistWarden:SkinFlatCheckbox(checkbox, boxSize)
    if checkbox.skinned then return end
    checkbox.skinned = true
    boxSize = boxSize or 24

    local frame = checkbox.frame
    local checkbg = checkbox.checkbg
    local check = checkbox.check

    if checkbg then
        checkbg:SetTexture(nil)
        checkbg:SetColorTexture(unpack(Colors.inputBg))
        checkbg:SetSize(boxSize, boxSize)

        local top = frame:CreateTexture(nil, "ARTWORK", nil, 1)
        top:SetColorTexture(unpack(Colors.accentDim))
        top:SetPoint("TOPLEFT", checkbg, "TOPLEFT")
        top:SetPoint("TOPRIGHT", checkbg, "TOPRIGHT")
        top:SetHeight(1)

        local bottom = frame:CreateTexture(nil, "ARTWORK", nil, 1)
        bottom:SetColorTexture(unpack(Colors.accentDim))
        bottom:SetPoint("BOTTOMLEFT", checkbg, "BOTTOMLEFT")
        bottom:SetPoint("BOTTOMRIGHT", checkbg, "BOTTOMRIGHT")
        bottom:SetHeight(1)

        local left = frame:CreateTexture(nil, "ARTWORK", nil, 1)
        left:SetColorTexture(unpack(Colors.accentDim))
        left:SetPoint("TOPLEFT", checkbg, "TOPLEFT")
        left:SetPoint("BOTTOMLEFT", checkbg, "BOTTOMLEFT")
        left:SetWidth(1)

        local right = frame:CreateTexture(nil, "ARTWORK", nil, 1)
        right:SetColorTexture(unpack(Colors.accentDim))
        right:SetPoint("TOPRIGHT", checkbg, "TOPRIGHT")
        right:SetPoint("BOTTOMRIGHT", checkbg, "BOTTOMRIGHT")
        right:SetWidth(1)
    end

    if check then
        local inset = boxSize >= 18 and 3 or 2
        check:SetTexture(nil)
        check:SetColorTexture(unpack(Colors.accent))
        check:ClearAllPoints()
        check:SetPoint("TOPLEFT", checkbg, "TOPLEFT", inset, -inset)
        check:SetPoint("BOTTOMRIGHT", checkbg, "BOTTOMRIGHT", -inset, inset)
    end

    if checkbox.highlight then
        checkbox.highlight:SetTexture(nil)
        checkbox.highlight:SetColorTexture(unpack(Colors.rowHighlight))
    end

    if checkbox.text then
        checkbox.text:SetTextColor(unpack(Colors.text))
    end

    if frame then
        frame:SetHeight(math.max(boxSize, 14))
    end
end

-- Strips all texture regions from a Blizzard template-driven frame 
local function ApplyFlatPanel(frame, insetL, insetT, insetR, insetB)
    insetL, insetT, insetR, insetB = insetL or 0, insetT or 0, insetR or 0, insetB or 0
    for _, region in ipairs({ frame:GetRegions() }) do
        if region.GetObjectType and region:GetObjectType() == "Texture" then
            region:SetTexture(nil)
        end
    end

    local bg = frame:CreateTexture(nil, "BACKGROUND")
    bg:SetPoint("TOPLEFT", insetL, -insetT)
    bg:SetPoint("BOTTOMRIGHT", -insetR, insetB)
    bg:SetColorTexture(unpack(Colors.inputBg))

    local top = frame:CreateTexture(nil, "BORDER")
    top:SetColorTexture(unpack(Colors.accentDim))
    top:SetPoint("TOPLEFT", bg, "TOPLEFT")
    top:SetPoint("TOPRIGHT", bg, "TOPRIGHT")
    top:SetHeight(1)

    local bottom = frame:CreateTexture(nil, "BORDER")
    bottom:SetColorTexture(unpack(Colors.accentDim))
    bottom:SetPoint("BOTTOMLEFT", bg, "BOTTOMLEFT")
    bottom:SetPoint("BOTTOMRIGHT", bg, "BOTTOMRIGHT")
    bottom:SetHeight(1)

    local left = frame:CreateTexture(nil, "BORDER")
    left:SetColorTexture(unpack(Colors.accentDim))
    left:SetPoint("TOPLEFT", bg, "TOPLEFT")
    left:SetPoint("BOTTOMLEFT", bg, "BOTTOMLEFT")
    left:SetWidth(1)

    local right = frame:CreateTexture(nil, "BORDER")
    right:SetColorTexture(unpack(Colors.accentDim))
    right:SetPoint("TOPRIGHT", bg, "TOPRIGHT")
    right:SetPoint("BOTTOMRIGHT", bg, "BOTTOMRIGHT")
    right:SetWidth(1)

    return bg
end

-- Reskins an AceGUI Dropdown
function BlacklistWarden:SkinFlatDropdown(dropdown)
    if dropdown.skinned then return end
    dropdown.skinned = true

    if dropdown.dropdown then
        ApplyFlatPanel(dropdown.dropdown, 17, 3, 16, 3)
    end

    if dropdown.text then
        dropdown.text:SetTextColor(unpack(Colors.text))
    end
    if dropdown.label then
        dropdown.label:SetTextColor(unpack(Colors.textDim))
    end
    if dropdown.button then
        local icon = dropdown.button.GetNormalTexture and dropdown.button:GetNormalTexture()
        if icon then icon:SetVertexColor(unpack(Colors.accent)) end
    end
end

-- Reskins an AceGUI single-line EditBox
function BlacklistWarden:SkinFlatEditbox(widget)
    if widget.skinned then return end
    widget.skinned = true

    if widget.editbox then
        ApplyFlatPanel(widget.editbox, -5, 1, 6, 3)
        widget.editbox:SetTextColor(unpack(Colors.text))
    end
    if widget.label then
        widget.label:SetTextColor(unpack(Colors.textDim))
    end
end

-- Reskins an AceGUI MultiLineEditBox
function BlacklistWarden:SkinFlatMultiLineEditbox(widget)
    if widget.skinned then return end
    widget.skinned = true

    if widget.scrollBG and widget.scrollBG.SetBackdrop then
        widget.scrollBG:SetBackdrop(
            {
                bgFile = "Interface\\Buttons\\WHITE8x8",
                edgeFile = "Interface\\Buttons\\WHITE8x8",
                tile = false,
                tileSize = 0,
                edgeSize = 1,
                insets = { left = 1, right = 1, top = 1, bottom = 1 }
            })
        widget.scrollBG:SetBackdropColor(unpack(Colors.inputBg))
        widget.scrollBG:SetBackdropBorderColor(unpack(Colors.accentDim))
    end
    if widget.editBox then
        widget.editBox:SetTextColor(unpack(Colors.text))
    end
    if widget.label then
        widget.label:SetTextColor(unpack(Colors.textDim))
    end

    if widget.scrollFrame then
        BlacklistWarden:SkinFlatScrollbar(widget.scrollFrame)
    end
end

-- Recolors the divider/label of an AceGUI Heading to match the accent palette.
function BlacklistWarden:SkinFlatHeading(heading)
    if heading.skinned then return end
    heading.skinned = true

    for _, region in ipairs({ heading.frame:GetRegions() }) do
        if region.GetObjectType and region:GetObjectType() == "Texture" then
            region:SetVertexColor(unpack(Colors.accentDim))
        end
    end
    if heading.label then
        heading.label:SetTextColor(unpack(Colors.accent))
    end
end

-- Recolors the backdrop panel AceGUI draws behind TabGroup content / InlineGroup
-- boxes.
function BlacklistWarden:SkinFlatContainerBorder(widget)
    if widget.borderSkinned then return end
    widget.borderSkinned = true

    local border = widget.border
    if not border and widget.frame then
        for _, child in ipairs({ widget.frame:GetChildren() }) do
            if child.GetBackdrop and child:GetBackdrop() then
                border = child
                break
            end
        end
    end

    if border and border.SetBackdrop then
        border:SetBackdrop(
            {
                bgFile = "Interface\\Buttons\\WHITE8x8",
                edgeFile = "Interface\\Buttons\\WHITE8x8",
                tile = false,
                tileSize = 0,
                edgeSize = 1,
                insets = { left = 1, right = 1, top = 1, bottom = 1 }
            })
        border:SetBackdropColor(unpack(Colors.tabGroupBg))
        border:SetBackdropBorderColor(unpack(Colors.accentDim))
    end
    if widget.titletext then
        widget.titletext:SetTextColor(unpack(Colors.accent))
    end
end

function BlacklistWarden:SkinFlatTabGroupBorder(tabgroup)
    if tabgroup.borderSkinned then return end
    tabgroup.borderSkinned = true

    local border = tabgroup.border
    if not border and tabgroup.frame then
        for _, child in ipairs({ tabgroup.frame:GetChildren() }) do
            if child.GetBackdrop and child:GetBackdrop() then
                border = child
                break
            end
        end
    end

    if border and border.SetBackdrop then
        border:SetBackdrop(nil)
    end
end

-- Recolors an AceGUI Dropdown-free UIPanelScrollBarTemplate scrollbar
function BlacklistWarden:SkinFlatScrollbar(scrollFrame)
    local bar = scrollFrame.ScrollBar
    if not bar then
        -- Fallback for clients where the scrollbar isn't exposed via parentKey
        for _, child in ipairs({ scrollFrame:GetChildren() }) do
            if child.IsObjectType and child:IsObjectType("Slider") then
                bar = child
                break
            end
        end
    end
    if not bar then return end
    if bar.flatSkinned then return end
    bar.flatSkinned = true

    local track = bar:CreateTexture(nil, "BACKGROUND")
    track:SetPoint("TOP", bar, "TOP", 0, 0)
    track:SetPoint("BOTTOM", bar, "BOTTOM", 0, 0)
    track:SetWidth(4)
    track:SetColorTexture(1, 1, 1, 0.06)

    for _, buttonKey in ipairs({ "ScrollUpButton", "ScrollDownButton" }) do
        local btn = bar[buttonKey]
        if btn then
            for _, texKey in ipairs({ "Normal", "Pushed", "Disabled", "Highlight" }) do
                local tex = btn[texKey]
                if tex then tex:SetAlpha(0) end
            end
        end
    end

    local thumb = bar.ThumbTexture or (bar.GetThumbTexture and bar:GetThumbTexture())
    if thumb then
        thumb:SetTexture(nil)
        thumb:SetColorTexture(unpack(Colors.accent))
        thumb:SetWidth(4)
    end
end

-- Reskins a single AceGUI TabGroup tab button
function BlacklistWarden:SkinFlatTabButton(tab)
    if tab.flatSkinned then return end
    tab.flatSkinned = true

    for _, region in ipairs({ tab:GetRegions() }) do
        if region.GetObjectType and region:GetObjectType() == "Texture" then
            region:SetAlpha(0)
        end
    end

    local bg = tab:CreateTexture(nil, "BACKGROUND")
    bg:SetPoint("TOPLEFT", 4, -4)
    bg:SetPoint("BOTTOMRIGHT", -4, 2)
    tab.flatBg = bg

    local top = tab:CreateTexture(nil, "BORDER")
    top:SetColorTexture(unpack(Colors.accentDim))
    top:SetPoint("TOPLEFT", bg, "TOPLEFT")
    top:SetPoint("TOPRIGHT", bg, "TOPRIGHT")
    top:SetHeight(1)

    local bottom = tab:CreateTexture(nil, "BORDER")
    bottom:SetColorTexture(unpack(Colors.accent))
    bottom:SetPoint("BOTTOMLEFT", bg, "BOTTOMLEFT")
    bottom:SetPoint("BOTTOMRIGHT", bg, "BOTTOMRIGHT")
    bottom:SetHeight(2)
    tab.flatUnderline = bottom

    local left = tab:CreateTexture(nil, "BORDER")
    left:SetColorTexture(unpack(Colors.accentDim))
    left:SetPoint("TOPLEFT", bg, "TOPLEFT")
    left:SetPoint("BOTTOMLEFT", bg, "BOTTOMLEFT")
    left:SetWidth(1)

    local right = tab:CreateTexture(nil, "BORDER")
    right:SetColorTexture(unpack(Colors.accentDim))
    right:SetPoint("TOPRIGHT", bg, "TOPRIGHT")
    right:SetPoint("BOTTOMRIGHT", bg, "BOTTOMRIGHT")
    right:SetWidth(1)

    tab:SetHighlightTexture("Interface\\Buttons\\WHITE8x8")
    local highlight = tab:GetHighlightTexture()
    if highlight then
        highlight:SetVertexColor(unpack(Colors.rowHighlight))
        highlight:ClearAllPoints()
        highlight:SetPoint("TOPLEFT", bg, "TOPLEFT")
        highlight:SetPoint("BOTTOMRIGHT", bg, "BOTTOMRIGHT")
    end

    local function ApplyState(selected)
        if selected then
            bg:SetColorTexture(0.16, 0.14, 0.08, 1)
            bottom:SetColorTexture(unpack(Colors.accent))
            bottom:SetHeight(2)
            if tab.text then tab.text:SetTextColor(unpack(Colors.accent)) end
        else
            bg:SetColorTexture(unpack(Colors.headerBg))
            bottom:SetColorTexture(unpack(Colors.accentDim))
            bottom:SetHeight(1)
            if tab.text then tab.text:SetTextColor(unpack(Colors.textDim)) end
        end
    end

    ApplyState(tab.selected)
    hooksecurefunc(tab, "SetSelected", function(self, selected)
        ApplyState(selected)
    end)
end

-- Reskins an AceGUI TabGroup
function BlacklistWarden:SkinFlatTabGroup(tabgroup)
    if tabgroup.skinned then return end
    tabgroup.skinned = true

    BlacklistWarden:SkinFlatContainerBorder(tabgroup)

    if tabgroup.tabs then
        for _, tab in ipairs(tabgroup.tabs) do
            BlacklistWarden:SkinFlatTabButton(tab)
        end
    end
end


--Create default blizzard button
function BlacklistWarden:CreateStandardButton(text, width, parent)
    local button = {}
    button = AceGUI:Create("Button")
    button:SetText(text)
    button:SetWidth(width)
    button.frame:SetParent(parent)
    button.frame:Show()
    BlacklistWarden:SkinFlatButton(button)
    return button;
end

-- Create base frame for all widgets
function BlacklistWarden:CreateMainFrame(name, width, height)
    local container = CreateFrame("Frame", name, UIParent,
        BackdropTemplateMixin and "BackdropTemplate")
    container:SetFrameStrata("DIALOG")
    container:SetToplevel(true)
    container:SetWidth(width)
    container:SetHeight(height)
    container:SetScale(1 / UIParent:GetScale())
    container:SetBackdrop(
        {
            bgFile = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            tile = false,
            tileSize = 0,
            edgeSize = 1,
            insets = { left = 1, right = 1, top = 1, bottom = 1 }
        })
    container:SetBackdropColor(unpack(Colors.panelBg))
    container:SetBackdropBorderColor(unpack(Colors.panelBorder))
    container:SetMovable(true)
    container:RegisterForDrag("LeftButton")
    container:SetScript("OnDragStart",
        function(this, button)
            if container:IsMovable() then
                this:StartMoving()
            end
        end)
    container:EnableMouse(true)
    return container
end

--Create warning window that shows when joining a group with a blacklisted player
function BlacklistWarden:CreateBlacklistWarningWindow()
    local container = BlacklistWarden:CreateMainFrame("BlacklistWarningWindow", 250, 180)
    local frameConfig = BlacklistWarden.db.profile.blacklistWarningFrame
    BlacklistWarden:HandleFrameConfig(container, frameConfig)


    local savebutton = BlacklistWarden:CreateStandardButton("Leave", 100, container)
    savebutton:SetCallback("OnClick", function(this)
        C_PartyInfo.LeaveParty()
        this.frame:GetParent():Hide()
    end)
    savebutton.frame:SetPoint("BOTTOM", container, "BOTTOM", -60, 10)

    local cancelbutton = BlacklistWarden:CreateStandardButton("Stay", 100, container)
    cancelbutton:SetCallback("OnClick", function(this)
        local parent = this.frame:GetParent()
        BlacklistWarden:AcknowledgeBlacklistedPlayer(parent.currentPlayerKey)
        parent:Hide()
    end)
    cancelbutton.frame:SetPoint("BOTTOM", container, "BOTTOM", 60, 10)

    local title = container:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("CENTER", container, "TOP", 0, -20)
    title:SetTextColor(unpack(Colors.accent))
    title:SetText("BLACKLISTED PLAYER")

    local titleUnderline = container:CreateTexture(nil, "ARTWORK")
    titleUnderline:SetColorTexture(unpack(Colors.accentDim))
    titleUnderline:SetHeight(1)
    titleUnderline:SetPoint("BOTTOMLEFT", title, "BOTTOMLEFT", -10, -2)
    titleUnderline:SetPoint("BOTTOMRIGHT", title, "BOTTOMRIGHT", 10, -2)

    local name = container:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    name:SetPoint("TOPLEFT", titleUnderline, "TOPLEFT", 0, -10)
    name:SetTextColor(unpack(Colors.text))

    local reason = container:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    reason:SetPoint("TOPLEFT", name, "BOTTOMLEFT", 0, -10)
    reason:SetTextColor(unpack(Colors.text))

    local notes = container:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    notes:SetPoint("TOPLEFT", reason, "BOTTOMLEFT", 0, -10)
    notes:SetWidth(200)
    notes:SetJustifyH("LEFT")
    notes:SetWordWrap(true)
    notes:SetNonSpaceWrap(true)
    notes:SetMaxLines(4)
    notes:SetTextColor(unpack(Colors.text))
    local function RGBToHex(r, g, b)
        r = r <= 255 and r >= 0 and r or 0
        g = g <= 255 and g >= 0 and g or 0
        b = b <= 255 and b >= 0 and b or 0
        return string.format("%02x%02x%02x", r, g, b)
    end
    local function SetPlayerData(player)
        container.currentPlayerKey = (player["name"] .. "-" .. player["server"]):lower()

        local class = BlacklistWarden:NormalizeClass(player)
        name:SetText("Name: |cff" ..
            RGBToHex(classColor[class][1] * 255, classColor[class][2] * 255, classColor[class][3] * 255) ..
            player["name"] .. "-" .. player["server"])


        --name:SetTextColor(classColor[class][1], classColor[class][2], classColor[class][3], 1);
        reason:SetText("Reason: |cffe8615f" .. player["reason"])
        notes:SetText("Notes: \n|cffd9d9f0" .. player["notes"])
    end
    container.setPlayerData = SetPlayerData
    container:Hide()
    return container;
end

-- Handles getting and setting window positions
function BlacklistWarden:HandleFrameConfig(container, frameConfig)
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

--Creates extra window to add/edit a player
function BlacklistWarden:CreateBlacklistPopupWindow()
    local container = BlacklistWarden:CreateMainFrame("BlacklistPopupWindow", 250, 240)
    local frameConfig = BlacklistWarden.db.profile.blacklistPopupFrame
    BlacklistWarden:HandleFrameConfig(container, frameConfig)


    local savebutton = BlacklistWarden:CreateStandardButton("Save", 100, container)
    savebutton.frame:SetPoint("BOTTOM", container, "BOTTOM", -60, 15)
    savebutton:SetCallback("OnClick",
        function(this)
            BlacklistWarden:SavePlayerInfoValue("notes", container.editbox:GetText())
            BlacklistWarden:SavePlayerInfoValue("muted", container.checkbox:GetValue())
            BlacklistWarden:WritePlayerToDisk()
            this.frame:GetParent():Hide()
        end)

    local cancelbutton = BlacklistWarden:CreateStandardButton("Cancel", 100, container)
    cancelbutton.frame:SetPoint("BOTTOM", container, "BOTTOM", 60, 15)
    cancelbutton:SetCallback("OnClick", function(this) this.frame:GetParent():Hide(); end)

    local title = container:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("CENTER", container, "TOP", 0, -20)
    title:SetTextColor(unpack(Colors.accent))

    local titleUnderline = container:CreateTexture(nil, "ARTWORK")
    titleUnderline:SetColorTexture(unpack(Colors.accentDim))
    titleUnderline:SetHeight(1)
    titleUnderline:SetPoint("BOTTOMLEFT", title, "BOTTOMLEFT", -10, -2)
    titleUnderline:SetPoint("BOTTOMRIGHT", title, "BOTTOMRIGHT", 10, -2)

    container.title = title
    local playerName = container:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    playerName:SetPoint("TOP", titleUnderline, "TOP", 0, -10)
    playerName:SetWordWrap(true)
    playerName:SetMaxLines(1)
    playerName:SetWidth(200)
    local function SetPlayerName(player)
        playerName:SetText(player["name"] .. "-" .. player["server"])
        local class = BlacklistWarden:NormalizeClass(player)

        playerName:SetTextColor(classColor[class][1], classColor[class][2], classColor[class][3], 1);
    end
    container.setPlayerName = SetPlayerName;

    local drop = {}
    drop = AceGUI:Create("Dropdown")
    drop:SetList(BlacklistWarden.db.global.blacklistPopupWindowOptions)
    drop:SetWidth(157)
    drop:SetValue(1)
    drop:SetLabel("Reason:")
    drop:SetCallback("OnValueChanged", function(this, event, item)
        BlacklistWarden:SavePlayerInfoValue("reason",
            BlacklistWarden.db.global.blacklistPopupWindowOptions[item])
    end
    )
    drop.frame:SetParent(container)
    drop.frame:Show()
    BlacklistWarden:SkinFlatDropdown(drop)
    drop.frame:SetPoint("LEFT", playerName, "TOPLEFT", -5, -33)
    container.dropdown = drop;

    local muteLabel = container:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    muteLabel:SetPoint("LEFT", drop.frame, "RIGHT", 20, 10)
    muteLabel:SetTextColor(unpack(Colors.textDim))
    muteLabel:SetText("Mute?")

    local checkbox = {}
    checkbox = AceGUI:Create("CheckBox")
    checkbox:SetType("checkbox")
    checkbox.frame:SetParent(container)
    checkbox.frame:Show()
    checkbox.frame:SetPoint("LEFT", drop.frame, "RIGHT", 20, -7)
    checkbox.frame:SetWidth(23)
    BlacklistWarden:SkinFlatCheckbox(checkbox, 20)
    container.checkbox = checkbox

    local noteLabel = container:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    noteLabel:SetPoint("LEFT", drop.frame, "LEFT", 0, -30)
    noteLabel:SetTextColor(unpack(Colors.textDim))
    noteLabel:SetText("Note (optional):")

    -- Modern flat inset for the note editbox instead of the old tooltip-style border
    local editBoxContainer = CreateFrame("Frame", nil, container, BackdropTemplateMixin and "BackdropTemplate")
    editBoxContainer:SetPoint("TOPLEFT", noteLabel, "BOTTOMLEFT", 0, -1)
    editBoxContainer:SetPoint("BOTTOMRIGHT", container, "BOTTOMRIGHT", -20, 49)
    editBoxContainer:SetBackdrop(
        {
            bgFile = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            tile = false,
            tileSize = 0,
            edgeSize = 1,
            insets = { left = 1, right = 1, top = 1, bottom = 1 }
        })
    editBoxContainer:SetBackdropColor(unpack(Colors.inputBg))
    editBoxContainer:SetBackdropBorderColor(unpack(Colors.accentDim))

    local editbox = CreateFrame("EditBox", "NoteEditBox", container)
    editbox:SetPoint("TOPLEFT", editBoxContainer, "TOPLEFT", 5, -8)
    editbox:SetPoint("BOTTOMRIGHT", editBoxContainer, "BOTTOMRIGHT", -5, 0)
    editbox:SetFontObject("ChatFontSmall")
    editbox:SetMultiLine(true)
    editbox:SetAutoFocus(false)
    editbox:SetMaxLetters(140)
    editbox:SetScript("OnEnterPressed", function(self)
        self:ClearFocus()
    end)
    editbox:SetTextColor(unpack(Colors.text))
    --editbox:SetScript("OnShow", function(this) editbox:SetFocus() end)
    container.editbox = editbox;
    container:Hide()

    return container;
end

-- Sorting data
local FilteredScrollButtons = {}
local columnCount           = 0
local lastSort              = false;
local lastSortID            = 1;

-- Creates window to list all the blacklisted players
function BlacklistWarden:CreateListFrame()
    local container = BlacklistWarden:CreateMainFrame("ListWindow", 860, 500)
    local frameConfig = BlacklistWarden.db.profile.listFrame
    BlacklistWarden:HandleFrameConfig(container, frameConfig)
    columnCount   = 0
    local heading = {}
    heading       = AceGUI:Create("Heading")
    heading:SetText("Blacklist Warden")
    heading:SetWidth(container:GetWidth() - 5)
    heading.frame:SetParent(container)
    heading.frame:SetPoint("TOP", container, "TOP", 0, -20)
    heading.frame:Show()
    BlacklistWarden:SkinFlatHeading(heading)

    local closebutton = BlacklistWarden:CreateStandardButton("Close", 80, container)
    closebutton.frame:SetPoint("BOTTOMRIGHT", container, "BOTTOMRIGHT", -6, 10)
    closebutton:SetHeight(20)
    closebutton:SetCallback("OnClick",
        function(this)
            this.frame:GetParent():Hide()
        end)

    local tabgroup = AceGUI:Create("TabGroup")
    tabgroup:SetTabs { { value = "1", text = "Player List" }, { value = "2", text = "Add player" } }
    tabgroup.frame:SetParent(container)
    tabgroup.frame:SetPoint("TOPLEFT", container, "TOPLEFT", 5, -30)
    tabgroup.frame:SetPoint("BOTTOMRIGHT", container, "BOTTOMRIGHT", -5, 30)
    tabgroup:SelectTab("1")
    BlacklistWarden:SkinFlatTabGroup(tabgroup)




    -- Create the scrolling parent frame and size it to fit inside the texture
    local scrollFrame = CreateFrame("ScrollFrame", nil, tabgroup.frame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", tabgroup.frame, "TOPLEFT", 0, -60)
    scrollFrame:SetPoint("BOTTOMRIGHT", tabgroup.frame, "BOTTOMRIGHT", -28, 8)
    BlacklistWarden:SkinFlatScrollbar(scrollFrame)
    -- Create the scrolling child frame, set its width to fit, and give it an arbitrary minimum height (such as 1)
    local scrollChild = CreateFrame("Frame")
    scrollFrame:SetScrollChild(scrollChild)
    scrollChild:SetWidth(scrollFrame:GetWidth())
    scrollChild:SetHeight(1)

    BlacklistWarden:CreateColumnHeader("Name", scrollFrame, 110, "scroll", scrollChild)
    BlacklistWarden:CreateColumnHeader("Realm", scrollFrame, 105, "scroll", scrollChild)
    BlacklistWarden:CreateColumnHeader("Class", scrollFrame, 110, "scroll", scrollChild)
    BlacklistWarden:CreateColumnHeader("Reason", scrollFrame, 80, "scroll", scrollChild)
    BlacklistWarden:CreateColumnHeader("Date Added", scrollFrame, 90, "scroll", scrollChild)
    BlacklistWarden:CreateColumnHeader("Muted?", scrollFrame, 65, "scroll", scrollChild)
    BlacklistWarden:CreateColumnHeader("Notes", scrollFrame, 278, "scroll", scrollChild)

    --BlacklistWarden:CreateTableButton(scrollcontainer.frame,1);

    local addFrame = AceGUI:Create("InlineGroup")
    addFrame.frame:SetParent(tabgroup.frame)
    addFrame.frame:SetPoint("TOPLEFT", tabgroup.frame, "TOPLEFT", 20, -50)
    addFrame.frame:SetPoint("BOTTOMRIGHT", tabgroup.frame, "BOTTOMRIGHT", -10, 60)
    addFrame:SetTitle("ADD TO BLACKLIST: ")
    BlacklistWarden:SkinFlatTabGroupBorder(addFrame)
    --BlacklistWarden:SkinFlatContainerBorder(addFrame)


    local nameBox = AceGUI:Create("EditBox")
    nameBox:SetLabel("Name:")
    nameBox:SetWidth(200)
    nameBox.frame:SetParent(addFrame.frame)
    nameBox:DisableButton(true)
    nameBox.frame:SetPoint("TOPLEFT", addFrame.frame, "TOPLEFT", 15, -30)
    nameBox.frame:Show()
    BlacklistWarden:SkinFlatEditbox(nameBox)

    local separator = AceGUI:Create("Label")
    separator:SetText("-")
    separator.frame:SetParent(addFrame.frame)
    separator.frame:SetPoint("LEFT", nameBox.frame, "RIGHT", 3, -7)
    separator.frame:SetPoint("RIGHT", nameBox.frame, "RIGHT", 13, -7)
    separator.frame:Show()
    if separator.label then
        separator.label:SetTextColor(unpack(Colors.textDim))
    end

    local realmBox = AceGUI:Create("EditBox")
    realmBox:SetLabel("Realm:")
    realmBox:SetWidth(200)
    realmBox:DisableButton(true)
    realmBox.frame:SetParent(addFrame.frame)
    realmBox.frame:SetPoint("LEFT", separator.frame, "RIGHT", 1, 7)
    realmBox.frame:Show()
    BlacklistWarden:SkinFlatEditbox(realmBox)

    local classDropdown = {}
    classDropdown = AceGUI:Create("Dropdown")
    classDropdown:SetList(className)
    classDropdown:SetWidth(193)
    classDropdown:SetValue("DEATHKNIGHT")
    classDropdown:SetLabel("Class:")

    classDropdown.frame:SetParent(addFrame.frame)
    classDropdown.frame:Show()
    BlacklistWarden:SkinFlatDropdown(classDropdown)
    classDropdown.frame:SetPoint("TOPLEFT", nameBox.frame, "BOTTOMLEFT", 0, -10)
    classDropdown:SetCallback("OnValueChanged", function(this, event, item)
        BlacklistWarden:SavePlayerInfoValue("playerClass",
            item)
    end
    )

    local reasonDropdown = {}
    reasonDropdown = AceGUI:Create("Dropdown")
    reasonDropdown:SetList(BlacklistWarden.db.global.blacklistPopupWindowOptions)
    reasonDropdown:SetWidth(193)
    reasonDropdown:SetValue(1)
    reasonDropdown:SetLabel("Reason:")
    reasonDropdown:SetCallback("OnValueChanged", function(this, event, item)
        BlacklistWarden:SavePlayerInfoValue("reason",
            BlacklistWarden.db.global.blacklistPopupWindowOptions[item])
    end
    )
    reasonDropdown.frame:SetParent(addFrame.frame)
    reasonDropdown.frame:Show()
    BlacklistWarden:SkinFlatDropdown(reasonDropdown)
    reasonDropdown.frame:SetPoint("LEFT", classDropdown.frame, "RIGHT", 21, 0)

    local notesBox = AceGUI:Create("MultiLineEditBox")
    notesBox:SetLabel("Note (optional):")
    notesBox:SetWidth(425)
    notesBox:DisableButton(true)
    notesBox.frame:SetParent(addFrame.frame)
    notesBox.frame:SetPoint("TOPLEFT", classDropdown.frame, "BOTTOMLEFT", 0, -10)
    notesBox.frame:Show()
    BlacklistWarden:SkinFlatMultiLineEditbox(notesBox)
    notesBox:SetMaxLetters(140)
    notesBox:SetNumLines(2)


    local muteLabel = notesBox.frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    muteLabel:SetPoint("BOTTOMLEFT", notesBox.frame, "BOTTOMLEFT", 0, -15)
    muteLabel:SetTextColor(unpack(Colors.textDim))
    muteLabel:SetText("Mute?")

    local checkbox = {}
    checkbox = AceGUI:Create("CheckBox")
    checkbox:SetType("checkbox")
    checkbox:SetValue(true)
    checkbox.frame:SetParent(addFrame.frame)
    checkbox.frame:Show()
    checkbox.frame:SetPoint("BOTTOMLEFT", notesBox.frame, "BOTTOMLEFT", 0, -38)
    checkbox.frame:SetWidth(23)
    BlacklistWarden:SkinFlatCheckbox(checkbox, 20)
    container.checkbox = checkbox

    local function AddPlayer()
        if nameBox:GetText() == "" or realmBox:GetText() == "" then
            print("|cffFFFF00Blacklist Warden:|r Name or realm missing.")
        else
            local nameBoxString = nameBox:GetText()
            if not nameBoxString:find("[^%z\1-\127]") then
                nameBoxString = nameBoxString:lower()
                nameBoxString = nameBoxString:sub(1, 1):upper() .. nameBoxString:sub(2)
            end

            local realmBoxString = realmBox:GetText()
            if not realmBoxString:find("[^%z\1-\127]") then
                realmBoxString = realmBoxString:lower()
                realmBoxString = realmBoxString:sub(1, 1):upper() .. realmBoxString:sub(2)
            end

            BlacklistWarden:SavePlayerInfoValue("playerName", nameBoxString:match("^%s*(.-)%s*$"))
            BlacklistWarden:SavePlayerInfoValue("playerServer", realmBoxString:match("^%s*(.-)%s*$"))
            BlacklistWarden:SavePlayerInfoValue("notes", notesBox:GetText())
            BlacklistWarden:SavePlayerInfoValue("muted", checkbox:GetValue())
            BlacklistWarden:WritePlayerToDisk()
            nameBox:SetText("")
            realmBox:SetText("")
            notesBox:SetText("")
            reasonDropdown:SetValue(1)
            BlacklistWarden:SavePlayerInfoValue("reason",
                BlacklistWarden.db.global.blacklistPopupWindowOptions[1])
            classDropdown:SetValue("DEATHKNIGHT")
            BlacklistWarden:SavePlayerInfoValue("playerClass",
                "DEATHKNIGHT")
        end
    end

    local addButton = BlacklistWarden:CreateStandardButton("Add", 100, addFrame.frame)
    addButton.frame:SetPoint("BOTTOMLEFT", addFrame.frame, "BOTTOMLEFT", 15, 30)
    addButton:SetCallback("OnClick", function() AddPlayer(); end)

    addFrame.frame:Hide()
    local function SelectGroup(container, event, group)
        if group == "1" then
            scrollFrame:Show()
            addFrame.frame:Hide()
        elseif group == "2" then
            scrollFrame:Hide()
            addFrame.frame:Show();
            BlacklistWarden:TogglePopupWindow(false)
            reasonDropdown:SetValue(1)
            BlacklistWarden:SavePlayerInfoValue("reason",
                BlacklistWarden.db.global.blacklistPopupWindowOptions[1])
            classDropdown:SetValue("DEATHKNIGHT")
            BlacklistWarden:SavePlayerInfoValue("playerClass",
                "DEATHKNIGHT")
        end
    end
    tabgroup:SetCallback("OnGroupSelected", SelectGroup)


    FilteredScrollButtons = {}
    local index = 1
    for key, value in pairs(BlacklistWarden.db.global.blacklistedPlayers) do
        BlacklistWarden:CreateTableButton(scrollChild, index, value);
        index = index + 1
    end

    container:Hide()
    local function AddEntry(player)
        BlacklistWarden:CreateTableButton(scrollChild, index, player);
        lastSort = not lastSort
        BlacklistWarden:SortPlayerBlacklist(lastSortID, scrollChild)
        index = index + 1
    end
    local function RemoveEntry(player)
        local removeKey = (player["name"] .. "-" .. player["server"]):lower()
        for i = 1, #FilteredScrollButtons do
            if FilteredScrollButtons[i].playerKey == removeKey then
                FilteredScrollButtons[i]:Hide()
                table.remove(FilteredScrollButtons, i)
                lastSort = not lastSort
                BlacklistWarden:SortPlayerBlacklist(lastSortID, scrollChild)
                index = index - 1
                break
            end
        end
    end
    local function UpdateEntry(player)
        local updateKey = (player["name"] .. "-" .. player["server"]):lower()
        for i = 1, #FilteredScrollButtons do
            if FilteredScrollButtons[i].playerKey == updateKey then
                FilteredScrollButtons[i].reason:SetText(player["reason"])
                if player["notes"] and player["notes"] ~= "" then
                    FilteredScrollButtons[i].notes:SetText(player["notes"])
                else
                    FilteredScrollButtons[i].notes:SetText(" ")
                end
                FilteredScrollButtons[i].muted:SetText(player["muted"] and "Yes" or "No")
                if player["muted"] == true then
                    FilteredScrollButtons[i].muted:SetTextColor(unpack(Colors.success))
                else
                    FilteredScrollButtons[i].muted:SetTextColor(unpack(Colors.textDim))
                end
                break
            end
        end
    end


    container.addEntry = AddEntry
    container.removeEntry = RemoveEntry
    container.updateEntry = UpdateEntry
    container:SetScript("OnShow",
        function(self)
            lastSort = true
            lastSortID = 5
            BlacklistWarden:SortPlayerBlacklist(5, scrollChild)
            tabgroup:SelectTab("1")
        end)
    return container;
end

-- Creates columns for player list
function BlacklistWarden:CreateColumnHeader(text, parent, width, name, child)
    local p = _G[name .. "Header1"]

    if p == nil then
        columnCount = 0
    end

    columnCount = columnCount + 1

    local Header = CreateFrame("Button", name .. "Header" .. columnCount, parent, "WhoFrameColumnHeaderTemplate")
    Header:SetWidth(width)
    Header:SetHeight(22)

    -- Strip the legacy Blizzard header art 
    local headerName = Header:GetName()
    local leftTex = _G[headerName .. "Left"]
    local middleTex = _G[headerName .. "Middle"]
    local rightTex = _G[headerName .. "Right"]
    if leftTex then leftTex:SetTexture(nil) end
    if middleTex then middleTex:SetTexture(nil); middleTex:SetWidth(width - 9) end
    if rightTex then rightTex:SetTexture(nil) end

    local flatBg = Header:CreateTexture(nil, "BACKGROUND")
    flatBg:SetAllPoints(Header)
    flatBg:SetColorTexture(unpack(Colors.headerBg))

    local flatUnderline = Header:CreateTexture(nil, "ARTWORK")
    flatUnderline:SetColorTexture(unpack(Colors.accentDim))
    flatUnderline:SetHeight(1)
    flatUnderline:SetPoint("BOTTOMLEFT", Header, "BOTTOMLEFT")
    flatUnderline:SetPoint("BOTTOMRIGHT", Header, "BOTTOMRIGHT")

    Header:SetHighlightTexture("Interface\\Buttons\\WHITE8x8")
    local headerHighlight = Header:GetHighlightTexture()
    if headerHighlight then
        headerHighlight:SetVertexColor(unpack(Colors.rowHighlight))
        headerHighlight:ClearAllPoints()
        headerHighlight:SetPoint("TOPLEFT", Header, "TOPLEFT")
        headerHighlight:SetPoint("BOTTOMRIGHT", Header, "BOTTOMRIGHT")
    end

    Header:SetText(text)
    Header:SetNormalFontObject("GameFontHighlight")
    Header:SetHighlightFontObject("GameFontHighlight")
    if Header:GetFontString() then
        Header:GetFontString():SetTextColor(unpack(Colors.accent))
    end
    Header:SetID(columnCount)

    if columnCount == 1 then
        Header:SetPoint("TOPLEFT", parent, "TOPLEFT", 3, 27)
    else
        Header:SetPoint("LEFT", name .. "Header" .. columnCount - 1, "RIGHT", 0, 0)
    end
    local function SortPlayerBlacklist(self)
        BlacklistWarden:SortPlayerBlacklist(self:GetID(), child)
    end
    Header:SetScript("OnClick", SortPlayerBlacklist)
end

--Sorting function
function BlacklistWarden:SortPlayerBlacklist(sortBy, parent)
    if lastSortID ~= sortBy then
        lastSort = false
    end
    table.sort(FilteredScrollButtons,
        function(a, b)
            if sortBy == 1 then
                if not lastSort then
                    return a.name:GetText() < b.name:GetText()
                else
                    return b.name:GetText() < a.name:GetText()
                end
            elseif sortBy == 2 then
                if not lastSort then
                    return a.server:GetText() < b.server:GetText()
                else
                    return b.server:GetText() < a.server:GetText()
                end
            elseif sortBy == 3 then
                if not lastSort then
                    return a.class:GetText() < b.class:GetText()
                else
                    return b.class:GetText() < a.class:GetText()
                end
            elseif sortBy == 4 then
                if not lastSort then
                    return a.reason:GetText() < b.reason:GetText()
                else
                    return b.reason:GetText() < a.reason:GetText()
                end
            elseif sortBy == 5 then
                local firstHalfa, secondHalfa = strsplit(" ",
                    BlacklistWarden.db.global.blacklistedPlayers
                    [a.playerKey]
                    ["date"])
                local amonth, aday, ayear = strsplit("/", firstHalfa)
                local ahour, amin, asec = strsplit(":", secondHalfa)
                local dateTbla = {
                    year = ayear,
                    month = amonth,
                    day = aday,
                    hour = ahour,
                    min = amin,
                    sec = asec
                }
                local firstHalfb, secondHalfb = strsplit(" ",
                    BlacklistWarden.db.global.blacklistedPlayers
                    [b.playerKey]
                    ["date"])
                local bmonth, bday, byear = strsplit("/", firstHalfb)
                local bhour, bmin, bsec = strsplit(":", secondHalfb)
                local dateTblb = {
                    year = byear,
                    month = bmonth,
                    day = bday,
                    hour = bhour,
                    min = bmin,
                    sec = bsec
                }
                local adate = time(dateTbla)

                local bdate = time(dateTblb)
                if not lastSort then
                    return adate < bdate
                else
                    return bdate < adate
                end
            elseif sortBy == 6 then
                if not lastSort then
                    return string.lower(a.muted:GetText()) < string.lower(b.muted:GetText())
                else
                    return string.lower(b.muted:GetText()) < string.lower(a.muted:GetText())
                end
            elseif sortBy == 7 then
                if not lastSort then
                    return string.lower(a.notes:GetText()) < string.lower(b.notes:GetText())
                else
                    return string.lower(b.notes:GetText()) < string.lower(a.notes:GetText())
                end
            else
                if not lastSort then
                    return a.name:GetText() < b.name:GetText()
                else
                    return b.name:GetText() < a.name:GetText()
                end
            end
        end)
    lastSort = not lastSort
    lastSortID = sortBy
    for i = 1, #FilteredScrollButtons do
        if i == 1 then
            FilteredScrollButtons[i]:SetPoint("TOPLEFT", parent, -1, 0)
        else
            FilteredScrollButtons[i]:SetPoint("TOPLEFT", FilteredScrollButtons[i - 1], "BOTTOMLEFT")
        end
        -- Re-stripe alternating rows after every sort so the banding stays consistent
        -- with the new order.
        if FilteredScrollButtons[i].rowStripe then
            if i % 2 == 0 then
                FilteredScrollButtons[i].rowStripe:SetColorTexture(unpack(Colors.rowBaseA))
            else
                FilteredScrollButtons[i].rowStripe:SetColorTexture(unpack(Colors.rowBaseB))
            end
        end
    end
end

--Creates table entries
function BlacklistWarden:CreateTableButton(parent, index, player)
    FilteredScrollButtons[index] = CreateFrame("Button", nil, parent, "IgnoreListButtonTemplate")
    if index == 1 then
        FilteredScrollButtons[index]:SetPoint("TOPLEFT", parent, -1, 0)
    else
        FilteredScrollButtons[index]:SetPoint("TOPLEFT", FilteredScrollButtons[index - 1], "BOTTOMLEFT")
    end

    FilteredScrollButtons[index]:SetSize(840, 20)
    FilteredScrollButtons[index]:RegisterForClicks("RightButtonDown")

    FilteredScrollButtons[index].playerKey = (player["name"] .. "-" .. player["server"]):lower()

    local rowStripe = FilteredScrollButtons[index]:CreateTexture(nil, "BACKGROUND")
    rowStripe:SetAllPoints()
    if index % 2 == 0 then
        rowStripe:SetColorTexture(unpack(Colors.rowBaseA))
    else
        rowStripe:SetColorTexture(unpack(Colors.rowBaseB))
    end
    FilteredScrollButtons[index].rowStripe = rowStripe

    FilteredScrollButtons[index]:SetHighlightTexture("Interface\\Buttons\\WHITE8x8")
    local highlightTex = FilteredScrollButtons[index]:GetHighlightTexture()
    if highlightTex then
        highlightTex:SetVertexColor(unpack(Colors.rowHighlight))
    end

    local function createDropdown(self)
        BlacklistWarden:CreateDropdown(self)
    end

    FilteredScrollButtons[index]:SetScript("OnClick", createDropdown)


    -- set name style
    FilteredScrollButtons[index].name:SetWidth(100)
    FilteredScrollButtons[index].name:SetText(player["name"])
    FilteredScrollButtons[index].name:SetTextColor(unpack(Colors.text))
    -- set active style
    FilteredScrollButtons[index].server = FilteredScrollButtons[index]:CreateFontString("FontString", "OVERLAY",
        "GameFontNormal")
    FilteredScrollButtons[index].server:SetPoint("LEFT", FilteredScrollButtons[index].name, "RIGHT", 10, 0)
    FilteredScrollButtons[index].server:SetWidth(100)
    FilteredScrollButtons[index].server:SetJustifyH("LEFT")
    FilteredScrollButtons[index].server:SetText(player["server"])
    FilteredScrollButtons[index].server:SetTextColor(unpack(Colors.textDim))
    -- create blocked style
    FilteredScrollButtons[index].class = FilteredScrollButtons[index]:CreateFontString("FontString", "OVERLAY",
        "GameFontHighlight")
    FilteredScrollButtons[index].class:SetPoint("LEFT", FilteredScrollButtons[index].server, "RIGHT", 6, 0)
    FilteredScrollButtons[index].class:SetWidth(100)
    FilteredScrollButtons[index].class:SetJustifyH("LEFT")
    --UnfilteredScrollButtons[index].class:SetWordWrap(false)
    local class = BlacklistWarden:NormalizeClass(player)
    FilteredScrollButtons[index].class:SetText(className[class])

    FilteredScrollButtons[index].class:SetTextColor(classColor[class][1], classColor[class][2], classColor[class][3], 1);
    FilteredScrollButtons[index].reason = FilteredScrollButtons[index]:CreateFontString("FontString", "OVERLAY",
        "GameFontHighlight")
    FilteredScrollButtons[index].reason:SetPoint("LEFT", FilteredScrollButtons[index].class, "RIGHT", 10, 0)
    FilteredScrollButtons[index].reason:SetWidth(70)
    FilteredScrollButtons[index].reason:SetJustifyH("LEFT")
    FilteredScrollButtons[index].reason:SetTextColor(unpack(Colors.danger))
    if player["reason"] and player["reason"] ~= "" then
        FilteredScrollButtons[index].reason:SetText(player["reason"])
    else
        FilteredScrollButtons[index].reason:SetText(" ")
    end

    FilteredScrollButtons[index].date = FilteredScrollButtons[index]:CreateFontString("FontString", "OVERLAY",
        "GameFontNormal")
    FilteredScrollButtons[index].date:SetPoint("LEFT", FilteredScrollButtons[index].reason, "RIGHT", 10, 0)
    FilteredScrollButtons[index].date:SetWidth(93)
    FilteredScrollButtons[index].date:SetJustifyH("LEFT")
    FilteredScrollButtons[index].date:SetTextColor(unpack(Colors.textDim))
    local date, time = strsplit(" ", player["date"])
    FilteredScrollButtons[index].date:SetText(date)

    FilteredScrollButtons[index].muted = FilteredScrollButtons[index]:CreateFontString("FontString", "OVERLAY",
        "GameFontNormal")
    FilteredScrollButtons[index].muted:SetPoint("LEFT", FilteredScrollButtons[index].date, "RIGHT", 10, 0)
    FilteredScrollButtons[index].muted:SetWidth(42)
    FilteredScrollButtons[index].muted:SetJustifyH("LEFT")
    FilteredScrollButtons[index].muted:SetMaxLines(1)
    if player["muted"] == true then
        FilteredScrollButtons[index].muted:SetText("Yes")
        FilteredScrollButtons[index].muted:SetTextColor(unpack(Colors.success))
    else
        FilteredScrollButtons[index].muted:SetText("No")
        FilteredScrollButtons[index].muted:SetTextColor(unpack(Colors.textDim))
    end

    FilteredScrollButtons[index].notes = FilteredScrollButtons[index]:CreateFontString("FontString", "OVERLAY",
        "GameFontHighlight")
    FilteredScrollButtons[index].notes:SetPoint("LEFT", FilteredScrollButtons[index].muted, "RIGHT", 10, 0)
    FilteredScrollButtons[index].notes:SetWidth(255)
    FilteredScrollButtons[index].notes:SetJustifyH("LEFT")
    FilteredScrollButtons[index].notes:SetMaxLines(1)
    FilteredScrollButtons[index].notes:SetTextColor(unpack(Colors.textDim))
    if player["notes"] and player["notes"] ~= "" then
        FilteredScrollButtons[index].notes:SetText(player["notes"])
    else
        FilteredScrollButtons[index].notes:SetText(" ")
    end



    FilteredScrollButtons[index]:Show()
    -- create filter style
end

--Creates context menu for player list
function BlacklistWarden:CreateDropdown(self)
    local playerKey = self.playerKey
    MenuUtil.CreateContextMenu(UIParent, function(ownerRegion, rootDescription)
        rootDescription:CreateTitle("Select option")
        rootDescription:CreateButton("Edit", function() BlacklistWarden:EditEntry(playerKey) end)
        rootDescription:CreateButton("Remove", function() BlacklistWarden:RemovePlayer(playerKey) end)
    end)
end