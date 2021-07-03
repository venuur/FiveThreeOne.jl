module FiveThreeOne

using Printf:@printf

export lift_table, MainLiftSet

abstract type LiftSet end

struct MainLiftSet <: LiftSet
    percentage::Float64
    weight::Float64
    reps::Int
end

function entry(s::MainLiftSet, sets=1)
    return (s.percentage, s.weight, sets, s.reps)
end

function lift_table(name, sets::Vector{<:LiftSet})
    @printf "%20s\n" name
    println(repeat("-", 44))
    @printf "%4s %10s %10s %10s\n" "%" "Weight" "Sets" "Reps"
    for (p, w, s, r) in map(entry, sets)
        @printf "%4.0f %10.1f %10d %10d\n" p w s r
    end
end

make_sets(percentages, weights, reps) = collect(map(MainLiftSet, percentages, weights, reps))
make_weights(percentages, weights) = round_to_half_pound.(percentages / 100 .* training_max)

function warmup_sets(training_max)
    percentages = [40, 50, 60]
    weights = make_weights(percentages, weights)
    reps = [5,5,3]
    return make_sets(percentages, weights, reps)
end

function main_sets_531(training_max, week)
    if week == 1
        percentages = [65, 75, 85]
        reps = [5,5,5]
    elseif week == 2
        percentages = [70, 80, 90]
        reps = [3,3,3]
    elseif week == 3
        percentages = [75, 85, 95]
        reps = [5,3,1]
    else
        throw(DomainError("Argument `week` must be 1, 2, or 3."))
    end
    
    weights = make_weights(percentages, weights)
    return make_sets(percentages, weights, reps)
end
    

round_to_half_pound(x) = round(x * 2, RoundNearest) / 2

end
