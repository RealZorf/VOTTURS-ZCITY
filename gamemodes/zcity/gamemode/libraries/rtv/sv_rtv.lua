-- Old ZCity RTV UI/logic was replaced by SolidMapVote.
-- Compatibility shims live in lua/autorun/sh_solidmapvote_loader.lua so the
-- round system can still call zb.StartRTV / zb.CheckRTVVotes.

zb = zb or {}
zb.votestarted = zb.votestarted or false

function zb.StartRTV()
    if SolidMapVote and SolidMapVote.start and not SolidMapVote.isOpen and not SolidMapVote.finished and not SolidMapVote.changingMap then
        zb.votestarted = true
        SolidMapVote.start()
    end
end

function zb.CheckRTVVotes()
    return SolidMapVote and (SolidMapVote.RTVCompleted or SolidMapVote.startVoteAfterRound or SolidMapVote.isOpen or SolidMapVote.finished or SolidMapVote.changingMap)
end

function zb.ClearRTVVotes()
    if not SolidMapVote then return end
    SolidMapVote.RTVs = {}
    SolidMapVote.PleaseRTVs = {}
    SolidMapVote.DontRTVs = {}
    SolidMapVote.RTVCompleted = false
    SolidMapVote.startVoteAfterRound = false
end

function zb.EndRTV() end
function zb.ThinkRTV() end
function zb.RTVMenu() end
