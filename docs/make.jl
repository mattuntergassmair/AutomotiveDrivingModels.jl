using Documenter, AutomotiveDrivingModels

include("src/logo/ADMlogo_v3.jl")
mkpath("src/assets")
write("src/assets/logo.svg", snapshot)

makedocs(
	 modules = [AutomotiveDrivingModels],
	 format = Documenter.HTML(),
	 sitename="AutomotiveDrivingModels.jl"
	 )

deploydocs(
    repo = "github.com/sisl/AutomotiveDrivingModels.jl.git",
)
