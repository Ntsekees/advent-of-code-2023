
mutable struct CardData
	rank::UInt
	count::UInt
end

function solution_of(stream, mode)
	if mode == 1
		solution = 0
		for line in stream
			(_, r) = id_and_rank_of_card(line)
			solution += r == 0 ? 0 : 2 ^ (r - 1)
		end
		return solution
	else # mode == 2
		l = []
		for (i, line) in enumerate(stream)
			(id, r) = id_and_rank_of_card(line)
			@assert i == id
			push!(l, CardData(r, 1))
		end
		len = length(l)
		for (i, card) in enumerate(l)
			j = 1
			while j <= card.rank && i + j <= len
				l[i + j].count += card.count
				j += 1
			end
		end
		return sum(map(c -> c.count, l))
	end
end

function id_and_rank_of_card(s)
	(header, body) = split(s, ": ")
	(_, id) = split(header, " ", keepempty = false)
	(winning_numlist, obtained_numlist) = map(
		s -> split(s, " ", keepempty = false),
		split(body, " | "))
	return (
		parse(Int, id),
		length(intersect(winning_numlist, obtained_numlist))
	)
end

# =========================================================== #

if length(ARGS) >= 1 && ARGS[1] == "1"
	mode = 1
else
	mode = 2
end
println(string(solution_of(readlines(), mode)))


