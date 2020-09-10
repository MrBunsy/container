import os
from multiprocessing import Pool
import multiprocessing
from pathlib import Path


Path("out").mkdir(parents=True, exist_ok=True)

door_styles = 8
lengths = [True, False]
highcubes = [True, False]
coins = ["penny","tuppence","none"]

def genContainer(tup):
    style, twentyfooter, highcube, coin = tup

    name = "out/gen{}ft_style{}{}{}".format("20" if twentyfooter else "40", style, "highcube" if highcube else "", coin)
    print(name)
    os.system("openscad -o {}.stl -D twentyFooter=\"{}\" -D DOOR_STYLE={} -D highcube=\"{}\" -D COIN_HOLDER=\"\\\"{}\\\"\" parametric_container.scad"
              .format(name, "true" if twentyfooter else "false", style, "true" if highcube else "false", coin))

jobs = []
for length in lengths:
    for door in range(door_styles):
        for highcube in highcubes:
            for coin in coins:
                jobs.append([door, length, highcube, coin])

if __name__ == '__main__':
    p = Pool(multiprocessing.cpu_count()-1)
    p.map(genContainer, jobs)