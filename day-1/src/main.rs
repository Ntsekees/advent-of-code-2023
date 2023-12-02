
use std::io;
use num_bigint::BigUint;
use num_traits::{Zero,};

use std::collections::HashMap;
use regex::{Captures, Regex};

fn main() -> io::Result<()> {
	let mut input = io::read_to_string(io::stdin())?;
	let args: Vec<String> = std::env::args().collect();
	if args.len() >= 2 && ["2", "b", "B"].map(|x| {x.to_string()}).contains(&args[1]) {
		/* PUZZLE PART TWO */
		input = with_digitized_spelled_numbers(input);
	}
	println!("{}", solution_of(input));
	Ok(())
}

fn digitization_map() -> HashMap<&'static str, &'static str> {
	HashMap::from([
		("zero", "0"), ("one", "1"), ("two", "2"), ("three", "3"),
		("four", "4"), ("five", "5"), ("six", "6"), ("seven", "7"),
		("eight", "8"), ("nine", "9")
	])
}

fn with_digitized_spelled_numbers(s: String) -> String {
	let mut kl: Vec<&str> = Vec::new();
	for key in digitization_map().keys() {
		kl.push(key);
	}
	let rs = format!("({})", &kl.join("|"));
	let re = Regex::new(&rs).unwrap();
	let f = |capt: &Captures| {
		if let Some(v) = digitization_map().get(&capt[0]) {
			v.to_string()
		} else {
			capt[0].to_string()
		}
	};
	let res = re.replace_all(&s, f);
	format!("{}", res)
}

const DIGITS: &str = &"0123456789";

fn solution_of(s: String) -> String {
	let lines_iter = s.split("\n");
	let mut n: BigUint = Zero::zero();
	for line in lines_iter {
		n += value_for(line);
	}
	return n.to_string();
}

fn value_for(s: &str) -> usize {
	if s == "" {
		return 0;
	}
	let mut first = 0;
	let mut last = 0;
	let mut first_digit_has_been_found = false;
	for c in s.chars().rev() {
		if let Some(i) = DIGITS.find(c) {
			if !first_digit_has_been_found {
				first = i;
				last = i;
				first_digit_has_been_found = true;
			} else {
				last = i;
			}
		}
	}
	if !first_digit_has_been_found {
		eprintln!("⚠ Warning: no digit found in line ⟪{}⟫!", s);
	}
	first + last * 0xA
}
