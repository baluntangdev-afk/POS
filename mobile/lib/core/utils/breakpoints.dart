abstract final class Breakpoints {
  static const double tablet = 720.0;

  static bool isTablet(double width) => width >= tablet;
  static bool isPhone(double width) => width < tablet;
}
