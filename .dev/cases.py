def kill(cast, start, n=4):
    return ";".join("%d:near=%d;%d:atk" % (t, cast, t + 1) for t in range(start, start + 25 * n, 25))


LP = "[lua:4rtefakt.achievements] "
CASES = {
    # A kill earns First Blood (with its card); level 30 and a full wallet are noticed within a second; the list is
    # still there on the next start of the game.
    "basics": dict(room="S_10/S_1002/S_1002",
        drive="8:opt=DamageDealt=10;10:opt=DamageTaken=0;" + kill(17, 40) + ";150:level=30;160:sp=100000;300:lua=ach;310:quit",
        drive2="60:lua=ach;70:quit",
        expect=["notice Achievement: First Blood: Kill a monster.", LP + "earned first_blood", LP + "earned lv10", LP + "earned lv30",
                LP + "earned rich", LP + "earned [first_blood lv10 lv30 rich] kills 1 ",
                "==== second boot", LP + "earned [first_blood lv10 lv30 rich] kills 1 "],
        absent=[LP + "earned lv60"]),
    # A floor boss beaten without a hit: its own achievement and Untouchable.
    "boss_clean": dict(room="S_10/S_1009/S_1009",
        drive="60:flag=220,1;130:lua=ach;140:quit",
        expect=[LP + "earned untouchable", LP + "earned boss220", LP + "earned [boss220 untouchable]"]),
    # The same after taking a hit in the room, at 5 of 60 HP: no Untouchable, but a Close Call.
    "boss_hit": dict(room="S_10/S_1009/S_1009",
        drive="30:hurt=60;50:hp=5;60:flag=220,1;130:lua=ach;140:quit",
        expect=[LP + "earned close_call", LP + "earned boss220", " hits here 1"], absent=[LP + "earned untouchable"]),
    # The end of Yunica's story (Dalles, flag 226) in a short deathless save: five at once.
    "clear": dict(room="S_10/S_1009/S_1009",
        drive="30:hurt=60;60:flag=226,1;130:lua=ach;140:quit",
        expect=[LP + "earned clear", LP + "earned clear1", LP + "earned deathless", LP + "earned swift"],
        absent=[LP + "earned clear3", LP + "earned boss226"]),
    # A death first: no Deathless.
    "clear_after_death": dict(room="S_10/S_1009/S_1009",
        drive="30:hp=0;200:ok;260:ok;400:flag=226,1;470:lua=ach;480:quit",
        expect=["[death] HP 0", LP + "earned clear", " deaths 1 "], absent=[LP + "earned deathless"]),
    # A hit of half the max HP that does not kill: Still Standing.
    "survivor": dict(room="S_10/S_1002/S_1002",
        drive="30:hurt=75;60:lua=ach;70:quit", expect=[LP + "earned survivor"]),
}
