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

function routine_from_file(; days, main_lifts, maxes_file, assistance_file, order, print_config=nothing)
    function _routine_for_week(week)
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
        maxes_data = YAML.load_file(maxes_file)
        assistance_data = YAML.load_file(assistance_file)

        main_sets = Vector{FiveThreeOne.MainLift}[]
        assistance_sets = Vector{FiveThreeOne.AssistanceLift}[]
        for day in days
            day_mains = Vector{MainLift}[]
            push!(day_mains, warmup_sets(maxes_data["training"][day]))
            for lift in main_lifts
                push!(day_mains, lift(maxes_data, day, week, order))
            end
            day_mains = vcat(day_mains...)
            @show day_mains
            push!(main_sets, day_mains)
            day_assistance = AssistanceLift[]
            for lift in assistance_data[day]
                push!(day_assistance, AssistanceLift(lift...))
            end
            push!(assistance_sets, day_assistance)
        end
        print_routine(
            days,
            main_sets,
            assistance_sets,
            n_columns=active_print_config[:number_columns])
    end
    return _routine_for_week
end

function make_routine(training_maxes, supplemental, order, assistance, e1rm_for_pr=nothing; print_config=nothing)
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
    names = Vector{AbstractString}
    lifts = Vector{MainLift}
    assistance_lifts = Vector{AssistanceLift}

    if e1rm_for_pr === nothing
        e1rm_for_pr = repeat([nothing], length(training_maxes))
        has_pr_sets = false
    else
        has_pr_sets = true
    end

    function _print_routine(week; fives_progression=false)
        names = [n for (n, _) in training_maxes]
        if fives_progression
            _main = ((tm, week) -> main_lifts_5pro(tm, week, order))
        else
            _main = ((tm, week) -> main_lifts(tm, week, order, has_pr_sets, e1rm_to_beat))
        end
        main_sets = [
            vcat(warmup_sets(tm),
                 _main(tm, week),
                 supplemental(tm, week, order))
            for ((_, tm), lift_e1rm) in zip(training_maxes, e1rm_for_pr)
        ]
        assistance_sets = [
            [AssistanceLift(each_lift...) for each_lift in daily_assistance]
            for daily_assistance in assistance
        ]
        print_routine(
            names,
            main_sets,
            assistance_sets,
            n_columns=active_print_config[:number_columns])
    end

    return _print_routine
end

function make_main_lift_cell(name, lifts::Vector{MainLift})
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

function print_routine(
    names::Vector{<:AbstractString},
    main_lifts::Vector{Vector{MainLift}},
    assistance::Vector{Vector{AssistanceLift}};
    n_columns::Int=length(names),
    row_sep=" ",
    )
    main_lift_cells = [make_main_lift_cell(name, lifts) for (name, lifts) in zip(names, main_lifts)]
    assistance_cells = [make_assistance_cell(lifts) for lifts in assistance]
    daily_cells = [vmerge(main, assistance; sep="=") for (main, assistance) in zip(main_lift_cells, assistance_cells)]
    n_rows = Int(ceil(length(names) / n_columns))
    row_cells = Vector{TextCell}(undef, n_rows)
    groups = [(1+(i-1)*n_columns):i*n_columns for i in 1:n_rows]
    for i in 1:n_rows
        j1 = first(groups[i])
        j2 = min(last(groups[i]), length(daily_cells))
        row_cells[i] = hmerge(daily_cells[j1:j2], sep=" | ")
    end
    if length(row_cells) > 1
        routine = vmerge(row_cells; sep=row_sep)
    else
        routine = row_cells[1]
    end
    println(format_text(routine))
end

make_single_sets(percentages, weights, reps) = collect(map(MainLift, percentages, weights, repeat([1], length(percentages)), reps))
function make_single_sets(percentages, weights, reps, e1rm_to_beat)
    collect(map(MainLift, percentages, weights, repeat([1], length(percentages)), reps, repeat([e1rm_to_beat], length(percentages))))
end
round_to_half_pound(x) = round(x * 2, RoundNearest) / 2
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

end
