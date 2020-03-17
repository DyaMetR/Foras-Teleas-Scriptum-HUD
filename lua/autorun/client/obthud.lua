--[[
Foras Teleas Scriptum HUD
     Version 2.2.1
       18/03/20
By DyaMetR
]]

--[[
  Returns the HUD scale
  @return {number} scale
]]
local function GetScale()
  return ScrH() / 768;
end

--[[
  Create fonts
]]
surface.CreateFont( "obt_numbers", {
  font = "Coolvetica",
  size = 74 * GetScale(),
  weight = 500,
  antialias = true
});

surface.CreateFont( "obt_number_small", {
  font = "Coolvetica",
  size = 33 * GetScale(),
  weight = 500,
  antialias = true
});

surface.CreateFont( "obt_label", {
  font = "Verdana",
  size = 20 * GetScale(),
  weight = 600,
  antialias = true
});

surface.CreateFont( "obt_label_small", {
  font = "Verdana",
  size = 16 * GetScale(),
  weight = 600,
  antialias = true
});

--[[
  ConVars
]]
local enabled = CreateClientConVar( "obt_enabled", 1, true );
local auxpow = CreateClientConVar( "obt_auxpow", 1, true );
local drawTargetHP = CreateClientConVar( "obt_targetbar", 1, true );

--[[
  Parameters
]]
local DEFAULT_FONT = "obt_label";
local HEALTH_GOOD = Color(20, 235, 20, 255);
local HEALTH_WARN = Color(255, 200, 0, 255);
local HEALTH_CRIT = Color(236, 25, 25, 255);
local ARMOUR_COLOUR = Color(35, 186, 255, 255);
local AMMUNITION_COLOUR = Color(225, 215, 30, 255);
local LOW_AMMUNITION = Color(225, 15, 5, 255);
local AUXPOW_COLOUR = Color(255, 200, 0, 255);
local LOW_AUXPOW = Color(255, 30, 30, 255);
local ROUNDNESS = 4;
local NO_NUMBER = "";
local DEFAULT_WIDTH, DEFAULT_HEIGHT = 200, 14;

--[[
  Draws a horizontal progress bar
  @param {number} x
  @param {number} y
  @param {number} w
  @param {number} h
  @param {number|nil} value
  @param {Color|nil} colour
]]
local function DrawBar(x, y, w, h, value, colour)
  value = value or 1;
  colour = colour or Color(255, 255, 255, 255);
  draw.RoundedBox(ROUNDNESS * GetScale(), x, y, w, h, Color(10, 10, 10, 166));
  draw.RoundedBox(ROUNDNESS * GetScale(), x + 1, y + 1, (w - 2), h - 2, Color(colour.r * 0.76, colour.g * 0.76, colour.b * 0.76, colour.a * 0.33));
  draw.RoundedBox(ROUNDNESS * GetScale(), x + 1, y + 1, (w - 2) * math.min(value, 1), h - 2, colour);
  draw.RoundedBox(ROUNDNESS * GetScale(), x + 1, y + 1, (w - 2) * math.min(value, 1), (h - 2) * 0.4, Color(255, 255, 255, 86));
end

--[[
  Draws a progress bar with a label
  @param {number} x
  @param {number} y
  @param {number} w
  @param {number} h
  @param {string} label
  @param {number|nil} value
  @param {Color|nil} colour
  @param {number|nil} absolute value
  @param {boolean|nil} should the bar be hidden
  @param {string|nil} label's font
]]
local function DrawProgressBar(x, y, w, h, label, value, colour, absValue, hideBar, labelFont)
  value = value or 1;
  absValue = absValue or math.Round(value * 100);
  colour = colour or Color(255, 255, 255, 255);
  labelFont = labelFont or DEFAULT_FONT;
  w = w * GetScale();
  h = h * GetScale();
  y = y - h;

  -- Draw text
  draw.SimpleTextOutlined(label, labelFont, x + 7 * GetScale(), y + 1 * GetScale(), colour, nil, TEXT_ALIGN_BOTTOM, 1, Color(0, 0, 0, 153));
  draw.SimpleTextOutlined(absValue, "obt_numbers", x + w - 93 * GetScale(), y + 16.5 * GetScale(), colour, nil, TEXT_ALIGN_BOTTOM, 1, Color(0, 0, 0, 153));

  -- Draw bar
  if (hideBar) then return; end
  DrawBar(x, y, w, h, value, colour);
end

--[[
  Draw HUD
]]
local apowl, apowfl = 1, 1; -- aux power lerp values
local function DrawHUD()
  if (not LocalPlayer():Alive() or enabled:GetInt() <= 0) then return; end
  local health = math.max(LocalPlayer():Health(), 0);
  local armour = LocalPlayer():Armor();

  -- Draw health and armour
  local colour = HEALTH_GOOD;
  if (health > 25 and health < 50) then
    colour = HEALTH_WARN;
  elseif (health <= 25) then
    colour = HEALTH_CRIT;
  end

  DrawProgressBar(40 * GetScale(), ScrH() - (30 * GetScale()), DEFAULT_WIDTH, DEFAULT_HEIGHT, "HEALTH", health * 0.01, colour)

  if (armour > 0) then
    DrawProgressBar(260 * GetScale(), ScrH() - (30 * GetScale()), DEFAULT_WIDTH, DEFAULT_HEIGHT, "SUIT", armour * 0.01, ARMOUR_COLOUR)
  end

  -- Draw ammunition
  local weapon = LocalPlayer():GetActiveWeapon();
  if (IsValid(weapon) and (weapon:GetPrimaryAmmoType() > 0 or weapon:GetSecondaryAmmoType() > 0)) then
    local colour = AMMUNITION_COLOUR;

    -- Clip based weapons
    local clip, max, reserve = weapon:Clip1(), weapon:GetMaxClip1(), LocalPlayer():GetAmmoCount(weapon:GetPrimaryAmmoType());
    if (weapon:GetPrimaryAmmoType() > 0) then
      if (weapon:Clip1() <= -1) then
        clip = reserve;
        max = game.GetAmmoMax(weapon:GetPrimaryAmmoType());
      end
    else
      clip = LocalPlayer():GetAmmoCount(weapon:GetSecondaryAmmoType());
      max = game.GetAmmoMax(weapon:GetSecondaryAmmoType());
    end

    if ((clip / max < 0.25 and weapon:GetPrimaryAmmoType() > 0) or clip <= 0) then colour = LOW_AMMUNITION; end
    local w, h = 221, DEFAULT_HEIGHT;
    local x, y = ScrW() - ((40 * GetScale()) + w * GetScale()), ScrH() - (30 * GetScale());
    DrawProgressBar(x, y, w, h, "AMMO", clip / max, colour, clip, max >= 9999 and (weapon:Clip1() <= -1 or (weapon:GetPrimaryAmmoType() <= 0 and weapon:GetSecondaryAmmoType() > 0)));

    -- Draw reserve ammunition
    if (weapon:GetPrimaryAmmoType() > 0) then
      -- Draw reserve ammunition
      if (weapon:Clip1() > -1) then
        draw.SimpleTextOutlined(reserve, "obt_number_small", x + 68 * GetScale(), y - 7 * GetScale(), colour, nil, TEXT_ALIGN_BOTTOM, 1, Color(0, 0, 0, 153));
      end

      -- Draw alternate fire mode ammunition
      if (weapon:GetSecondaryAmmoType() > 0) then
        local alt = LocalPlayer():GetAmmoCount(weapon:GetSecondaryAmmoType());
        local colour = AMMUNITION_COLOUR;
        if (alt <= 0) then colour = LOW_AMMUNITION; end
        DrawProgressBar(x - (200 * GetScale()), y, 179, h, "ALT", alt / game.GetAmmoMax(weapon:GetSecondaryAmmoType()), colour, alt);
      end
    end
  end

  -- Draw Aux Power
  if (auxpow:GetInt() <= 0) then return end
  local power = LocalPlayer():GetSuitPower() * 0.01;
  if (AUXPOW and AUXPOW:IsEnabled()) then -- if addon is installed, use it and draw flashlight if enabled
    power = math.max(AUXPOW:GetPower(), 0);
    if (AUXPOW:GetFlashlight() < 1) then
      apowfl = Lerp(FrameTime() * 20, apowfl, AUXPOW:GetFlashlight());
      local colour = AUXPOW_COLOUR;
      if (AUXPOW:GetFlashlight() < 0.2) then
        colour = LOW_AUXPOW;
      end
      local x = 260;
      if (armour > 0) then x = x + 220; end
      DrawProgressBar(x * GetScale(), ScrH() - (30 * GetScale()), 150, DEFAULT_HEIGHT, "FLASHLIGHT", apowfl, colour, NO_NUMBER, nil, "obt_label_small");
    end
  end
  if (power < 1) then -- if power is being used display HUD element
    apowl = Lerp(FrameTime() * 20, apowl, power);
    local colour = AUXPOW_COLOUR;
    if (power < 0.2) then colour = LOW_AUXPOW; end
    DrawProgressBar(40 * GetScale(), ScrH() - (108 * GetScale()), 178, DEFAULT_HEIGHT, "AUX POWER", apowl, colour, NO_NUMBER, nil, "obt_label_small");
  end
end
hook.Add("HUDPaint", "obt_drawhud", DrawHUD);

-- Override addon HUD
hook.Add("AuxPowerHUDPaint", "obt_auxpow_hud1", function(power, expenses)
  if (enabled:GetInt() > 0 and auxpow:GetInt() > 0) then
    if (power >= 1 or not LocalPlayer():Alive()) then return end -- don't draw if not displayed
    local colour = AUXPOW_COLOUR;
    if (power < 0.2) then colour = LOW_AUXPOW; end

    -- Draw expenses
    local i = 0;
    for _, expense in pairs(expenses) do
      draw.SimpleTextOutlined(expense, "obt_label_small", 40 * GetScale(), ScrH() - ((108 - 14 * i) * GetScale()), colour, nil, nil, 1, Color(0, 0, 0, 153));
      i = i + 1;
    end

    return true;
  else
    return
  end
end)

-- Override addon flashlight HUD
hook.Add("EP2FlashlightHUDPaint", "obt_auxpow_hud2", function(power)
  if (enabled:GetInt() > 0 and auxpow:GetInt() > 0) then
    return true;
  else
    return
  end
end)

--[[
  Override target ID
]]
local function DrawTargetID()
  if (enabled:GetInt() <= 0 or drawTargetHP:GetInt() <= 0) then return; end

  local w, h = 150, 15;
  local ent = LocalPlayer():GetEyeTrace().Entity;

  if (IsValid(ent) and (ent:IsNPC() or ent:IsPlayer())) then
    local name = language.GetPhrase(ent:GetClass());
    local health, max = ent:Health(), ent:GetNWInt("npc_maxhealth");
    local armor = -1;
    if (ent:IsPlayer()) then name = ent:Name(); max = ent:GetMaxHealth(); armor = 100; end
    local value = health / max;
    local colour = HEALTH_GOOD;

    -- Colour
    if (value > 0.25 and value < 0.5) then
      colour = HEALTH_WARN;
    elseif (value <= 0.25) then
      colour = HEALTH_CRIT;
    end

    -- Get size
    w = w * GetScale();
    h = h * GetScale();

    -- Draw
    draw.SimpleTextOutlined(name, "obt_label_small", ScrW() * 0.5, (ScrH() * 0.56) - 1, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM, 1, Color(0, 0, 0, 153));

    if (health <= 0 and max <= 0) then return; end
    DrawBar((ScrW() * 0.5) - (w * 0.5), ScrH() * 0.56, w, h, value, colour);
    draw.SimpleTextOutlined(health .. "/" .. max, "obt_label_small", ScrW() * 0.5, (ScrH() * 0.56) + (h * 0.5) - 1, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, Color(0, 0, 0, 153));

    if (armor > -1 and ent:Armor() > 0) then
      DrawBar((ScrW() * 0.5) - (w * 0.5), (ScrH() * 0.56) + h + 2, w, h, ent:Armor()/armor, ARMOUR_COLOUR);
      draw.SimpleTextOutlined(ent:Armor() .. "/" .. armor, "obt_label_small", ScrW() * 0.5, (ScrH() * 0.56) + (h * 0.5) + h + 1, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, Color(0, 0, 0, 153));
    end
  end

  return true;
end
hook.Add("HUDDrawTargetID","obt_targethud_override", DrawTargetID);

--[[
  Hide default HUD
]]
local tohide = {
  ["CHudHealth"] = true,
  ["CHudBattery"] = true,
  ["CHudAmmo"] = true,
  ["CHudSecondaryAmmo"] = true,
  ["CHudSuitPower"] = true
}
local function HUDShouldDraw(name)
  if (enabled:GetInt() <= 0) then return; end
  tohide["CHudSuitPower"] = auxpow:GetInt() >= 1;
  if (tohide[name]) then
    return false;
  end
end
hook.Add("HUDShouldDraw", "obt_hidehud", HUDShouldDraw);

--[[
  Create menu
]]
local function TheMenu( Panel )
	Panel:ClearControls();

  Panel:AddControl( "CheckBox", {
		Label = "Enabled",
		Command = "obt_enabled",
		}
	);

  Panel:AddControl( "CheckBox", {
		Label = "Aux power enabled",
		Command = "obt_auxpow",
		}
	);

	Panel:AddControl( "CheckBox", {
		Label = "Enable custom Target ID",
		Command = "obt_targetbar",
		}
	);
end

local function createthemenu()
	spawnmenu.AddToolMenuOption( "Options", "DyaMetR", "obtHUD", "Foras Teleas Scriptum HUD", "", "", TheMenu )
end
hook.Add( "PopulateToolMenu", "obthud_menu", createthemenu );
