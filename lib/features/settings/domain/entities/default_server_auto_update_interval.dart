/// User-configurable default-server auto-update cadence.
enum DefaultServerAutoUpdateInterval {
  disabled('disabled'),
  every12Hours('12h'),
  every24Hours('24h'),
  every7Days('7d');

  const DefaultServerAutoUpdateInterval(this.storageValue);

  final String storageValue;

  static DefaultServerAutoUpdateInterval fromStorageValue(String? value) {
    for (final interval in values) {
      if (interval.storageValue == value) {
        return interval;
      }
    }
    return disabled;
  }
}
