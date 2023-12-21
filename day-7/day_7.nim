
import sugar
from os import nil
from strutils import split, replace
from parseutils import parseInt
import bigints
from std/algorithm import sort, SortOrder
from std/enumerate import enumerate
from std/tables import toCountTable, `[]`, keys, sort
from sequtils import toSeq, foldl
import std/options

# ============================================================ #

proc solution_of(stream: File, mode: uint): string

when isMainModule:
   let args = os.commandLineParams()
   var mode: uint
   if args.len >= 1 and args[0] == "1":
      mode = 1
   else:
      mode = 2
   echo solution_of(stdin, mode)
   quit()

# ============================================================ #

type HandData = object
   hand: string
   bid: uint

proc read_hands_and_bids(stream: File): seq[HandData]
proc hand_order_for(h1: string, h2: string, mode: uint): int

proc solution_of(stream: File, mode: uint): string =
   var l = read_hands_and_bids(stream)
   sort(
      l,
      (hd1, hd2) => hand_order_for(hd1.hand, hd2.hand, mode))
   var s: BigInt = 0'bi
   for i, hand_data in enumerate(l):
      s += initBigInt(hand_data.bid * uint(i + 1))
   return $ s

proc read_hands_and_bids(stream: File): seq[HandData] =
   var hdl: seq[HandData] = @[]
   for line in lines stream:
      let r: seq[string] = split(line, ' ')
      if (len r) >= 2:
         var bid: int = 0
         discard parseInt(r[1], bid)
         add hdl, HandData(hand: r[0], bid: uint(bid))
   return hdl

# ============================================================ #

type CharCounter = tuple[item: char, count: uint]
type HandCounts = seq[CharCounter]

func hand_counts_of(hand_string: string): HandCounts
func with_mode(counts: HandCounts, mode: uint): HandCounts
func with_optimal_joker_mutation(counts: HandCounts): HandCounts
func hand_type_rank_of(counts: HandCounts): uint
func tie_order_for(h1: string, h2: string): int
func card_rank_of(c: char): int

proc hand_order_for(h1: string, h2: string, mode: uint): int =
   doAssert h1.len == 5
   doAssert h2.len == 5
   let hc1 = with_mode(hand_counts_of(h1), mode)
   let hc2 = with_mode(hand_counts_of(h2), mode)
   let order =
      cmp((hand_type_rank_of hc1), (hand_type_rank_of hc2))
   if order != 0:
      return order
   elif mode == 1:
      return tie_order_for(h1, h2)
   else: # mode == 2
      return tie_order_for(
         h1.replace("J", "1"),
         h2.replace("J", "1"))

func hand_counts_of(hand_string: string): HandCounts =
   var counts: seq[CharCounter] = @[]
   var freqs = toCountTable(hand_string)
   for k in keys freqs:
      counts.add(
         (item: k, count: uint(freqs[k])))
   sort(
      counts,
      ((a: CharCounter, b: CharCounter) =>
         (if a.count < b.count: 1 else: -1)))
   return counts

func with_mode(counts: HandCounts, mode: uint): HandCounts =
   if mode == 2:
      with_optimal_joker_mutation(counts)
   else:
      counts

func first_in[T](
   prop: proc (e: T): bool {.noSideEffect.},
   s: seq[T]
): Option[tuple[item: T, index: int]] =
   for i, e in s:
      if prop(e):
         return some((item: e, index: i))
   return none((T, int))

func with_optimal_joker_mutation(
   counts: HandCounts
): HandCounts =
   let r1 = first_in(
      (e: CharCounter) => (e.item == 'J'), counts)
   if r1.isSome:
      let joker = r1.get()
      let r2 = first_in(
         (e: CharCounter) => (e.item != 'J'), counts)
      if r2.isSome:
         let top_other = r2.get()
         var counts′ = counts
         counts′[top_other.index] = (
            item: top_other.item.item,
            count: top_other.item.count + joker.item.count)
         counts′.delete(joker.index)
         return counts′
      else:
         return counts
   else:
      return counts

func hand_type_rank_of(counts: HandCounts): uint =
   doAssert counts.len > 0
   if counts.len == 1:
      doAssert counts[0].count == 5
      result = counts[0].count * 2 - 3
   else:
      result =
         counts[0].count * 2 + counts[1].count - 3

func tie_order_for(h1: string, h2: string): int =
   doAssert h1.len == h2.len
   for i, _ in h1:
      let diff = card_rank_of(h1[i]) - card_rank_of(h2[i])
      if diff != 0:
         return diff
   return 0

const CARDS = toSeq("AKQJT987654321".items)
const CARDN = CARDS.len

func card_rank_of(c: char): int =
   let r = find(CARDS, c)
   if r >= 0:
      return CARDN - r
   else:
      raise newException(
         ValueError, "Invalid character: ⟪" & $ c & "⟫")
