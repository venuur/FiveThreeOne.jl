module FiveThreeOne

using Printf:@printf

export print_main_lift_table, MainLiftSet

struct Order531 end
struct Order351 end
struct Week1 end
struct Week2 end
struct Week3 end

struct Reps 
    number::Union{Int, UnitRange{Int}}
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
    weight::Float64
    sets::Int
    reps::Reps
end

AssistanceLift(percentage, weight, sets, reps::Int) = AssistanceLift(percentage, weight, sets, Reps(reps))

function entry(s::AssistanceLift, name, sets=1)
    return (s.percentage, s.weight, sets, s.reps)
end

function print_divider(width, n_columns)
    println(repeat("-", width*n_columns))
end

function print_main_lift_table(names, lifts::Vector{Vector{MainLift}})
    # Print header for lifts
    for name in names
        @printf "%20s" name
        print(repeat(" ", 6+2))
    end
    print("\n")

    # Divide header
    print_divider(31, length(names))


    # Print rows of lift table
    for name in names
        @printf "%4s %10s %6s %6s |" "%" "Weight" "Sets" "Reps"
    end
    print("\n")

    #Print lift table entries
    n_longest_lift = maximum([length(lift) for lift in lifts])
    row = 1
    while row <= n_longest_lift
        has_pr_set = false
        for lift in lifts
            if row <= length(lift)
                entry = lift[row]
                has_pr_set = has_pr_set || entry.reps.is_pr_set
                @printf "%4.0f %10.1f %6d %6s |" entry.percentage entry.weight entry.sets entry.reps
            else
                print(repeat(" ", 26))
            end
        end
        if has_pr_set
            println()
            for lift in lifts
                if row <= length(lift)
                    entry = lift[row]
                    pr_goal = pr_set_goal_reps(entry.weight, entry.e1rm_to_beat)
                    @printf "  %6s reps for E1RM %6.1f |" pr_goal.reps pr_goal.new_e1rm
                else
                    print(repeat(" ", 26))
                end
            end
        end
        print("\n")
        row += 1
    end
end

function print_assistance_lift_table(lifts::Vector{Vector{AssistanceLift}})
    for _ in lifts
        @printf "%20s      " "Assistance"
    end
    println()
    print_divider(31, length(lifts))

    for _ in lifts
        @printf "%14s %6s %6s  |" "Weight" "Sets" "Reps"
    end
    println()


    #Print lift table entries
    n_longest_lift = maximum([length(lift) for lift in lifts])
    row = 1
    while row <= n_longest_lift
        for lift in lifts
            if row <= length(lift)
                entry = lift[row]
                @printf "  %-26s  |" entry.name
            else
                print(repeat(" ", 26))
            end
        end
        print("\n")
        for lift in lifts
            if row <= length(lift)
                entry = lift[row]
                @printf "%14d %6d %6s  |" entry.weight entry.sets entry.reps
            else
                print(repeat(" ", 26))
            end
        end
        print("\n")
        row += 1
    end
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
    return MainLift(percentages, weights, 5, 10)
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
