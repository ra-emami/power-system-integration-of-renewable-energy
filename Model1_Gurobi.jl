using JuMP
using Gurobi
using Plots

num_days = 30
num_hours = 24

historical_data = "62127	66016	65632	65090	62331	60801	58300	56027	54066	51199	44019	35964	34252	32703	29916	30024	31842	34512	36961	36635	37026	40489	50063	58810	65634	66750	65767	64154	61168	59043	55811	52791	50245	46544	39484	31247	29308	27666	24798	25369	30304	34399	35542	36811	37992	41761	49520	59079	62047	67191	69418	69656	67082	64644	62297	59230	57488	54291	48529	37558	36113	36227	34726	35182	38003	41590	43972	45279	48207	56879	68720	76723	81378	83008	82216	80018	79179	77631	75547	73683	71870	68601	63871	61255	60173	59945	62144	65788	69314	70744	70261	69503	69485	70907	77082	82905	86187	86217	83722	81106	77400	73205	68699	65727	65479	65328	63550	65358	65164	60842	53707	47414	44418	43066	42059	43074	46426	48903	53622	59025	63665	62458	60851	57170	54853	52310	51524	49734	48557	45368	41075	40330	37592	34242	33226	32428	31170	30598	29932	29949	28045	27504	32509	38937	44259	44380	44380	44129	45222	45547	43622	41963	40814	39640	34910	28936	28871	27655	26462	26159	26390	26612	25795	25423	27320	31191	36088	42268	48259	46122	47387	47262	47259	45113	42053	39469	37788	34676	29299	22669	20782	19670	20094	19751	19536	20458	21338	22581	24619	28144	34983	42485	46052	48733	48759	46794	41657	37229	33377	30682	26400	23681	18970	12955	11647	10798	11104	11233	12216	13850	16096	19292	24045	28267	34391	40875	44206	45446	45834	42846	37840	34262	33249	31933	31906	29757	25651	22892	22252	21977	21591	20074	20281	20659	21610	23127	26686	30085	34887	39531	41736	40526	39230	37266	34412	30382	27617	24915	24939	23969	22593	20655	19898	20593	22965	24057	23870	24254	26796	29373	33289	36208	39367	42011	41117	39835	37249	35148	33012	30686	27192	25895	24955	24572	22699	20517	19459	19079	18855	18480	18324	19083	19880	20866	21659	23311	26830	29547	29946	30033	28466	27774	27362	25791	24614	23304	22773	22521	20060	15977	15600	17031	17903	18072	18202	19290	21466	22561	24059	26566	30666	35779	38798	38093	36881	34890	33828	31263	29744	28139	26754	26851	23727	19145	17646	19331	20894	21772	22384	22767	23864	24968	26395	28381	32131	36307	37870	38410	36279	33455	31767	30700	29955	29541	27202	24009	19278	14613	12949	11956	10916	11245	12261	12589	13215	13772	15419	15473	17833	20793	23416	23436	22251	20214	19458	19055	18473	18700	20216	19849	17577	14086	11452	10888	10948	10229	10887	12946	13937	15208	15600	16832	19241	21782	23105	23056	23312	23502	22513	22526	22688	22006	21924	21697	19481	15012	13235	14544	15386	15577	15742	15569	16113	16744	17575	19772	25156	31183	35314	39103	43233	45224	45849	46733	46919	48509	49497	50808	49493	42498	44419	48577	49238	48082	47215	47758	47746	47082	45043	46081	53672	60480	63796	67412	67228	66237	63881	62086	60880	60121	59501	56217	50108	44922	44232	44677	44141	43198	44303	46871	47185	46350	48520	50648	55886	60782	60446	63929	63300	61956	58850	55516	52962	50991	50097	45142	38306	30033	26820	23110	19889	18705	19515	20025	21999	24883	28464	32752	41786	48444	57831	57936	58388	56760	54032	50220	46665	43460	42129	40972	36774	32780	33581	35984	37808	38594	37326	38831	41534	45204	46814	46824	51102	55186	54810	55684	55454	55155	55207	53134	51038	49531	48689	47304	44659	41815	41303	38253	36300	34951	34178	35078	35251	37219	38814	41548	48164	54577	56131	58906	57751	57014	55407	53500	52571	51297	51223	49962	46157	43960	41862	39879	39694	39380	39155	39153	39565	40234	41287	43482	48278	51536	51015	52637	52396	50719	48201	46234	43351	40836	38164	34654	29563	24864	23120	21547	21853	22237	22958	23092	23427	22694	22770	24871	29506	32629	38772	34298	31794	29040	26637	24430	22121	20774	18951	17392	15006	12490	11889	13191	14691	16877	18387	19542	19982	19798	20486	22053	25791	30463	31832	36029	37828	37194	35531	32849	31384	30165	27931	25226	22293	16923	16733	17152	16792	16515	17120	18223	20106	22353	26067	32171	39448	42896	44144	43520	42574	42812	41415	39493	37621	35121	33831	33322	30536	23496	22820	22317	20035	18583	19723	22479	26205	29402	33437	39960	48745	55342	59775	58584	56859	55621	54491	53297	51063	48249	46957	45136	41709	33201	33440	37366	40645	42438	44793	48054	50456	53638	54185	57273	64325	69130	69799	68372	66412	64483	62721	60806	59730	59229	58987	58200	54834	50846	47712	44817	43336	45784	48354	50125	53040	55760	58926	61677	66543	70171	69497	67392	64781	59728	57015	55263	53864	52751	52242	51876	47997	44663	46389	47643	47308	48879	53886	58125	61742	63440	63738	64523	67240	68968"
historical_data = parse.(Float64, split(historical_data, "\t"))
historical_data = reshape(historical_data, num_days, num_hours) # Historical wind power data (MWh) for 30 days from: www.eia.gov
historical_data = 100*historical_data/maximum(historical_data) # Historical wind power data (%) for 30 days

# Simulate wind power for the current day using Monte Carlo
num_simulations = 1000
simulated_data = zeros(num_simulations, num_hours)
for i in 1:num_simulations
    random_day = rand(1:num_days)
    simulated_data[i, :] = historical_data[random_day, :]
end


mean_hourly_power = mean(simulated_data, dims=1)[:]
std_hourly_power = std(simulated_data, dims=1)[:]


# Plot the mean wind power with uncertainty
hours = 1:num_hours
plt = plot(hours, mean_hourly_power, ribbon=(mean_hourly_power .- 1.5 .* std_hourly_power, mean_hourly_power .+ 1.5 .* std_hourly_power), label="Mean Wind Power with Uncertainty", color=:blue, xlabel="Hour of the Day", ylabel="Wind Power (%)", title="Probabilistic Forecasting of Wind Power for a Day")
display(plt)

# Solar availability
Solar_availability = "0	0	0	0	0	0	16	38	63	82	96	100	96	82	63	38	16	0	0	0	0	0	0	0"
Solar_availability = parse.(Float64, split(Solar_availability, "\t")) ./ 100 # Hourly Solar radiation percentage (%)

plt = plot(hours, 100 .* Solar_availability, label=false, color=:blue, xlabel="Hour of the Day", ylabel="Solar Radiation (%)", title="Solar Radiation (%)")
display(plt)
#==============================================================================================================#
println("______________________________________ Gurobi Optimizer _________________________________________")

# Create a new model
model = Model(Gurobi.Optimizer)

# Set NonConvex parameter to 2 to handle non-convex problems
set_optimizer_attribute(model, "NonConvex", 2)
#==============================================================================================================#

# Define the initial values
num_hours = 24
hours = 1:num_hours
power_demand = [14 14 14 14 14 17 31 74 90 92 95 100 80 68 89 90 81 56 43 39 39 38 26 18] # Power demand in 24 hours (MW)
#Solar_availability = [0 0 0 0 0 0 16 38 63 82 96 100 96 82 63 38 16 0 0 0 0 0 0 0]/100 # Hourly Solar radiation percentage (%)
wind_availability = mean_hourly_power/100 # Wind power availability (%) - Simulate using Monte Carlo method based on Historical wind power data for 30 days from: www.eia.gov
wind_cost = 20 .*( 2 ./ (wind_availability .+ 1 )) # Wind power cost ($/MW)
solar_cost = 25 .*( 2 ./ (Solar_availability .+ 1 )) # Solar power cost ($/MW)

stored_energy_initial = 1 # initial stored energy (MWh)
min_storage = 1
max_storage = 55 # Storage capacity (MWh)
stored_max_power = 16 # (MW)
charging_max_power = 10 # (MW)
deg_penalty = 10 # Battery Degradation penalty ($/MWh)

wind_capacity = 95 # Max Wind power (MW)
solar_capacity = 85 # Max Solar power (MW)
#==============================================================================================================#

# Decision Variables
@variable(model, 0 <= wind_power[1:num_hours] <= wind_capacity) # Wind power integrated (MW)
@variable(model, 0 <= solar_power[1:num_hours] <= solar_capacity) # Solar power integrated (MW)
@variable(model, 0 <= stored_power_decharge[1:num_hours] <= stored_max_power) # stored decharging power (MW)
@variable(model, 0 <= stored_power_charge[1:num_hours] <= charging_max_power) # stored charging power (MW)
#==============================================================================================================#

# Objective: Minimize cost with the piecewise linear approximation
@objective(model, Min, sum(wind_cost[i] * wind_power[i] + solar_cost[i] * solar_power[i] + deg_penalty * stored_power_decharge[i]  for i in 1:24))

# Constraints
for i in 1:num_hours
    @constraint(model, wind_power[i] <= wind_availability[i]*wind_capacity)
    @constraint(model, solar_power[i] <= Solar_availability[i]*solar_capacity)
    @constraint(model, wind_power[i] + solar_power[i] + stored_power_decharge[i] == power_demand[i] + stored_power_charge[i])
    @constraint(model, min_storage <= stored_energy_initial - sum(stored_power_decharge[j] for j in 1:i) + sum(stored_power_charge[j] for j in 1:i) <= max_storage)
end

# Solve the problem
optimize!(model)

stored_power = stored_power_decharge .- stored_power_charge

stored_energy = zeros(1,num_hours)
for i in 1:num_hours
    stored_energy[i] = stored_energy_initial - sum(value.(stored_power_decharge[j]) for j in 1:i) + sum(value.(stored_power_charge[j]) for j in 1:i)
end
#==============================================================================================================#

# Print and Save the results
using DataFrames

df = DataFrame(Hour = hours,
    Power_Demand_MW = vec(power_demand),
    Wind_Power_MW = round.(value.(wind_power), digits=1),
    Solar_Power_MW = round.(value.(solar_power), digits=1),
    Stored_Power_MW = round.(value.(stored_power), digits=1),
    Stored_Energy_MWh = vec(round.(stored_energy, digits=1))
    )
print(df,"\n\n")

println("Optimal cost of energy production (\$): ", round(objective_value(model)))


# Plot the results

plt = plot()
plot!(hours, vec(power_demand), w=2, label="Power Demand", color=:black, xlabel="Hour of the Day", ylabel="Power (MW)", title="Integration of Renewable Energy", ylimits=(0,100))
plot!(hours, value.(wind_power), w=2, label="Wind Power")
plot!(hours, value.(solar_power), w=2, label="Solar Power")
plot!(hours, value.(stored_power), w=2, label="Stored Power")
plot!(hours, -value.(stored_power), w=2, label="Storage Charging", color=:yellow)
bar!(twinx(),hours,vec(stored_energy), fill = 0, alpha = 0.3, label="Stored Energy", ylabel="Stored Energy (MWh)", legend=:topleft)

display(plt)