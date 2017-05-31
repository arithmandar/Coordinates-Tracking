-- $Id: Config.lua 12 2017-05-09 04:27:23Z arith $
-----------------------------------------------------------------------
-- Upvalued Lua API.
-----------------------------------------------------------------------
-- Functions
local _G = getfenv(0)
local pairs = _G.pairs
-- Libraries
-- ----------------------------------------------------------------------------
-- AddOn namespace.
-- ----------------------------------------------------------------------------
local FOLDER_NAME, private = ...
local LibStub = _G.LibStub;
local addon = LibStub("AceAddon-3.0"):GetAddon(private.addon_name)
local L = LibStub("AceLocale-3.0"):GetLocale(private.addon_name);

local AceConfigReg = LibStub("AceConfigRegistry-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")
local AceDBOptions = LibStub("AceDBOptions-3.0")
local Media = LibStub("LibSharedMedia-3.0")

local profile

local optGetter, optSetter
do
	function optGetter(info)
		local key = info[#info]
		return addon.db.profile[key]
	end

	function optSetter(info, value)
		local key = info[#info]
		addon.db.profile[key] = value
		addon:Refresh()
	end
end

local options, moduleOptions = nil, {}

local function getOptions()
	profile = addon.db.profile
	if not options then
		options = {
			type = "group",
			name = addon.LocName,
			args = {
				general = {
					order = 1,
					type = "group",
					name = L["Options"],
					get = optGetter,
					set = optSetter,
					args = {
						version = {
							order = 1,
							type = "description",
							name = addon.Notes,
							width = "full",
						},
						group1 = {
							order = 10,
							type = "group",
							name = L["Display Settings"],
							--inline = true,
							args = {
								show_coords_onscreen = {
									order = 11,
									type = "toggle",
									name = L["Show coordinates info on screen"],
									width = "full",
								},
								show_zonename = {
									order = 12,
									type = "toggle",
									name = L["Show zone name together with coordinates"],
									width = "full",
									--disabled = function()
									--	return not profile.show_coords_onscreen
									--end,
								},
								show_zonenametooltip = {
									order = 13,
									type = "toggle",
									name = L["Show zone name as tooltip on coordinates when mouse hover"],
									width = "full",
								},
								show_coords_onworldmap = {
									order = 14,
									type = "toggle",
									name = L["Show coordinates info on world map"],
									width = "full",
								},
								resetPos = {
									order = 15, 
									type = "execute",
									name = L["Reset position"],
									func = function()
										CoordsTrackingFrame:SetPoint("TOPLEFT", nil, "TOPLEFT", 450, -80)
										profile.offsetx = 450
										profile.offsety = -80
									end,
								},
							},
						},
						group2 = {
							order = 20,
							type = "group",
							name = L["Font Settings"],
							--inline = true,
							args = {
								group21 = {
									order = 10,
									type = "group",
									name = L["Setup font style for on-screen frame"],
									inline = true,
									args = {
										font_onscreen = {
											order = 11,
											type = "select",
											dialogControl = 'LSM30_Font',
											name = L["Select font"],
											get = function()
												return profile.font_onscreen
											end,
											set = function(info, value)
												profile.font_onscreen = value
												addon:SetOnScreenFontStyle()
											end,
											values = AceGUIWidgetLSMlists.font,
										},
										fontsize_onscreen = {
											order = 12, 
											type = "range",
											name = L["Configure font size"],
											min = 7, max = 20, step = 1,
											get = function() 
												return profile.fontsize_onscreen
											end,
											set = function(info, value)
												profile.fontsize_onscreen = value
												addon:SetOnScreenFontStyle()
											end,
										},
										fontoutline_onscreen = {
											order = 13, 
											type = "toggle",
											name = L["Show outline"],
										},
									},
								},
								group22 = {
									order = 20,
									type = "group",
									name = L["Setup font style for coordinates on WorldMap frame"],
									inline = true,
									args = {
										font_worldmap = {
											order = 21,
											type = "select",
											dialogControl = 'LSM30_Font',
											name = L["Select font"],
											get = function()
												return profile.font_worldmap
											end,
											set = function(info, value)
												profile.font_worldmap =  value
												addon:SetWorldMapFontStyle()
											end,
											values = AceGUIWidgetLSMlists.font,
										},
										fontsize_worldmap = {
											order = 22, 
											type = "range",
											name = L["Configure font size"],
											min = 7, max = 20, step = 1,
											get = function() 
												return profile.fontsize_worldmap
											end,
											set = function(info, value)
												profile.fontsize_worldmap = value
												addon:SetWorldMapFontStyle()
											end,
										},
										fontoutline_worldmap = {
											order = 23, 
											type = "toggle",
											name = L["Show outline"],
										},
									},
								},
							},
						},
						group3 = {
							order = 30,
							type = "group",
							name = L["Coordinates' accuracy"],
							--inline = true,
							args = {
								coords_accuracy = {
									order = 11,
									type = "range",
									name = L["On-screen frame"],
									min = 0, max = 4, bigStep = 1, 
								},
								worldmap_accuracy = {
									order = 12,
									type = "range",
									name = WORLD_MAP,
									min = 0, max = 4, bigStep = 1, 
								},
							},
						},
						group4 = {
							order = 40,
							type = "group",
							name = L["Scale and Transparency"],
							--inline = true,
							args = {
								group41 = {
									order = 20,
									type = "group",
									name = L["On-screen frame"],
									inline = true,
									args = {
										alpha = {
											order = 21,
											type = "range",
											name = L["Transparency"],
											min = 0, max = 1, bigStep = 0.1, 
										},
										scale = {
											order = 22,
											type = "range",
											name = L["Scale"],
											min = 0, max = 3, bigStep = 0.1, 
										},
									},
								},
								group42 = {
									order = 30,
									type = "group",
									name = L["Tooltip"],
									inline = true,
									args = {
										tooltip_alpha = {
											order = 33,
											type = "range",
											name = L["Transparency"],
											min = 0, max = 1, bigStep = 0.1, 
										},
										tooltip_scale = {
											order = 34,
											type = "range",
											name = L["Scale"],
											min = 0, max = 1.75, bigStep = 0.01, 
										},
									},
								},
							},
						},
					},
				},
			},
		}
		for k,v in pairs(moduleOptions) do
			options.args[k] = (type(v) == "function") and v() or v
		end
	end
	
	return options
end

local function openOptions()
	-- open the profiles tab before, so the menu expands
	InterfaceOptionsFrame_OpenToCategory(addon.optionsFrames.Profiles)
	InterfaceOptionsFrame_OpenToCategory(addon.optionsFrames.Profiles) -- yes, run twice to force the tre get expanded
	InterfaceOptionsFrame_OpenToCategory(addon.optionsFrames.General)
	InterfaceOptionsFrame:Raise()
end

function addon:OpenOptions() 
	openOptions()
end

local function giveProfiles()
	return AceDBOptions:GetOptionsTable(addon.db)
end

function addon:SetupOptions()
	self.optionsFrames = {}

	-- setup options table
	AceConfigReg:RegisterOptionsTable(addon.LocName, getOptions)
	self.optionsFrames.General = AceConfigDialog:AddToBlizOptions(addon.LocName, nil, nil, "general")

	self:RegisterModuleOptions("Profiles", giveProfiles, L["Profile Options"])

	-- Add in the about panel to the Bliz options (not a part of the ace3 config)
	if LibStub:GetLibrary("LibAboutPanel", true) then
		self.optionsFrames["About"] = LibStub:GetLibrary("LibAboutPanel").new(addon.LocName, addon.Name)
	end
end

-- Description: Function which extends our options table in a modular way
-- Expected result: add a new modular options table to the modularOptions upvalue as well as the Blizzard config
-- Input:
--		name			: index of the options table in our main options table
--		optionsTable	: the sub-table to insert
--		displayName	: the name to display in the config interface for this set of options
-- Output: None.
function addon:RegisterModuleOptions(name, optionTbl, displayName)
	moduleOptions[name] = optionTbl
	self.optionsFrames[name] = AceConfigDialog:AddToBlizOptions(addon.LocName, displayName, addon.LocName, name)
end
