import 'contact.dart'; // Import the new Contact model

class ContactGroup {
  final String name;
  final List<Contact> contacts; // <-- Use a list of Contact objects

  ContactGroup({required this.name, required this.contacts});

  // Calculate online/total counts based on the contacts list
  int get onlineCount => contacts.where((c) => c.statusText != '离线').length;
  int get totalCount => contacts.length;

  String get countDisplay => '$onlineCount/$totalCount';
}
