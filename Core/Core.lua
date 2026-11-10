-----------------------------------------------------------------------
-- Upvalued Lua API.
-----------------------------------------------------------------------
---@type string, CoordinatesTrackingPrivate
local FOLDER_NAME, private = ...
local _G = getfenv(0)
local pairs, string, select = _G.pairs, _G.string, _G.select

local format = string.format

local GetCursorPosition, GetSubZoneText, GetZoneText = _G.GetCursorPosition, _G.GetSubZoneText, _G.GetZoneText
local C_Map = _G.C_Map
local GetPlayerMapPosition, GetBestMapForUnit = C_Map.GetPlayerMapPosition, C_Map.GetBestMapForUnit
local WorldMapScrollChild = WorldMapFrame.ScrollContainer.Child
local C_AddOns = _G.C_AddOns
local GetAddOnInfo, GameTooltip = C_AddOns.GetAddOnInfo, _G.GameTooltip
local GetAddOnMetadata = C_AddOns.GetAddOnMetadata
local C_PvP = _G.C_PvP
local GetZonePVPInfo = C_PvP.GetZonePVPInfo

local Client = private.Client

local LibStub = _G.LibStub
local L = LibStub("AceLocale-3.0"):GetLocale(private.addon_name)
local AceDB = LibStub("AceDB-3.0")
local LDB = LibStub:GetLibrary("LibDataBroker-1.1"):NewDataObject(private.addon_name, {
	type = "data source",
	text = L["TITLE"],
	label = L["TITLE"],
	icon = "Interface\\MINIMAP\\MinimapArrow",
})
local Media = LibStub("LibSharedMedia-3.0")

-- Frame names
local onscreenName = private.addon_name.."Frame"
local worldmapName = "CoordsOnWorldMapFrame"
---@type CoordinatesTrackingOnScreenFrame
local MyFrame = _G[onscreenName]
if not MyFrame then MyFrame = CreateFrame("Frame", onscreenName, UIParent, BackdropTemplateMixin and "BackdropTemplate") --[[@as CoordinatesTrackingOnScreenFrame]] end

local addon = LibStub("AceAddon-3.0"):NewAddon(MyFrame, private.addon_name, "AceEvent-3.0") --[[@as CoordinatesTrackingAddon]]
addon.constants = private.constants
addon.constants.addon_name = private.addon_name
addon.Name = FOLDER_NAME
addon.LocName = select(2, GetAddOnInfo(addon.Name))
addon.Notes = select(3, GetAddOnInfo(addon.Name))
-- ToC Metadata
addon.Version 		= GetAddOnMetadata(addon.Name, "Version") or ""
addon.UpdateDate 	= GetAddOnMetadata(addon.Name, "X-Date") or ""
addon.Author 		= GetAddOnMetadata(addon.Name, "Author") or ""

_G.CoordsTracking = addon
---@type CoordinatesTrackingProfile
local profile
local locationText = ""

local isInLockdown = false

local CRDS_ORIG_GAMPTOOLTIP_SCALE = GameTooltip:GetScale()
local CRDS_POSTEXT = nil

local function getLocationText()
	local subZoneText = GetSubZoneText()
	local zoneText = GetZoneText()
	if (subZoneText == "") then
		locationText = zoneText
	else
		locationText = format("%s - %s", zoneText, subZoneText)
	end
	return locationText
end

-- Classic Forever now use so-called "Main Name" and "Secondary Name", it's more like the first and last name of the player. And both look to be mandatory. 
-- While in other game client, UnitName's second return value is actually the realmName
local function getPlayerSName()
    local firstName, secondName = UnitName("player")
	local storageName = firstName

    if Client.isForever and (secondName and secondName ~= "") then
        storageName = firstName .. " " .. secondName
    end

    return storageName
end

-- Codes adopted from Mapster
local function getCursorPositionText()
	local left, top = WorldMapScrollChild:GetLeft() or 0, WorldMapScrollChild:GetTop() or 0
	local width, height = WorldMapScrollChild:GetWidth(), WorldMapScrollChild:GetHeight()
	local scale = WorldMapScrollChild:GetEffectiveScale()
	
	local cx, cy, x, y
	
	if (width == 0) or (height == 0) then 
		cx, cy = 0, 0
	else
		x, y = GetCursorPosition()
		cx = (x/scale - left) / width
		cy = (top - y/scale) / height
	end 

	if (cx < 0 or cx > 1 or cy < 0 or cy > 1) then
		return
	end

	local crdsTextTemplate = "%%.%df"..L["COMMA"].."%%.%df"
	local crdsText, posText
	local acc = profile.worldmap_accuracy
	
	crdsText = crdsTextTemplate:format(acc, acc)
	
	posText = format(crdsText, cx*100, cy*100)
	
	return posText
end

-- Instances and garrisons are treated the same way everywhere: the on-screen
-- frame, the zone tooltip and the coordinates all follow profile.show_indungeon.
---@return boolean
local function isInInstanceOrGarrison()
	if IsInInstance() then
		return true
	end
	if C_Garrison and C_Garrison.IsOnGarrisonMap and C_Garrison.IsOnGarrisonMap() then
		return true
	end
	return false
end

---@param isWorldMap boolean?
---@return string?
local function getPlayerPositionText(isWorldMap)
	local crdsTextTemplate = "%%.%df"..L["COMMA"].."%%.%df"
	local acc = isWorldMap and profile.worldmap_accuracy or profile.coords_accuracy
	local crdsText = crdsTextTemplate:format(acc, acc)

	local isRestricted = isInInstanceOrGarrison()
	if (isRestricted and not profile.show_indungeon) then
		return ""
	end

	local uiMapID = GetBestMapForUnit("player")
	local posXY = uiMapID and GetPlayerMapPosition(uiMapID, "player")
	local posX, posY
	if (posXY) then
		posX, posY = posXY:GetXY()
	end

	if (posX and posY) then
		return format(crdsText, posX*100, posY*100)
	elseif (isRestricted) then
		-- Most instances don't expose the player position; show zeros using the
		-- configured accuracy and localized separator instead of a fixed "0.0, 0.0".
		return format(crdsText, 0, 0)
	end
	return nil
end

local function getButtonText()
	local posText = ""
	local playerPosText = getPlayerPositionText()

	if (profile.show_zonename) then
		if ( isInInstanceOrGarrison() ) then
			if (profile.show_indungeon) then 
				posText = format("%s"..L["COLON"].."%s", locationText or "", playerPosText or "")
			else
				posText = ""
			end
		else
			posText = format("%s"..L["COLON"].."%s", locationText or "", playerPosText or "")
		end
	else
		posText = playerPosText or ""
	end

	return posText
end

local function updateButtonText()
	if (profile.show_coords_onscreen) then
	
		local posText
		-- Hide the coordinates tracking frame if the player is in an instance and the frame is visible.
		if (isInInstanceOrGarrison() and MyFrame:IsVisible() and not profile.show_indungeon) then
			posText = " "
			if (MyFrame:IsShown()) then
				addon.Text:SetText(posText)
			end
			return
		end

		posText = getButtonText() or ""
		if (posText ~= CRDS_POSTEXT) then
			local pvpType = GetZonePVPInfo()
			local color = {}

			if ( pvpType == "sanctuary" ) then
				color = {r=0.41, g=0.8, b=0.94}
			elseif ( pvpType == "arena" ) then
				color = {r=1.0, g=0.1, b=0.1}
			elseif ( pvpType == "friendly" ) then
				color = {r=0.1, g=1.0, b=0.1}
			elseif ( pvpType == "hostile" ) then
				color = {r=1.0, g=0.1, b=0.1}
			elseif ( pvpType == "contested" ) then
				color = {r=1.0, g=0.7, b=0.0}
			else
				--color = {r=HIGHLIGHT_FONT_COLOR.r, g=HIGHLIGHT_FONT_COLOR.g, b=HIGHLIGHT_FONT_COLOR.b}
				color.r, color.g, color.b = HIGHLIGHT_FONT_COLOR:GetRGB()
			end

			local colortag = format("|cff%02x%02x%02x", color.r * 255, color.g * 255, color.b * 255)

			if (MyFrame:IsShown()) then
				addon.Text:SetText(posText)
				addon:SetWidth(MyFrame.Text:GetStringWidth())
				addon.Text:SetTextColor(color.r, color.g, color.b)
			end

			LDB.text = colortag..posText..FONT_COLOR_CODE_CLOSE
			CRDS_POSTEXT = posText
		end
	end
end

local function updateWorldmapText(isInitialize)
	local isWorldMapOpened = WorldMapFrame:IsShown()
	local WMFrame = addon.WorldMapFrame
	local playerPosText = getPlayerPositionText(true) or ""
	local playerName = getPlayerSName()

	if (profile.show_coords_onworldmap and (isWorldMapOpened or isInitialize)) then
		WMFrame.playerTxt:SetText(playerName..L["COLON"]..playerPosText)
		local cursorPos = getCursorPositionText()
		if (cursorPos) then
			WMFrame.cursorTxt:SetText(L["Cursor"]..L["COLON"]..cursorPos)
			WMFrame.cursorTxt:Show()
		else
			--WMFrame.cursorTxt:SetText("")
			WMFrame.cursorTxt:Hide()
		end
	end
end


-- GameTooltip has no SetBackdropColor on current clients: it inherits
-- SharedTooltipArtTemplate, whose background is the NineSlice center. Blizzard
-- resets it in GameTooltip_OnHide (SharedTooltip_SetBackdropStyle), so the alpha
-- doesn't leak into other tooltips.
---@param tooltip GameTooltip
---@param alpha number
local function setTooltipBackgroundAlpha(tooltip, alpha)
	local nineSlice = tooltip.NineSlice
	if nineSlice then
		nineSlice:SetCenterColor(0, 0, 0, alpha)
	end
end

local function get_zonename_tooltip(frame)
	if (not GameTooltip:IsShown()) then
		local pvpType, isSubZonePvP, factionName = GetZonePVPInfo()
		local zoneText = locationText
		if frame then GameTooltip:SetOwner(frame, "ANCHOR_BOTTOM", -10, 0) end
		setTooltipBackgroundAlpha(GameTooltip, profile.tooltip_alpha)
		if ( pvpType == "sanctuary" ) then
			GameTooltip:SetText( zoneText.." "..SANCTUARY_TERRITORY, 0.41, 0.8, 0.94 )
		elseif ( pvpType == "arena" ) then
			GameTooltip:SetText( zoneText.." "..FREE_FOR_ALL_TERRITORY, 1.0, 0.1, 0.1 )	
		elseif ( pvpType == "friendly" ) then
			GameTooltip:SetText( zoneText, 0.1, 1.0, 0.1 )
			GameTooltip:AddLine(format(FACTION_CONTROLLED_TERRITORY, factionName), 0.1, 1.0, 0.1)
		elseif ( pvpType == "hostile" ) then
			GameTooltip:SetText( zoneText, 1.0, 0.1, 0.1 )
			GameTooltip:AddLine(format(FACTION_CONTROLLED_TERRITORY, factionName), 1.0, 0.1, 0.1)
		elseif ( pvpType == "contested" ) then
			GameTooltip:SetText( zoneText.." "..CONTESTED_TERRITORY, 1.0, 0.7, 0.0 )	
		elseif ( pvpType == "combat" ) then
			GameTooltip:SetText( zoneText.." "..COMBAT_ZONE, 1.0, 0.1, 0.1 )
		else
			GameTooltip:SetText( zoneText, NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b )
		end
		GameTooltip:SetScale(profile.tooltip_scale)
		GameTooltip:Show()
	else
		GameTooltip:Hide()
	end
end

local function onscreenFrameStatusRefresh()
	local f = _G[private.addon_name.."Frame"]
	if (f and profile.show_coords_onscreen) then
		if (isInInstanceOrGarrison() and (not profile.show_indungeon)) then
			f:Hide()
		else
			f:Show()
			f:SetAlpha(profile.alpha)
			f:SetScale(profile.scale)
			local lp = profile.latestpoint
			local point, relativePoint, ofsx, ofsy = lp[1], lp[2], lp[3], lp[4]
			f:ClearAllPoints()
			f:SetPoint(point or "TOPLEFT", UIParent, relativePoint or "TOPLEFT", ofsx or 450, ofsy or -80)
		end
	elseif (f) then
		f:Hide()
	else
		-- do nothing
	end
end

-- Re-evaluate the on-screen frame visibility after a zone change, so entering or
-- leaving an instance/garrison shows or hides it without a /reload. Only touches
-- the frame when the state actually changes, so a frame being dragged isn't reset.
local function onscreenFrameVisibilityRefresh()
	local f = _G[private.addon_name.."Frame"]
	if not (f and profile) then return end
	local shouldShow = profile.show_coords_onscreen and not (isInInstanceOrGarrison() and not profile.show_indungeon)
	if (shouldShow and not f:IsShown()) or (not shouldShow and f:IsShown()) then
		onscreenFrameStatusRefresh()
	end
end

local function setupCoordsTrackingFrame()
	local function onShow()
		CRDS_POSTEXT = nil
	end

	local function onMouseDown(self, buttonName)    
		-- Prevent activation when in combat
		if (isInLockdown) then
			return
		end
		if(MyFrame:IsVisible()) then
			-- Handle left button clicks
			if (buttonName == "LeftButton") then
				-- Hide tooltip while draging
				GameTooltip:Hide()
				MyFrame:StartMoving()
			elseif (buttonName == "RightButton") then
				addon:OpenOptions()
				GameTooltip_Hide()
			end
		end
	end

	local function onMouseUp(self, buttonName)
		if(MyFrame:IsVisible()) then
			MyFrame:StopMovingOrSizing()
			local point, _, relativePoint, offsetX, offsetY = MyFrame:GetPoint()
			profile.latestpoint = { point, relativePoint, offsetX, offsetY }
		end
	end

	local function onEnter(self)
		if (isInLockdown) then
			return
		end
		if (isInInstanceOrGarrison() and MyFrame:IsVisible() and not profile.show_indungeon) then
			MyFrame:Hide()
		else
			MyFrame:Show()
		end

		if (profile.show_zonenametooltip) then
			if(MyFrame:IsVisible() and (not isInInstanceOrGarrison())) then
				get_zonename_tooltip(self)
			end
		end
	end

	local function onLeave(self)
		GameTooltip_Hide()
		GameTooltip:SetScale(CRDS_ORIG_GAMPTOOLTIP_SCALE)
	end

	local function onUpdate()
		updateButtonText()
	end

	local name = addon.Name
	
	local f = _G[name.."Frame"]
	if not f then f = CreateFrame("Frame", name.."Frame", UIParent, BackdropTemplateMixin and "BackdropTemplate") end
	f:SetWidth(200)
	f:SetHeight(28)
	--f:SetText(name)
	local lp = profile.latestpoint
	local point, relativePoint, ofsx, ofsy = lp[1], lp[2], lp[3], lp[4]
	f:SetPoint(point or "TOPLEFT", UIParent, relativePoint or "TOPLEFT", ofsx or 450, ofsy or -80)
	
	f.Background = f:CreateTexture(name.."Background", "BACKGROUND")
	f.Border = CreateFrame("Frame", name.."Border", f, BackdropTemplateMixin and "BackdropTemplate" or nil)
	
	f.Text = f:CreateFontString(name.."Text", "OVERLAY", "NumberFontNormal")
	f.Text:SetPoint("CENTER", 0, 0)
	
	f:RegisterForDrag("LeftButton")
	f:SetClampedToScreen(true)
	f:SetMovable(true)
	f:EnableMouse(true)
	
	-- SetScript
	f:SetScript("OnEnter", onEnter)
	f:SetScript("OnLeave", onLeave)
	f:SetScript("OnMouseDown", onMouseDown)
	f:SetScript("OnMouseUp", onMouseUp)
	f:SetScript("OnShow", onShow)
	f:SetScript("OnUpdate", onUpdate)
end

local function setupLDB()
	-- setup LDB
	LDB.text = getButtonText()
	LDB.OnClick = (function(self, button) addon:OpenOptions() end)
	LDB.OnTooltipShow = (function(tooltip)
		if not tooltip or not tooltip.AddLine then return end
		if (profile.show_zonenametooltip) then
			get_zonename_tooltip()
		end
	end)
end

function addon:SetOnScreenFontStyle()
	local f = _G[private.addon_name.."Frame"]
	if (f) then
		local newfont = Media:Fetch("font", profile.font_onscreen)
		f.Text:SetFont(newfont, profile.fontsize_onscreen, profile.fontoutline_onscreen and "OUTLINE" or nil)
	end
end

function addon:SetOnScreenBackground()
	local f = _G[private.addon_name.."Frame"]
	if (f) then
		f.Background:SetAllPoints()
		f.Background:SetTexture(profile.background or nil)
		f.Background:SetSize(f:GetWidth(), f:GetHeight())
		f.Background:SetPoint("TOPLEFT", 0, 0)
		local t = profile.backgroundColor or nil
		if t then
			f.Background:SetVertexColor(t.r, t.g, t.b, t.a)
		else
			f.Background:SetVertexColor(0, 0, 0, 1)
		end
	end
end

function addon:SetWorldMapFontStyle()
	local f = _G[worldmapName]
	if (f) then
		local newfont = Media:Fetch("font", profile.font_worldmap)
		f.playerTxt:SetFont(newfont, profile.fontsize_worldmap, profile.fontoutline_worldmap and "OUTLINE" or nil)
		f.cursorTxt:SetFont(newfont, profile.fontsize_worldmap, profile.fontoutline_worldmap and "OUTLINE" or nil)
	end
end

function addon:SetWorldMapFontColor()
	local f = _G[worldmapName]
	local color = profile.fontcolor_worldmap
	if (f) then
		f.playerTxt:SetTextColor(color.r or 1, color.g or 1, color.b or 1)
		f.cursorTxt:SetTextColor(color.r or 1, color.g or 1, color.b or 1)
	end
end

local function CoordsOnWorldMapFrameRefresh()
	local ofsx_diff1, ofsy_diff1, ofsy_diff2 = 0, 0, 0
	if (Client.isRetail) then
		ofsy_diff2 = -4
	elseif (Client.isProgressionClassic) then
		-- for now no adjustments needed
	elseif (Client.isForever) then
		ofsx_diff1 = 120
		ofsy_diff1 = 6
		ofsy_diff2 = -10
	else
		ofsy_diff1 = 6
		ofsy_diff2 = 20
	end

	local f = _G[worldmapName]
	if not f then return end
	updateWorldmapText(true)
	if (profile.wmPoint) then
		local wp = profile.wmPoint
		local point, relativePoint, ofsx, ofsy = wp.point, wp.relativePoint, wp.ofsx, wp.ofsy
		-- adjust horizontal offset for right-aligned points
		if (point == "TOPRIGHT" or point == "BOTTOMRIGHT") then
			ofsx = -ofsx - ofsx_diff1
		end
		-- offset when point is at the top or bottom
		if (point == "TOPRIGHT" or point == "TOPLEFT") then
			ofsy = - ofsy - ofsy_diff1
		else
			ofsy = ofsy - ofsy_diff2
		end
		
		if (point == "TOPRIGHT" or point == "BOTTOMRIGHT") then
			f.cursorTxt:ClearAllPoints()
			f.cursorTxt:SetPoint(point, WorldMapFrame.ScrollContainer, relativePoint, ofsx, ofsy)
			f.playerTxt:ClearAllPoints()
			f.playerTxt:SetPoint("TOPRIGHT", f.cursorTxt, "TOPLEFT", -20, 0)
		else
			f.playerTxt:ClearAllPoints()
			f.playerTxt:SetPoint(point or "TOPLEFT", WorldMapFrame.ScrollContainer, relativePoint or "TOPLEFT", ofsx or 0, ofsy or 0)
			f.cursorTxt:ClearAllPoints()
			f.cursorTxt:SetPoint("TOPLEFT", f.playerTxt, "TOPRIGHT", 20, 0)
		end
	end
end

---@return CoordinatesTrackingWorldMapFrame
local function createCoordsOnWorldMapFrame()
	---@type CoordinatesTrackingWorldMapFrame
	local f = _G[worldmapName]
	if not f then f = CreateFrame("Frame", worldmapName, WorldMapFrame.ScrollContainer, BackdropTemplateMixin and "BackdropTemplate") --[[@as CoordinatesTrackingWorldMapFrame]] end
	
	local function onUpdate()
		updateWorldmapText()
	end

	f.playerTxt = f:CreateFontString(worldmapName.."PlayerText", "OVERLAY", "NumberFontNormal")
	--f.playerTxt:SetPoint("TOPLEFT", f, "TOPLEFT", 0, 0)

	f.cursorTxt = f:CreateFontString(worldmapName.."CursorText", "OVERLAY", "NumberFontNormal")
	--f.cursorTxt:SetPoint("TOPLEFT", f.playerTxt, "TOPRIGHT", 20, 0)

	f:SetScript("OnUpdate", onUpdate)

	return f
end

function addon:OnInitialize()
	self.db = AceDB:New(addon.Name.."DB", addon.constants.defaults, true) --[[@as CoordinatesTrackingDB]]
	profile = self.db.profile
	
	if profile and profile.point then profile.point = nil end

	self.db.RegisterCallback(self, "OnProfileChanged", "Refresh")
	self.db.RegisterCallback(self, "OnProfileCopied", "Refresh")
	self.db.RegisterCallback(self, "OnProfileReset", "Refresh")

	self:SetupOptions()
end

function addon:OnEnable()
	setupCoordsTrackingFrame()
	self.WorldMapFrame = createCoordsOnWorldMapFrame()

	-- Register events
	for _, value in pairs( addon.constants.events ) do
		self:RegisterEvent( value )
	end

	setupLDB()
	if (profile.show_zonename and locationText == "") then
		getLocationText()
	end
	self:Refresh()
end

function addon:Refresh()
	profile = self.db.profile
	
	onscreenFrameStatusRefresh()
	CoordsOnWorldMapFrameRefresh()
	addon:SetOnScreenFontStyle()
	addon:SetWorldMapFontStyle()
	if (profile and profile.show_coords_onworldmap) then
		self.WorldMapFrame:Show()
	else
		self.WorldMapFrame:Hide()
	end
	addon:SetOnScreenBackground()
end

function addon:PLAYER_REGEN_DISABLED()
	isInLockdown = true
end

function addon:PLAYER_REGEN_ENABLED()
	isInLockdown = false
end

function addon:PLAYER_ENTERING_WORLD()
	if (profile.show_zonename) then getLocationText() end
	onscreenFrameVisibilityRefresh()
end

function addon:ZONE_CHANGED()
	if (profile.show_zonename) then getLocationText() end
	onscreenFrameVisibilityRefresh()
end

function addon:ZONE_CHANGED_NEW_AREA()
	if (profile.show_zonename) then getLocationText() end
	onscreenFrameVisibilityRefresh()
end

function addon:ZONE_CHANGED_INDOORS()
	if (profile.show_zonename) then getLocationText() end
	onscreenFrameVisibilityRefresh()
end
