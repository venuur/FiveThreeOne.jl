import Pkg; Pkg.activate(".")
using Revise
import FiveThreeOne
const F = FiveThreeOne
import FiveThreeOne.TextTable
const T = FiveThreeOne.TextTable

include("training_max.jl")
include("e1rm.jl")

function deload_week()
    sets = [
        vcat(F.warmup_sets(SQUAT), F.deload_lifts(SQUAT)),
        vcat(F.warmup_sets(BENCH), F.deload_lifts(BENCH)),
        vcat(F.warmup_sets(DEADLIFT), F.deload_lifts(DEADLIFT)),
        vcat(F.warmup_sets(PRESS), F.deload_lifts(PRESS)),
    ]
    daily_assistance = [
        F.AssistanceLift("KB Swing", 35, 6, 10),
        F.AssistanceLift("KB Swing", 53, 4, 10),
        F.AssistanceLift("Push-Up", 0, 5, 10),
        F.AssistanceLift("Chin-Up", 0, 5, 3),
        F.AssistanceLift("Face Pull", 0, 5, 10),
    ]
    assistance_sets = [
        daily_assistance,
        daily_assistance,
        daily_assistance,
        daily_assistance,
    ]
    F.print_routine(["Squat", "Bench Press", "Deadlift", "Press"], sets, assistance_sets)
end

function write_deload_week()
    open("routine.txt", "w") do outfile
        redirect_stdout(outfile) do 
            deload_week()
        end
    end
end

function training_max_test_week()
    sets = [
        vcat(F.warmup_sets(SQUAT), F.training_max_test_lifts(SQUAT)),
        vcat(F.warmup_sets(BENCH), F.training_max_test_lifts(BENCH)),
        vcat(F.warmup_sets(DEADLIFT), F.training_max_test_lifts(DEADLIFT)),
        vcat(F.warmup_sets(PRESS), F.training_max_test_lifts(PRESS)),
    ]
    assistance_sets = [
        [
        F.AssistanceLift("KB Swing", 53, 5, 10),
        F.AssistanceLift("Push-Up", 0, 5, 10),
        F.AssistanceLift("Chin-Up", 0, 5, 5),
    ],
    [
        F.AssistanceLift("KB Swing", 53, 5, 10),
        F.AssistanceLift("DB Press", 20, 4, 12),
        F.AssistanceLift("Face Pull", 4, 5, 10),
    ],
        [
        F.AssistanceLift("KB Swing", 53, 5, 10),
        F.AssistanceLift("Push-Up", 0, 5, 10),
        F.AssistanceLift("Chin-Up", 0, 5, 5),
    ],
    [
        F.AssistanceLift("KB Swing", 53, 5, 10),
        F.AssistanceLift("DB French Press", 20, 4, 8),
        F.AssistanceLift("DB Row", 40, 4, 12),
    ],
    ]
    F.print_routine(["Squat", "Bench Press", "Deadlift", "Press"], sets, assistance_sets)
end

function write_training_max_test_week()
    open("routine.txt", "w") do outfile
        redirect_stdout(outfile) do 
            training_max_test_week()
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
    assistance_sets = [
        [
        F.AssistanceLift("KB Swing", 35, 8, 10),
        F.AssistanceLift("KB Swing", 53, 2, 10),
        F.AssistanceLift("Push-Up", 0, 10, 5),
        F.AssistanceLift("Chin-Up", 0, 10, 3),
    ],
        [
        F.AssistanceLift("KB Swing", 35, 8, 10),
        F.AssistanceLift("KB Swing", 53, 2, 10),
        F.AssistanceLift("Lat Raise", 10, 8, 8),
        F.AssistanceLift("Face Pull", 4, 10, 10),
    ],
    [
        F.AssistanceLift("KB Swing", 35, 8, 10),
        F.AssistanceLift("KB Swing", 53, 2, 10),
        F.AssistanceLift("Push-Up", 0, 10, 5),
        F.AssistanceLift("Chin-Up", 0, 10, 3),
    ],
        [
        F.AssistanceLift("KB Swing", 35, 8, 10),
        F.AssistanceLift("KB Swing", 53, 2, 10),
        F.AssistanceLift("Front Plate Raise", 10, 8, 8),
        F.AssistanceLift("Face Pull", 4, 10, 10),
    ],
    ]
    F.print_routine(["Squat", "Bench Press", "Deadlift", "Press"], sets, assistance_sets)
end

function write_anchor_week(week)
    open("routine.txt", "w") do outfile
        redirect_stdout(outfile) do 
            anchor_week(week)
        end
    end
end

leader_week_bbb = F.make_routine(
    ["Squat" => SQUAT,
     "Bench" => BENCH,
     "Deadlift" => DEADLIFT,
     "Press" => PRESS,
     "Row" => ROW],
     F.boringbutbig_light,
     F.Order351,
     [
        [
            ("Hanging Leg Raise", 0, 6, 5),
            ("French Press", 15, 4, 12),
            ("DB Kroc Row", 40, 4, 8),
        ],
            [
            ("Ab Wheel", 0, 5, 5),
            ("DB Press", 15, 4, 12),
            ("Chin-Up", 0, 10, 3),
        ],
            [
            ("Side Plank", 0, 5, 30),
            ("Push-Up", 0, 6, 10),
            ("Face Pull", "yellow", 6, 12),
        ],
        [
            ("Palloff Press", "blue", 5, 30),
            ("Lat Raise", 10, 4, 10),
            ("Inverted Row", 0, 6, 10),
        ],
        [
            ("KB Swing", 35, 4, 10),
            ("KB Swing", 53, 6, 10),
        ],
    ],
)

function write_leader_week_bbb(week)
    open("routine.txt", "w") do outfile
        redirect_stdout(outfile) do 
            leader_week_bbb(week)
        end
    end
end

