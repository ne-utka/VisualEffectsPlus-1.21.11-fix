-- Torch override: vanilla flame_0..14 + orange glow

-- 0) ОБЯЗАТЕЛЬНО: создать глобальную таблицу
global = global or {}

-- 1) Коэффициенты (как у тебя)
local l = (bl and 1) or -1
local d = (bl and 1) or -0.43
local a = (bl and 1) or 0.8

-- 2) Совместимость по их глобалкам (теперь global гарантированно есть)
global.fall        = global.fall        or 0.0
global.pitchAngle  = global.pitchAngle  or 0.0
global.pitchAngleO = global.pitchAngleO or 0.0
global.yawAngle    = global.yawAngle    or 0.0
global.yawAngleO   = global.yawAngleO   or 0.0

local ptAngle = (mainHand and pitchAngle) or pitchAngleO
local ywAngle = (mainHand and yawAngle) or yawAngleO

-- 3) Если какие-то биндинги не подтянулись — тихо выходим (чтобы не ловить nil)
if not (particleManager and particles and Texture and M and I and Items and P) then
  return
end

-- 4) Подстройка позы для torch
do
  if I:isOf(item, Items:get("minecraft:torch")) then
    M:moveX(matrices, 0.0 * l)
    M:moveY(matrices, 0.05)
    M:moveZ(matrices, 0.035)
    M:scale(matrices, 1.05, 1.05, 1.05)
    I:setTranslate(item, true)
  end
end

-- 5) Кадровая анимация пламени (flame_0..14) — CUTOUT_L
if I:isOf(item, Items:get("minecraft:torch")) then
  local age = P:getAge(player)
  local frameIndex = math.floor(age * 0.45) % 15
  local flameTexture = Texture:of("minecraft", "textures/particle/flame_" .. frameIndex .. ".png")

  particleManager:addParticle(
    particles,
    false,
    0.56 * l,  -- x
    0.85,      -- y
    0.30,      -- z
    0, 0, 0,   -- vx, vy, vz
    0, 0, 0,   -- ax, ay, az
    0, 0, 0,   -- r, g, b
    1.25,      -- size
    flameTexture,
    "ITEM",
    hand,
    "SPAWN",
    "ADDITIVE_L", -- для кадров пламени лучше CUTOUT_L
    0,
    255
  )
end

-- 6) Оранжевый glow поверх пламени — ADDITIVE
if I:isOf(item, Items:get("minecraft:torch")) then
  particleManager:addParticle(
    particles,
    false,
    0.40 * l,  -- x
    0.60,      -- y
    0.60,      -- z
    0, 0, 0,
    0, 0, 0,
    1, 0.6235, 0.0078,
    1.50,
    Texture:of("davidparticles", "textures/particle/holdmyitems/orange_glow.png"),
    "ITEM",
    hand,
    "SPAWN",
    "ADDITIVE",
    0,
    200 + (20 * M:sin(P:getAge(player) * 0.2))
  )
end
