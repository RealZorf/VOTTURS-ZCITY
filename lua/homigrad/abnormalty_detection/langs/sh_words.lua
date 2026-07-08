--\\Translation of plug-in things into your things
hg.Abnormalties = hg.Abnormalties or {}
local PLUGIN = hg.Abnormalties
--

PLUGIN.SpecialWords = PLUGIN.SpecialWords or {}
local sw = PLUGIN.SpecialWords
sw["ritual"] = {ritual = 4, shield = -4}
sw["blood"] = {harm = 3, help = -4}
sw["death"] = {harm = 3, sacrifice = 3, help = -4}
sw["sacrifice"] = {sacrifice = 5, help = -4}
sw["help"] = {help = 5, harm = -4}
sw["shield"] = {shield = 2, harm = -2}
sw["Hello"] = {shield = 2, harm = -2, help = 2}
sw["note"] = {ritual = 4}

sw["ritual"] = sw["ritual"]
sw["blood"] = sw["blood"]
sw["death"] = sw["death"]
sw["sacrifice"] = sw["sacrifice"]
sw["help"] = sw["help"]
sw["shield"] = sw["shield"]