class SubjectModel {
  final String id;
  final String name;
  final String classId;
  final String teacherId;
  final String subjectType;
  SubjectModel({
    required this.id,
    required this.name,
    required this.classId,
    required this.teacherId,
    required this.subjectType,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'classId': classId,
      'teacherId': teacherId,
      'subjectType': subjectType,
    };
  }
}
