class Teacher {
  final String uid;
  final String name;
  final String email;
  final String teacherId; // Add this field

  Teacher({
    required this.uid,
    required this.name,
    required this.email,
    required this.teacherId, // Add to constructor
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'teacherId': teacherId, // Add to map
    };
  }
}
