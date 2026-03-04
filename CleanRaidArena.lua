-- Apply gradient overlay and clean arena accessories to improve raid and arena frames because default UI is cluttered

-- Define gradient colors to create healthbar depth effect because flat bars lack visual distinction

local GRADIENT_ALPHA = 0.25
local TOP_COLOR = CreateColor(0, 0, 0, GRADIENT_ALPHA)
local BOTTOM_COLOR = CreateColor(0, 0, 0, 0)

-- Add gradient texture to healthbars to create visual depth because flat colors lack dimension

local function ApplyHealthBarGradient(frame)
    if not frame or not frame.healthBar then return end
    local healthBar = frame.healthBar
    if healthBar.cleanGradient then return end
    local gradient = healthBar:CreateTexture(nil, "ARTWORK", nil, 7)
    gradient:SetAllPoints(healthBar)
    gradient:SetColorTexture(1, 1, 1, 1)
    gradient:SetGradient("VERTICAL", BOTTOM_COLOR, TOP_COLOR)
    healthBar.cleanGradient = gradient
end

-- Hook frame setup to apply gradient to all raid and arena frames because frames are created dynamically

hooksecurefunc("DefaultCompactUnitFrameSetup", ApplyHealthBarGradient)
hooksecurefunc("DefaultCompactMiniFrameSetup", ApplyHealthBarGradient)

-- Limit visible debuffs to one per frame to reduce clutter because multiple debuffs obscure health info

local function HideExtraDebuffs(frame)
    if not frame or not frame.debuffFrames then return end
    for debuffIndex = 2, #frame.debuffFrames do
        if frame.debuffFrames[debuffIndex] then
            frame.debuffFrames[debuffIndex]:Hide()
        end
    end
end

-- Hook aura updates to hide extra debuffs because frames refresh dynamically

hooksecurefunc("CompactUnitFrame_UpdateAuras", HideExtraDebuffs)

local ACCESSORY_SIZE = 40

-- Reposition arena accessories and hide casting bar to clean up arena frames because default layout is noisy

local function AdjustArenaMember(memberFrame)
    if not memberFrame then return end

    -- Hide casting bar to reduce visual noise because cast information is rarely needed

    local castingBar = memberFrame.CastingBarFrame
    if castingBar then
        castingBar:SetAlpha(0)
    end

    -- Position crowd control remover to the right of member frame because default placement overlaps

    local crowdControlRemover = memberFrame.CcRemoverFrame
    if crowdControlRemover then
        crowdControlRemover:SetSize(ACCESSORY_SIZE, ACCESSORY_SIZE)
        crowdControlRemover:ClearAllPoints()
        crowdControlRemover:SetPoint("TOPLEFT", memberFrame, "TOPRIGHT", 2, 0)
    end

    -- Position debuff frame to the left of member frame because default placement overlaps content

    local debuffFrame = memberFrame.DebuffFrame
    if debuffFrame then
        debuffFrame:SetSize(ACCESSORY_SIZE, ACCESSORY_SIZE)
        debuffFrame:ClearAllPoints()
        debuffFrame:SetPoint("TOPRIGHT", memberFrame, "TOPLEFT", -2, 0)
    end

    -- Position diminish tray to the bottom-left of member frame because it avoids overlapping other elements

    local diminishTray = memberFrame.SpellDiminishStatusTray
    if diminishTray then
        diminishTray:ClearAllPoints()
        diminishTray:SetPoint("BOTTOMRIGHT", memberFrame, "BOTTOMLEFT", -2, 0)
    end
end

-- Hook arena frame directly to apply layout changes because mixin hooks fail after frame creation

local function SetupArenaHook()
    if not CompactArenaFrame or CompactArenaFrame.cleanArenaHooked then return end
    CompactArenaFrame.cleanArenaHooked = true
    hooksecurefunc(CompactArenaFrame, "UpdateLayout", function(self)
        for _, memberFrame in ipairs(self.memberUnitFrames) do
            AdjustArenaMember(memberFrame)
        end
    end)
end

-- Apply arena hooks immediately to catch existing frames because frames may already be created

SetupArenaHook()

-- Hook frame generation to apply layout on new frames because arena frames are created lazily

if CompactArenaFrame_Generate then
    hooksecurefunc("CompactArenaFrame_Generate", SetupArenaHook)
end