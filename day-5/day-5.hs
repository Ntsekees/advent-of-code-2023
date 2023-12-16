
{-# LANGUAGE OverloadedStrings #-}

import Integer.Natural (
	Natural, toInt, fromInteger, fromInt, toInteger)
import Data.List (length)
import qualified Data.Text as T
import qualified Data.Text.IO as TIO
import Data.Text (Text, unpack, splitOn)
import Text.Read (readMaybe)
import Data.Maybe (fromJust)

import System.Environment (getArgs)

main :: IO ()
main = do
	args <- getArgs
	let mode = case args of
		(first:_) ->
			if first == "1" then
				1
			else
				2
		_ -> 2
	input <- TIO.getContents
	putStrLn $ show $ solution_of input mode

data SizedRange = SizedRange {
	sr_position :: Natural,
	sr_size :: Natural
} deriving Show

data RangeMap = RangeMap {
	source_index :: Natural,
	destination_index :: Natural,
	size :: Natural
} deriving Show

data MapData = MapData {
	desc :: Text,
	maps :: [RangeMap]
} deriving Show
	
solution_of :: Text -> Int -> Natural
solution_of input mode =
	let
		mtl = splitOn "\n\n" input
		seeds = if length mtl > 0
			then read_seedlist (mtl !! 0) mode
			else error $ "No solution: empty list of seeds."
		ml = map
			read_mapdata
			(drop 1 mtl)
	in
		let
			candidates = map
				(\ r -> sr_position r)
				(locations_from_seeds seeds ml)
		in foldl
			min
			(candidates !! 0)
			(drop 1 candidates)

locations_from_seeds :: [SizedRange] -> [MapData] -> [SizedRange]
locations_from_seeds seeds maplist =
	foldl list_with_applied_map seeds maplist
	where
	list_with_applied_map :: [SizedRange] -> MapData -> [SizedRange]
	list_with_applied_map list mapdata =
		as_flattened $
			map
				(\ range ->
					map
						(\ pair -> fst pair)
						(foldl
							f
							[(range, True)]
							(maps mapdata)))
				list
	f :: [(SizedRange, Bool)] -> RangeMap -> [(SizedRange, Bool)]
	f = \ l -> \ m -> as_flattened $ map (with_applied_map m) l
	with_applied_map ::
		RangeMap -> (SizedRange, Bool) -> [(SizedRange, Bool)]
	with_applied_map m (r, b) =
		let
			mi = sr_intersection_of
				r (SizedRange (source_index m) (size m))
		in case (b, mi) of
			(True, Just i) ->
				proceeded i r (mapped_via m)
			_ ->
				[(r, b)]
	mapped_via :: RangeMap -> SizedRange -> (SizedRange, Bool)
	mapped_via m r =
		let
			i = Integer.Natural.toInteger
			p = fromJust $ Integer.Natural.fromInteger(
				i(sr_position r) +
					(i(destination_index m) - i(source_index m)))
		in
			(SizedRange p (sr_size r), False)

as_flattened :: [[a]] -> [a]
as_flattened =
	foldl (++) []

sr_intersection_of ::
	SizedRange -> SizedRange -> Maybe SizedRange
sr_intersection_of a b =
	if sr_position a <= sr_position b
	then
		if sr_position a + sr_size a - 1 >= sr_position b
		then
			Just (SizedRange
				(sr_position b)
				(min
					(sr_size b)
					(sr_size a - (sr_position b - sr_position a))))
		else
			Nothing
	else -- sr_position a > sr_position b
		sr_intersection_of b a
		--if sr_position b + sr_size b <= sr_position a
		
proceeded ::
	SizedRange ->
	SizedRange ->
	(SizedRange -> (SizedRange, Bool)) ->
	[(SizedRange, Bool)]
proceeded i r g =
	if sr_position i == sr_position r
	then
		if sr_position i + sr_size i ==
			sr_position r + sr_size r
		then
			[g i]
		else -- (<)
			let v = SizedRange
				(sr_position i + sr_size i)
				(sr_size r - sr_size i)
			in [g i, (v, True)]
	else -- sr_position i > sr_position r
		if sr_position i + sr_size i ==
			sr_position r + sr_size r
		then
			let v = SizedRange
				(sr_position r) (sr_position i - sr_position r)
			in [(v, True), g i]
		else -- (<)
			let
				a = SizedRange
					(sr_position r)
					(sr_position i - sr_position r)
				b = SizedRange
					(sr_position i + sr_size i)
					(sr_size r - sr_size i)
			in [(a, True), g i, (b, True)]

-- ========================================================== --

read_seedlist :: Text -> Int -> [SizedRange]
read_seedlist t mode =
	let
		list = case splitOn ": " t of
			["seeds", body] ->
				natlist_from_text body
			_ -> error $
				"Invalid seed list: ⟪" ++ unpack t ++ "⟫!"
	in
		if mode == 2
		then
			if (mod (length list) 2) == 1
			then error $
				"Missing range length for the last seed set!" 
			else
				map
					(\ pair -> SizedRange (pair !! 0) (pair !! 1))
					(chunks_of 2 list)
		else -- mode == 1
			map
				(\ item -> SizedRange item 1)
				list

chunks_of :: Natural -> [a] -> [[a]]
chunks_of _ [] = []
chunks_of n l =
	let i = fromJust $ toInt n
	in (take i l) : (chunks_of n (drop i l))

read_mapdata :: Text -> MapData
read_mapdata t =
	case splitOn " map:\n" t of
		[desc, body] ->
			MapData desc (map
				read_rangemap
				(filter (\ t -> t /= "")
				(splitOn "\n" body)))
		_ -> error $
			"Invalid Map Section: ⟪\n" ++ unpack t ++ "\n⟫"

read_rangemap :: Text -> RangeMap
read_rangemap t =
	case natlist_from_text t of
		[dst, src, len] ->
			RangeMap src dst len
		_ -> error $
			"Invalid range map data: ⟪" ++ unpack t ++ "⟫!"

natlist_from_text :: Text -> [Natural]
natlist_from_text text =
	let r = map
		(\ t -> readMaybe (unpack t) :: Maybe Natural)
		(filter (\ t -> t /= "") (splitOn " " text))
	in
		if any (== Nothing) r then
			error $
				"Invalid number expression found in ⟪" ++
					(unpack text) ++ "⟫!"
		else
			map fromJust r
