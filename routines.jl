import Pkg; Pkg.activate(".")
using Revise

import FiveThreeOne
const F = FiveThreeOne

const MAXES_FILE = "maxes.yaml"
const BBB_ASSISTANCE_FILE = "assistance.yaml"

main_lifts_5pro(maxes_data, day, week, order) = F.main_lifts_5pro(maxes_data["training"][day], week, order)
main_lifts(maxes_data, day, week, order) = F.main_lifts_5pro(maxes_data["training"][day], week, order, false, maxes["e1rm"])
main_lifts_pr_sets(maxes_data, day, week, order) = F.main_lifts_5pro(maxes_data["training"][day], week, order, true, maxes["e1rm"])
boringbutbig_light(maxes_data, day, week, order) = F.boringbutbig_light(maxes_data["training"][day], week, order)

bbb = F.routine_from_file(
    days=["Squat", "Bench", "Deadlift", "Press"],
    main_lifts=[
        main_lifts_5pro,
        boringbutbig_light,
    ],
    maxes_file=MAXES_FILE,
    assistance_file=BBB_ASSISTANCE_FILE,
    order=F.Order351,
)

bbb(F.Week3)

GZCL_T3 = "gzcl_t3.yaml"
GZCL_T2_MAP = Dict(
    "Squat" => "Bench",
    "Deadlift" => "Press",
    "Bench" => "Squat",
)
gzcl_t1(maxes_data, day, week, order) = F.gzcl_t1(maxes_data["training"][day], week, order)
gzcl_t2(maxes_data, day, week, order) = F.gzcl_t2(maxes_data["training"][GZCL_T2_MAP[day]], week, order)

gzcl_3day = F.routine_from_file(
    days=["Squat", "Deadlift",  "Bench"],
    main_lifts=[
        gzcl_t1,
    ],
    secondary_names=["Bench", "Press", "Squat"],
    secondary_lifts=[
        gzcl_t2,
    ],
    maxes_file=MAXES_FILE,
    assistance_file=GZCL_T3,
    order=F.Order351,
)

gzcl_3day(F.Week1)



GZCL_TM = "maxes_rippler.yaml"
GZCL_T3 = "gzcl_t3.yaml"

gzcl_rippler_t1(maxes_data, day, week, order) = F.gzcl_the_rippler_t1(maxes_data["training"]["t1"][day], week)
gzcl_rippler_t2(maxes_data, day, week, order) = F.gzcl_the_rippler_t2(maxes_data["training"]["t2"][GZCL_T2_MAP[day]], week)

gzcl_3day_rippler = F.routine_from_file(
    days=["Squat", "Deadlift",  "Bench"],
    main_lifts=[
        gzcl_rippler_t1,
    ],
    secondary_names=["Bench", "Press", "Squat"],
    secondary_lifts=[
        gzcl_rippler_t2,
    ],
    maxes_file=GZCL_TM,
    assistance_file=GZCL_T3,
    order=F.Order351,
)

gzcl_3day_rippler(F.Week12)