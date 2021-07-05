module FiveThreeOne

using Printf:@printf

export print_main_lift_table, MainLiftSet

struct Order531 end
struct Order351 end
struct Week1 end
struct Week2 end
struct Week3 end
    
struct MainLift
    percentage::Float64
    weight::Float64
    sets::Int
    reps::Int
end

struct AssistanceLift
    name::AbstractString
    weight::Float64
    sets::Int
    reps::Int
end


function entry(s::AssistanceLift, name, sets=1)
    return (s.percentage, s.weight, sets, s.reps)
end

function print_main_lift_table(names, lifts::Vector{Vector{MainLift}})
    # Print header for lifts
    for name in names
        @printf "%20s" name
        print(repeat(" ", 6+2))
    end
    print("\n")

    # Divide header
    println(repeat("-", 31*length(names)))


    # Print rows of lift table
    for name in names
        @printf "%4s %10s %6s %6s |" "%" "Weight" "Sets" "Reps"
    end
    print("\n")

    #Print lift table entries
    n_longest_lift = maximum([length(lift) for lift in lifts])
    row = 1
    while row <= n_longest_lift
        for lift in lifts
            if row <= length(lift)
                entry = lift[row]
                @printf "%4.0f %10.1f %6d %6d |" entry.percentage entry.weight entry.sets entry.reps
            else
                print(repeat(" ", 26))
            end
        end
        print("\n")
        row += 1
    end
end

function print_assistance_lift_table(lifts::Vector{AssistanceLift})
    @printf "%30s\n" "Assistance"
    println(repeat("-", 50))
    @printf "%20s %10s %10s %10s\n" "Name" "Weight" "Sets" "Reps"
    for lift in lifts
        @printf "%20s %10s %10s %10s\n" lift.name lift.weight lift.sets lift.reps
    end
end

make_single_sets(percentages, weights, reps) = collect(map(MainLift, percentages, weights, repeat([1], length(percentages)), reps))
round_to_half_pound(x) = round(x * 2, RoundNearest) / 2
make_weights(percentages, training_max) = round_to_half_pound.(percentages / 100 .* training_max)


function warmup_sets(training_max)
    percentages = [40, 50, 60]
    reps = [5,5,3]
    weights = make_weights(percentages, training_max)
    return make_single_sets(percentages, weights, reps)
end

function main_lifts(training_max, week, order)
    if order === Order351 && week === Week1
        week = Week2
    elseif order === Order351 && week === Week2
        week = Week1
    end
    if week === Week1
        percentages = [65, 75, 85]
        reps = [5,5,5]
    elseif week === Week2
        percentages = [70, 80, 90]
        reps = [3,3,3]
    elseif week === Week3
        percentages = [75, 85, 95]
        reps = [5,3,1]
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

end
