:- module day_2.

:- interface.

:- import_module io.
:- pred main(io::di, io::uo) is det.

% ============================================================ %

:- implementation.

:- import_module uint, list, string, char, maybe, bool.
:- import_module require. % ⟦error/1⟧

main(!IO) :-
	io.command_line_arguments(Args, !IO),
	R = nth(0u, Args),
	(
		if R = yes(A)
		then IsPart2: bool = (if A = "1" then no else yes)
		else IsPart2: bool = yes
	),
	has_solution(stdin_stream, IsPart2, Solution, !IO),
	io.write_string(Solution ++ "\n", !IO).

:- func nth(uint, list(T)) = maybe(T).
nth(_, []) = no.
nth(I, [X | Xs]) = (
    if I = 0u
    then yes(X)
    else nth(I - 1u, Xs)
    ).

:- type game
	---> game(
		game_id :: uint,
		cubesets :: list(cubeset)
	).

:- type cubeset
	---> cubeset(
		red :: uint,
		green :: uint,
		blue :: uint
	).

:- func puzzle_limit = cubeset.
(puzzle_limit) = T :- T = cubeset(12u, 13u, 14u).

:- pred has_solution(
	io.text_input_stream::in,
	bool::in,
	string::out,
	io::di, io::uo
	).
has_solution(Stream, IsPartTwo, Solution, !IO) :-
	read_game_stream(Stream, [], GameList, !IO),
	(
		if IsPartTwo = yes
		then (
			Solution = uint_to_string(foldl(F, GameList, 0u)),
			F = (
				func(Game, Acc) = NextAcc :-
					Game = game(_, CubesetList),
					NextAcc = Acc +
						cubeset_power_of(max_cubeset_of(CubesetList))
			)
		)
		else (
			FilterPred = (
				pred(G::in) is semidet :-
					G = game(_, CubesetList),
					MaxCubeset = max_cubeset_of(CubesetList),
					isnt_greater_cubeset(MaxCubeset, puzzle_limit)
			),
			FilteredList = filter(FilterPred, GameList),
			Solution = uint_to_string(foldl(F, FilteredList, 0u)),
			F = (
				func(Game, Acc) = NextAcc :-
					Game = game(ID, _),
					NextAcc = Acc + ID
			)
		)
	).

:- func cubeset_power_of(cubeset) = uint.
cubeset_power_of(CS) =
	CS^red * CS^green * CS^blue.

:- func max_cubeset_of(list(cubeset)) = cubeset.
max_cubeset_of(L) = R :-
	R = foldl(F, L, cubeset(0u, 0u, 0u)),
	F = (
		func(Elem, Acc) = NewAcc :-
			NewAcc^red   = max(Elem^red,   Acc^red),
			NewAcc^green = max(Elem^green, Acc^green),
			NewAcc^blue  = max(Elem^blue,  Acc^blue)
	).

:- pred isnt_greater_cubeset(cubeset::in, cubeset::in) is semidet.
isnt_greater_cubeset(A, B) :-
	A^red =< B^red,
	A^green =< B^green,
	A^blue =< B^blue.

:- pred read_game_stream(
	io.text_input_stream::in,
	list(game)::in,
	list(game)::out,
	io::di, io::uo
	).
read_game_stream(Stream, L1, L2, !IO) :-
	io.read_line_as_string(Read, !IO),
	(
		Read = ok(Line),
		LineContent = replace_all(Line, "\n", ""),
		(
			if LineContent = ""
			then L1b = []
			else L1b = [read_game_line(LineContent)]
		),
		read_game_stream(
			Stream,
			append(L1, L1b),
			L2,
			!IO)
	;
		(Read = eof; Read = error(_)),
		L2 = L1
	).

:- func read_game_line(string) = game.
read_game_line(Line) = Game :-
	(
		split(Line, length("Game "), "Game ", Remainder),
		[GameIdStr, GameContent] = split_at_string(": ", Remainder),
		split_at_string("; ", GameContent) = CubesetStringList,
		map(cubeset_string_reads_as, CubesetStringList, CubesetList),
		to_uint(GameIdStr, GameId),
		Game = game(GameId, CubesetList)
	;
		error("⚠ ⟦read_game_line⟧ failed!")
	).

:- type colorval
	---> colorval(
		color :: string,
		count :: uint
	).

:- pred cubeset_string_reads_as(string::in, cubeset::out) is det.
cubeset_string_reads_as(S, R) :-
	(
		map(parses_as_color, split_at_string(", ", S), L),
		foldl(
			is_cubeset_updated_with_colorval, L, cubeset(0u, 0u, 0u), R)
	;
		error("⚠ Error at ⟦cubeset_string_reads_as⟧!")
	).

:- pred is_cubeset_updated_with_colorval(
	colorval::in, cubeset::in, cubeset::out) is det.
is_cubeset_updated_with_colorval(Colorval, Cubeset, NewCubeset) :-
	Colorval = colorval(Color, Count),
	(
		Color = "red",
		NewCubeset = (Cubeset^red := max(Cubeset^red, Count))
	;
		Color = "green",
		NewCubeset = (Cubeset^green := max(Cubeset^green, Count))
	;
		Color = "blue",
		NewCubeset = (Cubeset^blue := max(Cubeset^blue, Count))
	;
		error("Unknown color name: ⟪" ++ Color ++ "⟫!")
	).

:- pred parses_as_color(string::in, colorval::out) is det.
parses_as_color(S, CV) :-
	(
		is_color_phrase(S, Color, NumStr),
		to_uint(NumStr, N),
		CV = colorval(Color, N)
	;
		error("⚠ ⟦parses_as_color⟧: Invalid color string!")
	).

:- pred is_color_phrase(string::in, string::out, string::out)
	is semidet.
is_color_phrase(Str, Color, NumStr) :-
	[NumStr, Color] = split_at_string(" ", Str).

