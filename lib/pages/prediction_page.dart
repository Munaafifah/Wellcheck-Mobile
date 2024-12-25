// prediction2_page.dart (Updated UI to Reflect New Flow)
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/material.dart';
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

  // Initialize FlutterSecureStorage
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
    if (!symptoms.contains(symptom) && symptoms.length < 5) {
      setState(() {
        symptoms.add(symptom);
      });
    }
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
                .asMap()
                .entries
                .map(
                  (e) => "${e.value}", // Keep the diagnosis as-is
                )
                .join("\n");
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Prediction successful")),
          );
        } else {
          setState(() {
            result = "Prediction failed.";
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Prediction failed")),
          );
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Disease Prediction")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            DropdownButton<String>(
              value: symptoms.isEmpty ? null : symptoms.last,
              hint: const Text("Select a Symptom"),
              isExpanded: true,
              onChanged: (value) {
                if (value != null) {
                  addSymptom(value);
                }
              },
              items: symptomList
                  .map((symptom) => DropdownMenuItem(
                        value: symptom,
                        child: Text(symptom),
                      ))
                  .toList(),
            ),
            Wrap(
              children: symptoms.map((s) => Chip(label: Text(s))).toList(),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: isLoading ? null : submitSymptoms,
              child: Text(isLoading ? "Processing..." : "Submit"),
            ),
            if (result.isNotEmpty) ...[
              const SizedBox(height: 20),
              Text(result, style: const TextStyle(fontSize: 16)),
            ],
          ],
        ),
      ),
    );
  }
}
