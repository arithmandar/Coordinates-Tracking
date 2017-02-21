-- $Id$
-----------------------------------------------------------------------
-- Upvalued Lua API.
-----------------------------------------------------------------------
-- Functions
local _G = getfenv(0)
local pairs = _G.pairs
-- Libraries

CRDS_Player = UnitName("player");
CRDS_Server = GetRealmName();

local LibStub = _G.LibStub;
local L = LibStub("AceLocale-3.0"):GetLocale("CoordsTracking");

local CRDS_Version = GetAddOnMetadata("CoordsTracking", "Version");
local CRDS_Category = GetAddOnMetadata("CoordsTracking", "X-Category");
local isInLockdown = false;
local CRDS_ORIG_GAMPTOOLTIP_SCALE = GameTooltip:GetScale();
local CRDS_POSTEXT = nil;

local CRDS_DefaultOptions = {
	offsetx = 450,
	offsety = -80,
	show_coords_onscreen = true,
	show_zonename = true,
	show_zonenametooltip = true,
	show_coords_onworldmap = true,
	coords_accuracy = 1,
	alpha = 1,
	scale = 1,
	tooltip_alpha = 0.9,
	tooltip_scale = 1,
};

local CRDS_Events = {
	"ADDON_LOADED",
	"PLAYER_ENTERING_WORLD",
	"PLAYER_LEAVING_WORLD",
	"PLAYER_LOGIN",
	"PLAYER_REGEN_ENABLED",
	"PLAYER_REGEN_DISABLED",
};

local function CRDS_UpdateOptions(player_options)
	for k, v in pairs(CRDS_DefaultOptions) do
		if (player_options[k] == nil) then
			player_options[k] = v;
		end
	end
end

local function CRDS_GetZoneText()
	local posText;
	if (GetSubZoneText() == "") then
		posText = GetZoneText();
	else
		posText = format("%s - %s", GetZoneText(), GetSubZoneText());
	end
	return posText;
end

-- Codes adopted from Mapster
local function CRDS_GetCursorPosition()
	local left, top = WorldMapDetailFrame:GetLeft(), WorldMapDetailFrame:GetTop();
	local width, height = WorldMapDetailFrame:GetWidth(), WorldMapDetailFrame:GetHeight();
	local scale = WorldMapDetailFrame:GetEffectiveScale();

	local x, y = GetCursorPosition();
	local cx = (x/scale - left) / width;
	local cy = (top - y/scale) / height;

	if (cx < 0 or cx > 1 or cy < 0 or cy > 1) then
		return
	end

	local options = CoordsTrackingDB[CRDS_Server][CRDS_Player]["options"];
	local crdsTextTemplate, crdsText, posText = "%%.%df, %%.%df";
	local acc = options.coords_accuracy;
	
	crdsText = crdsTextTemplate:format(acc, acc);
	
	-- SetMapToCurrentZone(); -- this should not be called
	posX, posY = GetPlayerMapPosition("player");
	
	posText = format(crdsText, cx*100, cy*100);
	
	return posText;
end

local LDB_CoordsTracking = LibStub:GetLibrary("LibDataBroker-1.1"):NewDataObject("CoordsTracking", {
	type = "data source",
	text = L["TITLE"],
	label = L["TITLE"],
	icon = "Interface\\MINIMAP\\MinimapArrow",
	OnClick = function(self, button)
		if button == "LeftButton" then
			CRDS_OnClick();
		elseif button == "RightButton" then
			CoordsTrackingOptions_Toggle();
		end
	end,
	OnTooltipShow = function(tooltip)
		if not tooltip or not tooltip.AddLine then return end
		local options = CoordsTrackingDB[CRDS_Server][CRDS_Player]["options"];
		if (options.show_zonenametooltip) then
			GameTooltip:SetBackdropColor(0, 0, 0, options.tooltip_alpha);
			GameTooltip:SetText(CRDS_GetZoneText(), 1, 1, 1, nil, 1);
			GameTooltip:SetScale(options.tooltip_scale);
		end;
	end,
});

local function CRDS_GetPlayerPositionText()
	local posText, posX, posY;
	local options = CoordsTrackingDB[CRDS_Server][CRDS_Player]["options"];
	local crdsTextTemplate, crdsText = "%%.%df, %%.%df";
	local acc = options.coords_accuracy;
	
	crdsText = crdsTextTemplate:format(acc, acc);
	
	-- SetMapToCurrentZone();
	if ( IsInInstance() ) then
		posX = 0;
		posY = 0;
	else
		posX, posY = GetPlayerMapPosition("player");
	end
	
	posText = format(crdsText, posX*100, posY*100);
	
	return posText;
end

local function CRDS_GetButtonText()
	local posText = CRDS_GetPlayerPositionText();
	local options = CoordsTrackingDB[CRDS_Server][CRDS_Player]["options"];

	if (posText) then 
		if (options.show_zonename) then
			if ( IsInInstance() ) then 
				posText = CRDS_GetZoneText();
			else
				posText = format("%s"..L["COLON"]..posText, CRDS_GetZoneText());
			end
		else
			--posText = "|cffffffff"..posText;
		end
	else
		posText = L["TITLE"];
	end

	return posText;
end

--[[
function CRDS_UpdateAlpha()
	local options = CoordsTrackingDB[CRDS_Server][CRDS_Player]["options"];
	
	CoordsTrackingFrame:SetAlpha(options.tooltip_alpha);
end
]]

local function CRDS_InitOptions()
	if ( CoordsTrackingDB == nil ) then
		CoordsTrackingDB = { };
	end
	if ( CoordsTrackingDB[CRDS_Server] == nil ) then
		CoordsTrackingDB[CRDS_Server] = { };
	end
	if ( CoordsTrackingDB[CRDS_Server][CRDS_Player] == nil ) then
		CoordsTrackingDB[CRDS_Server][CRDS_Player] = { };
	end
	if ( CoordsTrackingDB[CRDS_Server][CRDS_Player]["options"] == nil ) then
		CoordsTrackingDB[CRDS_Server][CRDS_Player]["options"] = CRDS_DefaultOptions;
	end
	
	local options = CoordsTrackingDB[CRDS_Server][CRDS_Player]["options"];
	CRDS_UpdateOptions(options);
end

local function CRDS_Init()
	CRDS_InitOptions();
	local options = CoordsTrackingDB[CRDS_Server][CRDS_Player]["options"];

	if(options.show_coords_onscreen == true) then
		CoordsTrackingFrame:Show();
		CoordsTrackingFrame:SetAlpha(options.alpha);
		CoordsTrackingFrame:SetScale(options.scale);
	else
		CoordsTrackingFrame:Hide();
	end
end

function CRDS_OnLoad(self)
	-- Register the CoordsTracking frame for the following events
        for key, value in pairs( CRDS_Events ) do
            self:RegisterEvent( value );
        end

	self:RegisterForDrag("LeftButton");
end

function CRDS_OnEvent(self, event, ...)
	local arg1 = ...;
	if (event == "ADDON_LOADED" and arg1 == "CoordsTracking") then
		CRDS_Init();
	end
	-- for combact lockdown
	if (event == "PLAYER_REGEN_DISABLED") then
		isInLockdown = true;
	elseif (event == "PLAYER_REGEN_ENABLED") then
		isInLockdown = false;
	end
	
	--LDB_CoordsTracking.text = CRDS_GetButtonText();
end

function CRDS_OnUpdate()
	local options = CoordsTrackingDB[CRDS_Server][CRDS_Player]["options"];
	local posText = CRDS_GetButtonText();
	if (posText ~= CRDS_POSTEXT) then
		local pvpType = GetZonePVPInfo();
		local color = {};

		if ( pvpType == "sanctuary" ) then
			color = {r=0.41, g=0.8, b=0.94};
		elseif ( pvpType == "arena" ) then
			color = {r=1.0, g=0.1, b=0.1};
		elseif ( pvpType == "friendly" ) then
			color = {r=0.1, g=1.0, b=0.1};
		elseif ( pvpType == "hostile" ) then
			color = {r=1.0, g=0.1, b=0.1};
		elseif ( pvpType == "contested" ) then
			color = {r=1.0, g=0.7, b=0.0};
		else
			color = {r=HIGHLIGHT_FONT_COLOR.r, g=HIGHLIGHT_FONT_COLOR.g, b=HIGHLIGHT_FONT_COLOR.b};
		end

		local colortag = string.format("|cff%02x%02x%02x", color.r * 255, color.g * 255, color.b * 255);

		if (CoordsTrackingFrame:IsShown()) then
			CoordsTrackingFrame.Text:SetText(posText);
			CoordsTrackingFrame:SetWidth(CoordsTrackingFrame.Text:GetStringWidth());
			CoordsTrackingFrame.Text:SetTextColor(color.r, color.g, color.b);
		end

		LDB_CoordsTracking.text = colortag..posText..FONT_COLOR_CODE_CLOSE;
		CRDS_POSTEXT = posText;
	end

	if (options.show_coords_onworldmap) then
		CoordsOnWorldMapFramePlayerText:SetText(UnitName("player")..L["COLON"]..CRDS_GetPlayerPositionText());
		local cursorPos = CRDS_GetCursorPosition();
		if (cursorPos) then
			CoordsOnWorldMapFrameCursorText:SetText(L["CURSOR"]..L["COLON"]..cursorPos);
		else
			CoordsOnWorldMapFrameCursorText:SetText("");
		end
	end
end

function CRDS_OnShow()
	CRDS_POSTEXT = nil;
end

function CRDS_OnMouseDown(self, buttonName)    
	-- Prevent activation when in combat
	if (isInLockdown) then
		return;
	end
	if(CoordsTrackingFrame:IsVisible()) then
		-- Handle left button clicks
		if (buttonName == "LeftButton") then
			-- Hide tooltip while draging
			GameTooltip:Hide();
			CoordsTrackingFrame:StartMoving();
		elseif (buttonName == "RightButton") then
			CoordsTrackingOptions_Toggle();
			GameTooltip_Hide();
		end
	end
end

function CRDS_OnMouseUp(self, buttonName)
	if(CoordsTrackingFrame:IsVisible()) then
		CoordsTrackingFrame:StopMovingOrSizing();
	end
end

function CRDS_OnEnter(self)
	if (isInLockdown) then
		return;
	end

	local options = CoordsTrackingDB[CRDS_Server][CRDS_Player]["options"];
	
	if (options.show_zonenametooltip) then
		if(CoordsTrackingFrame:IsVisible()) then
			if (not GameTooltip:IsShown()) then
				local pvpType, isSubZonePvP, factionName = GetZonePVPInfo();
				local zoneText = CRDS_GetZoneText();
				GameTooltip:SetOwner(self, "ANCHOR_BOTTOM", -10, 0);
				GameTooltip:SetBackdropColor(0, 0, 0, options.tooltip_alpha);
				if ( pvpType == "sanctuary" ) then
					GameTooltip:SetText( zoneText.." "..SANCTUARY_TERRITORY, 0.41, 0.8, 0.94 );	
				elseif ( pvpType == "arena" ) then
					GameTooltip:SetText( zoneText.." "..FREE_FOR_ALL_TERRITORY, 1.0, 0.1, 0.1 );	
				elseif ( pvpType == "friendly" ) then
					GameTooltip:SetText( zoneText, 0.1, 1.0, 0.1 );	
					GameTooltip:AddLine(format(FACTION_CONTROLLED_TERRITORY, factionName), 0.1, 1.0, 0.1);
				elseif ( pvpType == "hostile" ) then
					GameTooltip:SetText( zoneText, 1.0, 0.1, 0.1 );	
					GameTooltip:AddLine(format(FACTION_CONTROLLED_TERRITORY, factionName), 1.0, 0.1, 0.1);
				elseif ( pvpType == "contested" ) then
					GameTooltip:SetText( zoneText.." "..CONTESTED_TERRITORY, 1.0, 0.7, 0.0 );	
				elseif ( pvpType == "combat" ) then
					GameTooltip:SetText( zoneText.." "..COMBAT_ZONE, 1.0, 0.1, 0.1 );	
				else
					GameTooltip:SetText( zoneText, NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b );	
				end
				GameTooltip:SetScale(options.tooltip_scale);
				GameTooltip:Show();
			else
				GameTooltip:Hide();
			end
		end
	end
end

function CRDS_OnLeave(self)
	GameTooltip_Hide();
	GameTooltip:SetScale(CRDS_ORIG_GAMPTOOLTIP_SCALE);
end

