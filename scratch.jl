import Pkg; Pkg.activate(".")
using Revise
import FiveThreeOne
const F = FiveThreeOne

sets = [
    vcat(F.warmup_sets(215), F.deload_lifts(215)),
    vcat(F.warmup_sets(155), F.deload_lifts(155)),
    vcat(F.warmup_sets(240), F.deload_lifts(240)),
    vcat(F.warmup_sets(85), F.deload_lifts(85)),
]
F.print_main_lift_table(["Squat", "Bench Press", "Deadlift", "Press"], sets)