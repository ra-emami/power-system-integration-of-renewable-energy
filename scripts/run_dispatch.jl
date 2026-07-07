#!/usr/bin/env julia
#
# Reproduces the main result of the report: the cost-optimal 24-hour dispatch
# of wind, solar, and battery storage for the New York City case study.
#
# Usage:  julia --project scripts/run_dispatch.jl

using Random
using Printf
using Plots

include(joinpath(@__DIR__, "..", "src", "data_loading.jl"))
include(joinpath(@__DIR__, "..", "src", "wind_forecast.jl"))
include(joinpath(@__DIR__, "..", "src", "dispatch_model.jl"))

const FIGURES_DIR = joinpath(dirname(@__DIR__), "figures")

Random.seed!(2023)  # fixed seed for a reproducible Monte-Carlo forecast

demand = load_demand()
solar_availability = load_solar_availability()
wind_history = load_wind_history()
hours = 1:length(demand)

# --- Probabilistic wind forecast (Monte-Carlo bootstrap over historical days)
forecast = forecast_wind(wind_history)
wind_availability = forecast.mean ./ 100

plt = plot(hours, forecast.mean;
    ribbon = 1.5 .* forecast.std,
    fillalpha = 0.2, color = :steelblue, linewidth = 2,
    marker = :circle, markersize = 3,
    label = "Mean forecast (band: ±1.5 std)",
    xlabel = "Hour of the day", ylabel = "Wind availability (% of capacity)",
    xticks = [1, 4, 8, 12, 16, 20, 24], ylims = (0, 100), legend = :top)
savefig(plt, joinpath(FIGURES_DIR, "wind_forecast.png"))

# --- Solve the dispatch LP
params = DispatchParameters()
result = solve_dispatch(demand, wind_availability, solar_availability, params)

show(stdout, result.dispatch; allrows = true, allcols = true)
@printf "\n\nOptimal cost of energy production: \$%.2f\n" result.cost
@printf "Peak state of charge: %.1f MWh (capacity %.0f MWh)\n" maximum(
    result.dispatch.stored_energy_MWh) params.storage_capacity

# --- Dispatch figure: power balance (top) and storage state of charge (bottom)
p1 = plot(hours, demand; color = :black, linewidth = 2.5, label = "Demand",
    ylabel = "Power (MW)", legend = :topleft)
plot!(p1, hours, result.dispatch.wind_MW; color = :steelblue, linewidth = 2,
    label = "Wind")
plot!(p1, hours, result.dispatch.solar_MW; color = :orange, linewidth = 2,
    label = "Solar")
plot!(p1, hours, result.dispatch.storage_MW; color = :orangered, linewidth = 2,
    label = "Storage (+ discharge / - charge)")
hline!(p1, [0]; color = :gray, linewidth = 0.8, label = false)

p2 = plot(hours, result.dispatch.stored_energy_MWh; color = :seagreen,
    linewidth = 2, fill = (0, 0.25, :seagreen), label = false,
    xlabel = "Hour of the day", ylabel = "Stored energy (MWh)",
    xticks = [1, 4, 8, 12, 16, 20, 24])
hline!(p2, [params.storage_capacity]; color = :gray, linestyle = :dash,
    label = false)

plt = plot(p1, p2; layout = (2, 1), size = (760, 640), link = :x)
savefig(plt, joinpath(FIGURES_DIR, "dispatch_solution.png"))

println("Figures written to ", FIGURES_DIR)
