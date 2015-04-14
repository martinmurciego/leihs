Feature: Leihs must perform acceptably for its users

	We want to make sure that performance of leihs does not degrade as leihs evolves.

  @personas
  Scenario: Computing availability of a heavily booked model should remain acceptable
    Given I am Mike
    Given the model "Kamera Nikon X12" exists
    And it has at least 500 items in the current inventory pool
    And it has at least 3 group partitions in the current inventory pool
    And it has at least 100 unsubmitted lines in the current inventory pool
    And it has at least 100 submitted lines in the current inventory pool
    And it has at least 100 approved lines in the current inventory pool
    And it has at least 100 signed lines in the current inventory pool
    When its availability is recalculate
    Then it should take at maximum 0.3 seconds
