#!/usr/bin/env julia
#
# Sensitivity of the optimal cost to the storage energy capacity, and the
# minimum capacity for which the 24-hour dispatch remains feasible
# (Section 4.5 of the report).
#
# Usage:  julia --project scripts/storage_capacity_sweep.jl

using Random
using Printf
using Plots

include(joinpath(@__DIR__, "..", "src", "data_loading.jl"))
include(joinpath(@__DIR__, "..", "src", "wind_forecast.jl"))
include(joinpath(@__DIR__, "..", "src", "dispatch_model.jl"))

const FIGURES_DIR = joinpath(dirname(@__DIR__), "figures")

Random.seed!(2023)

demand = load_demand()
solar_availability = load_solar_availability()
wind_availability = forecast_wind(load_wind_history()).mean ./ 100

"Optimal daily cost for a given storage capacity, or `nothing` if infeasible."
function cost_at_capacity(capacity)
    params = DispatchParameters(storage_capacity = capacity)
    model = build_dispatch_model(demand, wind_availability, solar_availability,
                                 params)
    optimize!(model)
    return termination_status(model) == MOI.OPTIMAL ? objective_value(model) :
           nothing
end

"""
Bisect the smallest storage capacity for which the dispatch is feasible,
starting from an infeasible `lo` and a feasible `hi`.
"""
function minimum_feasible_capacity(; lo = 40.0, hi = 55.0, tol = 1e-3)
    while hi - lo > tol
        mid = (lo + hi) / 2
        if cost_at_capacity(mid) === nothing
            lo = mid
        else
            hi = mid
        end
    end
    return hi
end

min_capacity = minimum_feasible_capacity()
@printf "Minimum feasible storage capacity: %.2f MWh\n\n" min_capacity

capacities = [min_capacity; (ceil(min_capacity * 2) / 2):0.5:60.0]
costs = [cost_at_capacity(q) for q in capacities]

for (q, c) in zip(capacities, costs)
    @printf "Qmax = %5.2f MWh  ->  optimal cost \$%.2f\n" q c
end

plt = plot(capacities, costs;
    color = :steelblue, linewidth = 2, marker = :circle, markersize = 3,
    label = false, xlabel = "Storage capacity (MWh)",
    ylabel = "Optimal daily cost (\$)", xlims = (50, 60.5))
vline!(plt, [min_capacity]; color = :orangered, linestyle = :dash,
    label = "feasibility limit")
savefig(plt, joinpath(FIGURES_DIR, "storage_sweep.png"))

println("\nFigure written to ", FIGURES_DIR)
