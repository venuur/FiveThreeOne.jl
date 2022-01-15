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

bbb(F.Week2)

