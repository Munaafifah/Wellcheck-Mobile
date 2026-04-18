import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import '../services/appointment_service.dart';
import '../services/availability_service.dart';
import '../services/sickness_service.dart';
import '../services/hospital_service.dart';
import '../models/sickness_model.dart';
import '../models/hospital_model.dart';
import '../models/appointment_model.dart';

class AppointmentPage extends StatefulWidget {
  const AppointmentPage({super.key});

  @override
  _AppointmentPageState createState() => _AppointmentPageState();
}

class _AppointmentPageState extends State<AppointmentPage> {
  late Future<List<Hospital>> futureHospitals;
  final SicknessService _sicknessService = SicknessService();
  late Future<List<Sickness>> futureSicknesses;

  @override
  void initState() {
    super.initState();
    futureHospitals = HospitalService().fetchHospitals();
    futureSicknesses = _sicknessService.fetchSicknesses();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF4CAF93),
        title: const Text(
          'Select Hospital',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF4CAF93).withOpacity(0.1),
              Colors.white,
            ],
          ),
        ),
        child: FutureBuilder<List<Hospital>>(
          future: futureHospitals,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                  child: CircularProgressIndicator(color: Color(0xFF4CAF93)));
            } else if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline,
                        color: Colors.red, size: 60),
                    const SizedBox(height: 16),
                    Text('Error: ${snapshot.error}',
                        style: const TextStyle(color: Colors.red)),
                  ],
                ),
              );
            }

            List<Hospital> hospitals = snapshot.data!;
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: ListView.builder(
                itemCount: hospitals.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15)),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(15),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AppointmentFormScreen(
                                hospital: hospitals[index],
                                futureSicknesses: futureSicknesses,
                              ),
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  color:
                                      const Color(0xFF4CAF93).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.local_hospital,
                                    color: Color(0xFF4CAF93), size: 30),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(hospitals[index].name,
                                        style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 4),
                                    const Text('Tap to book appointment',
                                        style: TextStyle(
                                            color: Colors.grey, fontSize: 14)),
                                  ],
                                ),
                              ),
                              const Icon(Icons.arrow_forward_ios,
                                  color: Color(0xFF4CAF93), size: 20),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  APPOINTMENT FORM SCREEN
// ─────────────────────────────────────────────

class AppointmentFormScreen extends StatefulWidget {
  final Hospital hospital;
  final Future<List<Sickness>> futureSicknesses;

  const AppointmentFormScreen({
    super.key,
    required this.hospital,
    required this.futureSicknesses,
  });

  @override
  _AppointmentFormScreenState createState() => _AppointmentFormScreenState();
}

class _AppointmentFormScreenState extends State<AppointmentFormScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _additionalNotesController =
      TextEditingController();
  final TextEditingController _insuranceProviderController =
      TextEditingController();
  final TextEditingController _insurancePolicyNumberController =
      TextEditingController();
  final TextEditingController _sicknessSearchController =
      TextEditingController();

  final AppointmentService _appointmentService = AppointmentService();
  final AvailabilityService _availabilityService = AvailabilityService();
  final SicknessService _sicknessService = SicknessService();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // Doctor picker
  List<Map<String, dynamic>> _doctors = [];
  Map<String, dynamic>? _selectedDoctor;

  // Date & slots
  DateTime? _selectedDate;
  String? _selectedTimeSlot;
  List<Map<String, dynamic>> _slots = [];
  bool _loadingSlots = false;
  bool _isWorkingDay = true;

  // Sickness
  List<Sickness> _sicknesses = [];
  List<Sickness> _filteredSicknesses = [];
  final List<String> _selectedSicknessTypes = [];
  bool _showSicknessList = false;

  // Form
  bool _isLoading = false;
  String? _selectedDuration;
  final List<String> _durations = ['30 mins', '1 hour', '1.5 hours', '2 hours'];

  String get hospitalId => widget.hospital.hospitalId;

  @override
  void initState() {
    super.initState();
    _loadDoctors();
    _loadSicknesses();
    _sicknessSearchController.addListener(_filterSicknesses);
  }

  @override
  void dispose() {
    _sicknessSearchController.dispose();
    super.dispose();
  }

  Future<void> _loadDoctors() async {
    try {
      final token = await _storage.read(key: "auth_token");
      if (token == null) return;
      final doctors = await _availabilityService.fetchDoctors(token);
      setState(() => _doctors = doctors);
    } catch (e) {
      debugPrint("Error loading doctors: $e");
    }
  }

  Future<void> _loadSicknesses() async {
    try {
      final list = await _sicknessService.fetchSicknesses();
      setState(() {
        _sicknesses = list;
        _filteredSicknesses = list;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load sickness types: $e')),
      );
    }
  }

  void _filterSicknesses() {
    final query = _sicknessSearchController.text.toLowerCase();
    setState(() {
      _filteredSicknesses = _sicknesses
          .where((s) => s.name.toLowerCase().contains(query))
          .toList();
    });
  }

  void _addSickness(Sickness sickness) {
    if (!_selectedSicknessTypes.contains(sickness.name)) {
      setState(() {
        _selectedSicknessTypes.add(sickness.name);
        _sicknessSearchController.clear();
        _showSicknessList = false;
      });
    }
  }

  void _removeSickness(String name) {
    setState(() {
      _selectedSicknessTypes.remove(name);
    });
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 60)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: Color(0xFF4CAF93)),
        ),
        child: child!,
      ),
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _selectedTimeSlot = null;
        _slots = [];
      });
      await _loadSlots(picked);
    }
  }

  Future<void> _loadSlots(DateTime date) async {
    if (_selectedDoctor == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a doctor first')),
      );
      return;
    }
    setState(() => _loadingSlots = true);
    try {
      final token = await _storage.read(key: "auth_token");
      if (token == null) return;
      final dateStr = DateFormat('yyyy-MM-dd').format(date);
      final result = await _availabilityService.fetchAvailability(
        token,
        _selectedDoctor!['doctorId'],
        dateStr,
      );
      setState(() {
        _isWorkingDay = result['isWorkingDay'] ?? false;
        _slots = _isWorkingDay
            ? List<Map<String, dynamic>>.from(result['slots'])
            : [];
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load slots: $e')),
      );
    } finally {
      setState(() => _loadingSlots = false);
    }
  }

  Future<void> _submitAppointment() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDoctor == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a doctor')));
      return;
    }
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Please select a date')));
      return;
    }
    if (_selectedTimeSlot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a time slot')));
      return;
    }
    if (_selectedSicknessTypes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Please select at least one sickness type')));
      return;
    }
    if (_selectedDuration == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a duration')));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final token = await _storage.read(key: "auth_token");
      if (token == null) return;

      final timeParts = _selectedTimeSlot!.split(":");
      final selectedTime = TimeOfDay(
        hour: int.parse(timeParts[0]),
        minute: int.parse(timeParts[1]),
      );

      await _appointmentService.createAppointment(
        token: token,
        appointmentDate: _selectedDate!,
        appointmentTime: selectedTime,
        duration: _selectedDuration!,
        typeOfSickness: _selectedSicknessTypes.join(', '),
        additionalNotes: _additionalNotesController.text,
        email: _emailController.text,
        hospitalId: hospitalId,
        registeredHospital: widget.hospital.name,
        appointmentCost: 0.0,
        statusPayment: "Not Paid",
        statusAppointment: "Not Approved",
        insuranceProvider: _insuranceProviderController.text,
        insurancePolicyNumber: _insurancePolicyNumberController.text,
      );

      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Appointment booked successfully!')));
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF4CAF93),
        title: Text(
          'Book at ${widget.hospital.name}',
          style:
              const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF4CAF93).withOpacity(0.1),
              Colors.white,
            ],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Card(
            elevation: 8,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Appointment Details',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF4CAF93),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ── Doctor Picker ──────────────────────────
                    _sectionLabel("Select Doctor"),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<Map<String, dynamic>>(
                      value: _selectedDoctor,
                      decoration:
                          _inputDecoration("Choose a doctor", Icons.person),
                      hint: const Text("Choose a doctor"),
                      items: _doctors.map((doc) {
                        return DropdownMenuItem(
                          value: doc,
                          child: Text(doc['doctorName'] ?? doc['doctorId']),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setState(() {
                          _selectedDoctor = val;
                          _selectedDate = null;
                          _selectedTimeSlot = null;
                          _slots = [];
                        });
                      },
                      validator: (val) =>
                          val == null ? 'Please select a doctor' : null,
                    ),
                    const SizedBox(height: 20),

                    // ── Date Picker ────────────────────────────
                    _sectionLabel("Select Date"),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: _pickDate,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 14),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade400),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today,
                                color: Color(0xFF4CAF93)),
                            const SizedBox(width: 12),
                            Text(
                              _selectedDate != null
                                  ? DateFormat('EEEE, dd MMM yyyy')
                                      .format(_selectedDate!)
                                  : 'Tap to select date',
                              style: TextStyle(
                                color: _selectedDate != null
                                    ? Colors.black87
                                    : Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── Time Slot Grid ─────────────────────────
                    if (_selectedDate != null) ...[
                      _sectionLabel("Select Time Slot"),
                      const SizedBox(height: 8),
                      if (_loadingSlots)
                        const Center(
                            child: CircularProgressIndicator(
                                color: Color(0xFF4CAF93)))
                      else if (!_isWorkingDay)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.orange.shade200),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.info_outline, color: Colors.orange),
                              SizedBox(width: 8),
                              Text("Doctor is not available on this day",
                                  style: TextStyle(color: Colors.orange)),
                            ],
                          ),
                        )
                      else if (_slots.isEmpty)
                        const Text("No slots available",
                            style: TextStyle(color: Colors.grey))
                      else
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 4,
                            childAspectRatio: 2.2,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                          ),
                          itemCount: _slots.length,
                          itemBuilder: (context, index) {
                            final slot = _slots[index];
                            final time = slot['time'] as String;
                            final available = slot['available'] as bool;
                            final isSelected = _selectedTimeSlot == time;

                            return GestureDetector(
                              onTap: available
                                  ? () =>
                                      setState(() => _selectedTimeSlot = time)
                                  : null,
                              child: Container(
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: !available
                                      ? Colors.grey.shade200
                                      : isSelected
                                          ? const Color(0xFF4CAF93)
                                          : Colors.white,
                                  border: Border.all(
                                    color: !available
                                        ? Colors.grey.shade300
                                        : isSelected
                                            ? const Color(0xFF4CAF93)
                                            : const Color(0xFF4CAF93)
                                                .withOpacity(0.5),
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  time,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: !available
                                        ? Colors.grey.shade400
                                        : isSelected
                                            ? Colors.white
                                            : const Color(0xFF4CAF93),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      if (_slots.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _legendDot(const Color(0xFF4CAF93), "Available"),
                            const SizedBox(width: 16),
                            _legendDot(Colors.grey.shade300, "Booked"),
                          ],
                        ),
                      ],
                      const SizedBox(height: 20),
                    ],

                    // ── Type of Sickness ───────────────────────
                    _sectionLabel("Type of Sickness"),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _sicknessSearchController,
                      decoration: _inputDecoration(
                          "Search sickness type...", Icons.search),
                      onTap: () => setState(() => _showSicknessList = true),
                      validator: (_) => _selectedSicknessTypes.isEmpty
                          ? 'Please select at least one sickness type'
                          : null,
                    ),

                    // Scrollable dropdown list
                    if (_showSicknessList && _filteredSicknesses.isNotEmpty)
                      Container(
                        constraints: const BoxConstraints(maxHeight: 200),
                        margin: const EdgeInsets.only(top: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: _filteredSicknesses.length,
                          itemBuilder: (context, index) {
                            final sickness = _filteredSicknesses[index];
                            final alreadySelected =
                                _selectedSicknessTypes.contains(sickness.name);
                            return ListTile(
                              dense: true,
                              title: Text(sickness.name),
                              trailing: alreadySelected
                                  ? const Icon(Icons.check,
                                      color: Color(0xFF4CAF93), size: 18)
                                  : null,
                              onTap: alreadySelected
                                  ? null
                                  : () => _addSickness(sickness),
                            );
                          },
                        ),
                      ),

                    const SizedBox(height: 12),

                    // Selected sickness list
                    if (_selectedSicknessTypes.isNotEmpty) ...[
                      const Text(
                        'Selected:',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const SizedBox(height: 8),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _selectedSicknessTypes.length,
                        itemBuilder: (context, index) {
                          return ListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            title: Text(_selectedSicknessTypes[index]),
                            trailing: IconButton(
                              icon: const Icon(Icons.remove_circle,
                                  color: Colors.red, size: 20),
                              onPressed: () => _removeSickness(
                                  _selectedSicknessTypes[index]),
                            ),
                          );
                        },
                      ),
                    ],
                    const SizedBox(height: 20),

                    // ── Duration ───────────────────────────────
                    _sectionLabel("Duration"),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedDuration,
                      decoration:
                          _inputDecoration("Select duration", Icons.timer),
                      hint: const Text("Select duration"),
                      items: _durations
                          .map(
                              (d) => DropdownMenuItem(value: d, child: Text(d)))
                          .toList(),
                      onChanged: (val) =>
                          setState(() => _selectedDuration = val),
                      validator: (val) =>
                          val == null ? 'Please select duration' : null,
                    ),
                    const SizedBox(height: 20),

                    // ── Email ──────────────────────────────────
                    _sectionLabel("Email"),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _emailController,
                      decoration:
                          _inputDecoration("Email address", Icons.email),
                      keyboardType: TextInputType.emailAddress,
                      validator: (val) => val == null || val.isEmpty
                          ? 'Email is required'
                          : null,
                    ),
                    const SizedBox(height: 20),

                    // ── Additional Notes ───────────────────────
                    _sectionLabel("Additional Notes (optional)"),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _additionalNotesController,
                      decoration: _inputDecoration(
                          "Any notes for the doctor", Icons.notes),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 20),

                    // ── Insurance ──────────────────────────────
                    _sectionLabel("Insurance Provider (optional)"),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _insuranceProviderController,
                      decoration: _inputDecoration(
                          "Insurance provider", Icons.health_and_safety),
                    ),
                    const SizedBox(height: 12),
                    _sectionLabel("Insurance Policy Number (optional)"),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _insurancePolicyNumberController,
                      decoration:
                          _inputDecoration("Policy number", Icons.numbers),
                    ),
                    const SizedBox(height: 32),

                    // ── Submit Button ──────────────────────────
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _submitAppointment,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4CAF93),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          elevation: 4,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2),
                              )
                            : const Text(
                                'Book Appointment',
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────

  Widget _sectionLabel(String text) => Text(
        text,
        style: const TextStyle(
            fontWeight: FontWeight.w600, fontSize: 14, color: Colors.black87),
      );

  InputDecoration _inputDecoration(String hint, IconData icon) =>
      InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: const Color(0xFF4CAF93)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF4CAF93)),
        ),
      );

  Widget _legendDot(Color color, String label) => Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
                color: color, borderRadius: BorderRadius.circular(3)),
          ),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      );
}
