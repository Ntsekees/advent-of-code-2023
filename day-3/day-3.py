
import sys

from dataclasses import dataclass
from functools import reduce
from itertools import takewhile
from numpy import prod as product


@dataclass
class Coord:
	x: int
	y: int

@dataclass
class PartData:
	symbol: str
	coord: Coord

@dataclass
class NumData:
	number: int
	length: int
	coord: Coord
	hosts: [PartData]

@dataclass
class GearData:
	coord: int
	numbers: [int]

def is_digit(c):
	return c in "0123456789"

def solution_of(input, mode):
	numlist = numlist_of(input.split("\n"))
	match mode:
		case 1:
			return sum(
				[nd.number for nd in numlist if nd.hosts != []])
		case 2:
			return sum(
				[product(gd.numbers) for gd in gearlist_from(numlist)])

def gearlist_from(numlist):
	l = []
	for nd in numlist:
		for host in nd.hosts:
			if host.symbol == "*":
				i = index_of_first_with_prop(
					l, lambda gd: gd.coord == host.coord)
				if i != None:
					l[i].numbers.append(nd.number)
				else:
					l.append(GearData(host.coord, [nd.number]))
	return [gd for gd in l if len(gd.numbers) == 2]

def index_of_first_with_prop(iterable, p):
	for i, e in enumerate(iterable):
		if p(e):
			return i
	return None

def numlist_of(grid):
	numlist: list(NumData) = []
	y = 0
	while y < len(grid):
		x = 0
		while x < len(grid[y]):
			c = grid[y][x]
			if c == ".":
				x += 1
			elif is_digit(c):
				ns = "".join(list(takewhile(is_digit, grid[y][x:])))
				n = int(ns)
				l = len(ns)
				numlist.append(
					find_parts_for(
						NumData(n, l, Coord(x, y), []),
						grid))
				x += l
			else:
				x += 1
		y += 1
	return numlist

def find_parts_for(numdata, grid):
	coord = numdata.coord
	start_x = coord.x - 1
	end_x = coord.x + numdata.length
	targets = [
		(coord.y,     [start_x, start_x + 1]),
		(coord.y,     [end_x,   end_x + 1]),
		(coord.y - 1, [start_x, end_x + 1]),
		(coord.y + 1, [start_x, end_x + 1])
	]
	for target in targets:
		j = target[0]
		if j in range (0, len(grid)):
			r = target[1]
			for i in range(r[0], r[1]):
				if i in range(0, len(grid[j])):
					c = grid[j][i]
					if c != "." and not is_digit(c):
						numdata.hosts.append(PartData(
							c, Coord(i, j)
						))
	return numdata

if __name__ == "__main__":
	if len(sys.argv) > 1 and sys.argv[1] == "1":
		mode = 1
	else:
		mode = 2
	print(solution_of(sys.stdin.read(), mode))

