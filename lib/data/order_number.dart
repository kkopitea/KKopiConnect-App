String formatOrderNumber(int serial) {
  if (serial < 1) {
    throw ArgumentError.value(serial, 'serial', 'Must be positive.');
  }
  return '#KK${serial.toString().padLeft(3, '0')}';
}
