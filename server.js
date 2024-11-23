const express = require('express');
const { MongoClient } = require('mongodb');
const cors = require('cors');
require('dotenv').config();
const mongoose = require("mongoose");


const app = express();
app.use(cors());
app.use(express.json()); // Middleware to parse JSON bodies

const uri = process.env.MONGO_URI;
const client = new MongoClient(uri);

// Define Patient schema
const PatientSchema = new mongoose.Schema({
  _id: String,
  name: String,
  address: String,
  contact: String,
  emergencyContact: String,
  assigned_doctor: String,
  sensorDataId: String,
  status: String,
  prescriptions: [
    {
      prescriptionId: String,
      diagnosisAilmentDescription: String,
      prescriptionDescription: String,
      doctorId: String,
      timestamp: String,
      medicineList: [
        {
          name: String,
          dosage: String,
        },
      ],
    },
  ],
  healthStatus: [
    {
      healthStatusId: String,
      doctorId: String,
      additionalNotes: String,
      timestamp: String,
    },
  ],
});

// Create Patient model
const Patient = mongoose.model("Patient", PatientSchema);

// Endpoint to get a patient by ID
app.get("/patients/:id", async (req, res) => {
  const patientId = req.params._id; // Correct the parameter to use 'id'
  const dbName = "test2"; // Specify the database name
  const collectionName = "users"; // Specify the collection name

  try {
    const client = new MongoClient(uri);
    await client.connect(); // Connect to MongoDB
    const database = client.db(test2); // Use the 'wellcheck' database
    const collection = database.collection(users); // Access 'patients' collection

    const patient = await collection.findOne({ _id: patientId }); // Query by patient ID

    if (!patient) {
      return res.status(404).json({ message: "Patient not found" });
    }

    res.json(patient); // Return the patient data
  } catch (error) {
    console.error("Error fetching patient:", error);
    res.status(500).json({ message: "Internal server error" });
  }
});

// Endpoint to get all prescriptions for a specific patient
app.get("/patients/:id/prescriptions", async (req, res) => {
  const patientId = req.params.id; // Correct the parameter to use 'id'
  const dbName = "test2"; // Specify the database name
  const collectionName = "patients"; // Specify the collection name

  try {
    const client = new MongoClient(uri);
    await client.connect(); // Connect to MongoDB
    const database = client.db(test2); // Use the 'wellcheck' database
    const collection = database.collection(patients); // Access 'patients' collection

    const patient = await collection.findOne({ _id: patientId }, { projection: { prescriptions: 1 } }); // Fetch prescriptions only

    if (!patient || !patient.prescriptions) {
      return res.status(404).json({ message: "Prescriptions not found for this patient" });
    }

    res.json(patient.prescriptions); // Return the prescriptions
  } catch (error) {
    console.error("Error fetching prescriptions:", error);
    res.status(500).json({ message: "Internal server error" });
  }
});


// New endpoint to handle symptom submissions
app.post('/symptoms', async (req, res) => {
  try {
    await client.connect();
    const database = client.db('test');
    const symptomsCollection = database.collection('symptoms');

    const { symptom } = req.body;
    if (!symptom || symptom.trim() === '') {
      return res.status(400).json({ error: 'Symptom description is required' });
    }

    // Save the symptom to the database
    const newSymptom = { description: symptom, createdAt: new Date() };
    await symptomsCollection.insertOne(newSymptom);

    res.status(200).json({ message: 'Symptom saved successfully' });
  } catch (error) {
    console.error('Error saving symptom:', error);
    res.status(500).json({ error: 'Error saving symptom' });
  } finally {
    await client.close();
  }
});

const PORT = process.env.PORT || 5000;
app.listen(PORT, () => {
  console.log(`Server is running on port ${PORT}`);
});

//Appointments
// Endpoint to fetch appointments
app.get('/appointments', async (req, res) => {
  try {
    await client.connect();
    const database = client.db('test');
    const appointmentsCollection = database.collection('appointments');

    // Fetch all appointments from the database
    const appointments = await appointmentsCollection.find().toArray();
    if (appointments.length === 0) {
      return res.status(404).json({ error: 'No appointments found' });
    }

    // Map the appointments data to the desired response format
    const response = appointments.map(appointment => ({
      appointmentDateTime: new Date(`${appointment.appointmentDate}T${appointment.appointmentTime}:00Z`), // Combine date and time
      duration: appointment.duration,
      typeOfSickness: appointment.typeOfSickness,
      additionalNotes: appointment.additionalNotes,
      createdAt: appointment.createdAt
    }));

    res.json(response);
  } catch (error) {
    console.error('Error fetching appointments:', error);
    res.status(500).json({ error: 'Error fetching appointments' });
  } finally {
    await client.close();
  }
});

// Endpoint for adding a new appointment
app.post('/appointments', async (req, res) => {
  try {
    console.log("Incoming Request Body:", req.body); // Debug request body
    await client.connect();
    console.log("Connected to MongoDB for appointments.");

    const database = client.db('test'); // Replace 'test' with your DB name
    const appointmentsCollection = database.collection('appointments');

    const { appointmentDate, appointmentTime, duration, typeOfSickness, additionalNotes } = req.body;

    // Validate required fields
    if (!appointmentDate || !appointmentTime || !duration || !typeOfSickness) {
      console.log("Validation Error: Missing required fields");
      return res.status(400).json({ message: 'Missing required fields' });
    }

    // Convert duration to minutes
    const durationMinutes = parseInt(duration.replace(/[^\d]/g, ''), 10); // Extracts numeric value from duration string
    if (isNaN(durationMinutes)) {
      console.log("Validation Error: Invalid duration format");
      return res.status(400).json({ message: 'Invalid duration format' });
    }

    // Calculate cost based on duration
    const appointmentCost = durationMinutes * 1; // RM1 per minute

    // Combine appointmentDate and appointmentTime into a single Date object
    const appointmentDateTime = new Date(`${appointmentDate}T${appointmentTime}:00Z`);

    // Prepare the new appointment object
    const newAppointment = {
      appointmentDate,             // Appointment date
      appointmentTime,             // Appointment time
      duration,                   // Appointment duration
      typeOfSickness,             // Type of sickness
      additionalNotes: additionalNotes || '', // Additional notes (optional)
      appointmentDateTime,        // Full datetime for convenience
      appointmentCost,            // Include calculated cost
      createdAt: new Date(),      // Timestamp for when the appointment was created
    };

    console.log("New Appointment Object:", newAppointment); // Debug the object

    // Insert the appointment into the database
    const result = await appointmentsCollection.insertOne(newAppointment);

    console.log("Insert Result:", result); // Debug insertion result

    // Respond with success
    res.status(201).json({
      message: 'Appointment created successfully',
      appointmentId: result.insertedId,
      cost: appointmentCost, // Include the calculated cost in the response
    });
  } catch (error) {
    console.error("Error in /appointments endpoint:", error.message);
    res.status(500).json({
      message: 'Internal server error',
      error: error.message,
    });
  } finally {
    await client.close();
    console.log("Connection to MongoDB closed.");
  }
});

// Endpoint to update symptoms
app.put('/symptoms/:id', async (req, res) => {
  try {
    await client.connect();
    const database = client.db('test');
    const symptomsCollection = database.collection('symptoms');

    const { id } = req.params;
    const { description } = req.body;

    if (!description || description.trim() === '') {
      return res.status(400).json({ error: 'Description is required' });
    }

    const result = await symptomsCollection.updateOne(
      { _id: new MongoClient.ObjectId(id) },
      { $set: { description } }
    );

    if (result.matchedCount === 0) {
      return res.status(404).json({ error: 'Symptom not found' });
    }

    res.status(200).json({ message: 'Symptom updated successfully' });
  } catch (error) {
    console.error('Error updating symptom:', error);
    res.status(500).json({ error: 'Error updating symptom' });
  } finally {
    await client.close();
  }
});

// Endpoint to delete symptoms
app.delete('/symptoms/:id', async (req, res) => {
  try {
    await client.connect();
    const database = client.db('test');
    const symptomsCollection = database.collection('symptoms');

    const { id } = req.params;

    const result = await symptomsCollection.deleteOne({
      _id: new MongoClient.ObjectId(id),
    });

    if (result.deletedCount === 0) {
      return res.status(404).json({ error: 'Symptom not found' });
    }

    res.status(200).json({ message: 'Symptom deleted successfully' });
  } catch (error) {
    console.error('Error deleting symptom:', error);
    res.status(500).json({ error: 'Error deleting symptom' });
  } finally {
    await client.close();
  }
});


// New endpoint to login system
app.post('/login', async (req, res) => {
  try {
    await client.connect();
    const database = client.db('test2'); // Use the correct database name as shown in the image
    const usersCollection = database.collection('users');

    const { userId, password } = req.body; // Adjust field names to match the new structure

    if (!userId || !password) {
      return res.status(400).json({
        error: 'User ID and password are required',
      });
    }

    // Find the user in the database
    const user = await usersCollection.findOne({
      userId,
      password, // Note: In production, use proper password hashing
    });

    if (!user) {
      return res.status(401).json({
        error: 'Invalid user ID or password',
      });
    }

    // Check if user is a patient (trim to handle extra spaces)
    if (user.role.trim().toLowerCase() !== 'patient') {
      return res.status(403).json({
        error: 'Access denied: Only patients can login through this portal',
      });
    }

    // Success: Return user details
    res.status(200).json({
      message: 'Login successful',
      user: {
        userId: user.userId,
        name: user.name,
        contact: user.contact, // Include contact if needed
        role: user.role.trim(),
      },
    });

  } catch (error) {
    console.error('Error during login:', error);
    res.status(500).json({ error: 'Internal server error' });
  } finally {
    await client.close();
  }
});


app.get('/symptoms', async (req, res) => {
  try {
    await client.connect();
    const database = client.db('test');
    const symptomsCollection = database.collection('symptoms');

    const symptoms = await symptomsCollection.find().toArray();
    res.status(200).json(symptoms);
  } catch (error) {
    console.error('Error fetching symptoms:', error);
    res.status(500).json({ error: 'Error fetching symptoms' });
  } finally {
    await client.close();
  }
});

app.put('/symptoms/:id', async (req, res) => {
  try {
    await client.connect();
    const database = client.db('test');
    const symptomsCollection = database.collection('symptoms');

    const { id } = req.params;
    const { description } = req.body;

    if (!description || description.trim() === '') {
      return res.status(400).json({ error: 'Description is required' });
    }

    const result = await symptomsCollection.updateOne(
      { _id: new MongoClient.ObjectId(id) },
      { $set: { description } }
    );

    if (result.matchedCount === 0) {
      return res.status(404).json({ error: 'Symptom not found' });
    }

    res.status(200).json({ message: 'Symptom updated successfully' });
  } catch (error) {
    console.error('Error updating symptom:', error);
    res.status(500).json({ error: 'Error updating symptom' });
  } finally {
    await client.close();
  }
});

app.delete('/symptoms/:id', async (req, res) => {
  try {
    await client.connect();
    const database = client.db('test');
    const symptomsCollection = database.collection('symptoms');

    const { id } = req.params;

    const result = await symptomsCollection.deleteOne({
      _id: new MongoClient.ObjectId(id),
    });

    if (result.deletedCount === 0) {
      return res.status(404).json({ error: 'Symptom not found' });
    }

    res.status(200).json({ message: 'Symptom deleted successfully' });
  } catch (error) {
    console.error('Error deleting symptom:', error);
    res.status(500).json({ error: 'Error deleting symptom' });
  } finally {
    await client.close();
  }
});




