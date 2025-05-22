class Person {
  final String id;
  final String name;
  final String email;
  final String password;
  final String phone;
  final String role;
  final String? image; 


  Person({
    required this.id,
    required this.name,
    required this.email,
    required this.password,
    required this.phone,
    required this.role,
    this.image,
  });

  factory Person.fromMap(Map<String, dynamic> map) {
  return Person(
    id: map['id'],
    name: map['name'] ?? '',
    email: map['email'] ?? '',
    password: map['password'] ?? '',
    phone: map['phone'] ?? '',
    role: map['role'] ?? 'customer',
    image: map['image'] ?? '',
  );
}

  
}
