import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/appointment_service.dart';
import '../models/appointment_model.dart';
import '../pages/appointment_page.dart';
// For date formatting

class ViewAppointmentsPage extends StatefulWidget {
  final String userId;

  const ViewAppointmentsPage({super.key, required this.userId});

  @override
  _ViewAppointmentsPageState createState() => _ViewAppointmentsPageState();
}

class _ViewAppointmentsPageState extends State<ViewAppointmentsPage> {
  final AppointmentService _appointmentService = AppointmentService();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  List<Appointment>? _appointments;
  List<Appointment>? _filteredAppointments;
  String? _selectedMonth;
  String? _statusFilter;
  bool _isLoading = false;
  String? _errorMessage;

  int _currentPage = 0;
  final int _itemsPerPage = 5;

  @override
  void initState() {
    super.initState();
    _fetchAppointments();
  }

  Future<void> _fetchAppointments() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final token = await _storage.read(key: "auth_token");
      if (token != null) {
        final appointments =
            await _appointmentService.fetchAppointments(token, widget.userId);
        setState(() {
          _appointments = appointments;
          _filteredAppointments = appointments;
        });
      } else {
        setState(() {
          _errorMessage = "Authentication token not found.";
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Failed to load appointments. Please try again.";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _filterAppointments({String? month, String? status}) {
    setState(() {
      // Start with the full list of appointments
      _filteredAppointments = _appointments;

      // Filter by month if provided
      if (month != null && month.isNotEmpty) {
        _filteredAppointments = _filteredAppointments!.where((appointment) {
          return appointment.appointmentDate.month.toString() == month;
        }).toList();
      }

      // Filter by status if provided
      if (status != null && status.isNotEmpty) {
        _filteredAppointments = _filteredAppointments!.where((appointment) {
          return appointment.statusAppointment == status;
        }).toList();
      }

      // Reset to the first page when filters are applied
      _currentPage = 0;
    });
  }

  void _updateStatusFilter(String status) {
    setState(() {
      _statusFilter = status;
    });
    _filterAppointments(status: status);
  }

  Future<void> _deleteAppointment(String appointmentId) async {
    try {
      final token = await _storage.read(key: "auth_token");
      if (token != null) {
        await _appointmentService.deleteAppointment(token, appointmentId);
        _fetchAppointments(); // Refresh the list after deletion
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to delete appointment: $e")),
      );
    }
  }

  Future<void> _editAppointment(String appointmentId, String newNotes) async {
    try {
      final token = await _storage.read(key: "auth_token");
      if (token != null) {
        await _appointmentService.updateAppointment(
            token, appointmentId, newNotes);
        _fetchAppointments(); // Refresh the list after update
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to update appointment: $e")),
      );
    }
  }

  List<Appointment> _getPaginatedAppointments() {
    if (_filteredAppointments == null) return [];
    final startIndex = _currentPage * _itemsPerPage;
    final endIndex = startIndex + _itemsPerPage;
    return _filteredAppointments!.sublist(
      startIndex,
      endIndex > _filteredAppointments!.length
          ? _filteredAppointments!.length
          : endIndex,
    );
  }

  void _goToPreviousPage() {
    if (_currentPage > 0) {
      setState(() {
        _currentPage--;
      });
    }
  }

  void _goToNextPage() {
    if (_currentPage <
        (_filteredAppointments!.length / _itemsPerPage).ceil() - 1) {
      setState(() {
        _currentPage++;
      });
    }
  }

  Widget buildAppointmentCard(Appointment appointment) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        title: Text(
          "Appointment - ${appointment.typeOfSickness}",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  "Status: ",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  appointment.statusAppointment, // Dynamically show the status
                  style: TextStyle(
                    color: appointment.statusAppointment == "Approved"
                        ? Colors.green
                        : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text("Date: ${appointment.getFormattedDate()}"),
            Text("Time: ${appointment.getFormattedTime()}"),
            Text("Duration: ${appointment.duration} mins"),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.remove_red_eye, color: Colors.blue),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text("Appointment - ${appointment.typeOfSickness}"),
                    content: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("General Information",
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Text("Date: ${appointment.getFormattedDate()}"),
                          Text("Time: ${appointment.getFormattedTime()}"),
                          Text("Duration: ${appointment.duration} mins"),
                          const SizedBox(height: 16),
                          const Text("Details",
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Text(
                              "Type of Sickness: ${appointment.typeOfSickness}"),
                          Text(
                              "Additional Notes: ${appointment.additionalNotes}"),
                          const SizedBox(height: 16),
                          const Text("Contact Information",
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Text("Email: ${appointment.email}"),
                          const SizedBox(height: 16),
                          const Text("Identifiers & Cost",
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Text("Doctor ID: ${appointment.doctorId}"),
                          Text("User ID: ${appointment.userId}"),
                          Text(
                              "Cost: RM${appointment.appointmentCost.toStringAsFixed(2)}"),
                        ],
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("Close"),
                      ),
                    ],
                  ),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.orange),
              onPressed: () {
                TextEditingController controller =
                    TextEditingController(text: appointment.additionalNotes);
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text("Edit Notes"),
                    content: TextField(
                      controller: controller,
                      decoration: const InputDecoration(labelText: "Notes"),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () {
                          _editAppointment(
                              appointment.appointmentId, controller.text);
                          Navigator.pop(context);
                        },
                        child: const Text("Save"),
                      ),
                    ],
                  ),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _deleteAppointment(appointment.appointmentId),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("View Appointments"),
        backgroundColor: const Color(0xFF4CAF93),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!))
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: DropdownButtonFormField<String>(
                        value: _selectedMonth,
                        items: const [
                          DropdownMenuItem(value: "", child: Text("All")),
                          DropdownMenuItem(value: "1", child: Text("January")),
                          DropdownMenuItem(value: "2", child: Text("February")),
                          DropdownMenuItem(value: "3", child: Text("March")),
                          DropdownMenuItem(value: "4", child: Text("April")),
                          DropdownMenuItem(value: "5", child: Text("May")),
                          DropdownMenuItem(value: "6", child: Text("June")),
                          DropdownMenuItem(value: "7", child: Text("July")),
                          DropdownMenuItem(value: "8", child: Text("August")),
                          DropdownMenuItem(
                              value: "9", child: Text("September")),
                          DropdownMenuItem(value: "10", child: Text("October")),
                          DropdownMenuItem(
                              value: "11", child: Text("November")),
                          DropdownMenuItem(
                              value: "12", child: Text("December")),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedMonth = value;
                          });
                          _filterAppointments(
                              month: value, status: _statusFilter);
                        },
                        decoration: InputDecoration(
                          labelText: "Filter by Month",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          ElevatedButton.icon(
                            onPressed: () {
                              setState(() {
                                _statusFilter = "Not Approved";
                              });
                              _filterAppointments(
                                  month: _selectedMonth,
                                  status: "Not Approved");
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _statusFilter == "Not Approved"
                                  ? const Color(0xFF4CAF93)
                                  : Colors.grey[300],
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(
                                  vertical: 12, horizontal: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                              elevation:
                                  _statusFilter == "Not Approved" ? 6 : 2,
                            ),
                            icon: Icon(
                              Icons.cancel_outlined,
                              color: _statusFilter == "Not Approved"
                                  ? Colors.white
                                  : Colors.black,
                            ),
                            label: Text(
                              "Not Approved",
                              style: TextStyle(
                                color: _statusFilter == "Not Approved"
                                    ? Colors.white
                                    : Colors.black,
                              ),
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: () {
                              setState(() {
                                _statusFilter = "Approved";
                              });
                              _filterAppointments(
                                  month: _selectedMonth, status: "Approved");
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _statusFilter == "Approved"
                                  ? const Color(0xFF4CAF93)
                                  : Colors.grey[300],
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(
                                  vertical: 12, horizontal: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                              elevation: _statusFilter == "Approved" ? 6 : 2,
                            ),
                            icon: Icon(
                              Icons.check_circle_outline,
                              color: _statusFilter == "Approved"
                                  ? Colors.white
                                  : Colors.black,
                            ),
                            label: Text(
                              "Approved",
                              style: TextStyle(
                                color: _statusFilter == "Approved"
                                    ? Colors.white
                                    : Colors.black,
                              ),
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: () {
                              setState(() {
                                _statusFilter = null;
                              });
                              _filterAppointments(
                                  month: _selectedMonth, status: null);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _statusFilter == null ||
                                      _statusFilter!.isEmpty
                                  ? const Color(0xFF4CAF93)
                                  : Colors.grey[300],
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(
                                  vertical: 12, horizontal: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                              elevation: _statusFilter == null ||
                                      _statusFilter!.isEmpty
                                  ? 6
                                  : 2,
                            ),
                            icon: Icon(
                              Icons.all_inclusive,
                              color: _statusFilter == null ||
                                      _statusFilter!.isEmpty
                                  ? Colors.white
                                  : Colors.black,
                            ),
                            label: Text(
                              "All",
                              style: TextStyle(
                                color: _statusFilter == null ||
                                        _statusFilter!.isEmpty
                                    ? Colors.white
                                    : Colors.black,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: _filteredAppointments == null ||
                              _filteredAppointments!.isEmpty
                          ? const Center(child: Text('No appointments found'))
                          : ListView.builder(
                              itemCount: _getPaginatedAppointments().length,
                              itemBuilder: (context, index) {
                                return buildAppointmentCard(
                                    _getPaginatedAppointments()[index]);
                              },
                            ),
                    ),
                    if (_filteredAppointments != null &&
                        _filteredAppointments!.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.chevron_left),
                              onPressed:
                                  _currentPage > 0 ? _goToPreviousPage : null,
                              color:
                                  _currentPage > 0 ? Colors.black : Colors.grey,
                            ),
                            for (int i = 0;
                                i <
                                    (_filteredAppointments!.length /
                                            _itemsPerPage)
                                        .ceil();
                                i++)
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 4),
                                child: ElevatedButton(
                                  onPressed: () {
                                    setState(() {
                                      _currentPage = i;
                                    });
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: i == _currentPage
                                        ? const Color(0xFF4CAF93)
                                        : Colors.grey[200],
                                    foregroundColor: i == _currentPage
                                        ? Colors.white
                                        : Colors.black,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: Text('${i + 1}'),
                                ),
                              ),
                            IconButton(
                              icon: const Icon(Icons.chevron_right),
                              onPressed: _currentPage <
                                      (_filteredAppointments!.length /
                                                  _itemsPerPage)
                                              .ceil() -
                                          1
                                  ? _goToNextPage
                                  : null,
                              color: _currentPage <
                                      (_filteredAppointments!.length /
                                                  _itemsPerPage)
                                              .ceil() -
                                          1
                                  ? Colors.black
                                  : Colors.grey,
                            ),
                          ],
                        ),
                      )
                  ],
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) =>
                    const AppointmentPage()), // Replace with your page
          );
        },
        backgroundColor: const Color(0xFF4CAF93),
        child: const Icon(Icons.add),
      ),
    );
  }
}
