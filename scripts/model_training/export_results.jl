using AutomotiveDrivingModels

using RandomForestBehaviors
using DynamicBayesianNetworkBehaviors

push!(LOAD_PATH, "/home/tim/Documents/wheelerworkspace/UtilityCode/")
using LaTeXeXport

const TEXFILE = "/home/tim/Documents/wheelerworkspace/Papers/2015_ITS_RiskEstimation/2015_IEEE_ITS_riskest.tex"
const TEXDIR = splitdir(TEXFILE)[1]

const INCLUDE_FILE_BASE = "realworld"

const SAVE_FILE_MODIFIER = ""
const EVALUATION_DIR = "/media/tim/DATAPART1/PublicationData/2015_TrafficEvolutionModels/" * INCLUDE_FILE_BASE* "/"
const METRICS_OUTPUT_FILE = joinpath(EVALUATION_DIR, "validation_results" * SAVE_FILE_MODIFIER * ".jld")
const MODEL_OUTPUT_JLD_FILE = joinpath(EVALUATION_DIR, "validation_models" * SAVE_FILE_MODIFIER * ".jld")

function _grab_metric{B<:BehaviorMetric}(T::DataType, metrics::Vector{B})
    j = findfirst(m->isa(m, T), metrics)
    metrics[j]
end
function _grab_metric{B<:BaggedMetricResult}(T::DataType, metrics::Vector{B})
    j = findfirst(res->res.M == T, metrics)
    metrics[j]
end
function _grab_score{B<:BehaviorMetric}(T::DataType, metrics::Vector{B})
    j = findfirst(m->isa(m, T), metrics)
    get_score(metrics[j])
end
function _grab_confidence(T::DataType, metrics::Vector{BaggedMetricResult})
    j = findfirst(m-> m.M <: T, metrics)
    confidence = metrics[j].confidence_bound
    if isnan(confidence)
        confidence = 0.0
    end
    confidence
end
function _grab_score_and_confidence{B<:BehaviorMetric}(
    T::DataType,
    metrics::Vector{B},
    metrics_bagged::Vector{BaggedMetricResult},
    )

    μ = _grab_score(T, metrics)
    Δ = _grab_confidence(T, metrics_bagged)

    (μ, Δ)
end
function create_tikzpicture_model_compare_logl_test{S<:String}(io::IO,
    metrics_sets_test::Vector{Vector{BehaviorFrameMetric}},
    metrics_sets_test_frames_bagged::Vector{Vector{BaggedMetricResult}},
    names::Vector{S},
    )

    #=
    For each model, add these options:
    (produces 95% confidence bounds)

    \addplot+[thick, mark=*, mark options={colorA}, error bars/error bar style={colorA}, error bars/.cd,x dir=both,x explicit]
    coordinates{(1.000,Gaussian Filter)+=(0.664,0)-=(0.664,0)};
    \addplot+[thick, mark=*, mark options={colorB}, error bars/error bar style={colorB}, error bars/.cd,x dir=both,x explicit]
    coordinates{(1.400,Single Variable)+=(0.664,0)-=(0.164,0)};
    \addplot+[thick, mark=*, mark options={colorC}, error bars/error bar style={colorC}, error bars/.cd,x dir=both,x explicit]
    coordinates{(1.400,Random Forest)+=(0.664,0)-=(0.264,0)};
    \addplot+[thick, mark=*, mark options={colorD}, error bars/error bar style={colorD}, error bars/.cd,x dir=both,x explicit]
    coordinates{(1.400,Dynamic Forest)+=(0.664,0)-=(0.364,0)};
    \addplot+[thick, mark=*, mark options={colorE}, error bars/error bar style={colorE}, error bars/.cd,x dir=both,x explicit]
    coordinates{(1.400,Bayesian Network)+=(0.664,0)-=(0.664,0)};
    =#

    for (i,name) in enumerate(names)

        μ, Δ = _grab_score_and_confidence(LoglikelihoodMetric, metrics_sets_test[i],
                                          metrics_sets_test_frames_bagged[i])

        color_letter = string('A' + i - 1)

        println(io, "\\addplot+[thick, mark=*, mark options={thick, color", color_letter, "}, error bars/error bar style={color", color_letter, "}, error bars/.cd,x dir=both,x explicit]")
        @printf(io, "\tcoordinates{(%.4f,%s)+=(%.3f,0)-=(%.3f,0)};\n", μ, name, Δ, Δ)
    end
end
function create_tikzpicture_model_compare_logl_train{S<:String}(io::IO,
    metrics_sets_cv::CrossValidationResults,
    names::Vector{S},
    )

    #=
    For each model, add these options:
    (produces 95% confidence bounds)

    \addplot+[thick, mark=*, mark options={colorA}, error bars/error bar style={colorA}, error bars/.cd,x dir=both,x explicit]
    coordinates{(1.000,Gaussian Filter)+=(0.664,0)-=(0.664,0)};
    \addplot+[thick, mark=*, mark options={colorB}, error bars/error bar style={colorB}, error bars/.cd,x dir=both,x explicit]
    coordinates{(1.400,Single Variable)+=(0.664,0)-=(0.164,0)};
    \addplot+[thick, mark=*, mark options={colorC}, error bars/error bar style={colorC}, error bars/.cd,x dir=both,x explicit]
    coordinates{(1.400,Random Forest)+=(0.664,0)-=(0.264,0)};
    \addplot+[thick, mark=*, mark options={colorD}, error bars/error bar style={colorD}, error bars/.cd,x dir=both,x explicit]
    coordinates{(1.400,Dynamic Forest)+=(0.664,0)-=(0.364,0)};
    \addplot+[thick, mark=*, mark options={colorE}, error bars/error bar style={colorE}, error bars/.cd,x dir=both,x explicit]
    coordinates{(1.400,Bayesian Network)+=(0.664,0)-=(0.664,0)};
    =#

    for (i,name) in enumerate(names)

        model_cv_res = metrics_sets_cv.models[i]

        likelihood_μ = 0.0
        likelihood_lo = Inf
        likelihood_hi = -Inf
        for cvfold_res in model_cv_res.results
            metrics = cvfold_res.metrics_test_frames
            j = findfirst(m->isa(m, LoglikelihoodMetric), metrics)
            logl = metrics[j].logl
            likelihood_μ += logl
            likelihood_lo = min(likelihood_lo, logl)
            likelihood_hi = max(likelihood_hi, logl)
        end
        likelihood_μ /= length(model_cv_res.results)

        color_letter = string('A' + i - 1)

        println(io, "\\addplot+[thick, mark=*, mark options={thick, color", color_letter, "}, error bars/error bar style={color", color_letter, "}, error bars/.cd,x dir=both,x explicit]")
        @printf(io, "\tcoordinates{(%.4f,%s)+=(%.3f,0)-=(%.3f,0)};\n", likelihood_μ, name, likelihood_hi-likelihood_μ, likelihood_μ-likelihood_lo)
    end
end
function create_tikzpicture_model_compare_kldiv_barplot{S<:String}(io::IO,
    metrics_sets_test_traces::Vector{Vector{BehaviorTraceMetric}},
    metrics_sets_test_traces_bagged::Vector{Vector{BaggedMetricResult}},
    names::Vector{S}
    )
    #=
    The first model is used as the baseline

    This outputs, for each model by order of names:

    \addplot [colorA,fill=colorA!60,error bars/.cd,y dir=both,y explicit]
            coordinates{
            (speed,     0.005)+-(0,0.002)
            (timegap,   0.005)+-(0,0.002)
            (laneoffset,0.010)+-(0,0.002)
        };
    =#

    for i in 1 : length(names)

        speed_μ, speed_Δ = μ, Δ = _grab_score_and_confidence(EmergentKLDivMetric{symbol(SPEED)}, metrics_sets_test_traces[i+1],
                                                            metrics_sets_test_traces_bagged[i])
        timegap_μ, timegap_Δ = μ, Δ = _grab_score_and_confidence(EmergentKLDivMetric{symbol(TIMEGAP_X_FRONT)}, metrics_sets_test_traces[i+1],
                                                            metrics_sets_test_traces_bagged[i])
        offset_μ, offset_Δ = μ, Δ = _grab_score_and_confidence(EmergentKLDivMetric{symbol(D_CL)}, metrics_sets_test_traces[i+1],
                                                            metrics_sets_test_traces_bagged[i])

        color = "color" * string('A' + i - 1)
        print(io, "\\addplot [", color, ",fill=", color, "!60,error bars/.cd,y dir=both,y explicit]\n\t\tcoordinates{\n")
        @printf(io, "\t\t\(%-15s%.4f)+=(0,%.4f)-=(0,%.4f)\n", "speed,",      speed_μ,   speed_Δ, speed_Δ)
        @printf(io, "\t\t\(%-15s%.4f)+=(0,%.4f)-=(0,%.4f)\n", "timegap,",    timegap_μ, timegap_Δ, timegap_Δ)
        @printf(io, "\t\t\(%-15s%.4f)+=(0,%.4f)-=(0,%.4f)\n", "laneoffset,", offset_μ,  offset_Δ, offset_Δ)
        @printf(io, "\t};\n")
    end

    print(io, "\\legend{")
    for (i,name) in enumerate(names)
        print(io, name)
        if i != length(names)
            print(io, ", ")
        end
    end
    print(io, "}\n")
end
function create_tikzpicture_model_compare_rwse_mean{S<:String}(io::IO, metrics_sets::Vector{Vector{BehaviorTraceMetric}}, names::Vector{S})

    #=
    This outputs, for each model by order of names:

    \addplot[colorA, solid, thick, mark=none] coordinates{
      (0,0.0) (1,0.0042) (2,0.0180) (3,0.0376) (4,0.0610)};
    \addplot[colorB, dashdotted, thick, mark=none] coordinates{
      (0,0.0) (1,0.0032) (2,0.0133) (3,0.0257) (4,0.0396)};
    \addplot[colorC, dashed, thick, mark=none] coordinates{
      (0,0.0) (1,0.0024) (2,0.0107) (3,0.0235) (4,0.0408)};
    \addplot[colorD, densely dotted, thick, mark=none] coordinates{
      (0,0.0) (1,0.0011) (2,0.0047) (3,0.0105) (4,0.0180)};
    \addplot[colorE, dotted, thick, mark=none] coordinates{
      (0,0.0) (1,0.0015) (2,0.0057) (3,0.0125) (4,0.0380)};

    And for the legend:

    \legend{Gaussian Filter, Random Forest, Dynamic Forest, Bayesian Network}
    =#

    nmodels = length(names)

    dash_types = ["solid", "dashdotted", "dashed", "densely dotted", "dotted"]

    for (i, metrics_set) in enumerate(metrics_sets[2:end])

        color = "color" * string('A' + i - 1)

        @printf(io, "\\addplot[%s, %s, thick, mark=none] coordinates{\n", color, dash_types[i])
        @printf(io, "\t(0,0.0) ")
        for horizon in [1.0,2.0,3.0,4.0]
            rwse = get_score(_grab_metric(RootWeightedSquareError{symbol(SPEED), horizon}, metrics_sets[i+1]))
            @printf(io, "(%.3f,%.4f) ", horizon, rwse)
        end
        @printf(io, "};\n")
    end
end
function create_tikzpicture_model_compare_rwse_variance{S<:String}(io::IO, metrics_sets::Vector{Vector{BaggedMetricResult}}, names::Vector{S})

    #=
    The first model is used as the baseline

    This outputs, for each model by order of names:

    \addplot[colorA, solid, thick, mark=none] coordinates{
      (0,0.0) (1,0.0042) (2,0.0180) (3,0.0376) (4,0.0610)};
    \addplot[colorB, dashdotted, thick, mark=none] coordinates{
      (0,0.0) (1,0.0032) (2,0.0133) (3,0.0257) (4,0.0396)};
    \addplot[colorC, dashed, thick, mark=none] coordinates{
      (0,0.0) (1,0.0024) (2,0.0107) (3,0.0235) (4,0.0408)};
    \addplot[colorD, densely dotted, thick, mark=none] coordinates{
      (0,0.0) (1,0.0011) (2,0.0047) (3,0.0105) (4,0.0180)};
    \addplot[colorE, dotted, thick, mark=none] coordinates{
      (0,0.0) (1,0.0015) (2,0.0057) (3,0.0125) (4,0.0380)};

    And for the legend:

    \legend{Gaussian Filter, Random Forest, Dynamic Forest, Bayesian Network}
    =#

    nmodels = length(names)

    dash_types = ["solid", "dashdotted", "dashed", "densely dotted", "dotted"]

    for (i,metrics_set) in enumerate(metrics_sets)

        color = "color" * string('A' + i - 1)

        @printf(io, "\\addplot[%s, %s, thick, mark=none] coordinates{\n", color, dash_types[i])
        @printf(io, "\t(0,0.0) ")
        for horizon in [1.0,2.0,3.0,4.0]
            σ = _grab_metric(RootWeightedSquareError{symbol(SPEED), horizon}, metrics_sets[i]).σ
            @printf(io, "(%.3f,%.4f) ", horizon, σ)
        end
        @printf(io, "};\n")
    end

    print(io, "\\legend{")
    for (i,name) in enumerate(names)
        print(io, name)
        if i != length(names)
            print(io, ", ")
        end
    end
    print(io, "}\n")
end

behaviorset = JLD.load(MODEL_OUTPUT_JLD_FILE, "behaviorset")

metrics_sets_test_frames = JLD.load(METRICS_OUTPUT_FILE, "metrics_sets_test_frames")
metrics_sets_test_traces = JLD.load(METRICS_OUTPUT_FILE, "metrics_sets_test_traces")
metrics_sets_test_frames_bagged = JLD.load(METRICS_OUTPUT_FILE, "metrics_sets_test_frames_bagged")
metrics_sets_test_traces_bagged = JLD.load(METRICS_OUTPUT_FILE, "metrics_sets_test_traces_bagged")
metrics_sets_cv = JLD.load(METRICS_OUTPUT_FILE, "metrics_sets_cv")

# all_names = String["Real World"]
# append!(all_names, behaviorset.names)

# println("TEST")
write_to_texthook(TEXFILE, "model-compare-logl-testing") do fh
    create_tikzpicture_model_compare_logl_test(fh, metrics_sets_test_frames,
                                               metrics_sets_test_frames_bagged, behaviorset.names)
end

# println("\nTRAIN")
write_to_texthook(TEXFILE, "model-compare-logl-training") do fh
    create_tikzpicture_model_compare_logl_train(fh, metrics_sets_cv, behaviorset.names)
end

write_to_texthook(TEXFILE, "model-compare-kldiv-testing") do fh
    create_tikzpicture_model_compare_kldiv_barplot(fh, metrics_sets_test_traces,
                                                   metrics_sets_test_traces_bagged, behaviorset.names)
end

write_to_texthook(TEXFILE, "model-compare-rmse-mean") do fh
    create_tikzpicture_model_compare_rwse_mean(fh, metrics_sets_test_traces, behaviorset.names)
end

write_to_texthook(TEXFILE, "model-compare-rmse-stdev") do fh
    create_tikzpicture_model_compare_rwse_variance(fh, metrics_sets_test_traces_bagged, behaviorset.names)
end
