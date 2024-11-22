import 'package:mongo_dart/mongo_dart.dart' as mongo;

class AppointmentService {
  final String mongoUri =
      "mongodb+srv://munaafifah:munaafifah@wellcheck.t0bkb.mongodb.net/?retryWrites=true&w=majority&appName=WellCheck"; // Replace with your MongoDB URI
  final String collectionName = "appointments";
  late mongo.Db _db;

  AppointmentService() {
    _db = mongo.Db(mongoUri);
  }

  /// Connect to MongoDB
  Future<void> connect() async {
    try {
      await _db.open();
    } catch (e) {
      throw Exception("Failed to connect to MongoDB: $e");
    }
  }

  /// Disconnect from MongoDB
  Future<void> disconnect() async {
    try {
      await _db.close();
    } catch (e) {
      throw Exception("Failed to disconnect from MongoDB: $e");
    }
  }

  /// Fetch all appointments
  Future<List<Map<String, dynamic>>> fetchAppointments() async {
    try {
      var collection = _db.collection(collectionName);
      var results = await collection.find().toList();
      return results.map((doc) {
        return {
          'id': doc['_id'].toString(),
          'appointmentDate':
              doc['appointmentDate'] ?? '', // Changed to appointmentDate
          'appointmentTime':
              doc['appointmentTime'] ?? '', // Changed to appointmentTime
          'duration': doc['duration'] ?? '',
          'typeOfSickness': doc['typeOfSickness'] ?? '',
          'additionalNotes': doc['additionalNotes'] ?? '',
          'appointmentDateTime':
              doc['appointmentDateTime'] ?? '', // appointmentDateTime field
          'createdAt': doc['createdAt'] ?? '',
        };
      }).toList();
    } catch (e) {
      throw Exception("Failed to fetch appointments: $e");
    }
  }

  /// Add a new appointment
  Future<bool> addAppointment(Map<String, dynamic> appointmentData) async {
    try {
      var collection = _db.collection(collectionName);
      await collection.insertOne(appointmentData);
      return true;
    } catch (e) {
      throw Exception("Failed to add appointment: $e");
    }
  }

  /// Edit an appointment by ID
  Future<bool> editAppointment(
      String id, Map<String, dynamic> updatedData) async {
    try {
      var collection = _db.collection(collectionName);
      var result = await collection.updateOne(
        {'_id': mongo.ObjectId.parse(id)},
        {
          '\$set': updatedData,
        },
      );
      return result.isAcknowledged;
    } catch (e) {
      throw Exception("Failed to edit appointment: $e");
    }
  }

  /// Delete an appointment by ID
  Future<void> deleteAppointment(String id) async {
    try {
      var collection = _db.collection(collectionName);
      await collection.deleteOne({'_id': mongo.ObjectId.parse(id)});
    } catch (e) {
      throw Exception("Failed to delete appointment: $e");
    }
  }
}
