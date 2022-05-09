import Pkg; Pkg.activate(".")
using Revise

import YAML
import FiveThreeOne
const F = FiveThreeOne

GZCL_TM = "maxes_rippler.yaml"
GZCL_T3 = "gzcl_t3.yaml"

gzcl_rippler_t1(data, week) = F.gzcl_the_rippler_t1(data.training_max, week)
gzcl_rippler_t2(data, week) = F.gzcl_the_rippler_t2(data.training_max, week)
gzcl_rippler_t3(data, week) = F.gzcl_the_rippler_t3(data.name, data.weight, week)

function parse_rippler_yaml(yaml_file)
    data = YAML.load_file(yaml_file)
    routine = [
        (
            mains=[
                (name=name, training_max=weight)
                for (name, weight) in day_data["mains"]
            ],
            assistance=[
                (name=name, weight=weight)
                for (name, weight) in day_data["assistance"]
            ]
        )
        for day_data in data
    ]
    return routine
end

rippler_data = parse_rippler_yaml("rippler_lifts.yaml")

gzcl_3day_rippler = F.make_routine_printer(
    rippler_data,
    [gzcl_rippler_t1, gzcl_rippler_t2],
    gzcl_rippler_t3,
)

gzcl_3day_rippler(F.Week9)

gzcl_rippler_tm_test(data, week) = F.gzcl_the_rippler_tm_test(data.training_max)

gzcl_3day_rippler_tm_test = F.make_routine_printer(
    rippler_data,
    [gzcl_rippler_tm_test],
    (x...) -> nothing,
)

gzcl_3day_rippler_tm_test(F.Week1)


function parse_j_and_t_yaml(yaml_file)
    data = YAML.load_file(yaml_file)
    function unpack_mains(mains_data)
        name, rm, tm = mains_data[1]
        t1 = (name=name, rep_maxes=rm, training_max=tm)
        name, tm = mains_data[2]
        t2 = (name=name, training_max=tm)
        return [t1, t2]
    end
    routine = [
        (
            mains=unpack_mains(day_data["mains"]),
            assistance=[
                (name=name,)
                for (name,) in day_data["assistance"]
            ]
        )
        for day_data in data
    ]
    return routine
end

gzcl_j_and_t_t1(data, week) = F.gzcl_j_and_t_t1(data.rep_maxes, data.training_max, week)
gzcl_j_and_t_t2(data, week) = F.gzcl_j_and_t_t2(data.training_max, week)
gzcl_j_and_t_t3(data, week) = F.gzcl_j_and_t_t3(data.name, week)

j_and_t_data = parse_j_and_t_yaml("jacked_and_tan_lifts.yaml")

gzcl_3day_j_and_t = F.make_routine_printer(
    j_and_t_data,
    [gzcl_j_and_t_t1, gzcl_j_and_t_t2],
    gzcl_j_and_t_t3,
)

gzcl_3day_j_and_t(F.Week1)
