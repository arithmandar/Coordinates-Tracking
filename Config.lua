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
						-- Display Settings
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
									disabled = function()
										return not profile.show_coords_onscreen
									end,
								},
								show_zonenametooltip = {
									order = 13,
									type = "toggle",
									name = L["Show zone name as tooltip on coordinates when mouse hover"],
									width = "full",
									disabled = function()
										return not profile.show_coords_onscreen
									end,
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
						-- Coordinates' accuracy
						group2 = {
							order = 20,
							type = "group",
							name = L["Coordinates' accuracy"],
							--inline = true,
							args = {
								coords_accuracy = {
									order = 1,
									type = "range",
									name = L["On-screen frame"],
									min = 0, max = 4, bigStep = 1, 
									disabled = function()
										return not (profile.show_coords_onscreen)
									end,
								},
								worldmap_accuracy = {
									order = 2,
									type = "range",
									name = WORLD_MAP,
									min = 0, max = 4, bigStep = 1, 
									disabled = function()
										return not (profile.show_coords_onworldmap)
									end,
								},
							},
							disabled = function()
								return not (profile.show_coords_onworldmap or profile.show_coords_onscreen)
							end,
						},
						-- Layout settings
						group3 = {
							order = 30,
							type = "group",
							name = L["Layouts Settings"],
							args = {
								-- Font Settings
								font_settings = {
									order = 1,
									type = "group",
									name = L["Font Settings"],
									inline = true,
									args = {
										font_settings_onscreen = {
											order = 1,
											type = "group",
											name = L["Setup font style for on-screen frame"],
											inline = true,
											args = {
												font_onscreen = {
													order = 1,
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
													order = 2, 
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
													order = 3, 
													type = "toggle",
													name = L["Show outline"],
												},
											},
											disabled = function()
												return not profile.show_coords_onscreen
											end,
										},
										font_settings_worldmap = {
											order = 2,
											type = "group",
											name = L["Setup font style for coordinates on WorldMap frame"],
											inline = true,
											args = {
												font_worldmap = {
													order = 1,
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
													order = 2, 
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
												fontcolor_worldmap = {
													order = 3,
													type = "color",
													hasAlpha = false,
													name = L["Configure font color"],
													get = function()
														local color = profile.fontcolor_worldmap
														return color.r or 1, color.g or 1, color.b or 1
													end,
													set = function(info, r, g, b)
														local color = {}
														color.r, color.g, color.b = r, g, b
														profile.fontcolor_worldmap = color
														addon:SetWorldMapFontColor()
													end,
												},
												fontoutline_worldmap = {
													order = 4, 
													type = "toggle",
													name = L["Show outline"],
												},
											},
											disabled = function()
												return not profile.show_coords_onworldmap
											end,
										},
									},
									disabled = function()
										return not (profile.show_coords_onworldmap or profile.show_coords_onscreen)
									end,
								},
								-- Scale and Transparency
								scale_transparency = {
									order = 2,
									type = "group",
									name = L["Scale and Transparency"],
									inline = true,
									args = {
										scale_transparency_onscreen = {
											order = 1,
											type = "group",
											name = L["On-screen frame"],
											inline = true,
											args = {
												alpha = {
													order = 1,
													type = "range",
													name = L["Transparency"],
													min = 0, max = 1, bigStep = 0.1, 
												},
												scale = {
													order = 2,
													type = "range",
													name = L["Scale"],
													min = 0, max = 3, bigStep = 0.1, 
												},
											},
										},
										scale_transparency_tooltip = {
											order = 2,
											type = "group",
											name = L["Tooltip"],
											inline = true,
											args = {
												tooltip_alpha = {
													order = 1,
													type = "range",
													name = L["Transparency"],
													min = 0, max = 1, bigStep = 0.1, 
												},
												tooltip_scale = {
													order = 2,
													type = "range",
													name = L["Scale"],
													min = 0, max = 1.75, bigStep = 0.01, 
												},
											},
										},
									},
									disabled = function()
										return not (profile.show_coords_onscreen)
									end,
								},
								-- Background and border
								background_border = {
									order = 3,
									type = "group",
									name = L["Background"],
									inline = true,
									args = {
										background = {
											order = 1, 
											name = L["Background Texture"],
											type = "select",
											dialogControl = "LSM30_Background",
											values = AceGUIWidgetLSMlists.background,
											get = function()
												return profile.background
											end,
											set = function(info, v)
												profile.background = Media:Fetch("background", v)
												addon:SetOnScreenBackground()
											end
										},
										textureColor = {
											type = "color",
											name = L["Vertex Color"],
											order = 2,
											hasAlpha = true,
											get = function()
												local c = profile.backgroundColor
												local r, g, b, a = c.r or 0, c.g or 0, c.b or 0, c.a or 1
												return r, g, b, a
											end,
											set = function(info, r, g, b, a)
												local c = profile.backgroundColor
												c.r, c.g, c.b, c.a = r, g, b, a
												addon:SetOnScreenBackground()
											end
										},
									},
									disabled = function()
										return not (profile.show_coords_onscreen)
									end,
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
