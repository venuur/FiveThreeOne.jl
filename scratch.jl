import Pkg; Pkg.activate(".")
using Revise
import FiveThreeOne
const F = FiveThreeOne


function deload_week()
    sets = [
        vcat(F.warmup_sets(215), F.deload_lifts(215)),
        vcat(F.warmup_sets(155), F.deload_lifts(155)),
        vcat(F.warmup_sets(240), F.deload_lifts(240)),
        vcat(F.warmup_sets(85), F.deload_lifts(85)),
    ]
    F.print_main_lift_table(["Squat", "Bench Press", "Deadlift", "Press"], sets)
    daily_assistance = [
        F.AssistanceLift("KB Swing", 35, 5, 10),
        F.AssistanceLift("Push-Up", 0, 5, 5),
        F.AssistanceLift("Chin-Up", 0, 5, 3),
        F.AssistanceLift("Hanging Knee Raises", 0, 5, 5),
    ]
    assistance_sets = [
        daily_assistance,
        daily_assistance,
        daily_assistance,
        daily_assistance,
    ]
    F.print_assistance_lift_table(assistance_sets)
end

open("routine.txt", "w") do outfile
    redirect_stdout(outfile) do 
        deload_week()
    end
end
