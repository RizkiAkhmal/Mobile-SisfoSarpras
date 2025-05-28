// Option 1: Use Stack and Positioned
Stack(
  children: [
    Positioned(
      top: -30,
      left: 0,
      right: 0,
      child: YourWidget(),
    ),
  ],
)

// Option 2: Use Transform
Transform.translate(
  offset: Offset(0, -30),
  child: YourWidget(),
)