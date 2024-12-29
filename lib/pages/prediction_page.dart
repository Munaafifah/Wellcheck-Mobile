import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dropdown_search/dropdown_search.dart';
import '../services/prediction_service.dart';
import '../models/prediction_model.dart';

class PredictionPage extends StatefulWidget {
  const PredictionPage({super.key});

  @override
  _PredictionPageState createState() => _PredictionPageState();
}

class _PredictionPageState extends State<PredictionPage> {
  List<String> symptoms = [];
  bool isLoading = false;
  String result = "";

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  final List<String> symptomList = [
    "itching",
    "skin_rash",
    "nodal_skin_eruptions",
    "continuous_sneezing",
    "shivering",
    "chills",
    "joint_pain",
    "stomach_pain",
    "acidity",
    "ulcers_on_tongue",
    "muscle_wasting",
    "vomiting",
    "burning_micturition",
    "fatigue",
    "weight_gain",
    "anxiety",
    "cold_hands_and_feets",
    "mood_swings",
    "weight_loss",
    "restlessness",
    "lethargy",
    "patches_in_throat",
    "irregular_sugar_level",
    "cough",
    "high_fever",
    "sunken_eyes",
    "breathlessness",
    "sweating",
    "dehydration",
    "indigestion",
    "headache",
    "yellowish_skin",
    "dark_urine",
    "nausea",
    "loss_of_appetite",
    "pain_behind_the_eyes",
    "back_pain",
    "constipation",
    "abdominal_pain",
    "diarrhoea",
    "mild_fever",
    "yellow_urine",
    "yellowing_of_eyes",
    "acute_liver_failure",
    "fluid_overload",
    "swelling_of_stomach",
    "swelled_lymph_nodes",
    "malaise",
    "blurred_and_distorted_vision",
    "phlegm",
    "throat_irritation",
    "redness_of_eyes",
    "sinus_pressure",
    "runny_nose",
    "congestion",
    "chest_pain",
    "weakness_in_limbs",
    "fast_heart_rate",
    "pain_during_bowel_movements",
    "pain_in_anal_region",
    "bloody_stool",
    "irritation_in_anus",
    "neck_pain",
    "dizziness",
    "cramps",
    "bruising",
    "obesity",
    "swollen_legs",
    "swollen_blood_vessels",
    "puffy_face_and_eyes",
    "enlarged_thyroid",
    "brittle_nails",
    "swollen_extremeties",
    "excessive_hunger",
    "extra_marital_contacts",
    "drying_and_tingling_lips",
    "slurred_speech",
    "knee_pain",
    "hip_joint_pain",
    "muscle_weakness",
    "stiff_neck",
    "swelling_joints",
    "movement_stiffness",
    "spinning_movements",
    "loss_of_balance",
    "unsteadiness",
    "weakness_of_one_body_side",
    "loss_of_smell",
    "bladder_discomfort",
    "continuous_feel_of_urine",
    "passage_of_gases",
    "internal_itching",
    "toxic_look_(typhos)",
    "depression",
    "irritability",
    "muscle_pain",
    "altered_sensorium",
    "red_spots_over_body",
    "belly_pain",
    "abnormal_menstruation",
    "watering_from_eyes",
    "increased_appetite",
    "polyuria",
    "family_history",
    "mucoid_sputum",
    "rusty_sputum",
    "lack_of_concentration",
    "visual_disturbances",
    "receiving_blood_transfusion",
    "receiving_unsterile_injections",
    "coma",
    "stomach_bleeding",
    "distention_of_abdomen",
    "history_of_alcohol_consumption",
    "blood_in_sputum",
    "prominent_veins_on_calf",
    "palpitations",
    "painful_walking",
    "pus_filled_pimples",
    "blackheads",
    "scurring",
    "skin_peeling",
    "silver_like_dusting",
    "small_dents_in_nails",
    "inflammatory_nails",
    "blister",
    "red_sore_around_nose",
    "yellow_crust_ooze",
    "prognosis",
  ];

  void addSymptom(String symptom) {
    if (!symptoms.contains(symptom)) {
      setState(() {
        symptoms.add(symptom);
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("${formatSymptom(symptom)} is already added.")),
      );
    }
  }

  void removeSymptom(String symptom) {
    setState(() {
      symptoms.remove(symptom);
    });
  }

  Future<void> submitSymptoms() async {
    if (symptoms.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select at least one symptom")),
      );
      return;
    }

    setState(() {
      isLoading = true;
      result = "";
    });

    try {
      final token = await _storage.read(key: "auth_token");
      if (token != null) {
        final PredictionModel? prediction =
            await PredictionService().sendSymptoms(token, symptoms);

        if (prediction != null) {
          setState(() {
            result = prediction.diagnosisList
                .map((disease) => formatSymptom(disease))
                .join("\n");
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Symptoms submitted successfully.")),
          );
        } else {
          setState(() {
            result = "Prediction failed.";
          });
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Token not found. Please log in.")),
        );
      }
    } catch (e) {
      setState(() {
        result = "Error: $e";
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  /// Capitalizes the first letter of each word and replaces underscores with spaces
  String formatSymptom(String symptom) {
    return symptom
        .replaceAll('_', ' ') // Replace underscores
        .split(' ') // Split by spaces
        .map((word) => word[0].toUpperCase() + word.substring(1)) // Capitalize
        .join(' '); // Join back into a sentence
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF4CAF93),
              Color(0xFF379B7E),
              Color(0xFF1E7F68),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: 80),
            _buildHeader(),
            Expanded(child: _buildContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 10),
          const Text(
            "Add Symptom",
            style: TextStyle(color: Colors.white, fontSize: 30),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(40),
          topRight: Radius.circular(40),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Select Your Symptoms",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const Text(
            "You can add more than 1 symptom",
            style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
          ),
          const SizedBox(height: 20),
          _buildSymptomDropdown(),
          const SizedBox(height: 20),
          _buildSelectedSymptomsList(),
          const SizedBox(height: 20),
          _buildSubmitButton(),
        ],
      ),
    );
  }

  Widget _buildSymptomDropdown() {
    return DropdownSearch<String>(
      items: symptomList.map((s) => formatSymptom(s)).toList(),
      popupProps: const PopupProps.menu(
        showSearchBox: true,
      ),
      dropdownDecoratorProps: DropDownDecoratorProps(
        dropdownSearchDecoration: InputDecoration(
          labelText: "Symptoms",
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
      onChanged: (symptom) {
        if (symptom != null) {
          String originalSymptom = symptom.toLowerCase().replaceAll(' ', '_');
          addSymptom(originalSymptom);
        }
      },
    );
  }

  Widget _buildSelectedSymptomsList() {
    return Column(
      children: symptoms
          .map((symptom) => ListTile(
                title: Text(formatSymptom(symptom)),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _showDeleteConfirmation(symptom),
                ),
              ))
          .toList(),
    );
  }

  void _showDeleteConfirmation(String symptom) {
    String formattedSymptom = symptom
        .replaceAll('_', ' ') // Replace underscores with spaces
        .split(' ') // Split the string into words
        .map((word) =>
            word[0].toUpperCase() + word.substring(1)) // Capitalize each word
        .join(' '); // Join words back into a single string

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Confirm Deletion"),
          content: Text("Are you sure you want to delete '$formattedSymptom'?"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                removeSymptom(symptom);
                Navigator.of(context).pop(); // Close the dialog after deletion
              },
              child: const Text(
                "Delete",
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSubmitButton() {
    return isLoading
        ? const Center(
            child: CircularProgressIndicator(),
          )
        : ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4CAF93),
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            onPressed: () => _showSubmitConfirmation(),
            child: const Text(
              "Submit Symptoms",
              style: TextStyle(fontSize: 18, color: Colors.white),
            ),
          );
  }

  void _showSubmitConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Confirm Submission"),
          content:
              const Text("Are you sure you want to submit these symptoms?"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
              },
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                submitSymptoms();
                Navigator.of(context).pop(); // Close dialog after submission
              },
              child: const Text(
                "Submit",
                style: TextStyle(color: Colors.green),
              ),
            ),
          ],
        );
      },
    );
  }
}
