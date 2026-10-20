/// True for tablets and phones held sideways.
/// We use one breakpoint everywhere so the app feels the same on every screen.
bool isWideScreen(double width) {
  return width >= 600;
}
