import Pkg; Pkg.activate(".")
using Revise
import FiveThreeOne
const F = FiveThreeOne

sets = [
    F.MainLiftSet(40, 92, 5),
    F.MainLiftSet(50, 115, 5),
    F.MainLiftSet(60, 138, 3),
]