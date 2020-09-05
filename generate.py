import os
from multiprocessing import Pool
import multiprocessing
from pathlib import Path


Path("out").mkdir(parents=True, exist_ok=True)

door_styles = 8
lengths = [True, False]
highcubes = [True, False]

def genContainer(tup):
    style, twentyfooter, highcube = tup

    name = "out/gen{}ft_style{}{}".format("20" if twentyfooter else "40", style, "highcube" if highcube else "")
    print(name)
    os.system("openscad -o {}.stl -D twentyFooter=\"{}\" -D DOOR_STYLE={} -D highcube=\"{}\" parametric_container.scad"
              .format(name, "true" if twentyfooter else "false", style, "true" if highcube else "false"))

jobs = []
for length in lengths:
    for door in range(door_styles):
        for highcube in highcubes:
            jobs.append([door, length, highcube])

if __name__ == '__main__':
    p = Pool(multiprocessing.cpu_count())
    p.map(genContainer, jobs)