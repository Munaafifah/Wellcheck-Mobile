const express = require('express');
const { MongoClient } = require('mongodb');
const cors = require('cors');
require('dotenv').config();

const app = express();
app.use(cors());
app.use(express.json()); // Middleware to parse JSON bodies

const uri = process.env.MONGO_URI;
const client = new MongoClient(uri);

app.get('/prescriptions', async (req, res) => {
  try {
    await client.connect();
    const database = client.db('test');
    const prescriptionsCollection = database.collection('prescriptions');
    const doctorsCollection = database.collection('doctors');

    // Fetch a prescription
    const prescription = await prescriptionsCollection.findOne({ iddoc: "2" });
    if (!prescription) {
      return res.status(404).json({ error: 'Prescription not found' });
    }
    const doctor = await doctorsCollection.findOne({ iddoc: "2" });
    if (!doctor) {
      return res.status(404).json({ error: 'Doctor not found' });
    }

    // Combine data from both collections
    const response = {
      doctorName: doctor.doctorName ,
      doctorSpecialty: doctor ? doctor.doctorSpecialty : 'Unknown',
      patientName: prescription.patientName,
      medicationsList: prescription.medicationsList,
      diagnosis: prescription.diagnosis,
      notes: prescription.notes,
      time: prescription.time,
      iddoc: prescription.iddoc,
    };

    res.json(response);
  } catch (error) {
    console.error('Error fetching data:', error);
    res.status(500).json({ error: 'Error fetching data' });
  } finally {
    await client.close();
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

// New endpoint to login system
app.post('/login', async (req, res) => {
  try {
    await client.connect();
    const database = client.db('test');
    const usersCollection = database.collection('users');

    const { username, password } = req.body;

    if (!username || !password) {
      return res.status(400).json({ 
        error: 'Username and password are required' 
      });
    }

    // Find the user in the database
    const user = await usersCollection.findOne({ 
      username, 
      password  // Note: In production, use proper password hashing
    });

    if (!user) {
      return res.status(401).json({ 
        error: 'Invalid username or password' 
      });
    }

    // Check if user is a patient (trim to handle extra spaces)
    if (user.role.trim().toLowerCase() !== 'patient') {
      return res.status(403).json({ 
        error: 'Access denied: Only patients can login through this portal' 
      });
    }

    // Success: Return user details
    res.status(200).json({ 
      message: 'Login successful',
      user: {
        username: user.username,
        name: user.name || user.username,
        role: user.role.trim()
      }
    });

  } catch (error) {
    console.error('Error during login:', error);
    res.status(500).json({ error: 'Internal server error' });
  } finally {
    await client.close();
  }
});