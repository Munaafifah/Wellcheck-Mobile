import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/appointment_service.dart';
import '../models/appointment_model.dart';
import '../pages/appointment_page.dart';
import '../pages/editAppointment_page.dart';

class ViewAppointmentsPage extends StatefulWidget {
  final String userId;
  final bool showPastAppointments;

  const ViewAppointmentsPage(
      {super.key, required this.userId, this.showPastAppointments = false});

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
  String? _selectedHospital;
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

        // Filter for past or upcoming appointments based on widget parameter
        final filteredAppointments = appointments.where((appointment) {
          return widget.showPastAppointments
              ? appointment.appointmentDate.isBefore(DateTime.now())
              : appointment.appointmentDate.isAfter(DateTime.now());
        }).toList();

        // Sort appointments by date
        filteredAppointments
            .sort((a, b) => a.appointmentDate.compareTo(b.appointmentDate));

        setState(() {
          _appointments = filteredAppointments;
          _filteredAppointments = filteredAppointments;
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

  void _filterAppointments({String? month, String? status, String? hospital}) {
    setState(() {
      if (_appointments == null) return;

      _filteredAppointments = List.from(_appointments!);

      // Filter by status if selected
      if (_statusFilter != null && _statusFilter!.isNotEmpty) {
        _filteredAppointments = _filteredAppointments!.where((appointment) {
          return appointment.statusAppointment == _statusFilter;
        }).toList();
      }

      // Filter by hospital if a specific hospital is selected
      if (_selectedHospital != null && _selectedHospital!.isNotEmpty) {
        _filteredAppointments = _filteredAppointments!.where((appointment) {
          return appointment.registeredHospital == _selectedHospital;
        }).toList();
      }

      // Filter by month if selected
      if (_selectedMonth != null && _selectedMonth!.isNotEmpty) {
        _filteredAppointments = _filteredAppointments!.where((appointment) {
          return appointment.appointmentDate.month.toString() == _selectedMonth;
        }).toList();
      }

      // Reset to the first page when filters are applied
      _currentPage = 0;
    });
  }

  // Helper method to get unique hospitals from appointments
  List<String> _getUniqueHospitals() {
    if (_appointments == null) return [];
    return _appointments!
        .map((appointment) => appointment.registeredHospital)
        .toSet()
        .toList();
  }

  void _updateStatusFilter(String status) {
    setState(() {
      _statusFilter = status;
    });
    _filterAppointments(status: status);
  }

  Future<void> _deleteAppointment(String appointmentId) async {
    // Show a confirmation dialog before deleting
    bool? confirmDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirm Deletion"),
        content:
            const Text("Are you sure you want to delete this appointment?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    // Only proceed with deletion if user confirms
    if (confirmDelete == true) {
      try {
        final token = await _storage.read(key: "auth_token");
        if (token != null) {
          await _appointmentService.deleteAppointment(token, appointmentId);
          _fetchAppointments(); // Refresh the list after deletion

          // Show a success snackbar
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Appointment deleted successfully"),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to delete appointment: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
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

  // Helper method to create consistent table rows
  TableRow _buildTableRow(String label, String value) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(value),
        ),
      ],
    );
  }

  Widget buildAppointmentCard(Appointment appointment) {
    TableRow buildTableRow(String label, String value,
        {Color textColor = Colors.black}) {
      return TableRow(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              value,
              style: TextStyle(color: textColor),
            ),
          ),
        ],
      );
    }

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
              const Text(
                "Status: ",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                appointment.statusAppointment,
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
                      child: Table(
                        columnWidths: const {
                          0: FlexColumnWidth(1),
                          1: FlexColumnWidth(2),
                        },
                        border: TableBorder.all(color: Colors.grey.shade300),
                        children: [
                          TableRow(
                            decoration:
                                BoxDecoration(color: Colors.grey.shade100),
                            children: [
                              const Padding(
                                padding: EdgeInsets.all(8.0),
                                child: Text(
                                  "Status",
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  appointment.statusAppointment,
                                  style: TextStyle(
                                    color: appointment.statusAppointment ==
                                            "Approved"
                                        ? Colors.green
                                        : Colors.red,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          // Conditional Attributes
                          if (appointment.userId.isNotEmpty)
                            buildTableRow("User ID", appointment.userId),

                          if (appointment.hospitalId.isNotEmpty)
                            buildTableRow(
                                "Hospital ID", appointment.hospitalId),

                          if (appointment.doctorId.isNotEmpty)
                            buildTableRow("Doctor ID", appointment.doctorId),

                          if (appointment.email.isNotEmpty)
                            buildTableRow("Email", appointment.email),
                          // Date and Time Information
                          buildTableRow("Date", appointment.getFormattedDate()),
                          buildTableRow("Time", appointment.getFormattedTime()),
                          buildTableRow(
                              "Duration", "${appointment.duration} mins"),

                          if (appointment.typeOfSickness.isNotEmpty)
                            buildTableRow(
                                "Type of Sickness", appointment.typeOfSickness),

                          if (appointment.additionalNotes.isNotEmpty)
                            buildTableRow("Additional Notes",
                                appointment.additionalNotes),

                          if (appointment.statusPayment.isNotEmpty)
                            buildTableRow(
                                "Payment Status", appointment.statusPayment),

                          if (appointment.insuranceProvider?.isNotEmpty ??
                              false)
                            buildTableRow("Insurance Provider",
                                appointment.insuranceProvider!),

                          if (appointment.insurancePolicyNumber?.isNotEmpty ??
                              false)
                            buildTableRow(
                              "Insurance Policy Number",
                              appointment.insurancePolicyNumber!,
                            ),

                          if (appointment.preferredLanguage?.isNotEmpty ??
                              false)
                            buildTableRow("Preferred Language",
                                appointment.preferredLanguage!),

                          buildTableRow("Cost",
                              "RM${appointment.appointmentCost.toStringAsFixed(2)}"),
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
            if (appointment.statusAppointment != "Approved") ...[
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.orange),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditAppointmentPage(appointment: appointment),
                  ),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _deleteAppointment(appointment.appointmentId),
            ),
          ],
        ],
      ),
    ),
  );
}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.showPastAppointments
            ? "Past Appointments"
            : "Upcoming Appointments"),
        backgroundColor: const Color(0xFF4CAF93),
        actions: [
          IconButton(
            icon: Icon(
              widget.showPastAppointments
                  ? Icons.calendar_today // Show upcoming icon when in past view
                  : Icons.history, // Show history icon when in upcoming view
              color: Colors.white,
            ),
            tooltip: widget.showPastAppointments
                ? "View Upcoming Appointments"
                : "View Past Appointments",
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => ViewAppointmentsPage(
                    userId: widget.userId,
                    showPastAppointments: !widget.showPastAppointments,
                  ),
                ),
              );
            },
          ),
        ],
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
                        value:
                            _selectedHospital == "" ? null : _selectedHospital,
                        items: [
                          const DropdownMenuItem<String>(
                              value: null, // Change from empty string to null
                              child: Text("All Hospitals")),
                          ..._getUniqueHospitals().map((hospital) {
                            return DropdownMenuItem(
                              value: hospital,
                              child: Text(hospital),
                            );
                          }),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedHospital = value ?? ""; // Handle null case
                          });
                          _filterAppointments();
                        },
                        decoration: InputDecoration(
                          labelText: "Filter by Hospital",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
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
                            month: value,
                            status: _statusFilter,
                            hospital: _selectedHospital,
                          );
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
                              _filterAppointments();
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
                              _filterAppointments();
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
                              _filterAppointments();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _statusFilter == null
                                  ? const Color(0xFF4CAF93)
                                  : Colors.grey[300],
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(
                                  vertical: 12, horizontal: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                              elevation: _statusFilter == null ? 6 : 2,
                            ),
                            icon: Icon(
                              Icons.all_inclusive,
                              color: _statusFilter == null
                                  ? Colors.white
                                  : Colors.black,
                            ),
                            label: Text(
                              "All",
                              style: TextStyle(
                                color: _statusFilter == null
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
