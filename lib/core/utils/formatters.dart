class CurrencyFormatter {
  const CurrencyFormatter._();

  static String inRupees(num amount) {
    final value = amount.round().toString();
    if (value.length <= 3) return '₹$value';

    final lastThree = value.substring(value.length - 3);
    final remaining = value.substring(0, value.length - 3);
    final groupedRemaining = remaining.replaceAllMapped(
      RegExp(r'\B(?=(\d{2})+(?!\d))'),
      (match) => ',',
    );
    return '₹$groupedRemaining,$lastThree';
  }
}
