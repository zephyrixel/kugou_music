enum AppLogLevel {
  off(0, '关闭'),
  error(1, '错误'),
  warn(2, '警告'),
  info(3, '信息'),
  debug(4, '调试'),
  trace(5, '跟踪');

  const AppLogLevel(this.priority, this.label);

  final int priority;
  final String label;

  bool allows(AppLogLevel other) => other.priority <= priority;

  static AppLogLevel parse(String? value) => values.firstWhere(
    (level) => level.name == value,
    orElse: () => AppLogLevel.info,
  );
}
