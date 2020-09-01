-- $Id$

local L = LibStub("AceLocale-3.0"):NewLocale("CoordsTracking", "zhTW", false)

if not L then return end

if L then
--@do-not-package@
-- General
L["TITLE"] = "座標追蹤"
L["ADDON_NOTES"] = "追蹤並顯示你目前所在位置的座標並顯示在遊戲畫面和世界地圖上"
L["COLON"] = "："
L["COMMA"] = ", "
L["Cursor"] = "游標"
-- Options Header
L["Display Settings"] = "顯示設定"
L["Font Settings"] = "字體設定"
L["Scale and Transparency"] = "大小與透明度"
-- Options
L["Options"] = "選項"
L["Show coordinates info on screen"] = "在遊戲畫面上顯示座標資訊"
L["Show zone name together with coordinates"] = "顯示座標時也顯示區域名稱"
L["Show zone name as tooltip on coordinates when mouse hover"] = "滑鼠移至座標資訊上面時顯示區域名稱提示訊息"
L["Show coordinates info on world map"] = "在世界地圖上顯示座標資訊"
L["Reset position"] = "重設位置"
L["Setup font style for on-screen frame"] = "設定遊戲畫面上的座標框架字體樣式"
L["Setup font style for coordinates on WorldMap frame"] = "設定世界地圖上的座標框架字體樣式"
L["Select font"] = "選擇字形"
L["Configure font size"] = "設定字體大小"
L["Configure font color"] = "設定字體顏色"
L["Show outline"] = "使用外框字型"
L["Coordinates' accuracy"] = "座標資訊精確度"
L["On-screen frame"] = "遊戲畫面窗格"
L["Tooltip"] = "提示訊息"
L["Profile Options"] = "選項設定"
L["Scale"] = "大小"
L["Transparency"] = "透明度"
L["Background"] = "背景"
L["Background Texture"] = "背景材質"
L["Vertex Color"] = "頂點顏色"
--@end-do-not-package@
--@localization(locale="zhTW", format="lua_additive_table")@
end