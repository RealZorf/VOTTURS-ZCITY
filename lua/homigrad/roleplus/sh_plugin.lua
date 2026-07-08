--\\
--; TODO
--; Traitor sees the sub-roles of other players at the beginning of the round
--; Traitor is given time to choose his sub-role

--; Traitor sub-roles:
--=\\Jack of all Trades
--; Everything is standard as it is now
--=//
--=\\Assassin -imba
--; Weapon:
--; Spitting paralyzing darts (3 darts)
--; Capabilities:
--; Take a weapon from your back (even if it is in use), Trip (knocks you down)
--; Passives:
--; Expert in handling any weapon (especially fists), when struck from behind with fists, paralyzes the victim for 3 seconds
--=//

--=\\Saw +-engineer
--; Weapon:
--; Knife, IED
--; Capabilities:
--; Hihihihihihihihihihihihihihihihihihihihihihihihihihihihihihihihihihihihihihihihihihihihihihihihihihihihihihihihihi
--; Passives:
--; Craft from any props on the map and items
--=//

--=\\Saboteur
--; Weapon:
--; Knife, IED, Grenade, Smoke, Adrenaline, Trap???, Door blockers
--; Capabilities:
--; Hide in a suitable prop, Completely change your appearance to that of a corpse (including skin), Roll your neck from behind
--=//

--; Roll your neck from behind
--

--\\Translation of plug-in things into your things
hg.RolePlus = hg.RolePlus or {}
local PLUGIN = hg.RolePlus
PLUGIN.ID = "RolePlus"

function PLUGIN:AddHook(id, func)
	hook.Add(id, "HG.Plugin.List[" .. self.ID .. "].Hooks[" .. id .. "]", func)
end

function PLUGIN:RunHook(id, ...)
	return hook.Run("HG.Plugin.List[" .. self.ID .. "].Hooks[" .. id .. "]", ...)
end
--

PLUGIN.Name = "RolePlus"
PLUGIN.Description = "Adds subroles"
PLUGIN.Version = 1

