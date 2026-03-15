import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:universal_science_academy/core/models/test_result_model.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // --- TEACHER METHODS ---
  // UPDATED METHOD for teachers with search functionality
  Stream<QuerySnapshot> getTeachersStream({String? query}) {
    Query teachersQuery = _db.collection('teachers');

    if (query != null && query.isNotEmpty) {
      // Convert the user's search query to lowercase
      String lowerCaseQuery = query.toLowerCase();

      // Perform the search on the 'searchName' field
      teachersQuery = teachersQuery
          .where('searchName', isGreaterThanOrEqualTo: lowerCaseQuery)
          .where('searchName', isLessThanOrEqualTo: '$lowerCaseQuery\uf8ff');
    }

    return teachersQuery.snapshots();
  }

  Future<void> deleteTeacher(String uid) {
    return _db.collection('teachers').doc(uid).delete();
  }

  Future<String?> getTeacherEmailFromId(String teacherId) async {
    try {
      var querySnapshot = await _db
          .collection('teachers')
          .where('teacherId', isEqualTo: teacherId)
          .limit(1)
          .get();
      if (querySnapshot.docs.isNotEmpty) {
        return querySnapshot.docs.first.data()['email'];
      }
      return null;
    } catch (e) {
      print("Error fetching email from ID: $e");
      return null;
    }
  }

  Future<DocumentSnapshot> getTeacherById(String uid) {
    return _db.collection('teachers').doc(uid).get();
  }

  // --- CLASS METHODS ---
  Future<void> addClass(String className, double fee) {
    return _db.collection('classes').add({
      'name': className,
      'monthlyFee': fee,
    });
  }

  Stream<QuerySnapshot> getClassesStream() {
    return _db.collection('classes').orderBy('name').snapshots();
  }

  Future<DocumentSnapshot> getClassById(String classId) {
    return _db.collection('classes').doc(classId).get();
  }

  // --- SUBJECT METHODS ---
  Future<void> addSubject(
    String name,
    String classId,
    String teacherId,
    String subjectType,
  ) {
    return _db.collection('subjects').add({
      'name': name,
      'classId': classId,
      'teacherId': teacherId,
      'subjectType': subjectType, // e.g., 'Compulsory' or 'Optional'
    });
  }

  Stream<QuerySnapshot> getSubjectsForClassStream(String classId) {
    return _db
        .collection('subjects')
        .where('classId', isEqualTo: classId)
        .snapshots();
  }

  Stream<QuerySnapshot> getSubjectsForTeacherStream(String teacherUid) {
    return _db
        .collection('subjects')
        .where('teacherId', isEqualTo: teacherUid)
        .snapshots();
  }

  // --- STUDENT METHODS ---
  Future<void> addStudent(Map<String, dynamic> studentData) {
    return _db.collection('students').add(studentData);
  }

  Stream<QuerySnapshot> getStudentsForClassByGroupStream(
    String classId,
    String studentGroup,
  ) {
    return _db
        .collection('students')
        .where('classId', isEqualTo: classId)
        .where('studentGroup', isEqualTo: studentGroup) // Filter by group
        .snapshots();
  }

  Stream<QuerySnapshot> getOptionalSubjectForGroupStream(
    String classId,
    String subjectName,
  ) {
    return _db
        .collection('subjects')
        .where('classId', isEqualTo: classId)
        .where('name', isEqualTo: subjectName)
        .where(
          'subjectType',
          isEqualTo: 'Optional',
        ) // Ensure it's an optional subject
        .limit(1) // We only expect one such subject
        .snapshots();
  }

  Future<void> deleteClassAndRelatedData(String classId) async {
    // A batch write allows us to perform multiple operations as a single unit.
    final batch = _db.batch();

    // 1. Find and mark all students in that class for deletion
    final studentsSnapshot = await _db
        .collection('students')
        .where('classId', isEqualTo: classId)
        .get();
    for (final doc in studentsSnapshot.docs) {
      batch.delete(doc.reference);
    }

    // 2. Find and mark all subjects for that class for deletion
    final subjectsSnapshot = await _db
        .collection('subjects')
        .where('classId', isEqualTo: classId)
        .get();
    for (final doc in subjectsSnapshot.docs) {
      batch.delete(doc.reference);
    }

    // 3. Find and mark all fee records for that class for deletion
    final feesSnapshot = await _db
        .collection('fees')
        .where('classId', isEqualTo: classId)
        .get();
    for (final doc in feesSnapshot.docs) {
      batch.delete(doc.reference);
    }

    // 4. Find and mark all attendance records for that class for deletion
    final attendanceSnapshot = await _db
        .collection('attendance')
        .where('classId', isEqualTo: classId)
        .get();
    for (final doc in attendanceSnapshot.docs) {
      batch.delete(doc.reference);
    }

    // 5. Find and mark all test results for that class for deletion
    final resultsSnapshot = await _db
        .collection('test_results')
        .where('classId', isEqualTo: classId)
        .get();
    for (final doc in resultsSnapshot.docs) {
      batch.delete(doc.reference);
    }

    // 6. Finally, mark the class document itself for deletion
    final classDocRef = _db.collection('classes').doc(classId);
    batch.delete(classDocRef);

    // 7. Commit the batch - this performs all the delete operations at once.
    await batch.commit();
  }

  // NEW: Checks if a roll number already exists in the database
  Future<bool> isRollNumberUnique(String rollNumber) async {
    final snapshot = await _db
        .collection('students')
        .where('rollNumber', isEqualTo: rollNumber)
        .limit(1)
        .get();
    return snapshot
        .docs
        .isEmpty; // Returns true if no documents are found (is unique)
  }

  Stream<QuerySnapshot> getStudentsForClassStream(String classId) {
    return _db
        .collection('students')
        .where('classId', isEqualTo: classId)
        .snapshots();
  }

  // --- FEE & REPORTING METHODS ---
  Stream<QuerySnapshot> getFeeHistoryForStudentStream(String studentId) {
    return _db
        .collection('fees')
        .where('studentId', isEqualTo: studentId)
        .orderBy('paymentDate', descending: true)
        .snapshots();
  }

  Stream<QuerySnapshot> getStudentsForSubject(DocumentSnapshot subjectDoc) {
    final data = subjectDoc.data() as Map<String, dynamic>;
    final classId = data['classId'];
    final subjectType = data.containsKey('subjectType')
        ? data['subjectType']
        : 'Compulsory';
    final subjectName = data['name']; // Keep original case for debugging

    // Add debug print to see what subject is being processed
    print(
      'Processing subject: $subjectName, Type: $subjectType, ClassId: $classId',
    );

    if (subjectType == 'Compulsory') {
      // For compulsory subjects, get all students.
      return getStudentsForClassStream(classId);
    } else {
      // For Optional subjects, check for special FSC/ICS rules.
      switch (subjectName.toLowerCase()) {
        case 'biology':
          print('Biology query: Biology and FSC Pre-Medical students only');
          return _db
              .collection('students')
              .where('classId', isEqualTo: classId)
              .where('studentGroup', whereIn: ['Biology', 'FSC Pre-Medical'])
              .snapshots();

        case 'chemistry':
          // Chemistry SIRF Pre-Medical aur Pre-Engineering ke liye hai
          // ICS students ko EXCLUDE karna hai
          print(
            'Chemistry query: ONLY FSC Pre-Medical and Pre-Engineering students',
          );
          return _db
              .collection('students')
              .where('classId', isEqualTo: classId)
              .where(
                'studentGroup',
                whereIn: ['FSC Pre-Medical', 'FSC Pre-Engineering'],
              )
              .snapshots();

        case 'math':
        case 'mathematics':
          print('Math query: FSC Pre-Engineering and ICS students');
          return _db
              .collection('students')
              .where('classId', isEqualTo: classId)
              .where('studentGroup', whereIn: ['FSC Pre-Engineering', 'ICS'])
              .snapshots();

        case 'computer':
        case 'computer science':
          print('Computer query: ONLY ICS students');
          return _db
              .collection('students')
              .where('classId', isEqualTo: classId)
              .where('studentGroup', isEqualTo: 'ICS')
              .snapshots();

        case 'physics':
          // Physics bhi Pre-Medical aur Pre-Engineering ke liye hai
          print('Physics query: FSC Pre-Medical and Pre-Engineering students');
          return _db
              .collection('students')
              .where('classId', isEqualTo: classId)
              .where(
                'studentGroup',
                whereIn: ['FSC Pre-Medical', 'FSC Pre-Engineering'],
              )
              .snapshots();

        default:
          print('Default query for subject: $subjectName');
          return getStudentsForClassByGroupStream(classId, subjectName);
      }
    }
  }

  // Stream<QuerySnapshot> debugStudentsQuery(
  //   String classId,
  //   List<String> groups,
  // ) {
  //   print('Querying students with classId: $classId and groups: $groups');

  //   return _db
  //       .collection('students')
  //       .where('classId', isEqualTo: classId)
  //       .where('studentGroup', whereIn: groups)
  //       .snapshots()
  //       .map((snapshot) {
  //         print('Found ${snapshot.docs.length} students');
  //         for (var doc in snapshot.docs) {
  //           final data = doc.data() as Map<String, dynamic>;
  //           print('Student: ${data['name']}, Group: ${data['studentGroup']}');
  //         }
  //         return snapshot;
  //       });
  // }

  Future<void> recordFeePayment(payment) {
    return _db.collection('fees').add(payment.toMap());
  }

  Stream<QuerySnapshot> getFeeCollectedForMonthStream(DateTime month) {
    String formattedMonth = DateFormat('MMMM yyyy').format(month);
    return _db
        .collection('fees')
        .where('feeMonth', isEqualTo: formattedMonth)
        .snapshots();
  }

  Stream<QuerySnapshot> getFeeCollectedForMonthStreamForClass(
    String classId,
    DateTime month,
  ) {
    String formattedMonth = DateFormat('MMMM yyyy').format(month);
    return _db
        .collection('fees')
        .where('classId', isEqualTo: classId)
        .where('feeMonth', isEqualTo: formattedMonth)
        .snapshots();
  }
  // In database_service.dart
  // In database_service.dart
  // In database_service.dart

  // In database_service.dart

  Future<List<Map<String, dynamic>>> getStudentFeeStatusForClass(
    String classId,
    DateTime month,
  ) async {
    // 1. Get all students in the class
    var studentSnapshot = await _db
        .collection('students')
        .where('classId', isEqualTo: classId)
        .get();

    // 2. Get all fee payments for this class for the given month
    String formattedMonth = DateFormat('MMMM yyyy').format(month);
    var feeSnapshot = await _db
        .collection('fees')
        .where('classId', isEqualTo: classId)
        .where('feeMonth', isEqualTo: formattedMonth)
        .get();

    List<Map<String, dynamic>> studentsWithStatus = [];
    Map<String, dynamic> paidStudentsMap = {};
    for (var feeDoc in feeSnapshot.docs) {
      paidStudentsMap[feeDoc['studentId']] = feeDoc.data();
    }

    // 3. Loop through all students and create the final list
    for (var studentDoc in studentSnapshot.docs) {
      bool hasPaid = paidStudentsMap.containsKey(studentDoc.id);

      studentsWithStatus.add({
        'studentName': studentDoc['name'],
        'hasPaid': hasPaid,
        // --- YEH NAYI LINE ADD KI GAYI HAI ---
        'studentGroup':
            studentDoc['studentGroup'] ?? 'N/A', // Adds the student's group
        // --- END OF CHANGE ---
        'amountPaid': hasPaid
            ? paidStudentsMap[studentDoc.id]['amountPaid']
            : 0.0,
        'paymentDate': hasPaid
            ? paidStudentsMap[studentDoc.id]['paymentDate']
            : null,
      });
    }

    return studentsWithStatus;
  }
  // --- ATTENDANCE METHODS ---

  // -> ADD THIS METHOD
  Future<void> saveAttendance(
    String classId,
    String subjectId,
    DateTime date,
    Map<String, String> studentStatus,
  ) {
    String docId =
        '${classId}_${subjectId}_${DateFormat('yyyy-MM-dd').format(date)}';
    return _db.collection('attendance').doc(docId).set({
      'classId': classId,
      'subjectId': subjectId,
      'date': Timestamp.fromDate(date),
      'studentStatus': studentStatus,
    });
  }

  Future<QuerySnapshot> searchStudentsByName(String query) async {
    if (query.isEmpty) {
      return FirebaseFirestore.instance
          .collection('students')
          .limit(10)
          .get(); // Return a few students if search is empty
    }
    return _db
        .collection('students')
        .where('searchName', isGreaterThanOrEqualTo: query.toLowerCase())
        .where(
          'searchName',
          isLessThanOrEqualTo: '${query.toLowerCase()}\uf8ff',
        )
        .get();
  }

  Future<String?> checkUserRole(String uid) async {
    // Check if the user is an admin
    final adminDoc = await _db.collection('users').doc(uid).get();
    if (adminDoc.exists && adminDoc.data()?['role'] == 'admin') {
      return 'admin';
    }

    // Check if the user is a teacher
    final teacherDoc = await _db.collection('teachers').doc(uid).get();
    if (teacherDoc.exists) {
      return 'teacher';
    }

    return null; // User not found in either role
  }

  // -> AND THIS METHOD
  Stream<DocumentSnapshot> getAttendanceForDate(
    String classId,
    String subjectId,
    DateTime date,
  ) {
    String docId =
        '${classId}_${subjectId}_${DateFormat('yyyy-MM-dd').format(date)}';
    return _db.collection('attendance').doc(docId).snapshots();
  }

  // -> AND THIS METHOD
  Future<bool> checkAttendanceStatusForToday(
    String classId,
    String subjectId,
  ) async {
    DateTime now = DateTime.now();
    DateTime today = DateTime(now.year, now.month, now.day);
    String docId =
        '${classId}_${subjectId}_${DateFormat('yyyy-MM-dd').format(today)}';
    var doc = await _db.collection('attendance').doc(docId).get();
    return doc.exists;
  }

  // A powerful stream to get all students with optional search and class filter
  Stream<QuerySnapshot> getAllStudentsStream({String? query, String? classId}) {
    Query studentQuery = _db.collection('students');

    // Apply class filter if provided
    if (classId != null && classId.isNotEmpty) {
      studentQuery = studentQuery.where('classId', isEqualTo: classId);
    }

    // Apply search query if provided
    if (query != null && query.isNotEmpty) {
      String lowerCaseQuery = query.toLowerCase();
      studentQuery = studentQuery
          .where('searchName', isGreaterThanOrEqualTo: lowerCaseQuery)
          .where('searchName', isLessThanOrEqualTo: '$lowerCaseQuery\uf8ff');
    }

    return studentQuery.snapshots();
  }

  // Method to update a student's details
  // Find your existing updateStudent function and replace it with this one.

  Future<void> updateStudent(
    String studentId,
    String name,
    String fatherName, // Add this
    String rollNumber,
    String studentGroup, // Add this
    String phoneNumber,
  ) {
    return _db.collection('students').doc(studentId).update({
      'name': name,
      'fatherName': fatherName, // Add this field to the update
      'rollNumber': rollNumber,
      'studentGroup': studentGroup, // Add this field to the update
      'searchName': name.toLowerCase(),
      'phoneNumber': phoneNumber,
    });
  }

  Future<void> deleteStudent(String studentId) {
    return _db.collection('students').doc(studentId).delete();
  }

  // Method to update a teacher's details
  Future<void> updateTeacher(
    String uid,
    String name,
    String email,
    String teacherId,
  ) {
    String searchName = name.toLowerCase();
    return _db.collection('teachers').doc(uid).update({
      'name': name,
      'email': email,
      'teacherId': teacherId,
      'searchName': searchName, // Make sure to update the search name too
    });
  }

  Future<int> getTotalCount(String collectionName) async {
    try {
      var snapshot = await _db.collection(collectionName).get();
      return snapshot.docs.length;
    } catch (e) {
      print("Error getting total count for $collectionName: $e");
      return 0;
    }
  }

  // Get the total fees collected today
  Future<double> getFeesCollectedToday() async {
    DateTime now = DateTime.now();
    DateTime todayStart = DateTime(now.year, now.month, now.day);
    DateTime todayEnd = todayStart.add(const Duration(days: 1));

    try {
      var snapshot = await _db
          .collection('fees')
          .where('paymentDate', isGreaterThanOrEqualTo: todayStart)
          .where('paymentDate', isLessThan: todayEnd)
          .get();

      double total = 0;
      for (var doc in snapshot.docs) {
        total += (doc['amountPaid'] as num).toDouble();
      }
      return total;
    } catch (e) {
      print("Error getting fees for today: $e");
      return 0;
    }
  }

  // In database_service.dart

  // Find this function
  Future<void> updateSubject(
    String subjectId,
    String newName,
    String newTeacherId,
    // --- ADD THIS PARAMETER ---
    String subjectType,
  ) {
    return _db.collection('subjects').doc(subjectId).update({
      'name': newName,
      'teacherId': newTeacherId,
      // --- ADD THIS FIELD TO THE UPDATE ---
      'subjectType': subjectType,
    });
  }

  // Delete a subject
  Future<void> deleteSubject(String subjectId) {
    return _db.collection('subjects').doc(subjectId).delete();
  }

  // fot Teacher
  Future<void> saveTestResults(List<TestResultModel> results) async {
    final batch = _db.batch();
    for (var result in results) {
      final docRef = _db.collection('test_results').doc();
      batch.set(docRef, result.toMap());
    }
    await batch.commit();
  }

  Stream<QuerySnapshot> getResultsForSubjectStream(String subjectId) {
    return _db
        .collection('test_results')
        .where('subjectId', isEqualTo: subjectId)
        .orderBy('testDate', descending: true)
        .snapshots();
  }

  Future<void> deleteTestResults(List<String> resultIds) async {
    final batch = _db.batch();
    for (var id in resultIds) {
      batch.delete(_db.collection('test_results').doc(id));
    }
    await batch.commit();
  }

  // Update a batch of test results
  Future<void> updateTestResults(Map<String, double> updatedMarks) async {
    final batch = _db.batch();
    updatedMarks.forEach((docId, newMark) {
      batch.update(_db.collection('test_results').doc(docId), {
        'marksObtained': newMark,
      });
    });
    await batch.commit();
  }

  Future<List<QueryDocumentSnapshot>> getTestResultsForAdmin({
    required String subjectId,
    required String sessionType,
    DateTime? month,
  }) async {
    Query query = _db
        .collection('test_results')
        .where('subjectId', isEqualTo: subjectId)
        .where('sessionType', isEqualTo: sessionType);

    // If it's a monthly report, filter by the selected month
    if (sessionType == 'Monthly' && month != null) {
      DateTime firstDay = DateTime(month.year, month.month, 1);
      // Add 1 to the month and subtract one day to get the last day of the month
      DateTime lastDay = DateTime(
        month.year,
        month.month + 1,
        0,
      ).add(const Duration(days: 1));
      query = query
          .where('testDate', isGreaterThanOrEqualTo: firstDay)
          .where('testDate', isLessThan: lastDay);
    }

    final snapshot = await query.get();
    return snapshot.docs;
  }

  // In database_service.dart

  // --- ADD THIS NEW METHOD ---
  Future<Map<String, dynamic>> getConsolidatedReportForClass(
    String classId,
  ) async {
    // 1. Get all subjects for the class
    final subjectsSnapshot = await _db
        .collection('subjects')
        .where('classId', isEqualTo: classId)
        .get();
    final subjects = subjectsSnapshot.docs;
    final subjectIds = subjects.map((doc) => doc.id).toList();

    // 2. Get all students for the class
    final studentsSnapshot = await _db
        .collection('students')
        .where('classId', isEqualTo: classId)
        .get();
    final students = studentsSnapshot.docs;

    // 3. Get all test results for all subjects in this class
    final resultsSnapshot = await _db
        .collection('test_results')
        .where('classId', isEqualTo: classId)
        .get();
    final allResults = resultsSnapshot.docs;

    return {'subjects': subjects, 'students': students, 'results': allResults};
  }

  Stream<QuerySnapshot> getAttendanceForClassInMonth(
    String classId,
    DateTime month,
  ) {
    DateTime firstDay = DateTime(month.year, month.month, 1);
    DateTime lastDay = DateTime(month.year, month.month + 1, 0);

    return _db
        .collection('attendance')
        .where('classId', isEqualTo: classId)
        .where('date', isGreaterThanOrEqualTo: firstDay)
        .where('date', isLessThanOrEqualTo: lastDay)
        .orderBy('date', descending: true)
        .snapshots();
  }

  Future<List<DocumentSnapshot>> getStudentsByIds(
    List<String> studentIds,
  ) async {
    if (studentIds.isEmpty) {
      return [];
    }

    // Firestore 'whereIn' query can take a list of up to 10 IDs at a time
    // For simplicity, we assume the list is not larger than 10.
    // For a production app with more absentees, this would need to handle batching.
    final snapshot = await _db
        .collection('students')
        .where(FieldPath.documentId, whereIn: studentIds)
        .get();
    return snapshot.docs;
  }
}
