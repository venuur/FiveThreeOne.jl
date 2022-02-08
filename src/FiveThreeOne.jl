module FiveThreeOne

include("TextTable.jl")
import .TextTable
using .TextTable
export TextTable

using Base: Float64
using Printf:@printf

import YAML

export print_main_lift_table, MainLiftSet

struct Order531 end
struct Order351 end
struct Week1 end
struct Week2 end
struct Week3 end
struct Week4 end
struct Week5 end
struct Week6 end
struct Week7 end
struct Week8 end
struct Week9 end
struct Week10 end
struct Week11 end
struct Week12 end

struct Reps 
    number::Union{Int, UnitRange{Int}, AbstractString}
    is_pr_set::Bool
end

Reps(number) = Reps(number, false)

function Base.show(io::IO, reps::Reps)
    if reps.number isa UnitRange{Int}
        print(io, first(reps.number), "-", last(reps.number))
    else
        print(io, reps.number)
    end
    reps.is_pr_set && print(io, "+")
end
    
struct MainLift
    percentage::Float64
    weight::Float64
    sets::Int
    reps::Reps
    e1rm_to_beat::Union{Nothing, Float64}
end

MainLift(percentage, weight, sets, reps::Int) = MainLift(percentage, weight, sets, Reps(reps), nothing)
MainLift(percentage, weight, sets, reps::UnitRange{Int}) = MainLift(percentage, weight, sets, Reps(reps), nothing)
MainLift(percentage, weight, sets, reps::Reps) = MainLift(percentage, weight, sets, reps, nothing)
MainLift(percentage, weight, sets, reps::Int, e1rm_to_beat) = MainLift(percentage, weight, sets, Reps(reps), e1rm_to_beat)
MainLift(percentage, weight, sets, reps::UnitRange{Int}, e1rm_to_beat) = MainLift(percentage, weight, sets, Reps(reps), e1rm_to_beat)


struct AssistanceLift
    name::AbstractString
    weight::Union{Float64, Int, String}
    sets::Int
    reps::Reps
end

AssistanceLift(percentage, weight, sets, reps::Union{Int, UnitRange{Int}, AbstractString}) = AssistanceLift(percentage, weight, sets, Reps(reps, false))


function parse_print_config(print_config)
    active_print_config = Dict(
        :number_columns => 4,
    )
    if print_config !== nothing
        for k in keys(active_print_config)
            if haskey(print_config, k)
                active_print_config[k] = print_config[k]
            end
        end
    end
    return active_print_config
end

function make_routine_printer(routine_data, mains_functions, assistance_function; print_config=nothing)
    function _routine_for_week(week)
        print_config = parse_print_config(print_config)
        routine_lifts = [
            (
                mains=[(name=data.name, lifts=main_function(data, week)) for (data, main_function) in zip(day_data.mains, mains_functions)],
                assistance=[assistance_function(data, week) for data in day_data.assistance],
            )
            for day_data in routine_data
        ]
        day_cells = [
            vcat(
                [make_main_lift_cell(main.name, main.lifts) for main in routine_day.mains]...,
                make_assistance_cell(routine_day.assistance),
            )
            for routine_day in routine_lifts
        ]
        @show day_cells
        print_day_cells(
            day_cells,
            print_config[:number_columns],
        )
    end
end

function print_day_cells(
    day_cells::Vector{Vector{TextCell}},
    n_columns::Int=length(names),
    row_sep=" ",
    )
    day_single_cells = [vmerge(cells; sep="=") for cells in day_cells]
    n_rows = Int(ceil(length(day_cells) / n_columns))
    row_cells = Vector{TextCell}(undef, n_rows)
    groups = [(1+(i-1)*n_columns):i*n_columns for i in 1:n_rows]
    for i in 1:n_rows
        j1 = first(groups[i])
        j2 = min(last(groups[i]), length(day_single_cells))
        row_cells[i] = hmerge(day_single_cells[j1:j2], sep=" | ")
    end
    if length(row_cells) > 1
        routine = vmerge(row_cells; sep=row_sep)
    else
        routine = row_cells[1]
    end
    println(format_text(routine))
end

function make_main_lift_cell(name, lifts::Vector{MainLift})
    if length(lifts) == 0
        return TextCell(["No Secondary"])
    end
    header_cell = TextCell([name])
    percentages = TextCell(vcat(
        ["%"],
        [string(Int(round(lift.percentage))) for lift in lifts]),
        horizontal_alignment=align_right,
        )
    set_width!(percentages, 4)
    weights = TextCell(vcat(
        ["Weight"],
        [string(lift.weight) for lift in lifts]),
        horizontal_alignment=align_right,
        )
    sets = TextCell(vcat(
        ["Sets"],
        [string(lift.sets) for lift in lifts]),
        horizontal_alignment=align_right,
        )
    reps = TextCell(vcat(
        ["Reps"],
        [string(lift.reps) for lift in lifts]),
        horizontal_alignment=align_right,
        )
    lift_details = hmerge([percentages, weights, sets, reps]; sep="  ")
    
    # append pr details if there's a pr set
    pr_content = AbstractString[]
    for lift in lifts
        if lift.reps.is_pr_set
            if lift.e1rm_to_beat === nothing
                continue
            end
            pr_goal = pr_set_goal_reps(lift.weight, lift.e1rm_to_beat)
            push!(pr_content, "$(pr_goal.reps) reps for E1RM $(pr_goal.new_e1rm)")
        end
    end
    if length(pr_content) > 0
        pr_cell = TextCell(pr_content)
        lift_details = vmerge(lift_details, pr_cell)
    end
    
    # add header to complete
    return vmerge(header_cell, lift_details; sep="-")
end

function make_assistance_cell(lifts::Vector{AssistanceLift})
    header_cell = TextCell(["Assistance"])
    weights = TextCell(vcat(
        ["Weight"],
        [string(lift.weight) for lift in lifts]),
        horizontal_alignment=align_right,
        )
    sets = TextCell(vcat(
        ["Sets"],
        [string(lift.sets) for lift in lifts]),
        horizontal_alignment=align_right,
        )
    reps = TextCell(vcat(
        ["Reps"],
        [string(lift.reps) for lift in lifts]),
        horizontal_alignment=align_right,
        )
    lift_details = hmerge([weights, sets, reps]; horizontal_alignment=align_right, sep="  ")
    
    names = TextCell([lift.name for lift in lifts])
    assistance = interleave(lift_details, names; horizontal_alignment=align_right)
    return vmerge(header_cell, assistance; sep="-")
end

make_single_sets(percentages, weights, reps) = collect(map(MainLift, percentages, weights, repeat([1], length(percentages)), reps))
function make_single_sets(percentages, weights, reps, e1rm_to_beat)
    collect(map(MainLift, percentages, weights, repeat([1], length(percentages)), reps, repeat([e1rm_to_beat], length(percentages))))
end
round_to_half_pound(x) = round(x * 2, RoundNearest) / 2
make_weight(percentage, training_max) = round_to_half_pound(percentage / 100 * training_max)
make_weights(percentages, training_max) = round_to_half_pound.(percentages / 100 .* training_max)


function warmup_sets(training_max)
    percentages = [40, 50, 60]
    reps = [5,5,3]
    weights = make_weights(percentages, training_max)
    return make_single_sets(percentages, weights, reps)
end

function main_lifts(training_max, week, order, pr_sets, e1rm_to_beat)
    make_pr_reps(reps) = Reps(reps, pr_sets)

    if order === Order351 && week === Week1
        week = Week2
    elseif order === Order351 && week === Week2
        week = Week1
    end
    if week === Week1
        percentages = [65, 75, 85]
        reps = [5,5, make_pr_reps(5)]
    elseif week === Week2
        percentages = [70, 80, 90]
        reps = [3,3, make_pr_reps(3)]
    elseif week === Week3
        percentages = [75, 85, 95]
        reps = [5,3, make_pr_reps(1)]
    else
        throw(DomainError("Argument `week` must be Week1, Week2, or Week3."))
    end
    weights = make_weights(percentages, training_max)
    return make_single_sets(percentages, weights, reps, e1rm_to_beat)
end

function main_lifts_5pro(training_max, week, order)
    if order === Order351 && week === Week1
        week = Week2
    elseif order === Order351 && week === Week2
        week = Week1
    end
    if week === Week1
        percentages = [65, 75, 85]
        reps = [5,5, 5]
    elseif week === Week2
        percentages = [70, 80, 90]
        reps = [5,5, 5]
    elseif week === Week3
        percentages = [75, 85, 95]
        reps = [5,5, 5]
    else
        throw(DomainError("Argument `week` must be Week1, Week2, or Week3."))
    end
    weights = make_weights(percentages, training_max)
    return make_single_sets(percentages, weights, reps)
end

function deload_lifts(training_max)
    percentages = [70, 80, 90, 100]
    reps = [5, 3, 1, 1]
    weights = make_weights(percentages, training_max)
    return make_single_sets(percentages, weights, reps)
end

function training_max_test_lifts(training_max)
    percentages = [70, 80, 90, 100]
    reps = [5, 5, 5, 3:5]
    weights = make_weights(percentages, training_max)
    return make_single_sets(percentages, weights, reps)
end

function widowmaker(training_max, week, order)
    if order === Order351 && week === Week1
        week = Week2
    elseif order === Order351 && week === Week2
        week = Week1
    end
    if week === Week1
        percentages = [65]
        reps = [15:20]
    elseif week === Week2
        percentages = [70]
        reps = [15:20]
    elseif week === Week3
        percentages = [75]
        reps = [15:20]
    else
        throw(DomainError("Argument `week` must be Week1, Week2, or Week3."))
    end
    weights = make_weights(percentages, training_max)
    return make_single_sets(percentages, weights, reps)
end

function boringbutbig_light(training_max, week, order)
    if order === Order351 && week === Week1
        week = Week2
    elseif order === Order351 && week === Week2
        week = Week1
    end
    if week === Week1
        percentages = 40
    elseif week === Week2
        percentages = 50
    elseif week === Week3
        percentages = 60
    else
        throw(DomainError("Argument `week` must be Week1, Week2, or Week3."))
    end
    weights = make_weights(percentages, training_max)
    return [MainLift(percentages, weights, 5, 10)]
end

e1rm(weight, reps::Int) = weight * reps * 0.0333 + weight
e1rm(weight, reps::UnitRange{Int}) = collect(map(x -> e1rm(weight, x), reps))
e1rm(weight, reps::Reps) = e1rm(weight, reps.number)

struct PRGoal
    reps::Reps
    new_e1rm::Float64
end

function pr_set_goal_reps(pr_set_weight, e1rm_to_beat)
    rep_range = 1:50
    e1rm_above_goal = e1rm(pr_set_weight, rep_range) .>= e1rm_to_beat
    goal_reps = collect(rep_range)[e1rm_above_goal][1]
    return PRGoal(Reps(goal_reps), e1rm(pr_set_weight, goal_reps))
end

function gzcl_t1(training_max, week, order)
    if order === Order351 && week === Week1
        week = Week2
    elseif order === Order351 && week === Week2
        week = Week1
    end
    if week === Week1
        percentages = [65, 75, 85]
        reps = [5, 5, 5]
    elseif week === Week2
        percentages = [70, 80, 90]
        reps = [5,5, 5]
    elseif week === Week3
        percentages = [75, 85, 95]
        reps = [5,5, 5]
    else
        throw(DomainError("Argument `week` must be Week1, Week2, or Week3."))
    end
    weights = make_weights(percentages, training_max)
    return [
        MainLift(percentages[1], weights[1], 1, 3),
        MainLift(percentages[2], weights[2], 1, 3),
        MainLift(percentages[3], weights[3], 5, 3)
    ]
end


function gzcl_t2(training_max, week, order)
    if order === Order351 && week === Week1
        week = Week2
    elseif order === Order351 && week === Week2
        week = Week1
    end
    if week === Week1
        percentages = [65, 75, 85]
        reps = [5, 5, 5]
    elseif week === Week2
        percentages = [70, 80, 90]
        reps = [5,5, 5]
    elseif week === Week3
        percentages = [75, 85, 95]
        reps = [5,5, 5]
    else
        throw(DomainError("Argument `week` must be Week1, Week2, or Week3."))
    end
    weights = make_weights(percentages, training_max)
    return [
        MainLift(percentages[1], weights[1], 3, 8)
    ]
end

function warmup_percentages(warmup_start, top_set) 
    percentages = collect(range(warmup_start, top_set, length=6))
    return percentages[1:5]
end
round_to_five_pounds(x) = round(x * .2, RoundNearest) / 0.2
make_warmup_weights(percentages, training_max) = round_to_five_pounds.(percentages / 100 .* training_max)

gzcl_spec(pct, reps, sets, is_pr_set=false) = (percentage=pct, reps=Reps(reps, is_pr_set), sets=sets)

GZCL_RIPPLER_T1_SPEC = Dict(
    Week1 => gzcl_spec(85, 5, 3),
    Week2 => gzcl_spec(90, 3, 4, true),
    Week3 => gzcl_spec(87.5, 4, 3),
    Week4 => gzcl_spec(92.5, 2, 5),
    Week5 => gzcl_spec(90, 4, 3, true),
    Week6 => gzcl_spec(95, 2, 4),
    Week7 => gzcl_spec(92.5, 3, 3),
    Week8 => gzcl_spec(97.5, 1, 9, true),
    Week9 => gzcl_spec(95, 2, 3, true),
    Week10 => gzcl_spec(100, 1, 1, true),
    Week11 => gzcl_spec(90, 2, 4, true),
    # Week 12 is TM test day
)

GZCL_RIPPLER_T2_SPEC = Dict(
    Week1 => gzcl_spec(80, 6, 5),
    Week2 => gzcl_spec(85, 5, 5),
    Week3 => gzcl_spec(90, 4, 5, true),
    Week4 => gzcl_spec(82.5, 6, 4),
    Week5 => gzcl_spec(87.5, 5, 4),
    Week6 => gzcl_spec(92.5, 4, 4, true),
    Week7 => gzcl_spec(85, 6, 3),
    Week8 => gzcl_spec(90, 5, 3),
    Week9 => gzcl_spec(95, 4, 3, true),
    Week10 => gzcl_spec(100, 3, 5, true),
    # No T2 Weeks 11 or 12
)

function gzcl_the_rippler_t1(training_max, week)
    if week == Week12
        return gzcl_the_rippler_tm_test(training_max)
    end
    topset_spec = GZCL_RIPPLER_T1_SPEC[week]
    warmup_set_percentages = warmup_percentages(40, topset_spec.percentage)
    warmup_set_weights = make_warmup_weights(warmup_set_percentages, training_max)
    topset_weight = make_weight(topset_spec.percentage, training_max)
    reps = [5, 5, 5, 3, 3]
    @show sets = make_single_sets(warmup_set_percentages, warmup_set_weights, reps)
    push!(sets, MainLift(topset_spec.percentage, topset_weight, topset_spec.sets, topset_spec.reps))
    return sets
end


function gzcl_the_rippler_tm_test(training_max)
    warmup_set_percentages = warmup_percentages(40, 90)
    warmup_set_weights = make_warmup_weights(warmup_set_percentages, training_max)
    reps = [5, 5, 5, 3, 3]
    topset_pct = [90, 95, 100]
    topset_weights = make_weights(topset_pct, training_max)
    topset_reps = [3, 2, 1]
    topset_sets = [1, 1, 3]
    topset_ispr = [false, false, true]
    sets = make_single_sets(warmup_set_percentages, warmup_set_weights, reps)
    return vcat(sets, [
        MainLift(pct, w, s, Reps(r, ispr))
        for (pct, w, s, r, ispr) in zip(
            topset_pct,
            topset_weights,
            topset_sets,
            topset_reps,
            topset_ispr,
        )
    ])
end

function gzcl_the_rippler_t2(training_max, week)
    if week in (Week11, Week12)
        return []
    end
    topset_spec = GZCL_RIPPLER_T2_SPEC[week]
    weight = make_weight(topset_spec.percentage, training_max)
    return [MainLift(topset_spec.percentage, weight, topset_spec.sets, topset_spec.reps)]
end

function gzcl_the_rippler_t3(name, weight, week)
    if week in (Week1, Week2, Week3)
        sets = 5
    elseif week in (Week4, Week5, Week6)
        sets = 4
    elseif week in (Week7, Week8, Week9)
        sets = 3
    elseif week in (Week10,)
        sets = 2
    elseif week in (Week11, Week12)
        return []
    end
    return AssistanceLift(name, weight, sets, Reps(10, true))
end

end