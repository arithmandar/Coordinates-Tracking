--[[
$Id$
]]
-----------------------------------------------------------------------
-- Upvalued Lua API.
-----------------------------------------------------------------------
-- Functions
local _G = getfenv(0)
-- Libraries
local math = _G.math;

local LibStub = _G.LibStub;
local L = LibStub("AceLocale-3.0"):GetLocale("CoordsTracking");

function CoordsTrackingOptions_Toggle()
	if(InterfaceOptionsFrame:IsVisible()) then
		InterfaceOptionsFrame:Hide();
	else
		InterfaceOptionsFrame_OpenToCategory(L["TITLE"]);
		-- Yes we have to call this twice
		InterfaceOptionsFrame_OpenToCategory(L["TITLE"]);
	end
end

function CoordsTrackingOptions_OnLoad(self)
	UIPanelWindows['CoordsTrackingOptionsFrame'] = {area = 'center', pushable = 0};
	
	self.name = L["TITLE"];
	InterfaceOptions_AddCategory(self);
	if (LibStub:GetLibrary("LibAboutPanel", true)) then
		LibStub("LibAboutPanel").new(L["TITLE"], "CoordsTracking");
	end
end

function CoordsTrackingOptions_OnShow()
	local options = CoordsTrackingDB[CRDS_Server][CRDS_Player]["options"];
	
	CoordsTrackingOptionsFrame_ShowOnScreen:SetChecked(options.show_coords_onscreen);
	CoordsTrackingOptionsFrame_ShowZoneName:SetChecked(options.show_zonename);
	CoordsTrackingOptionsFrame_ShowZoneNameTooltip:SetChecked(options.show_zonenametooltip);
	CoordsTrackingOptionsFrame_ShowOnWorldMap:SetChecked(options.show_coords_onworldmap);
	CoordsTrackingOptionsFrameSliderAccuracy:SetValue(options.coords_accuracy);
	CoordsTrackingOptionsFrameSliderAlpha:SetValue(options.tooltip_alpha);
	CoordsTrackingOptionsFrameSliderToolTipScale:SetValue(options.tooltip_scale);
end

function CoordsTrackingOptions_OnHide(self)
	if(MYADDONS_ACTIVE_OPTIONSFRAME == self) then
		ShowUIPanel(myAddOnsFrame);
	end
end

function CoordsTrackingOptions_ShowOnScreenToggle()
	local options = CoordsTrackingDB[CRDS_Server][CRDS_Player]["options"];
	
	if(CoordsTrackingFrame:IsVisible()) then
		CoordsTrackingFrame:Hide();
		options.show_coords_onscreen = false;
		CoordsTrackingOptionsFrame_ShowZoneName:Disable();
	else
		CoordsTrackingFrame:Show();
		options.show_coords_onscreen = true;
		CoordsTrackingOptionsFrame_ShowZoneName:Enable();
	end
end

function CoordsTrackingOptions_ShowZoneNameToggle()
	local options = CoordsTrackingDB[CRDS_Server][CRDS_Player]["options"];

	options.show_zonename = not options.show_zonename;
end

function CoordsTrackingOptions_ShowZoneNameTooltipToggle()
	local options = CoordsTrackingDB[CRDS_Server][CRDS_Player]["options"];

	options.show_zonenametooltip = not options.show_zonenametooltip;
end

function CoordsTrackingOptions_ShowOnWorldMapToggle()
	local options = CoordsTrackingDB[CRDS_Server][CRDS_Player]["options"];

	options.show_coords_onworldmap = not options.show_coords_onworldmap;
	if (options.show_coords_onworldmap) then
		CoordsOnWorldMapFrame:Show();
	else
		CoordsOnWorldMapFrame:Hide();
	end
end

function CoordsTrackingOptions_ResetPosition()
	local options = CoordsTrackingDB[CRDS_Server][CRDS_Player]["options"];

	CoordsTrackingFrame:SetPoint("TOPLEFT", nil, "TOPLEFT", 450, -80);
	options.offsetx = 450;
	options.offsety = -80;
end

function CoordsTrackingOptions_SetupSlider(self, text, mymin, mymax, step)
	self:SetMinMaxValues(mymin, mymax);
	self:SetValueStep(step);
end

local function round(num, idp)
   local mult = 10 ^ (idp or 0);
   return math.floor(num * mult + 0.5) / mult;
end

local function CoordsTrackingOptions_UpdateSlider(self, text)
	_G[self:GetName().."Text"]:SetText("|cffffd200"..text.." ("..round(self:GetValue(), 3)..")");
end

function CoordsTrackingOptions_SliderAccuracyOnValueChanged(self)
	local options = CoordsTrackingDB[CRDS_Server][CRDS_Player]["options"];
	
	CoordsTrackingOptions_UpdateSlider(self, CRDS_OPT_ACCURACY);
	options.coords_accuracy = self:GetValue();
end

function CoordsTrackingOptions_SliderAlphaOnValueChanged(self)
	local options = CoordsTrackingDB[CRDS_Server][CRDS_Player]["options"];
	
	CoordsTrackingOptions_UpdateSlider(self, CRDS_OPT_TRANSPARENCY);
	options.tooltip_alpha = self:GetValue();
end

function CoordsTrackingOptions_SliderToolTipScaleOnValueChanged(self)
	local options = CoordsTrackingDB[CRDS_Server][CRDS_Player]["options"];
	
	CoordsTrackingOptions_UpdateSlider(self, CRDS_OPT_TOOLTIPSCALE);
	options.tooltip_scale = self:GetValue();
end

function CoordsTrackingOptions_OnMouseWheel(self, delta)
	if (delta > 0) then
		self:SetValue(self:GetValue() + self:GetValueStep())
	else
		self:SetValue(self:GetValue() - self:GetValueStep())
	end
end

