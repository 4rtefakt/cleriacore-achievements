-- Achievements: thirty feats, earned across every save of this install.
-- Each one is a row of LIST (its key, name and text) and one `earn("key")` somewhere in an event or a filter.

local P, G = cleria.player, cleria.game

local LIST = {   -- key, name, how it is earned, {counter, goal} when it is a count
    {"first_blood", "First Blood", "Kill a monster.", {"kills", 1}},
    {"hunter", "Hunter", "Kill 100 monsters.", {"kills", 100}},
    {"slayer", "Slayer", "Kill 1 000 monsters.", {"kills", 1000}},
    {"exterminator", "Exterminator", "Kill 5 000 monsters.", {"kills", 5000}},
    {"lv10", "Apprentice", "Reach level 10."},
    {"lv30", "Veteran", "Reach level 30."},
    {"lv60", "Legend", "Reach level 60."},
    {"rich", "Deep Pockets", "Hold 100 000 SP at once."},
    {"opener", "Lockpick", "Open 10 chests.", {"chests", 10}},
    {"treasure", "Treasure Hunter", "Open 40 chests.", {"chests", 40}},
    {"keys", "Key Master", "Open all twelve locked doors of the tower.", {"doors", 12}},
    {"devout", "Devout", "Buy 10 blessings.", {"blessings", 10}},
    {"glutton", "Glutton", "Pick up 200 drops.", {"drops", 200}},
    {"chain", "Chain Fighter", "Kill a monster at a combo of 30 or more."},
    {"overkill", "Overkill", "Deal 500 damage or more in one hit."},
    {"survivor", "Still Standing", "Survive a hit worth half your max HP or more."},
    {"boss220", "Velagunder", "Beat the boss of the Wailing Blue."},
    {"boss221", "Nygtilger", "Beat the boss of the Flooded Prison."},
    {"boss222", "Gelaldy", "Beat the boss of the Guilty Fire."},
    {"boss223", "Khonsclard", "Beat the boss of the Silent Sands."},
    {"boss224", "Pictimos", "Beat the boss of the Blighted Blood."},
    {"boss225", "Zava", "Beat Zava."},
    {"untouchable", "Untouchable", "Win a boss fight without taking a single hit."},
    {"close_call", "Close Call", "Win a boss fight with a tenth of your HP or less."},
    {"clear", "Summit", "Finish the game."},
    {"clear1", "Yunica's Tale", "Finish the game as Yunica."},
    {"clear2", "Hugo's Tale", "Finish the game as Hugo."},
    {"clear3", "Toal's Tale", "Finish the game as Toal."},
    {"deathless", "Deathless", "Finish the game without dying once in that save."},
    {"swift", "Swift", "Finish the game in under four hours of play."},
}
local BY = {}
for _, a in ipairs(LIST) do BY[a[1]] = a end

-- Earned achievements and the counts live outside the saves (cleria.data): they belong to the player.
local db = cleria.json.decode(cleria.data.read("achievements.json") or "") or {}
db.earned = type(db.earned) == "table" and db.earned or {}
db.count = type(db.count) == "table" and db.count or {}
db.doors = type(db.doors) == "table" and db.doors or {}
local dirty = false
local function count(k) return math.tointeger(db.count[k]) or 0 end

local function earn(key)
    if db.earned[key] or not BY[key] then return end
    db.earned[key] = math.floor(cleria.unix_time())
    dirty = true
    cleria.notice(BY[key][2] .. ": " .. BY[key][3], "Achievement")
    cleria.log("earned " .. key)
end
local function add(k, n)
    db.count[k] = count(k) + (n or 1)
    dirty = true
    for _, a in ipairs(LIST) do
        if a[4] and a[4][1] == k and count(k) >= a[4][2] then earn(a[1]) end
    end
end

-- per save: deaths and play time (cleria.save), for Deathless and Swift
local run = {deaths = 0, ticks = 0}
local function restore()
    local t = cleria.save.get("run")
    run = {deaths = type(t) == "table" and math.tointeger(t.deaths) or 0, ticks = type(t) == "table" and math.tointeger(t.ticks) or 0}
end
local function keep_run() if cleria.save.ready() then cleria.save.set("run", run) end end
-- Continuing after a death can bring back the save's storage as it was before the death (the game reloads its
-- continue snapshot): the count made at the death is carried over that reload.
local carry, carry_ticks = nil, 0
cleria.events.on("new_game", function() carry = nil restore() end)
cleria.events.on("load", function()
    restore()
    if carry then run.deaths = math.max(run.deaths, carry) carry = nil keep_run() end
end)

local hits_here = 0                             -- hits taken since this room was entered (a boss room: its fight)
cleria.events.on("room_enter", function() hits_here = 0 end)
cleria.events.on("death", function()
    run.deaths = run.deaths + 1
    carry, carry_ticks, hits_here = run.deaths, 0, 0
    keep_run()
end)

cleria.events.on("enemy_killed", function() add("kills") end)
cleria.events.on("chest_opened", function() add("chests") end)
cleria.events.on("blessing_bought", function() add("blessings") end)
cleria.events.on("pickup_collected", function() add("drops") end)
cleria.events.on("door_opened", function(e)
    local k = tostring(e.flag)
    if not db.doors[k] then db.doors[k] = true add("doors") end
end)

cleria.events.on("boss_defeated", function(e)
    if hits_here == 0 then earn("untouchable") end
    if P.hp() > 0 and P.hp() <= P.max_hp() / 10 then earn("close_call") end
    if e.flag and e.flag >= 220 and e.flag <= 225 then earn("boss" .. e.flag) end
    local c = G.character()
    if (e.flag == 226 and c ~= 3) or e.flag == 227 then          -- Dalles ends Yunica's and Hugo's story, Darm Toal's
        earn("clear")
        earn("clear" .. c)
        if run.deaths == 0 then earn("deathless") end
        if run.ticks < 4 * 3600 * 60 then earn("swift") end
    end
end)

cleria.combat.add_filter("damage", function(q)
    if q.dir == "dealt" then
        if q.value >= 500 then earn("overkill") end
    elseif q.value > 0 then
        hits_here = hits_here + 1
        if q.value >= P.max_hp() / 2 and q.value < P.hp() then earn("survivor") end
    end
    return nil
end)
cleria.combat.add_filter("exp", function(q)
    if q.source == "kill" and (q.combo or 0) >= 30 then earn("chain") end
    return nil
end)

cleria.events.on("tick", function()
    if not G.in_game() then return end
    if not G.frozen() then run.ticks = run.ticks + 1 end
    if carry and P.hp() > 0 then                                   -- alive again for two seconds: no reload came
        carry_ticks = carry_ticks + 1
        if carry_ticks > 120 then carry = nil end
    end
    if run.ticks % 60 ~= 0 then return end                         -- once a second
    keep_run()
    local lv = P.level()
    if lv >= 10 then earn("lv10") end
    if lv >= 30 then earn("lv30") end
    if lv >= 60 then earn("lv60") end
    if P.sp() >= 100000 then earn("rich") end
    if dirty then dirty = false cleria.data.write("achievements.json", cleria.json.encode(db)) end
end)

cleria.ui.page("Achievements", function(p)
    local got = 0
    for _, a in ipairs(LIST) do if db.earned[a[1]] then got = got + 1 end end
    p:section("Achievements")
    p:info("Earned", got .. " of " .. #LIST, {color = got == #LIST and "good" or "value"})
    for _, a in ipairs(LIST) do
        local done = db.earned[a[1]]
        local value = done and os.date("%Y-%m-%d", done) or (a[4] and (math.min(count(a[4][1]), a[4][2]) .. " / " .. a[4][2]) or "-")
        p:info(a[2], value, {color = done and "good" or "muted", desc = a[3]})
    end
    p:section("Reset")
    if p:button("Forget everything", "Erases every achievement and count of this install.") then
        db = {earned = {}, count = {}, doors = {}}
        cleria.data.write("achievements.json", cleria.json.encode(db))
    end
end)

cleria.command("ach", function()
    local t = {}
    for _, a in ipairs(LIST) do if db.earned[a[1]] then t[#t + 1] = a[1] end end
    cleria.log("earned [" .. table.concat(t, " ") .. "] kills " .. count("kills") .. " deaths " .. run.deaths .. " hits here " .. hits_here)
end)
cleria.log("Achievements loaded")
