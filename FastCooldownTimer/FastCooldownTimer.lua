FastCooldownTimer = LibStub("AceAddon-3.0"):NewAddon("FastCooldownTimer", "AceConsole-3.0", "AceHook-3.0")

local L = LibStub("AceLocale-3.0"):GetLocale("FastCooldownTimer")
local SM = LibStub("LibSharedMedia-3.0")
local config = LibStub("AceConfig-3.0")
local dialog = LibStub("AceConfigDialog-3.0")
local blacklist = { "TargetFrame", "PetAction", "TotemFrame", "PartyFrame", "TargetofTargetFrame", "FocusFrame", "RaidFrame", "CompactRaidGroup", "LAB10ChargeCooldown" }
local sformat = string.format

-- Safe helpers ---------------------------------------------------------------
local function SafeGetName(obj)
    if not obj then return nil end
    local ok, name = pcall(function() return obj:GetName() end)
    if ok then return name end
    return nil
end

local function SafeGetParent(obj)
    if not obj then return nil end
    local ok, parent = pcall(function() return obj:GetParent() end)
    if ok then return parent end
    return nil
end

local function SafeCall(obj, method, ...)
    if not obj then return false end
    local fn = obj[method]
    if type(fn) ~= "function" then return false end
    local ok = pcall(fn, obj, ...)
    return ok
end
-- ----------------------------------------------------------------------------

local defaults = {
	profile = {
		shine = false,
		shineScale = 2,
		ShowDecimal = true,
		ShowSeconds = false,
		UseBlizCounter = false,
		WarnSpeed = 0.25,
		minimumDuration = 3,
		hideAnimation = false,
		font = SM:GetDefault("font"),
		color_common = {r=1, g=1, b=0.2, a=1},
		color_warn = {r=1, g=0, b=0, a=1},
		size1 = 18,
		size2 = 24,
		size3 = 28,
		size4 = 34,
		blacklist = {},
	}
}
local function get(info)
    local k = info[#info]
    return FastCooldownTimer.db.profile[k]
end
local function set(info,value)
    local k = info[#info]
    FastCooldownTimer.db.profile[k] = value
	if k == "font" then
		FastCooldownTimer:initFontStyle()
	end
end

function FastCooldownTimer:OnInitialize()
	self.db = LibStub("AceDB-3.0"):New("FastCooldownTimerDB", defaults, "Default")
	local options = {
		type = "group",
		name = "FastCooldownTimer",
		args = {
			FontSettings = {
				type = "group",
				name = L["Font Settings"],
				get = get,
				set = set,
				args = {
					font = {
						type = "select",
						name = L["Font Style"],
						desc = L["Set cooldown value display font."],
						order =10,
						values = function()
							local fonts, newFonts = SM:List("font"), {}
							for k, v in pairs(fonts) do
								newFonts[v] = v
							end
							return newFonts
						end,
					},
					header_font_color = {
						type = "header",
						name = L["Font Color"],
						order = 20,
					},
					color_common = {
						type = "color",
						name = L["Common color"],
						desc = L["Setup the common color for value display."],
						order = 21,
						hasAlpha = true,
						get = function(info)
							local k=info[#info]
							return self.db.profile[k].r, self.db.profile[k].g, self.db.profile[k].b, self.db.profile[k].a
						end,
						set = function(info, r, g, b, a)
							local k=info[#info]
							self.db.profile[k].r, self.db.profile[k].g, self.db.profile[k].b, self.db.profile[k].a = r, g, b, a
						end,
					},
					color_warn = {
						type = "color",
						name = L["warning color"],
						desc = L["Setup the warning color for value display."],
						order = 22,
						hasAlpha = true,
						get = function(info)
							local k=info[#info]
							return self.db.profile[k].r, self.db.profile[k].g, self.db.profile[k].b, self.db.profile[k].a
						end,
						set = function(info, r, g, b, a)
							local k=info[#info]
							self.db.profile[k].r, self.db.profile[k].g, self.db.profile[k].b, self.db.profile[k].a = r, g, b, a
						end,
					},
					header_font_size = {
						type = "header",
						name = L["Font Size"],
						order = 30,
					},
					size1 = {
						type = "range",
						name = L["Small Size"],
						desc = L["Small font size for cooldown is longer than 10 minutes."],
						min = 10,
						max = 45,
						step = 1,
						order = 31,
					},
					size2 = {
						type = "range",
						name = L["Medium Size"],
						desc = L["Medium font size for cooldown is longer than 1 minute and less than 10 minutes."],
						min = 10,
						max = 45,
						step = 1,
						order = 32,
					},
					size3 = {
						type = "range",
						name = L["Large Size"],
						desc = L["Large font size for cooldown is longer than 10 seconds and less than 1 minutes."],
						min = 10,
						max = 45,
						step = 1,
						order = 33,
					},
					size4 = {
						type = "range",
						name = L["Warning Size"],
						desc = L["Warning font size for cooldown is less than 10 seconds."],
						min = 10,
						max = 45,
						step = 1,
						order = 34,
					},
				},
			},
			Misc = {
				type = "group",
				order = 3,
				name = L["Misc"],
				get = get,
				set = set,
				args = {
					shine = {
						type = "toggle",
						name = L["Shine at finish cooldown"],
						desc = L["Toggle icon shine display at finish cooldown."],
						order = 10,
					},
					shineScale = {
						type = "range",
						name = L["Shine Scale"],
						desc = L["Adjust icon shine scale."],
						min = 0,
						max = 50,
						step = 1,
						order = 11,
					},
					header_hideAnimation = {
						type = "header",
						name = L["Hide Blizzard Origin Animation"],
						order = 20,
					},
					hideAnimation = {
						type = "toggle",
						name = L["Hide Blizzard Origin Animation"],
						desc = L["Hide Blizzard origin cooldown animation."],
						width = "full",
						order = 21,
					},
					header_minimumDuration = {
						type = "header",
						name = L["Minimum Duration"],
						order = 50,
					},
					minimumDuration = {
						type = "range",
						name = L["Minimum Duration"],
						desc = L["Minimum duration for display cooldown count."],
						min = 0.5,
						max = 30,
						step = 0.5,
						order = 51,
					},
					header_WarnSpeed = {
						type = "header",
						name = L["Warning speed"],
						order = 60,
					},
					WarnSpeed = {
						type = "range",
						name = L["Warning blink speed"],
						desc = L["Speed at which the warning blinking occurs."],
						min = 0.1,
						max = 0.5,
						step = 0.05,
						order = 61,
					},
					header_decimal = {
						type = "header",
						name = L["Show decimal"],
						order = 70,
					},
					ShowDecimal = {
						type = "toggle",
						name = L["Show decimal below 1 sec"],
						desc = L["Show decimal below 1 sec."],
						width = "full",
						order = 71,
					},
					ShowSeconds = {
						type = "toggle",
						name = L["Show seconds above 1 min"],
						desc = L["Show seconds above 1 min."],
						width = "full",
						order = 72,
					},
					header_blizCounter = {
						type = "header",
						name = L["Blizzard time display"],
						order = 80,
					},
					UseBlizCounter = {
						type = "toggle",
						name = L["Use Blizzard time display"],
						desc = L["Blizzard display 0 between 0 and 0.999 remaining seconds. Disabling this option will show 1 instead."],
						width = "full",
						order = 81,
					},
					header_resetdb = {
						type = "header",
						name = L["Reset"],
						order = 100,
					},
					resetdb = {
						type = "execute",
						confirm = true,
						confirmText = L["ResetDB_Confirm"],
						func = function()
							self.db:ResetDB()
							self:initFontStyle()
							self:Print(L["All settings are reset to default value."])
						end,
						name = L["Reset"],
						order = 101,
					},
				},
			},
		}
	}

	config:RegisterOptionsTable("FastCooldownTimer", {
		name = "FastCooldownTimer",
		type = "group",
		args = {
			description = {
				type = "description",
				name = L["WhatIsFastCooldownTimer"],
			},
		},
	})
	dialog:SetDefaultSize("FastCooldownTimer", 600, 400)
	dialog:AddToBlizOptions("FastCooldownTimer", "FastCooldownTimer")

	config:RegisterOptionsTable("FastCooldownTimer-Misc", options.args.Misc)
	dialog:AddToBlizOptions("FastCooldownTimer-Misc", options.args.Misc.name, "FastCooldownTimer")

	config:RegisterOptionsTable("FastCooldownTimer-FontSettings", options.args.FontSettings)
	dialog:AddToBlizOptions("FastCooldownTimer-FontSettings", options.args.FontSettings.name, "FastCooldownTimer")
end

local actions = {}
local function action_OnShow(self) actions[self] = true end
local function action_OnHide(self) actions[self] = nil end

local function action_Add(button, action, cooldown)
  if not cooldown.FastCooldownTimerAction then
    cooldown:HookScript('OnShow', action_OnShow)
    cooldown:HookScript('OnHide', action_OnHide)
  end
  cooldown.FastCooldownTimerAction = action
end

local function actions_Update()
  for cooldown in pairs(actions) do
    local start, duration = GetActionCooldown(cooldown.FastCooldownTimerAction)
  end
end

function FastCooldownTimer:OnEnable()
	self:initFontStyle()
	hooksecurefunc("CooldownFrame_Set", FastCooldownTimer.SetCooldown)
    hooksecurefunc('SetActionUIButton', action_Add)

    for _, button in pairs(ActionBarButtonEventsFrame.frames) do
      action_Add(button, button.action, button.cooldown)
    end
end

function FastCooldownTimer:initFontStyle()
	self.font = SM:Fetch('font', self.db.profile.font)
end

function FastCooldownTimer.SetCooldown(frame, start, duration, enable, forceShowDrawEdge, modRate)
    -- 1) Name + Blacklist zuerst
    local fname = SafeGetName(frame)
    if FastCooldownTimer:CheckBlacklist(fname) then
        return
    end

    -- 2) Blizzard-Swirl ggf. ausblenden (pcall-gesichert)
    if FastCooldownTimer.db.profile.hideAnimation then
        SafeCall(frame, "SetAlpha", 0)
    else
        SafeCall(frame, "SetAlpha", 1)
    end

    -- 3) Eigene Anzeige steuern
    if enable and enable ~= 0 and start and start > 0 and duration and duration > FastCooldownTimer.db.profile.minimumDuration then
        local FCT = frame.cooldownCounFrame
        if not FCT then
            FCT = FastCooldownTimer:CreateFastCooldownTimer(frame, start, duration)
            if not FCT then
                return
            end
            frame.cooldownCounFrame = FCT
        end

        -- Update Werte je Aufruf
        FCT.start = start
        FCT.duration = duration
        FCT.timeToNextUpdate = 0
        if not FCT:IsShown() then
            FCT:Show()
        end
    else
        local FCT = frame and frame.cooldownCounFrame
        if FCT and FCT:IsShown() then
            FCT:Hide()
        end
    end
end

function FastCooldownTimer:CreateFastCooldownTimer(frame, start, duration)
    local parent = SafeGetParent(frame)
    if not parent then return nil end

    frame.cooldownCounFrame = CreateFrame("Frame", nil, parent)
    local textFrame = frame.cooldownCounFrame

    textFrame:SetAllPoints(parent)
    textFrame:SetFrameLevel(textFrame:GetFrameLevel() + 5)
    textFrame:SetToplevel(true)
    textFrame.timeToNextUpdate = 0

    textFrame.text = textFrame:CreateFontString(nil, "OVERLAY")
    textFrame.text:SetPoint("CENTER", textFrame, "CENTER", 0, -1)

    local iconName = SafeGetName(parent)
    if iconName then
        textFrame.icon = _G[iconName .. "Icon"] or _G[iconName .. "IconTexture"]
    end
    if not textFrame.icon then
        return nil
    end

    textFrame:SetScript("OnUpdate", function(self, elapsed)
        if textFrame.timeToNextUpdate <= 0 or not textFrame.icon:IsVisible() then
            local current_time = GetTime()
            if not textFrame.start or current_time < textFrame.start then return end

            local remain = textFrame.duration - (current_time - textFrame.start)

            if math.floor(remain + 1) > 0 and textFrame.icon:IsVisible() then
                local text, toNextUpdate, size, isWarn = FastCooldownTimer:GetFormattedTime(remain)
                textFrame.text:SetFont(FastCooldownTimer.font, size, "OUTLINE")
                local color = FastCooldownTimer.db.profile.color_common
                if isWarn then
                    if textFrame.isWarn == nil then
                        textFrame.isWarn = 2
                        textFrame.nextWarnSwitch = current_time + FastCooldownTimer.db.profile.WarnSpeed
                    end
                    if current_time >= textFrame.nextWarnSwitch then
                        textFrame.isWarn = (textFrame.isWarn == 2) and 1 or 2
                        textFrame.nextWarnSwitch = current_time + FastCooldownTimer.db.profile.WarnSpeed
                    end
                    if textFrame.isWarn == 2 then
                        color = FastCooldownTimer.db.profile.color_warn
                    end
                end
                textFrame.text:SetTextColor(color.r, color.g, color.b)
                if type(text) == "number" then
                    if text < 1 and FastCooldownTimer.db.profile.ShowDecimal then
                        textFrame.text:SetText(string.format("%.1f", text))
                    else
                        textFrame.text:SetText(string.format("%.0f", text))
                    end
                else
                    textFrame.text:SetText(text)
                end
                textFrame.timeToNextUpdate = toNextUpdate
            else
                if FastCooldownTimer.db.profile.shine and textFrame.icon:IsVisible() then
                    FastCooldownTimer:StartToShine(textFrame.icon)
                end
                textFrame.isWarn = nil
                textFrame.nextWarnSwitch = 0
                textFrame:Hide()
            end
        else
            textFrame.timeToNextUpdate = textFrame.timeToNextUpdate - elapsed
        end
    end)

    textFrame:Hide()
    return textFrame
end

function FastCooldownTimer:Child_OnShow(self, event, ...)
	local textFrame = self:GetParent().textFrame
	if textFrame and not textFrame:IsShown() then
		textFrame:Show()
	end
end

function FastCooldownTimer:Child_OnHide(self, event, ...)
	local textFrame = self:GetParent().textFrame
	if textFrame and textFrame:IsShown() then
		textFrame:Hide()
	end
end

function FastCooldownTimer:GetFormattedTime(secs)
	local addSec = (FastCooldownTimer.db.profile.UseBlizCounter and 0) or 1
	if secs >= 86400 then
		return math.ceil(secs / 86400) .. L["d"], math.fmod(secs, 86400), FastCooldownTimer.db.profile.size1
	elseif secs >= 3600 then
		return math.ceil(secs / 3600) .. L["h"], math.fmod(secs, 3600), FastCooldownTimer.db.profile.size1
	elseif secs >= 600 then
		return math.ceil(secs / 60) .. L["m"], math.fmod(secs, 60), FastCooldownTimer.db.profile.size1
	elseif secs >= 60 then
		if FastCooldownTimer.db.profile.ShowSeconds then
			return sformat("%d:%02d", math.floor((secs+addSec) / 60), math.floor(math.fmod(secs+addSec, 60))), 0.100, FastCooldownTimer.db.profile.size1
		end
		return math.ceil(secs / 60) .. L["m"], math.fmod(secs, 60), FastCooldownTimer.db.profile.size2
	elseif secs >= 10 then
		return math.floor(secs+addSec), 0.100, FastCooldownTimer.db.profile.size3
	elseif secs >= 2 then
		return math.floor(secs+addSec), 0.050, FastCooldownTimer.db.profile.size4, true
	elseif secs >= 1 then
		return math.floor(secs+addSec), 0.025, FastCooldownTimer.db.profile.size4, true
	end
	if FastCooldownTimer.db.profile.ShowDecimal then
		return secs, 0.010, FastCooldownTimer.db.profile.size2, true
	end
	return math.floor(secs+addSec), 0.010, FastCooldownTimer.db.profile.size4, true
end

function FastCooldownTimer:StartToShine(textFrame)
	local shineFrame = textFrame.shine or FastCooldownTimer:CreateShineFrame(textFrame:GetParent())

	shineFrame.shine:SetAlpha(shineFrame:GetParent():GetAlpha())
	shineFrame.shine:SetHeight(shineFrame:GetHeight() * FastCooldownTimer.db.profile.shineScale)
	shineFrame.shine:SetWidth(shineFrame:GetWidth() * FastCooldownTimer.db.profile.shineScale)

	shineFrame:Show()
end

function FastCooldownTimer:CreateShineFrame(parent)
	local shineFrame = CreateFrame("Frame", nil, parent)
	shineFrame:SetAllPoints(parent)

	local shine = shineFrame:CreateTexture(nil, "OVERLAY")
	shine:SetTexture("Interface\\Cooldown\\star4")
	shine:SetPoint("CENTER", shineFrame, "CENTER")
	shine:SetBlendMode("ADD")
	shineFrame.shine = shine

	shineFrame:Hide()
	shineFrame:SetScript("OnUpdate", FastCooldownTimer.Shine_Update)
	shineFrame:SetAlpha(parent:GetAlpha())

	return shineFrame
end

function FastCooldownTimer:Shine_Update()
	local shine = self.shine
	local alpha = shine:GetAlpha()
	shine:SetAlpha(alpha * 0.95)

	if alpha < 0.1 then
		self:Hide()
	else
		shine:SetHeight(alpha * self:GetHeight() * FastCooldownTimer.db.profile.shineScale)
		shine:SetWidth(alpha * self:GetWidth() * FastCooldownTimer.db.profile.shineScale)
	end
end

function FastCooldownTimer:CheckBlacklist(frameName)
    -- Robust: niemals _G[frameName] indexen, wenn nil
    if not frameName then
        return true
    end
    local f = _G[frameName]
    if f and f.noFastCooldownTimer then
        return true
    end
    for _, v in ipairs(blacklist) do
        if strfind(frameName, v) then
            if f then f.noFastCooldownTimer = true end
            return true
        end
    end
    if FastCooldownTimer.db.profile.blacklist then
        for _, v in ipairs(FastCooldownTimer.db.profile.blacklist) do
            if strfind(frameName, v) then
                if f then f.noFastCooldownTimer = true end
                return true
            end
        end
    end
    return false
end

local function FastCooldownTimer_ChatPrint(str,r,g,b)
  if DEFAULT_CHAT_FRAME then
    DEFAULT_CHAT_FRAME:AddMessage("FastCooldownTimer: "..str, r or 1.0, g or 0.7, b or 0.15)
  end
end

local function FastCooldownTimer_ShowHelp()
  FastCooldownTimer_ChatPrint("Usage:")
  FastCooldownTimer_ChatPrint("  |cffffffff/fct options|r - "..L["Opens options panel"])
  FastCooldownTimer_ChatPrint("  |cffffffff/fct bl add <FrameName>|r - "..L["Adds a frame to the user blacklist"])
  FastCooldownTimer_ChatPrint("  |cffffffff/fct bl del <FrameName>|r - "..L["Removes a frame from the user blacklist"])
  FastCooldownTimer_ChatPrint("  |cffffffff/fct bl list|r - "..L["List user blacklisted frames"])
end

local function FastCooldownTimer_Commands(command)
  local _,_,cmd,param = strfind(command,"^([^ ]+) (.+)$")
  if(not cmd) then cmd = command end
  if(not cmd) then cmd = "" end
  if(not param) then param = "" end

  if((cmd == "") or (cmd == "help")) then
    FastCooldownTimer_ShowHelp()
  elseif(cmd == "options") then
    InterfaceOptionsFrame_OpenToCategory("FastCooldownTimer")
  elseif(cmd == "bl") then
    local _,_,cmd2,param2 = strfind(param,"^([^ ]+) (.+)$")
    if(not cmd2) then cmd2 = param end
    if(not cmd2) then cmd2 = "" end
    if(not param2) then param2 = "" end
    if(cmd2 == "add") then
      if(param2 == "") then
        FastCooldownTimer_ChatPrint(L["Missing parameter for 'blacklist add' command"])
        FastCooldownTimer_ShowHelp()
      else
        if(_G[param2] == nil) then
          FastCooldownTimer_ChatPrint(sformat(L["Frame '%s' is not known. Cannot add it to user blacklist."],param2))
        else
          FastCooldownTimer.db.profile.blacklist = FastCooldownTimer.db.profile.blacklist or {}
          tinsert(FastCooldownTimer.db.profile.blacklist,param2)
          FastCooldownTimer_ChatPrint(sformat(L["Frame '%s' added to user blacklist."],param2))
        end
      end
    elseif(cmd2 == "del") then
      if(param2 == "") then
        FastCooldownTimer_ChatPrint(L["Missing parameter for 'blacklist del' command"])
        FastCooldownTimer_ShowHelp()
      else
        FastCooldownTimer.db.profile.blacklist = FastCooldownTimer.db.profile.blacklist or {}
        for i,v in ipairs(FastCooldownTimer.db.profile.blacklist) do
          if(param2 == v) then
            tremove(FastCooldownTimer.db.profile.blacklist,i)
            FastCooldownTimer_ChatPrint(sformat(L["Frame '%s' removed from user blacklist."],param2))
            return
          end
        end
        FastCooldownTimer_ChatPrint(sformat(L["Frame '%s' is not in user blacklist."],param2))
      end
    elseif(cmd2 == "list") then
      FastCooldownTimer_ChatPrint(L["User blacklist:"])
      if(FastCooldownTimer.db.profile.blacklist) then
        for _, v in ipairs(FastCooldownTimer.db.profile.blacklist) do
          FastCooldownTimer_ChatPrint(" - "..v)
        end
      end
      FastCooldownTimer_ChatPrint(L["End of list"])
    else
      FastCooldownTimer_ChatPrint(sformat(L["Unknown or missing parameter for 'blacklist' command: %s"],param))
      FastCooldownTimer_ShowHelp()
    end
  else
    FastCooldownTimer_ChatPrint(sformat(L["Unknown command: %s"],cmd))
    FastCooldownTimer_ShowHelp()
  end
end

SLASH_FastCooldownTimer1 = "/FastCooldownTimer"
SlashCmdList["FastCooldownTimer"] = function(msg)
  FastCooldownTimer_Commands(msg)
end

SLASH_FCT1 = "/fct"
SlashCmdList["FCT"] = function(msg)
  FastCooldownTimer_Commands(msg)
end

local f = CreateFrame('Frame'); f:Hide()
f:SetScript('OnEvent', function(self, event, ...)
	if event == 'ACTIONBAR_UPDATE_COOLDOWN' then
		actions_Update()
	end
end)

f:RegisterEvent('ACTIONBAR_UPDATE_COOLDOWN')

FastCooldownTimer_ChatPrint(sformat(L["FastCooldownTimer v%s loaded!\nType /FastCooldownTimer (or /fct) for help"], C_AddOns.GetAddOnMetadata("FastCooldownTimer", "Version")))
