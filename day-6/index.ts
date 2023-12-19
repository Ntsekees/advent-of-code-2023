
var fs = require("fs");

// Reading from Stdin:
var input = fs.readFileSync(0).toString('utf8');

console.log(solution_of(input, 1));
process.exit();

function solution_of(input: string, mode: number): string {
	var times: Array<number>;
	var distances: Array<number>;
	var races: Array<Map<string, number>> = races_from_input(input);
	var solution_ranges: Array<Array<number>> = [];
	races.forEach(function (e, i) {
		solution_ranges.push(solution_range_for_race(e));
	});
	return solution_ranges
		.map(r => [
			r[0] % 1.0 == 0.0 ? r[0] + 1 : Math.ceil(r[0]),
			r[1] % 1.0 == 0.0 ? r[1] - 1 : Math.floor(r[1])
		])
		.filter(r => r[1] - r[0] > 1)
		.map(r => r[1] - r[0] + 1)
		.reduce((acc, val) => acc * val)
		.toString();
}

/*
The solution for a race of duration ⟦t⟧ and record distance ⟦d⟧ is the set of all button times ⟦b⟧ for which ⟦(t − b) × speed > d⟧ is true, with ⟦speed⟧ = ⟦b⟧.
For finding the boundaries of the winning range of button durations, it suffices to find the at most two button durations that yield the same distance as the record distance ⟦d⟧. This amounts to solving the equation ⟪(t − b) × b = d⟫, which can be rewritten as the quadratic equation ⟪−b² + t·b − d = 0⟫.
Such an equation has at most two solutions, namely ⟦(−t + √Δ) / −2⟧ and ⟦(−t − √Δ) / −2⟧, where ⟦Δ⟧ = ⟦t² − 4·d⟧.
*/
function solution_range_for_race(
	racedata: Map<string, number>
): Array<number> {
	var t: number = racedata.get("time") || 0;
	var d: number = racedata.get("dist") || 0;
	var Δ = t ** 2 - 4 * d;
	console.assert(Δ >= 0, "¬ Δ ≥ 0");
	return [1, -1].map(x => (-t + x * Math.sqrt(Δ)) / -2);
}

function races_from_input(input: string)
: Array<Map<string, number>> {
	var lines: Array<Array<string>> =
		input.split("\n").map(l => l.split(/\s+/));
	console.assert(lines[0].shift() === "Time:");
	console.assert(lines[1].shift() === "Distance:");
	var times: Array<number> =
		lines[0].map(s => parseInt(s, 0xA));
	var distances: Array<number> =
		lines[1].map(s => parseInt(s, 0xA));
	console.assert(
		times.length == distances.length,
		`[${times}].length ≠ [${distances}].length`);
	return times.map(function (e: number, i: number) {
		var map: Map<string, number> = new Map<string, number>();
		map.set("time", e);
		map.set("dist", distances[i]);
		return map;
	});
}

