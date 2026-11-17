extends TestCase
## Slice balance (Phase 7): a level 1 Knight, played sensibly, wins 3–5 graveyard fights before
## needing to rest, and rarely dies when resting at 30% HP. See tools/balance_sim.gd.

const TRIALS: int = 150


func test_knight_wins_three_to_five_fights_before_resting() -> void:
	var stats: Dictionary = BalanceSim.run(TRIALS, 2026)
	var mean: float = stats["mean_fights"]
	assert_true(mean >= 3.0 and mean <= 5.0, "mean fights before resting %.2f (target 3–5)" % mean)
	assert_true(int(stats["deaths"]) <= TRIALS / 10, "deaths %d / %d" % [stats["deaths"], TRIALS])
