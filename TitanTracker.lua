-----------
-- TODOS in v0.95

-- General
-- Turn on last tracked on death
-- Register for on player alive event and on player entered world event (look for way to register only on first session enter event)

-- Options
-- Implement options dropdown on ctrl + right-click
-- Option with preferred tracker (tracker that loads on startup)
-- Option to set if lasted tracked or preferred tracker should show on death.

-- Bugfixes
-- Move spells variable assignment to player entered world event. (fixes druid trackHumanoids bug)

-----------

-----------
-- Changelog

-- Features

-- Bugfixes

----------

local currentTracker = nil;


local TitanTracker = LibStub("AceAddon-3.0"):NewAddon("TitanTracker", "AceConsole-3.0", "AceEvent-3.0")

-- first value in array is icon id, and second is spell id
local spells = {
    trackBeasts = {132328, 1494},
    trackHumanoids = {135942, UnitClass("player") == "Druid" and 5225 or 19883 },
    trackUndead = {136142, 19884},
    trackHidden = {132320, 19885},
    trackElementals = {135861, 19880},
    trackDemons = {136217, 19878},
    trackGigants = {132275, 19882},
    trackDragonkin = {134153, 19879},
    senseDemons = {136172, 5500},
    senseUndead = {135974, 5502},
    findHerbs = {133939, 2383},
    findMinerals = {136025, 2580},
    findTreasure = {135725, 2481}
}

local LDBIcon = LibStub("LibDBIcon-1.0")

local broker = LibStub("LibDataBroker-1.1"):NewDataObject("TitanTracker", {
    type = "data source",
    text = "No Tracking Active",
    label = "Tracker",
    icon = "134400",
    OnClick = function(_, message)
        if message == "LeftButton" then
            TitanTracker:Picker();
        elseif message == "RightButton" then
            CancelTrackingBuff();
        end
    end,
})


function TitanTracker:OnInitialize()
    
    self.db = LibStub("AceDB-3.0"):New("TitanTrackerDB", {
		profile = {
			minimap = {
				hide = false,
				minimapPos = 142,
				lock = true,
			},
        },
        char = {
            tt = {
                prefTracker = 0,
                prefOnLogin = true,
            }
        },
	})

    MiniMapTrackingFrame:SetScale(0.001)
    LDBIcon:Register("TitanTrackerData", broker, self.db.profile.minimap)

    self:RegisterChatCommand("ttoggle", "Tt_toggle")

    TitanTracker:RegisterEvent("MINIMAP_UPDATE_TRACKING")

    -- Get preferred tracker and set current tracker variable
    TitanTracker:RegisterEvent("PLAYER_LOGIN", function() currentTracker = self.db.char.tt.prefTracker end)

    -- Set currentTracker as active 
    TitanTracker:RegisterEvent("PLAYER_UNGHOST", "OnRespawn")
    TitanTracker:RegisterEvent("PLAYER_ALIVE", "OnRespawn")

end

function TitanTracker:Tt_toggle()
    self.db.profile.minimap.hide = not self.db.profile.minimap.hide
    if self.db.profile.minimap.hide then 
        LDBIcon:Hide("TitanTrackerData") 
    else 
        LDBIcon:Show("TitanTrackerData")
    end
end

function TitanTracker:Picker()

    local menu = {
        {
            text = "Track", isTitle = true, notCheckable = true,
        }
    }
    
    for k,spell in pairs(spells) do
		if IsPlayerSpell(spell[2]) then
			table.insert(menu, {
				text = GetSpellInfo(spell[2]),
                icon = GetSpellTexture(spell[2]),
				func = function()
                    CastSpellByID(spell[2])
                end,
                checked = IsActive(spell[2])
			})
		end
    end

    table.insert(menu, {
        text = "Stop Tracking",
        notCheckable = true,
        func = function()
            CancelTrackingBuff();
        end
    })

    local menuFrame = CreateFrame("Frame", "ActiveSelectFrame", UIParent, "UIDropDownMenuTemplate")
	EasyMenu(menu, menuFrame, "cursor", 0 , 0, "MENU");
end

function TitanTracker:MINIMAP_UPDATE_TRACKING()

    local texture = GetTrackingTexture();

    if not texture then
        broker.icon = "134400";
        broker.text = "No Tracking Active";
        TitanTracker:SetMinimapIcon(134400)
        currentTracker = 0;
    else

        broker.icon = texture;
        TitanTracker:SetMinimapIcon(texture)

        for k,spell in pairs(spells) do
            if spell[1] == texture then
                broker.text = GetSpellInfo(spell[2]);
                currentTracker = spell[2];
            end
        end
    end
end

function TitanTracker:OnRespawn()
    if IsPlayerSpell(currentTracker) then
        CastSpellByID(currentTracker)
    end
end

function TitanTracker:SetMinimapIcon(texture)
    local mmBtn = LDBIcon:GetMinimapButton("TitanTrackerData")

    if (mmBtn ~= nil) then
        mmBtn.icon:SetTexture(texture)
    end

end

function TitanTracker:IsActive(spellId) 
    return spellId == currentTracker
end