# Cost-minimizing dispatch of wind, solar, and battery storage as a linear program.

using JuMP
using HiGHS
using DataFrames

"""
    DispatchParameters(; kwargs...)

Techno-economic parameters of the case study (Table 1 of the report).
Powers are in MW, energies in MWh, and costs in USD.
"""
Base.@kwdef struct DispatchParameters
    wind_capacity::Float64          = 95.0  # installed wind capacity (MW)
    solar_capacity::Float64         = 85.0  # installed solar capacity (MW)
    wind_cost_coeff::Float64        = 20.0  # wind cost coefficient C0_W ($/MWh)
    solar_cost_coeff::Float64       = 25.0  # solar cost coefficient C0_S ($/MWh)
    storage_capacity::Float64       = 55.0  # storage energy capacity Qmax (MWh)
    storage_min_energy::Float64     = 1.0   # minimum state of charge Qmin (MWh)
    storage_initial_energy::Float64 = 1.0   # initial state of charge Q0 (MWh)
    discharge_max_power::Float64    = 16.0  # maximum discharging power (MW)
    charge_max_power::Float64       = 10.0  # maximum charging power (MW)
    degradation_penalty::Float64    = 10.0  # battery degradation penalty ($/MWh discharged)
end

"""
    build_dispatch_model(demand, wind_availability, solar_availability,
                         params=DispatchParameters(); optimizer=HiGHS.Optimizer)

Build the 24-hour dispatch LP. Availabilities are fractions of installed
capacity in [0, 1]. Generation costs rise when availability is scarce,
``C_h = C_0 \\, 2 / (1 + A_h)``, and battery discharging carries a fixed
degradation penalty. Returns the unsolved JuMP model.
"""
function build_dispatch_model(demand::AbstractVector{<:Real},
                              wind_availability::AbstractVector{<:Real},
                              solar_availability::AbstractVector{<:Real},
                              params::DispatchParameters = DispatchParameters();
                              optimizer = HiGHS.Optimizer)
    horizon = length(demand)

    # Availability-dependent generation costs (eq. 9 of the report)
    wind_cost  = params.wind_cost_coeff  .* 2 ./ (wind_availability .+ 1)
    solar_cost = params.solar_cost_coeff .* 2 ./ (solar_availability .+ 1)

    model = Model(optimizer)
    set_silent(model)

    @variable(model, 0 <= wind_power[h = 1:horizon] <= wind_availability[h] * params.wind_capacity)
    @variable(model, 0 <= solar_power[h = 1:horizon] <= solar_availability[h] * params.solar_capacity)
    @variable(model, 0 <= discharge_power[1:horizon] <= params.discharge_max_power)
    @variable(model, 0 <= charge_power[1:horizon] <= params.charge_max_power)

    # State of charge implied by the charge/discharge schedule
    @expression(model, stored_energy[h = 1:horizon],
        params.storage_initial_energy +
        sum(charge_power[j] - discharge_power[j] for j in 1:h))

    # Hourly power balance
    @constraint(model, balance[h = 1:horizon],
        wind_power[h] + solar_power[h] + discharge_power[h] - charge_power[h] == demand[h])

    # Storage energy limits
    @constraint(model, soc_limits[h = 1:horizon],
        params.storage_min_energy <= stored_energy[h] <= params.storage_capacity)

    @objective(model, Min,
        sum(wind_cost[h] * wind_power[h] + solar_cost[h] * solar_power[h] +
            params.degradation_penalty * discharge_power[h] for h in 1:horizon))

    return model
end

"""
    solve_dispatch(demand, wind_availability, solar_availability,
                   params=DispatchParameters(); optimizer=HiGHS.Optimizer)
        -> (cost, dispatch::DataFrame, model)

Solve the dispatch LP and return the optimal cost, the hourly dispatch
schedule, and the solved JuMP model. Errors if no optimal solution is found.
"""
function solve_dispatch(demand::AbstractVector{<:Real},
                        wind_availability::AbstractVector{<:Real},
                        solar_availability::AbstractVector{<:Real},
                        params::DispatchParameters = DispatchParameters();
                        optimizer = HiGHS.Optimizer)
    model = build_dispatch_model(demand, wind_availability, solar_availability,
                                 params; optimizer = optimizer)
    optimize!(model)
    status = termination_status(model)
    status == MOI.OPTIMAL || error("optimization terminated with status $status")

    discharge = value.(model[:discharge_power])
    charge = value.(model[:charge_power])
    dispatch = DataFrame(
        hour = 1:length(demand),
        demand_MW = Float64.(demand),
        wind_MW = round.(value.(model[:wind_power]); digits = 2),
        solar_MW = round.(value.(model[:solar_power]); digits = 2),
        storage_MW = round.(discharge .- charge; digits = 2),
        stored_energy_MWh = round.(value.(model[:stored_energy]); digits = 2),
    )
    return (cost = objective_value(model), dispatch = dispatch, model = model)
end
