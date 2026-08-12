final class Account {
  const Account({required this.id});

  final String id;

  bool get isIdentified => id.trim().isNotEmpty && id.length <= 100;
}
