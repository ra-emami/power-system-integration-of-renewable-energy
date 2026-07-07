# Loaders for the packaged case-study data (New York City, September).

using CSV
using DataFrames

const DATA_DIR = joinpath(dirname(@__DIR__), "data")

"""
    load_demand() -> Vector{Float64}

Hourly grid demand over the 24-hour horizon (MW).
"""
load_demand() = Float64.(CSV.read(joinpath(DATA_DIR, "demand_24h.csv"), DataFrame).demand_MW)

"""
    load_solar_availability() -> Vector{Float64}

Hourly solar availability as a fraction of installed capacity, derived from the
hourly distribution of solar radiation on a south-facing panel at a 40-degree
tilt angle (New York City, September).
"""
load_solar_availability() =
    Float64.(CSV.read(joinpath(DATA_DIR, "solar_availability_24h.csv"), DataFrame).availability_pct) ./ 100

"""
    load_wind_history() -> Matrix{Float64}

Historical hourly wind generation for 30 days (rows) by 24 hours (columns),
normalized to percent of the observed peak. Source: U.S. Energy Information
Administration (https://www.eia.gov).
"""
function load_wind_history()
    df = CSV.read(joinpath(DATA_DIR, "wind_history_30d.csv"), DataFrame)
    history = Matrix{Float64}(df[:, Not(:day)])
    return 100 .* history ./ maximum(history)
end
