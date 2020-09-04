import os


door_styles = 6
lengths = [True, False]

for length in lengths:
    for door in range(door_styles):
        name = "gen{}ft_style{}".format("20" if length else "40", door)
        os.system("openscad -o {}.stl -D twentyFooter=\"{}\" -D DOOR_STYLE={} parametric_container.scad".format(name,"true" if length else "false",door))