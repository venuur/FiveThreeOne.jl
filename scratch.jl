import Pkg; Pkg.activate(".")
using Revise
import FiveThreeOne
const F = FiveThreeOne

include("training_max.jl")
include("e1rm.jl")

function deload_week()
    sets = [
        vcat(F.warmup_sets(SQUAT), F.deload_lifts(SQUAT)),
        vcat(F.warmup_sets(BENCH), F.deload_lifts(BENCH)),
        vcat(F.warmup_sets(DEADLIFT), F.deload_lifts(DEADLIFT)),
        vcat(F.warmup_sets(PRESS), F.deload_lifts(PRESS)),
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

function write_deload_week()
    open("routine.txt", "w") do outfile
        redirect_stdout(outfile) do 
            deload_week()
        end
    end
end

function anchor_week(week)
    sets = [
        vcat(F.warmup_sets(SQUAT), F.main_lifts(SQUAT, week, F.Order531, true, SQUAT_1RM), F.widowmaker(SQUAT, week, F.Order531)),
        vcat(F.warmup_sets(BENCH), F.main_lifts(BENCH, week, F.Order531, true, BENCH_1RM), F.widowmaker(BENCH, week, F.Order531)),
        vcat(F.warmup_sets(DEADLIFT), F.main_lifts(DEADLIFT, week, F.Order531, true, DEADLIFT_1RM), F.widowmaker(DEADLIFT, week, F.Order531)),
        vcat(F.warmup_sets(PRESS), F.main_lifts(PRESS, week, F.Order531, true, PRESS_1RM), F.widowmaker(PRESS, week, F.Order531)),
    ]
    F.print_main_lift_table(["Squat", "Bench Press", "Deadlift", "Press"], sets)
    daily_assistance = [
        F.AssistanceLift("KB Swing", 35, 10, 10),
        F.AssistanceLift("Push-Up", 0, 10, 5),
        F.AssistanceLift("Chin-Up", 0, 10, 3),
        F.AssistanceLift("Hanging Knee Raises", 0, 10, 5),
    ]
    assistance_sets = [
        daily_assistance,
        daily_assistance,
        daily_assistance,
        daily_assistance,
    ]
    F.print_assistance_lift_table(assistance_sets)
end

function write_anchor_week(week)
    open("routine.txt", "w") do outfile
        redirect_stdout(outfile) do 
            anchor_week(week)
        end
    end
end

