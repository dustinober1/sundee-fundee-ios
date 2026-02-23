# Pitfalls Research

- **Ignoring cycle edge cases**: Failing to handle irregular periods or missing data can break phase calculations. *Prevention*: add validation, default to last known phase, allow manual override. Address in cycle tracking phase.

- **Overcomplicating program generation**: Building overly complex adaptive logic can delay release. *Prevention*: start with simple multipliers per phase and expand later. Tackle in early program implementation phase.

- **Firebase rules drift**: As schema evolves, rules may lag causing security holes. *Prevention*: update rules alongside model changes; include rules review task in each phase.

- **Neglecting offline support**: Users may train in areas without connectivity. *Prevention*: ensure providers cache state and queue writes. Review in data layer phase.

- **UI confusion during menstruation**: Poor visual cues may cause frustration. *Prevention*: user test cycle-specific UI early.
