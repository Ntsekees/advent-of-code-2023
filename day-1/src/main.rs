
use std::io;
use num_bigint::BigUint;
use num_traits::{Zero,};

use std::collections::HashMap;

fn main() -> io::Result<()> {
	let input_stream = io::stdin();
	let part_id: u8;
	let args: Vec<String> = std::env::args().collect();
	if args.len() >= 2 &&
		["1", "a", "A"].map(|x| {x.to_string()})
			.contains(&args[1]) {
		part_id = 1; // PUZZLE PART ONE
	} else {
		part_id = 2; // PUZZLE PART TWO
	}
	println!("{}", solution_of(input_stream, part_id));
	Ok(())
}

fn digitization_map() -> HashMap<&'static str, &'static str> {
	HashMap::from([
		("zero", "0"), ("one", "1"), ("two", "2"), ("three", "3"),
		("four", "4"), ("five", "5"), ("six", "6"), ("seven", "7"),
		("eight", "8"), ("nine", "9")
	])
}

fn rev_digitization_map() -> HashMap<&'static str, &'static str> {
	HashMap::from([
		("orez", "0"), ("eno", "1"), ("owt", "2"), ("eerht", "3"),
		("ruof", "4"), ("evif", "5"), ("xis", "6"), ("neves", "7"),
		("thgie", "8"), ("enin", "9")
	])
}

const DIGITS: &str = &"0123456789";

fn solution_of(stream: io::Stdin, mode: u8) -> String {
	let mut n: BigUint = Zero::zero();
	for line_r in stream.lines() {
		if let Ok(line) = line_r {
			n += value_for(line, mode);
		}
	}
	return n.to_string();
}

fn value_for(s: String, mode: u8) -> usize {
	let (dm1, dm2) = match mode {
		1 => (None, None),
		2 => (Some(digitization_map()), Some(rev_digitization_map())),
		_ => panic!("⚠ Invalid mode {}!", mode)
	};
	let first: usize = first_value_for(s.to_string(), dm1);
	let last: usize =  first_value_for(reversed(s.to_string()), dm2);
	last + first * 0xA
}

fn reversed(s: String) -> String {
	s.chars().rev().collect()
}

fn first_value_for(
	line: String,
	dm: Option<HashMap<&'static str, &'static str>>
) -> usize {
	let mut iter = line.chars();
	loop {
		let s = iter.as_str();
		let next = iter.next();
		if s == "" || next == None {
			break;
		}
		if let Some(n) = DIGITS.find(next.unwrap()) {
			return n;
		} else if let Some(ref m) = dm {
			for k in m.keys() {
				if s.starts_with(k) {
					return DIGITS.find(m.get(k).unwrap()).unwrap();
				}
			}
		}
	}
	eprintln!("⚠ ⟦first_value_for⟧: No number found in line ⟪{}⟫!", line);
	0
}
