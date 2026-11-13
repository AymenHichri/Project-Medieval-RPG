class_name TestCase
extends RefCounted
## Base class for all tests. Every method whose name starts with `test_` is run by
## `tests/test_runner.gd`. Failed assertions are recorded (not thrown) so one test
## file reports every failure it finds.

var failures: Array[String] = []
var current_test: String = ""


## Called before each test method. Override when needed.
func before_each() -> void:
	pass


## Called after each test method. Override when needed.
func after_each() -> void:
	pass


func fail(message: String) -> void:
	failures.append("%s: %s" % [current_test, message])


func assert_true(condition: bool, message: String = "expected true") -> void:
	if not condition:
		fail(message)


func assert_false(condition: bool, message: String = "expected false") -> void:
	if condition:
		fail(message)


func assert_eq(actual: Variant, expected: Variant, message: String = "") -> void:
	if typeof(actual) != typeof(expected) or actual != expected:
		fail("expected <%s> but got <%s> %s" % [str(expected), str(actual), message])


func assert_ne(actual: Variant, unexpected: Variant, message: String = "") -> void:
	if typeof(actual) == typeof(unexpected) and actual == unexpected:
		fail("did not expect <%s> %s" % [str(actual), message])


func assert_almost_eq(actual: float, expected: float, tolerance: float, message: String = "") -> void:
	if absf(actual - expected) > tolerance:
		fail("expected %f ± %f but got %f %s" % [expected, tolerance, actual, message])


func assert_null(value: Variant, message: String = "expected null") -> void:
	if value != null:
		fail("%s (got <%s>)" % [message, str(value)])


func assert_not_null(value: Variant, message: String = "expected a non-null value") -> void:
	if value == null:
		fail(message)
