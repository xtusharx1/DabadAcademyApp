class TestRecord {
  final String testName;
  final int batchId;
  final DateTime date;
  final int marksObtained;
  final int totalMarks;

  TestRecord({
    required this.testName,
    required this.batchId,
    required this.date,
    required this.marksObtained,
    required this.totalMarks,
  });

  factory TestRecord.fromJson(Map<String, dynamic> json) {
    return TestRecord(
      testName: json['test_name'],
      batchId: json['batch_id'],
      date: DateTime.parse(json['date']),
      marksObtained: json['marks_obtained'],
      totalMarks: json['total_marks'],
    );
  }
}