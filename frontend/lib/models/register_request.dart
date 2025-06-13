class RegisterRequest {
  final String name;
  final String lastName;
  final String email;
  final String password;

  RegisterRequest({
    required this.name,
    required this.lastName,
    required this.email,
    required this.password,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'lastName': lastName,
        'email': email,
        'password': password,
      };
}