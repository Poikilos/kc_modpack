# Contributing
This file describes how to develop the modpack.

From IRC Aug 12, 2019 messages by Poikilos

The primary aspects of "Kinetic Combat" would be that position and timing affect whether or not an attack lands. You only have to check "defend" (target is holding use key, or mob is defending). Later on we could check whether you're attacking from behind, etc.

Ramping means you use addition and subtraction to calculate damage and defense. Both your stats and the enemies stats keep getting higher. It is even more exciting when the ramping is not constant and every once it a while there is a greater challenge.

Bounded accuracy could be implemented much more easily, by making the damage pseudocode I posted into real code (See "Damage calculation").

Most of the other information below (under "Bounded accuracy", "Balancing" and "Use of assets") is from e-mails by Poikilos (multiple on same day in some cases):
- April 7, 2019
- April 8, 2019
- August 8, 2019
- September 9, 2019
- June 15, 2019

## Bounded accuracy
"Heal" and "Level" are broken concepts:
In ~2017 student feedback said that shields seemed to reduce chance (not amount) of damage, which made sense. I don't know whether they were right.
As it stands, there seems to be little to no change involved with getting hit.
The armor level and damage or randomNumber%damage should be used and determine odds rather than an damage being used directly.
* The shield should especially affect hit/miss ratio, but only when you're not attacking.
* Holding the special key could be defend, and further increase blocking but delay the time until your next attack.
* All of the above should happen with both enemies and players attacking you, but not lava and other hazards presumably (maybe boots would prevent walk damage--I still would like a walk_damage=1 group capability to use for the dark walkable lava).
  - Lets just make the dang globalstep always happen, not just when armor_protect_water or armor_fire_protect is true. We could even make new walk_hot and walk_piercing damage groups on nodes and make the same globalstep check nodes under you.

Even hoards of enemies in SB's nethack castle cannot harm me no matter how long I stand there, with any of these armor combinations:

Level,Heal,What
63,48,Full Diamond armor except shield
49.5,36,Diamond armor except shield, helmet
49.5,36,Diamond armor except shield, boots
45,36,Diamond armor except shield, pants
45,36,Diamond armor except shield, chestplate
58.5,48,Diamond armor except chestplate (this is the only test I did with a shield)

It will increase funness by approximately 63%.

See "Damage calculation" for more details and pseudocode.

### Damage calculation
Some of this code may be moved to an expanded "cmi" mod that is also able to manage the player character `luaentity`.

To make damage calculation consistent and compatible with existing mods
1. damage should be calculated using groups
2. damage should be calculated the same way if attacker is player, mob, or environment

So far I think I can implement pretty much everything (see [EN#321](https://github.com/poikilos/EnlivenMinetest/issues/321)) using mods, except for:

I am having trouble with point 1 above. I can set source myself in all other situations (such as in 3d_armor, mobs, and other calls to set_hp) other than damage_per_second. I can try to change the related code if you need help, but I need to know whether it would be backward compatible, and whether to use cstdargs named params (and whether that is sufficient and necessary for backward compatibility) if the damage_per_second code is in C++ (it seems to be).

current callback:
some_hp_change_handler(player, hp_change)

* I capitalized parts where I don't know the variable names below.

1. suggested callback:
some_hp_change_handler(player, hp_change, damage_source)
-- where damage_source is optional when used in Lua, for backward compatibility

2. suggested change to engine's damage_per_second code:
- use the set_hp or whatever it does already, but always provide 3rd param (PLAYER,HP_CHANGE,damage_sources = {groups=NODE.groups, node=NODE})

3. suggested change to engine's PvP attack code:
- (PLAYER,HP_CHANGE,damage_source = {groups=ATTACKER.SELECTED_ITEM.groups, player=ATTACKER})

Everything below this sentence is documentation for damage_sources (I can add the documentation to the patch once everything is settled, or you can add the text below with changes if necessary).

**damage_source**
- The "groups" param usually has to be at least { fleshy = 1} to do anything, but groups are technically a completely game-defined feature (though they are part of what could be the "extended API" and universally used apart from damage_per_second in versions without damage_source).
- Mods could set any of the params manually to simulate actions (when calling set_hp manually), such as if getting a point in a boardgame hurts the opposing player (set player and groups in such cases).

```Lua
damage_source.missile -- mob or other mods can set this so that the mod or other mods know whether to handle hp change event differently (such as to prevent some kind of "spiked armor" from hurting the attacker if missile is not nil)
damage_source.object -- can be a player or a mob (see similar implementation in `function mob_class:collision()` in mobs/api.lua).
damage_source.player  -- ONLY reserved for cases if different than object, such as if object is a pet, in which case player would be the owner. Player can also be the owner of a node or missile for combat purposes, to provide a unified interface (there are redundant but varying mechanisms in those cases inside individual mods, such as arrow's owner in mobs mods' or node's owner in protection mods).
damage_source.itemstack -- Reference the item that the player or mob actually used.
damage_source.node -- The game (engine?) should set this automatically if damage_per_second >0
damage_source.pos -- In case the source location is not traceable such as a node, this is the position in the world
damage_source.groups -- The game (engine?) should set this automatically if damage_per_second >0, or if player attacks player (selected item's groups, but only if one of the groups is weapon, otherwise use fist's fleshy group value as only group)
```

### on_killing_callback
#### Getting mob Variables from Engine object is Possible
In reading the api.lua, thought I should share my findings which may be helpful for other issues:
I found out I can get any properties without passing the mob class:
since (where obj is an engine object that you can get directly from an engine event or object search) obj:get_luaentity() is equivalent to mob (of course, obj is equivalent to mob.object).
* This may be helpful in various situations--in my case it answers the earlier question: on_killing callback will only need 4 params (playername1, obj1, playername1, obj2) [not 6 (playername1, obj1, playername1, obj2, mob1, mob2)]


## Balancing
Users on my school (former) server who came from the most popular sandbox game rolled their eyes and accepted Minetest's combat since it was a reward for being finished their computer assignments, but still said there is really no challenge or monsters are too hard, depending on what mob they encountered. Codermobs seems to have better balancing--mostly I just hit tree monsters near forests and harder mobs in caves. However, see also critical issues gamers notice under "Pathfinding".

Regarding population and spawn_by removal during debugging: having to increase that chance  by at least 50 (or whatever would have been the chance of whatever the spawn_by node occuring in the world) after removing spawn_by to get a similar population seems like expected behavior.

### Pathfinding
Pathfinding is part of balancing since without good pathfinding, mobs can "cheat" or act "stupid". Either extreme is a glaring problem.

Critical issues gamers notice:
- [ ] mobs attacking through corners (https://github.com/poikilos/EnlivenMinetest/issues/62) and
- [ ] trying to walk up 2-high barriers (at least that aspect of: https://github.com/poikilos/EnlivenMinetest/issues/64), and
- [x] (resolved in codermobs: change from jump to walk) failing to jump up 1-high barriers
- [x] (resolved in codermobs) friendly mobs despawning (https://github.com/poikilos/EnlivenMinetest/issues/3)

#### OpenAI
Jordan4Ibanez helped make Mob Framework before he made OpenAI (little used but highly developed).
Jordan4Ibanez implemented some amazing pathing, using predictive "breadcrumb" sprites for fast debugging: ~~<http://www.youtube.com/watch?v=b_ZUPTYRh54&t=115m48s>~~ (The video is marked private now :( )
His code may be good for a look even though he did it inside his own mobs API: https://forum.minetest.org/viewtopic.php?t=16032

```
git clone https://github.com/jordan4ibanez/open_ai.git
```

In his dev vlog he said that making a copy of the pathing/AI module on each mob speeded up huge flocks of mobs significantly vs processing that many mobs centrally.
I'm not sure whether this can be accomplished trivially using separate timers, of if Mobs Redo or Codermobs already breaks up the processing in some way so the processing doesn't become blocky (blocking other processes).
I would like to compare the performance but I would have to program a command to spawn an arbitrary number of mobs at once.
~~<https://www.youtube.com/watch?v=tL5WbrgKGAg&t=3m33s>~~ (The video is marked private now :( )

He did something like put an AI module inside of the mob instead of having a loop in the mod that processes all mobs.
I found the video and timecode where he moves functions to the LUA entity to drastically increase performance of open_ai:
~~https://www.youtube.com/watch?v=2rDkQWi-RA4&t=31m50s>~~ (The video is marked private now :( )
Considering he was just switching to an accepted software development paradigm, it would be not surprising if mobs redo and codermobs already do things that way.
I see now Jordan4Ibanez was pretty much just moving global functions to the LUA entity which is normal in object-oriented programming (though I understand some of the Minetest core API was rather procedural like the original function for checking falling nodes etc).

- [ ] Needs verification: disregard until after doing performance tests with /se command (such as with 100+ mobs).

The date of video above is Jan 3, 2017, which indicates that the corresponding commits (rather large since refactoring) would be in or around:
* https://github.com/jordan4ibanez/open_ai/commit/28c64d3eb49ef21b1402d0af69403b2035f8647f "Beginning of classifying things" Jan 3, 2017
* https://github.com/jordan4ibanez/open_ai/commit/9c099aa102e6d5971db69464f5e87276951a749a "improved pathfinding" Jan 3, 2017
* https://github.com/jordan4ibanez/open_ai/commit/13961ab9ac6e3512ec6326a9be0aae40f569eb0d "Push more things into library" Jan 6, 2017
* https://github.com/jordan4ibanez/open_ai/commit/f3310b2211d8f5a683c15accb46ee5ad5e3c703f "Finish turning code into a library" Jan 6, 2017

The leashes are amazing too (they stretch, can lead multiple mobs, and a mob can hang from them and be pulled up):
~~<https://www.youtube.com/watch?v=r_IZCJC8Zs0>~~ (The video is marked private now :( )


## Use of assets

1. Storing the models at 60fps never made sense, since Irrlicht does all frame blending. I could alter the animations as we go so that only the keyframes are kept so the files should be about half the size or less. I have found that reducing Big Red from 60fps to 6fps reduces the B3D file to about 1/2 of the size (I'm not sure why not smaller--maybe some type of compression is already done). However, some manual steps are needed to make sure that the end frames and start frames don't get crunched when scaling all keyframes in the Blender dopesheet. Many sequences can be reduce to 2 or 3 frames, or ONE frame (such as for poses), or at most 5 (such as for walking or certain attacks).

2. Leveraging the client is a big part of any kind of server optimization. Ensure that the server only sends keyframe cycles instead of frame cycles, and definitely not send network traffic for every frame.
   - Do some Irrlicht experiments with that (transitioning between arbitrary poses) in the b3view code.

Some measure of interactivity, even just visual and/or audio cues, should be present (gamers notice there is something lacking). See "Consistent color flashes" and "Sounds".

### Consistent color flashes
[Make all mobs and players flash red when damaged, but flash white on block/parry or otherwise not damaged #257](https://github.com/poikilos/EnlivenMinetest/issues/257).
- block (whenever a hit does no damage)
- stun: flash the mob with a lighter/tinted color for a 250 milliseconds
  - solid white for block
  - solid red for damage
  - flash the color to about 50% opacity over the client's whole screen then fade out if it is the player being hurt or blocking).

From 4/17/19 11:59 AM ET email:

It is the mummy that flashes red when attacked (at least with 190413), but near death it flashed white. I'm not sure whether that means, or why only certain mobs flash and some don't. What would be more clear is if the mob flashed white when blocking and flashed red when getting damaged.

Suggestion for player (player's screen flashes red when player is damaged then
fades out nicely, but combat would be more clear if):
* 50% gray when armor damaged and you are not. In real life, falling or getting hit hard may cause you to see light even if you're not injured, so white seems intuitive. then fade similar to how red currently does.
* 25% gray when blocking--I think shield can actually block 100% of damage on occasion, so this color could indicate getting hit but taking no damage (I'm not sure whether this is really possible with just armor but I think it is with shields) unless there is a sound, in which case the color may not be needed (or better yet, wield the shield on the screen for 0.25 sec).

(1:07 PM ET) According to that pattern I suggested, the clam would flash gray when attacked while closed, since it apparently deflects 100% of damage at that time (it currently doesn't flash at all when closed and they are usually closed, which is confusing--a player on my server thought clams were invincible).


### Unify actions and feedback
Override mobs api to keep the features optional if possible.

#### Animations
For combat visuals, the player and mob should have the same animation, so that virtually limitless patterns (combinations of moves and ducking, transitions, interruptions of attack swings in any order) of combat can be done procedurally without significant work on the part of the server. See [issues with the kc_modpack tag on EnlivenMinetest](https://github.com/poikilos/EnlivenMinetest/issues?q=is%3Aissue+is%3Aopen+label%3Akc_modpack) for more.

Implement at least the following sequences for the player and matching ones every hostile mob: idle, idle weapon drawn, duck, high block, get damaged, low block, dodge, leap, walk, run, high attack, low attack, provoke, death
- Some of these will only require 1-3 frames such as the blocks and attacks
  - Irrlicht could transition between any of these including interruptions such as if an attack is interrupted by a block.
  - See if there is really a bug in Irrlicht or only in Minetest's use of it (frame blending is disabled by default due to a supposed Irrlicht bug that may be fixed in a dev version), perhaps such as the client controlling the model and the server having an inconsistent view of it, which can happen with the camera:
    - [Severe camera issues in multiplayer using set_look_horizontal, move_to, and set_pos #11502](https://github.com/minetest/minetest/issues/11502)
  - Around 4 times as much functionality, but 1/20 of the frames in the B3D file!
- Type-dependent: fly, swim, takeoff, land

##### Bone-based animation
- [ ] Make the mob look at you when you are its target regardless of the direction it is walking (The direction its body is facing should be different from the head if not walking toward you but targeting you).

##### Provoke
(from 5/5/19 12:35 AM ET e-mail by Poikilos)
Add a low-permission /provoke command to kc_modpack which can either succeed or fail (call /hostile on favorable random number) and have a cooldown, allowing for some fun RPG action.


#### Visuals for attack outcomes
A stopgap (possibly that could be kept even after new sequences are implemented) feature to make the battle process more understandable visually (somehow represent what is happening in the code) is attack sprites (such as a big bite mark that appears in the air only for a flash when the creature attacks). Blocking and showing a shield sprite could also be done.

[bite](kc/textures/kc_attack_bite_glow.png)
[blade_slash](kc/textures/kc_attack_blade_slash.png)
[claw_black](kc/textures/kc_attack_claw_black.png)
[claw](kc/textures/kc_attack_claw_glow.png)

- [ ] Make bone names consistent between mobs and the player.
- [ ] Make b3view able to set attachment points by choosing a named bone (or if necessary, add a vertex and saving to an accompanying metadata file):
  - A high or low attack can strike the correct part of the body.
  - Having particle effects on the right part of the body or weapon also requires setting attachment points.
    - Particles: I sent "codermobs_textures-same-names-as-basis.zip" April 16, 2019:
      codermobs_blood.png, codermobs_damage_stone.png, codermobs_lott_spider_blood.png, codermobs_fireball.png
      - [ ] Use the old Sapier animated version of the fireball.
      - [ ] Allow setting the particle size (and size variance, lifespan, and lifespan variance?) See email: 4/17/19 11:51 AM ET


#### Visuals for storytelling or multiplayer
Sprites for emotes would be just as easy to implement (just little symbols similar to above but for emotions), even for role playing bosses/NPCs such as for minigames or dungeons. I may implement the option to show emote sprites on the player if what they type in chat contains an emote (such as :) or :smile:).

#### Sounds
get hurt, attack, provoke [could also be for spell/skill like the identically-named animation sequence])

##### Warcry
[If war_cry is set, war cry plays every time you click the mob #269](https://github.com/poikilos/EnlivenMinetest/issues/269)
- See also email 5/24/19 9:01 AM ET

### Brainstorms
#### Node name ideas
- Maker Table
- War Table
- Masterwork Foundry
- Related words: Workshop, Mastery, Adept, Ace, Masterwork, Master, Guru, Grand, Maven, Engineer, Experiment, R&D, Study, Dabble, Trifle, Opus
