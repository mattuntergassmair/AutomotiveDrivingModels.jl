using AutomotiveDrivingModels
using AutoViz

AutoViz.colortheme["background"] = colorant"white" # RGBA(0.,0.,0.,0.)

# NOTE: colors as found at https://github.com/JuliaLang/julia-logo-graphics

julia_red = RGB(0.796, 0.235, 0.2)
julia_green = RGB(0.22, 0.596, 0.149)
julia_purple = RGB(0.584, 0.345, 0.698)



function append_to_curve!(target::Curve, newstuff::Curve)
    s_end = target[end].s
    for c in newstuff
        push!(target, CurvePt(c.pos, c.s+s_end, c.k, c.kd))
    end
    return target
end


roadway = Roadway()

r = 2.0 # turn radius
x = 2.0r

letter_width = 7
letter_height = 10
letter_spacing = 3
lane_width = 2.

Vec.VecSE2(vec::VecE2, x::Real=0.) = VecSE2(vec[1], vec[2], x)



#####
# A
#####
A1b = VecE2(0.0letter_width+0letter_spacing, 0.)
A1m = VecE2(0.0letter_width+0letter_spacing, .5letter_height-x)
A1x = VecE2(0.0letter_width+0letter_spacing, .7letter_height-x)
A1t = VecE2(0.0letter_width+0letter_spacing, letter_height-x)
A2b = VecE2(1.0letter_width+0letter_spacing, 0.)
A2m = VecE2(1.0letter_width+0letter_spacing, .5letter_height-x)
A2x = VecE2(1.0letter_width+0letter_spacing, .7letter_height-x)
A2t = VecE2(1.0letter_width+0letter_spacing, letter_height-x)

A12t = VecE2(0.5letter_width+0letter_spacing, letter_height)
A12m = VecE2(0.5letter_width+0letter_spacing, .5letter_height)

#####
# D
#####
D1b = VecE2(1.0letter_width+1letter_spacing, x)
D1t = VecE2(1.0letter_width+1letter_spacing, letter_height-x)
D2bl = VecE2(1.3letter_width+1letter_spacing, .5lane_width)
D2br = VecE2(1.3letter_width+1letter_spacing, .5lane_width)
D2t = VecE2(1.3letter_width+1letter_spacing, letter_height)
D3b = VecE2(2.0letter_width+1letter_spacing, .3letter_height)
D3t = VecE2(2.0letter_width+1letter_spacing, .6letter_height)

#####
# M
#####
M1b = VecE2(2.0letter_width+2letter_spacing, 0.)
M1x = VecE2(2.0letter_width+2letter_spacing, .7letter_height-x)
M1t = VecE2(2.0letter_width+2letter_spacing, letter_height-x)
M2b = VecE2(2.5letter_width+2letter_spacing, 0.)
M2t = VecE2(2.5letter_width+2letter_spacing, letter_height-x)
M3b = VecE2(3.0letter_width+2letter_spacing, 0.)
M3t = VecE2(3.0letter_width+2letter_spacing, letter_height-x)

M12 = VecE2(2.25letter_width+2letter_spacing, letter_height)
M23 = VecE2(2.75letter_width+2letter_spacing, letter_height)

####################################################################

curve = gen_straight_curve(A1b, A1x, 2)
append_to_curve!(curve, gen_bezier_curve(VecSE2(A1x,π/2), VecSE2(A12m), r, r, 100))
append_to_curve!(curve, gen_bezier_curve(VecSE2(A12m), VecSE2(A2x,-π/2), r, r, 100))
# append_to_curve!(curve, gen_straight_curve(A2m, A2b, 2))
append_to_curve!(curve, gen_bezier_curve(VecSE2(A2x, -π/2), VecSE2(D2bl), r, r, 100))
lane = Lane(LaneTag(length(roadway.segments)+1,1), curve, width=lane_width)
push!(roadway.segments, RoadSegment(lane.tag.segment, [lane]))
vs1 = VehicleState(Frenet(lane, 7.), roadway, 0.)

curve = gen_straight_curve(A1b, A1t, 2)
append_to_curve!(curve, gen_bezier_curve(VecSE2(A1t,π/2), VecSE2(A12t), r, r, 100))
append_to_curve!(curve, gen_bezier_curve(VecSE2(A12t), VecSE2(A2t,-π/2), r, r, 100))
append_to_curve!(curve, gen_straight_curve(A2t, A2x, 2))
lane = Lane(LaneTag(length(roadway.segments)+1,1), curve, width=lane_width)
push!(roadway.segments, RoadSegment(lane.tag.segment, [lane]))



curve = gen_straight_curve(D1b, D1t, 2)
append_to_curve!(curve, gen_bezier_curve(VecSE2(D1t,π/2), VecSE2(D2t), r, r, 100))
append_to_curve!(curve, gen_bezier_curve(VecSE2(D2t), VecSE2(D3t,-π/2), r, r, 100))
append_to_curve!(curve, gen_straight_curve(D3t, D3b, 2))
append_to_curve!(curve, gen_bezier_curve(VecSE2(D3b,-π/2), VecSE2(D2br,-3π), r, r, 100))
append_to_curve!(curve, gen_bezier_curve(VecSE2(D2bl,-π), VecSE2(D1b,π/2), r, r, 100))
lane = Lane(LaneTag(length(roadway.segments)+1,1), curve, width=lane_width)
push!(roadway.segments, RoadSegment(lane.tag.segment, [lane]))
vs2 = VehicleState(Frenet(lane, 10.), roadway, 0.)

curve = gen_bezier_curve(VecSE2(D3b,-π/2), VecSE2(M1x,π/2), r, r, 100)
lane = Lane(LaneTag(length(roadway.segments)+1,1), curve, width=lane_width)
push!(roadway.segments, RoadSegment(lane.tag.segment, [lane]))

curve = gen_straight_curve(M1x, M1t, 2)
append_to_curve!(curve, gen_bezier_curve(VecSE2(M1t,π/2), VecSE2(M12), r, r, 100))
append_to_curve!(curve, gen_bezier_curve(VecSE2(M12), VecSE2(M2t,-π/2), r, r, 100))
append_to_curve!(curve, gen_straight_curve(M2t, M2b, 2))
lane = Lane(LaneTag(length(roadway.segments)+1,1), curve, width=lane_width)
push!(roadway.segments, RoadSegment(lane.tag.segment, [lane]))
vs3 = VehicleState(Frenet(lane, 15.), roadway, 0.)

curve = gen_straight_curve(M2b, M2t, 2)
append_to_curve!(curve, gen_bezier_curve(VecSE2(M2t,π/2), VecSE2(M23), r, r, 100))
append_to_curve!(curve, gen_bezier_curve(VecSE2(M23), VecSE2(M3t,-π/2), r, r, 100))
append_to_curve!(curve, gen_straight_curve(M3t, M3b, 2))
lane = Lane(LaneTag(length(roadway.segments)+1,1), curve, width=lane_width)
push!(roadway.segments, RoadSegment(lane.tag.segment, [lane]))


k = 0.7

vehicle_states = [vs1, vs2, vs3]

renderables = [
    roadway,
    (
        FancyCar(
            car=Vehicle(vehicle_states[i], VehicleDef(width=2.0k, length=5.0k), i),
            color=c
        ) for (i, c) in enumerate((julia_green, julia_red, julia_purple))
    )...
]


snapshot = render(renderables, camera=StaticCamera(position=VecE2(14.,5.),zoom=24.,canvas_width=800,canvas_height=320))
