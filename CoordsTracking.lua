-- $Id$
-----------------------------------------------------------------------
-- Upvalued Lua API.
-----------------------------------------------------------------------
local _G = getfenv(0)

-- Functions
local ipairs = _G.ipairs
local pairs = _G.pairs
CRDS_Player = UnitName("player");
CRDS_Server = GetRealmName();

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
	tooltip_alpha = 0.9,
	tooltip_scale = 1;
};

local CRDS_Events = {
	"ADDON_LOADED",
	"PLAYER_ENTERING_WORLD",
	"PLAYER_LEAVING_WORLD",
	"PLAYER_LOGIN",
	"PLAYER_REGEN_ENABLED",
	"PLAYER_REGEN_DISABLED",
};


local LibStub = _G.LibStub;
local L = LibStub("AceLocale-3.0"):GetLocale("CoordsTracking");

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

function CRDS_GetButtonText()
	local posText = CRDS_GetPlayerPositionText();
	local options = CoordsTrackingDB[CRDS_Server][CRDS_Player]["options"];

	if (posText) then 
		if (options.show_zonename) then
			if ( IsInInstance() ) then 
				posText = format("|cffffffff%s", CRDS_GetZoneText());
			else
				posText = format("|cffffffff%s"..L["COLON"]..posText, CRDS_GetZoneText());
			end
		else
			posText = "|cffffffff"..posText;
		end
	else
		posText = L["TITLE"];
	end

	return posText;
end

function Currency_UpdateAlpha()
	local options = CoordsTrackingDB[CRDS_Server][CRDS_Player]["options"];
	
	AtlasFrame:SetAlpha(options.tooltip_alpha);
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

function CRDS_InitOptions()
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
end

function CRDS_Init()
	CRDS_InitOptions();
	local options = CoordsTrackingDB[CRDS_Server][CRDS_Player]["options"];

	if(options.show_coords_onscreen == true) then
		CoordsTrackingFrame:Show();
	else
		CoordsTrackingFrame:Hide();
	end
end

function CRDS_GetPlayerPositionText()
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

function CRDS_Frame_Update()
	local options = CoordsTrackingDB[CRDS_Server][CRDS_Player]["options"];
	local posText = CRDS_GetButtonText();
	if (posText ~= CRDS_POSTEXT) then
		CoordsTrackingFrame:SetText(posText);
		CoordsTrackingFrame:SetWidth(CoordsTrackingFrame:GetTextWidth()+10);
		LDB_CoordsTracking.text = posText;
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

function CRDS_Frame_HandleMouseDown(self, buttonName)    
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

function CRDS_Frame_HandleMouseUp(self, buttonName)
	if(CoordsTrackingFrame:IsVisible()) then
		CoordsTrackingFrame:StopMovingOrSizing();
	end
end

function CRDS_Frame_OnEnter(self)
	if (isInLockdown) then
		return;
	end

	local options = CoordsTrackingDB[CRDS_Server][CRDS_Player]["options"];
	
	if (options.show_zonenametooltip) then
		if(CoordsTrackingFrame:IsVisible()) then
			if (not GameTooltip:IsShown()) then
				GameTooltip:SetOwner(self, "ANCHOR_BOTTOM", -10, 0);
				GameTooltip:SetBackdropColor(0, 0, 0, options.tooltip_alpha);
				GameTooltip:SetText("|cFFFFFFFF"..CRDS_GetZoneText(), 1, 1, 1, nil, 1);
				GameTooltip:SetScale(options.tooltip_scale);
				GameTooltip:Show();
			else
				GameTooltip:Hide();
			end
		end
	end
end

function CRDS_Frame_OnLeave(self)
	GameTooltip_Hide();
	GameTooltip:SetScale(CRDS_ORIG_GAMPTOOLTIP_SCALE);
end

