extends TestCase
## Verifies the test harness itself.


func test_passing_assertions_record_nothing() -> void:
	assert_true(true)
	assert_eq(1 + 1, 2)
	assert_almost_eq(0.1 + 0.2, 0.3, 0.0001)
	assert_null(null)


func test_failing_assertion_is_detected() -> void:
	var inner: TestCase = TestCase.new()
	inner.current_test = "inner"
	inner.assert_eq(1, 2)
	inner.assert_true(false)
	inner.assert_eq(1, 1.0)  # different types must not compare equal
	assert_eq(inner.failures.size(), 3, "inner failures should be recorded")
