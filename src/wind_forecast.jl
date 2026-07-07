# Probabilistic wind-power forecasting via Monte-Carlo bootstrap resampling.

using Random
using Statistics

"""
    forecast_wind(history; nsimulations=1000, rng=Random.default_rng())
        -> (mean::Vector{Float64}, std::Vector{Float64})

Probabilistic day-ahead wind forecast. Whole days (rows of `history`) are
resampled with replacement `nsimulations` times, preserving the intra-day
correlation structure of the historical record. Returns the per-hour mean and
standard deviation of the resampled profiles, in the same units as `history`
(percent of capacity).
"""
function forecast_wind(history::AbstractMatrix{<:Real};
                       nsimulations::Integer = 1000,
                       rng::Random.AbstractRNG = Random.default_rng())
    ndays = size(history, 1)
    sampled = history[rand(rng, 1:ndays, nsimulations), :]
    return (mean = vec(mean(sampled; dims = 1)), std = vec(std(sampled; dims = 1)))
end
