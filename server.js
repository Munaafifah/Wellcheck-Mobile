const express = require("express");
const bodyParser = require("body-parser");
const cors = require("cors");
const jwt = require("jsonwebtoken");
const bcrypt = require("bcrypt");
const { MongoClient, ObjectId } = require("mongodb");
const { v4: uuidv4 } = require("uuid");

const app = express();

// Increase the payload size limit (e.g., 50MB) - MOVED TO TOP
app.use(bodyParser.json({ limit: "50mb" }));
app.use(bodyParser.urlencoded({ limit: "50mb", extended: true }));
app.use(cors());

const port = 5001; // SINGLE PORT DECLARATION

const uri = "mongodb+srv://munaafifah:munaafifah@wellcheck.t0bkb.mongodb.net/Wellcheck2?retryWrites=true&w=majority";
const secretKey = "your_secret_key";

const tokenBlacklist = new Set(); // In-memory blacklist

// Database connection helper
async function getConnection() {
  const client = new MongoClient(uri, { useNewUrlParser: true, useUnifiedTopology: true });
  await client.connect();
  return client;
}

// Middleware to check for blacklisted tokens - MOVED BEFORE ROUTES
app.use((req, res, next) => {
  const token = req.headers.authorization?.split(" ")[1];
  if (token && tokenBlacklist.has(token)) {
    return res.status(401).json({ error: "Token is invalid or expired" });
  }
  next();
});

// Login endpoint
app.post("/login", async (req, res) => {
  let client;
  try {
    const { userId, password } = req.body;
    
    console.log("Login attempt for userId:", userId); // DEBUG LOG

    // Create new connection for this request
    client = await getConnection();
    const users = client.db("Wellcheck2").collection("User");

    // Find the user by _id
    const user = await users.findOne({ _id: userId });
    if (!user) {
      console.log("User not found:", userId); // DEBUG LOG
      return res.status(404).json({ error: "User not found" });
    }

    // Check if the user is a patient
    if (user.role !== "PATIENT") {
      console.log("Access restricted - user role:", user.role); // DEBUG LOG
      return res.status(403).json({ error: "Access restricted to patients" });
    }

    // Validate the password using bcrypt
    const isPasswordValid = await bcrypt.compare(password, user.password);
    if (!isPasswordValid) {
      console.log("Invalid password for user:", userId); // DEBUG LOG
      return res.status(401).json({ error: "Invalid password" });
    }

    // Generate a JWT token
    const token = jwt.sign({ userId: user._id }, secretKey);
    console.log("Login successful for user:", userId); // DEBUG LOG
    res.json({ token });
  } catch (error) {
    console.error("Login error:", error);
    res.status(500).json({ error: "Internal server error" });
  } finally {
    if (client) {
      await client.close();
    }
  }
});

// Fetch patient details endpoint
app.get("/patient/:userId", async (req, res) => {
  let client;
  try {
    const token = req.headers.authorization?.split(" ")[1];
    if (!token) {
      return res.status(401).json({ error: "Unauthorized" });
    }

    // Verify token
    jwt.verify(token, secretKey, async (err, decoded) => {
      if (err) {
        return res.status(401).json({ error: "Invalid token" });
      }

      try {
        const userId = req.params.userId;
        client = await getConnection();
        const patients = client.db("Wellcheck2").collection("Patient");

        // Fetch the patient document and access the nested data
        const patientDoc = await patients.findOne({ _id: userId });
        if (!patientDoc || !patientDoc[userId]) {
          return res.status(404).json({ error: "Patient not found" });
        }

        const patient = patientDoc[userId]; // Access the nested patient data

        res.json({
          name: patient.name,
          address: patient.address,
          contact: patient.contact,
          emergencyContact: patient.emergencyContact,
          assigned_doctor: patient.assigned_doctor,
        });
      } catch (error) {
        console.error(error);
        res.status(500).json({ error: "Internal server error" });
      } finally {
        if (client) {
          await client.close();
        }
      }
    });
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: "Internal server error" });
  }
});

// Fetch prescriptions endpoint
app.get("/prescriptions/:userId", async (req, res) => {
  let client;
  try {
    const token = req.headers.authorization?.split(" ")[1];
    if (!token) {
      return res.status(401).json({ error: "Unauthorized" });
    }

    // Verify the token
    jwt.verify(token, secretKey, async (err, decoded) => {
      if (err) {
        return res.status(401).json({ error: "Invalid token" });
      }

      try {
        const userId = req.params.userId;
        client = await getConnection();
        const patients = client.db("Wellcheck2").collection("Patient");

        // Fetch the patient document
        const patientDoc = await patients.findOne({ _id: userId });
        if (!patientDoc) {
          return res.status(404).json({ error: "Patient not found" });
        }

        // Access the nested patient data
        const patient = patientDoc[userId];
        if (!patient || !patient.Prescription || Object.keys(patient.Prescription).length === 0) {
          return res.status(404).json({ error: "No prescriptions found for this patient." });
        }

        // Return all prescriptions as an array
        const prescriptions = Object.values(patient.Prescription);
        res.json(prescriptions);
      } catch (error) {
        console.error(error);
        res.status(500).json({ error: "Internal server error" });
      } finally {
        if (client) {
          await client.close();
        }
      }
    });
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: "Internal server error" });
  }
});

// Save predictions endpoint
app.post('/predictions2', async (req, res) => {
  let client;
  try {
    const token = req.headers.authorization?.split(" ")[1];
    if (!token) {
      return res.status(401).json({ error: "Unauthorized" });
    }

    jwt.verify(token, secretKey, async (err, decoded) => {
      if (err) {
        return res.status(401).json({ error: "Invalid token" });
      }

      try {
        client = await getConnection();
        const patients = client.db("Wellcheck2").collection("Patient");
        const userId = decoded.userId;
        const { diagnosisList, probabilityList, symptomsList, timestamp } = req.body;

        if (!diagnosisList || !probabilityList || !symptomsList) {
          return res.status(400).json({ error: "Missing required fields" });
        }

        const predictionID = uuidv4();
        const newPrediction = {
          diagnosisList,
          probabilityList,
          symptomsList,
          predictionID,
          timestamp: timestamp || new Date().toISOString(),
        };

        // Find the patient by user ID
        const existingPatient = await patients.findOne({ _id: userId });

        if (existingPatient) {
          // Dynamically detect the first key (like "000", "001")
          const patientKey = Object.keys(existingPatient).find(key => key !== '_id');

          if (patientKey) {
            const patientData = existingPatient[patientKey];

            if (patientData.Prediction) {
              // If Prediction exists, append new entry to the existing object
              await patients.updateOne(
                { _id: userId },
                { $set: { [`${patientKey}.Prediction.${predictionID}`]: newPrediction } }
              );
            } else {
              // If Prediction doesn't exist, create a new Prediction object
              await patients.updateOne(
                { _id: userId },
                { $set: { [`${patientKey}.Prediction`]: { [predictionID]: newPrediction } } }
              );
            }

            // Return updated patient data
            const updatedPatient = await patients.findOne({ _id: userId });
            res.status(200).json({
              message: "Prediction saved successfully",
              predictionID: predictionID,
              patient: updatedPatient,
            });
          } else {
            res.status(404).json({ error: "No valid nested document found for patient" });
          }
        } else {
          res.status(404).json({ error: "Patient not found" });
        }
      } catch (error) {
        console.error("Error saving prediction:", error);
        res.status(500).json({ error: "Internal server error" });
      } finally {
        if (client) {
          await client.close();
        }
      }
    });
  } catch (error) {
    console.error("Error saving prediction:", error);
    res.status(500).json({ error: "Internal server error" });
  }
});

// Get health status endpoint
app.get("/healthstatus/:userId", async (req, res) => {
  let client;
  try {
    const token = req.headers.authorization?.split(" ")[1];
    if (!token) {
      return res.status(401).json({ error: "Unauthorized" });
    }

    jwt.verify(token, secretKey, async (err, decoded) => {
      if (err) {
        return res.status(401).json({ error: "Invalid token" });
      }

      try {
        const userId = req.params.userId;
        client = await getConnection();
        const patients = client.db("Wellcheck2").collection("Patient");

        const patientDoc = await patients.findOne({ _id: userId });
        if (!patientDoc || !patientDoc[userId]) {
          return res.status(404).json({ error: "Patient not found" });
        }

        const patient = patientDoc[userId];
        if (!patient.HealthStatus || Object.keys(patient.HealthStatus).length === 0) {
          return res.status(404).json({ error: "No healthstatus found for this patient" });
        }

        const healthstatusList = Object.values(patient.HealthStatus);
        res.json(healthstatusList);
      } catch (error) {
        console.error(error);
        res.status(500).json({ error: "Internal server error" });
      } finally {
        if (client) {
          await client.close();
        }
      }
    });
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: "Internal server error" });
  }
});

// Delete health status endpoint
app.delete("/healthstatus/:userId/:healthStatusId", async (req, res) => {
  let client;
  try {
    const token = req.headers.authorization?.split(" ")[1];
    if (!token) {
      return res.status(401).json({ error: "Unauthorized" });
    }

    jwt.verify(token, secretKey, async (err, decoded) => {
      if (err) {
        return res.status(401).json({ error: "Invalid token" });
      }

      try {
        const userId = req.params.userId;
        const healthStatusId = req.params.healthStatusId;

        client = await getConnection();
        const patients = client.db("Wellcheck2").collection("Patient");

        const patientDoc = await patients.findOne({ _id: userId });
        if (!patientDoc || !patientDoc[userId]) {
          return res.status(404).json({ error: "Patient not found" });
        }

        const patient = patientDoc[userId];
        if (!patient.HealthStatus || !patient.HealthStatus[healthStatusId]) {
          return res.status(404).json({ error: "Health status entry not found" });
        }

        // Remove the health status entry from the HealthStatus object
        delete patient.HealthStatus[healthStatusId];

        // Update the patient document with the modified HealthStatus
        await patients.updateOne(
          { _id: userId },
          { $set: { [userId]: patient } }
        );

        res.json({ message: "Health status entry deleted" });
      } catch (error) {
        console.error(error);
        res.status(500).json({ error: "Internal server error" });
      } finally {
        if (client) {
          await client.close();
        }
      }
    });
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: "Internal server error" });
  }
});

// Add symptom endpoint
app.post("/add-symptom", async (req, res) => {
  let client;
  try {
    const token = req.headers.authorization?.split(" ")[1];
    if (!token) {
      return res.status(401).json({ error: "Unauthorized" });
    }

    // Verify the token
    jwt.verify(token, secretKey, async (err, decoded) => {
      if (err) {
        return res.status(401).json({ error: "Invalid token" });
      }

      try {
        const { symptomDescription } = req.body;
        const userId = decoded.userId;

        // Fetch patient details
        client = await getConnection();
        const patients = client.db("Wellcheck2").collection("Patient");
        const patient = await patients.findOne({ _id: userId });

        if (!patient) {
          return res.status(404).json({ error: "Patient not found" });
        }

        // Access the assigned_doctor field
        const doctorId = patient[userId]?.assigned_doctor;

        if (!doctorId) {
          return res.status(404).json({ error: "Assigned doctor not found" });
        }

        // Generate unique symptomId
        const symptomId = uuidv4();

        // Insert symptom into symptoms collection
        const symptoms = client.db("Wellcheck2").collection("Symptom");
        const newSymptom = {
          symptomId,
          userId,
          doctorId,
          symptomDescription,
          timestamp: new Date(),
        };
        await symptoms.insertOne(newSymptom);

        res.json({ message: "Symptom added successfully", symptom: newSymptom });
      } catch (error) {
        console.error(error);
        res.status(500).json({ error: "Internal server error" });
      } finally {
        if (client) {
          await client.close();
        }
      }
    });
  } catch (error) {
    res.status(500).json({ error: "Internal server error" });
  }
});

// Get symptoms endpoint
app.get("/symptoms/:userId", async (req, res) => {
  let client;
  try {
    const token = req.headers.authorization?.split(" ")[1];
    if (!token) {
      return res.status(401).json({ error: "Unauthorized" });
    }

    // Verify the token
    jwt.verify(token, secretKey, async (err, decoded) => {
      if (err) {
        return res.status(401).json({ error: "Invalid token" });
      }

      try {
        const userId = req.params.userId;

        // Fetch symptoms for the user
        client = await getConnection();
        const symptoms = client.db("Wellcheck2").collection("Symptom");
        const userSymptoms = await symptoms.find({ userId }).toArray();

        res.json(userSymptoms);
      } catch (error) {
        console.error(error);
        res.status(500).json({ error: "Internal server error" });
      } finally {
        if (client) {
          await client.close();
        }
      }
    });
  } catch (error) {
    res.status(500).json({ error: "Internal server error" });
  }
});

// Update symptom endpoint
app.put("/update-symptom", async (req, res) => {
  let client;
  try {
    const token = req.headers.authorization?.split(" ")[1];
    if (!token) {
      return res.status(401).json({ error: "Unauthorized" });
    }

    jwt.verify(token, secretKey, async (err, decoded) => {
      if (err) {
        return res.status(401).json({ error: "Invalid token" });
      }

      try {
        const { symptomId, symptomDescription } = req.body;

        // Update the symptom
        client = await getConnection();
        const symptoms = client.db("Wellcheck2").collection("Symptom");
        const result = await symptoms.updateOne(
          { symptomId },
          { $set: { symptomDescription } }
        );

        if (result.modifiedCount === 0) {
          return res.status(404).json({ error: "Symptom not found" });
        }

        res.json({ message: "Symptom updated successfully" });
      } catch (error) {
        console.error(error);
        res.status(500).json({ error: "Internal server error" });
      } finally {
        if (client) {
          await client.close();
        }
      }
    });
  } catch (error) {
    res.status(500).json({ error: "Internal server error" });
  }
});

// Delete symptom endpoint
app.delete("/delete-symptom/:symptomId", async (req, res) => {
  let client;
  try {
    const token = req.headers.authorization?.split(" ")[1];
    if (!token) {
      return res.status(401).json({ error: "Unauthorized" });
    }

    jwt.verify(token, secretKey, async (err, decoded) => {
      if (err) {
        return res.status(401).json({ error: "Invalid token" });
      }

      try {
        const symptomId = req.params.symptomId;

        // Delete the symptom
        client = await getConnection();
        const symptoms = client.db("Wellcheck2").collection("Symptom");
        const result = await symptoms.deleteOne({ symptomId });

        if (result.deletedCount === 0) {
          return res.status(404).json({ error: "Symptom not found" });
        }

        res.json({ message: "Symptom deleted successfully" });
      } catch (error) {
        console.error(error);
        res.status(500).json({ error: "Internal server error" });
      } finally {
        if (client) {
          await client.close();
        }
      }
    });
  } catch (error) {
    res.status(500).json({ error: "Internal server error" });
  }
});

// Get sickness endpoint
app.get("/sickness", async (req, res) => {
  let client;
  try {
    client = await getConnection();
    const sicknessCollection = client.db("Wellcheck2").collection("sickness");
    const sicknesses = await sicknessCollection.find().toArray();

    res.json(sicknesses);
  } catch (dbError) {
    console.error("Database Error:", dbError);
    res.status(500).json({ error: "Failed to fetch sickness records" });
  } finally {
    if (client) {
      await client.close();
    }
  }
});

// Get hospitals endpoint
app.get("/hospitals", async (req, res) => {
  let client;
  try {
    client = await getConnection();
    const hospitalsCollection = client.db("Wellcheck2").collection("hospitals");
    const hospitals = await hospitalsCollection.find().toArray();

    if (!hospitals.length) {
      return res.status(404).json({ error: "No hospitals found" });
    }

    res.json(hospitals);
  } catch (error) {
    console.error("Error fetching hospitals:", error.message);
    res.status(500).json({ error: "Failed to fetch hospitals. Details: " + error.message });
  } finally {
    if (client) {
      await client.close();
    }
  }
});

// Get hospital by ID endpoint
app.get("/hospitals/:hospitalId", async (req, res) => {
  let client;
  try {
    client = await getConnection();
    const hospitalsCollection = client.db("Wellcheck2").collection("hospitals");

    const hospitalId = req.params.hospitalId;

    // Fetch the hospital by ID, converting the id to ObjectId
    const hospital = await hospitalsCollection.findOne({ _id: new ObjectId(hospitalId) });

    if (!hospital) {
      return res.status(404).json({ error: "Hospital not found" });
    }

    // Return the hospital's dynamic form fields
    res.json(hospital.form_fields);
  } catch (error) {
    console.error("Error fetching hospital fields:", error);
    res.status(500).json({ error: "Failed to fetch hospital fields" });
  } finally {
    if (client) {
      await client.close();
    }
  }
});

// Get appointments endpoint
app.get("/appointments/:userId", async (req, res) => {
  let client;
  try {
    const token = req.headers.authorization?.split(" ")[1];
    if (!token) {
      return res.status(401).json({ error: "Unauthorized" });
    }

    // Verify the token
    jwt.verify(token, secretKey, async (err, decoded) => {
      if (err) {
        return res.status(401).json({ error: "Invalid token" });
      }

      try {
        const userId = req.params.userId;

        // Fetch appointments for the user
        client = await getConnection();
        const appointments = client.db("Wellcheck2").collection("appointments");
        const userAppointments = await appointments.find({ userId }).toArray();

        res.json(userAppointments);
      } catch (dbError) {
        console.error("Database Error:", dbError);
        res.status(500).json({ error: "Failed to fetch appointments" });
      } finally {
        if (client) {
          await client.close();
        }
      }
    });
  } catch (error) {
    console.error("Error:", error);
    res.status(500).json({ error: "Internal server error" });
  }
});

// Add appointment endpoint
app.post("/appointments", async (req, res) => {
  let client;
  try {
    // Extract token from Authorization header
    const token = req.headers.authorization?.split(" ")[1];
    if (!token) {
      return res.status(401).json({ error: "Unauthorized" });
    }

    // Verify JWT
    let decoded;
    try {
      decoded = jwt.verify(token, secretKey);
    } catch (err) {
      return res.status(401).json({ error: "Invalid token" });
    }

    // Extract data from request body
    const {
      appointmentDate,
      appointmentTime,
      duration,
      typeOfSickness,
      additionalNotes,
      email,
      insuranceProvider,
      insurancePolicyNumber,
      hospitalId,
      registeredHospital,
      appointmentCost,
      statusPayment = "Not Paid",
      statusAppointment = "Not Approved",
    } = req.body;

    const userId = decoded.userId;

    // Validate required fields
    if (
      !appointmentDate ||
      !appointmentTime ||
      !duration ||
      !typeOfSickness ||
      !email ||
      !statusAppointment ||
      appointmentCost == null
    ) {
      return res.status(400).json({ error: "Missing required fields" });
    }

    try {
      client = await getConnection();
      console.log("Connected to MongoDB");

      // Fetch patient details
      const patients = client.db("Wellcheck2").collection("Patient");
      const patient = await patients.findOne({ _id: userId });

      if (!patient) {
        return res.status(404).json({ error: "Patient not found" });
      }

      const appointmentId = uuidv4();
      // Access the assigned_doctor field
      const doctorId = patient[userId]?.assigned_doctor;

      if (!doctorId) {
        return res.status(404).json({ error: "Assigned doctor not found" });
      }

      // Check for duplicate appointment
      const appointments = client.db("Wellcheck2").collection("appointments");
      const existingAppointment = await appointments.findOne({
        userId,
        appointmentDate,
        appointmentTime,
      });

      if (existingAppointment) {
        return res.status(400).json({
          error: "Appointment already exists for the selected date and time",
        });
      }

      // Create a new appointment object
      const newAppointment = {
        appointmentId,
        userId,
        doctorId,
        hospitalId,
        appointmentDate,
        appointmentTime,
        duration,
        registeredHospital,
        typeOfSickness,
        additionalNotes: additionalNotes || null,
        insuranceProvider: insuranceProvider || null,
        insurancePolicyNumber: insurancePolicyNumber || null,
        email,
        appointmentCost,
        statusPayment,
        statusAppointment,
        timestamp: new Date(appointmentDate),
      };

      // Insert appointment into the database
      const result = await appointments.insertOne(newAppointment);
      if (result.acknowledged) {
        res.status(201).json({
          message: "Appointment created successfully",
          appointment: newAppointment,
        });
      } else {
        res.status(500).json({ error: "Failed to create appointment" });
      }
    } catch (mongoError) {
      console.error("MongoDB Error:", mongoError.message);
      res.status(500).json({ error: "Database error occurred", details: mongoError.message });
    } finally {
      if (client) {
        await client.close();
      }
      console.log("Disconnected from MongoDB");
    }
  } catch (error) {
    console.error("Error:", error);
    res.status(500).json({ error: "Internal server error" });
  }
});

// Update appointment endpoint
app.put("/update-appointment/:appointmentId", async (req, res) => {
  let client;
  console.log("Received request to update appointment with ID:", req.params.appointmentId);

  try {
    const token = req.headers.authorization?.split(" ")[1];
    if (!token) {
      return res.status(401).json({ error: "Unauthorized" });
    }

    const { appointmentDate, appointmentTime, duration, typeOfSickness } = req.body;
    const { appointmentId } = req.params;

    // Validate required fields
    if (!appointmentDate || !appointmentTime || !duration || !typeOfSickness) {
      return res.status(400).json({ error: "Missing required fields" });
    }

    // Combine date and time
    const fullAppointmentDateTime = new Date(`${appointmentDate}T${appointmentTime}:00.000Z`);

    try {
      client = await getConnection();
      console.log("Connected to MongoDB");

      const appointments = client.db("Wellcheck2").collection("appointments");

      const result = await appointments.updateOne(
        { appointmentId },
        {
          $set: {
            appointmentDate: fullAppointmentDateTime,
            appointmentTime,
            duration,
            typeOfSickness,
          },
        }
      );

      if (result.modifiedCount === 0) {
        return res.status(404).json({ error: "Appointment not found" });
      }

      res.status(200).json({ message: "Appointment updated successfully", appointmentId });
    } finally {
      if (client) {
        await client.close();
      }
    }
  } catch (error) {
    console.error("Error updating appointment:", error);
    res.status(500).json({ error: "Internal server error", details: error.message });
  }
});

// Update appointment status endpoint
app.put("/appointments/:appointmentId/status", async (req, res) => {
  let client;
  try {
    const { appointmentId } = req.params;
    const { statusPayment, statusAppointment } = req.body;

    client = await getConnection();
    const appointments = client.db("Wellcheck2").collection("appointments");

    const result = await appointments.updateOne(
      { appointmentId },
      { $set: { statusPayment } }
    );

    if (result.modifiedCount === 0) {
      return res.status(404).json({ error: "Appointment not found" });
    }

    res.status(200).json({ message: "Appointment status updated successfully" });
  } catch (error) {
    console.error("Error updating appointment:", error);
    res.status(500).json({ error: "Internal server error" });
  } finally {
    if (client) {
      await client.close();
    }
  }
});

// Delete appointment endpoint
app.delete('/delete-appointment/:appointmentId', async (req, res) => {
  let client;
  try {
    const token = req.headers.authorization?.split(" ")[1];
    if (!token) {
      return res.status(401).json({ error: "Unauthorized" });
    }

    // Verify JWT token
    jwt.verify(token, secretKey, async (err, decoded) => {
      if (err) {
        return res.status(401).json({ error: "Invalid token" });
      }

      try {
        const appointmentId = req.params.appointmentId;
        client = await getConnection();
        const appointments = client.db("Wellcheck2").collection("appointments");

        const result = await appointments.deleteOne({ appointmentId });

        if (result.deletedCount === 0) {
          return res.status(404).json({ message: 'Appointment not found' });
        }

        res.json({ message: 'Appointment deleted successfully' });
      } catch (error) {
        console.error('Error deleting appointment:', error);
        res.status(500).json({ message: 'Server error' });
      } finally {
        if (client) {
          await client.close();
        }
      }
    });
  } catch (error) {
    console.error('Error deleting appointment:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

// Update patient details endpoint
app.put("/patient/:userId", async (req, res) => {
  let client;
  try {
    const token = req.headers.authorization?.split(" ")[1];
    if (!token) {
      return res.status(401).json({ error: "Unauthorized" });
    }

    // Verify token
    jwt.verify(token, secretKey, async (err, decoded) => {
      if (err) {
        return res.status(401).json({ error: "Invalid token" });
      }

      try {
        const userId = req.params.userId;
        const updates = req.body;

        client = await getConnection();
        const patients = client.db("Wellcheck2").collection("Patient");

        // Get the existing patient data
        const existingPatient = await patients.findOne({ _id: userId });

        if (!existingPatient) {
          return res.status(404).json({ error: "Patient not found" });
        }

        // Prepare update object by adding only the fields present in the update request
        const updateData = {};

        // Update top-level fields if provided in the request
        if (updates.address) updateData[`${userId}.address`] = updates.address;
        if (updates.contact) updateData[`${userId}.contact`] = updates.contact;
        if (updates.emergencyContact) updateData[`${userId}.emergencyContact`] = updates.emergencyContact;
        if (updates.name) updateData[`${userId}.name`] = updates.name;

        // Optionally, you can update HealthStatus or Prescription fields if provided
        if (updates.HealthStatus) {
          updateData[`${userId}.HealthStatus`] = updates.HealthStatus;
        }

        if (updates.Prescription) {
          updateData[`${userId}.Prescription`] = updates.Prescription;
        }

        // Perform the update operation
        const result = await patients.updateOne(
          { _id: userId },
          { $set: updateData }
        );

        if (result.matchedCount === 0) {
          return res.status(404).json({ error: "Patient not found" });
        }

        res.json({ message: "Patient updated successfully" });
      } catch (error) {
        console.error(error);
        res.status(500).json({ error: "Internal server error" });
      } finally {
        if (client) {
          await client.close();
        }
      }
    });
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: "Internal server error" });
  }
});

// Update user details endpoint
app.put("/user/:userId", async (req, res) => {
  let client;
  try {
    // Token validation
    const token = req.headers.authorization?.split(" ")[1];
    if (!token) {
      return res.status(401).json({ error: "Unauthorized" });
    }

    jwt.verify(token, secretKey, async (err, decoded) => {
      if (err) {
        return res.status(401).json({ error: "Invalid token" });
      }

      try {
        // Get database connection
        client = await getConnection();
        const userId = req.params.userId;
        const updates = req.body;

        const userCollection = client.db("Wellcheck2").collection("User");

        // Create update object for changed fields
        const updateFields = {};
        Object.keys(updates).forEach(key => {
          updateFields[key] = updates[key];
        });

        const result = await userCollection.updateOne(
          { _id: userId },
          { $set: updateFields }
        );

        if (result.modifiedCount === 0) {
          return res.status(404).json({ error: "User not found" });
        }

        res.json({ message: "User updated successfully" });
      } catch (error) {
        console.error('Error:', error);
        res.status(500).json({ error: "Internal server error" });
      } finally {
        if (client) {
          await client.close();
        }
      }
    });
  } catch (error) {
    console.error('Error:', error);
    res.status(500).json({ error: "Internal server error" });
  }
});

// Edit password endpoint
app.put("/user/:userId/password", async (req, res) => {
  let client;
  try {
    const token = req.headers.authorization?.split(" ")[1];
    if (!token) {
      return res.status(401).json({ error: "Unauthorized" });
    }

    // Verify token
    jwt.verify(token, secretKey, async (err, decoded) => {
      if (err) {
        return res.status(401).json({ error: "Invalid token" });
      }

      try {
        const userId = req.params.userId;
        const { newPassword } = req.body;

        // Check if newPassword is provided
        if (!newPassword) {
          return res.status(400).json({ error: "New password is required" });
        }

        client = await getConnection();
        const users = client.db("Wellcheck2").collection("User");

        // Hash the new password
        const hashedPassword = await bcrypt.hash(newPassword, 10);

        // Update the password field directly
        const updateResult = await users.updateOne(
          { _id: userId },
          { $set: { password: hashedPassword } }
        );

        if (updateResult.matchedCount === 0) {
          return res.status(404).json({ error: "User not found" });
        }

        if (updateResult.modifiedCount === 0) {
          return res.status(400).json({ error: "Password update failed" });
        }

        res.json({ message: "Password updated successfully" });
      } catch (error) {
        console.error("Error:", error);
        res.status(500).json({ error: "Internal server error" });
      } finally {
        if (client) {
          await client.close();
        }
      }
    });
  } catch (error) {
    console.error("Error:", error);
    res.status(500).json({ error: "Internal server error" });
  }
});

// Image upload endpoint
app.put("/user/uploadImage/:userId", async (req, res) => {
  let client;
  try {
    const userId = req.params.userId;
    const { profilepic } = req.body;  // Base64 image data

    if (!profilepic) {
      return res.status(400).json({ error: "Profile picture is required" });
    }

    client = await getConnection();
    const users = client.db("Wellcheck2").collection("User");

    const result = await users.updateOne(
      { _id: userId },
      { $set: { profilepic: profilepic } }
    );

    if (result.matchedCount === 0) {
      return res.status(404).json({ error: "User not found" });
    }

    res.json({ message: "Profile picture updated successfully" });
  } catch (error) {
    console.error("Upload Error:", error);
    res.status(500).json({ error: "Internal server error" });
  } finally {
    if (client) {
      await client.close();
    }
  }
});

// Get profile image endpoint
app.get("/user/profileImage/:userId", async (req, res) => {
  let client;
  try {
    const userId = req.params.userId;

    // Connect to the database
    client = await getConnection();
    const users = client.db("Wellcheck2").collection("User");

    // Fetch user by _id
    const userDoc = await users.findOne({ _id: userId });

    if (!userDoc || !userDoc.profilepic) {
      return res.status(404).json({ error: "Profile image not found" });
    }

    // Return the Base64 image
    const profileImage = userDoc.profilepic;
    res.json({ profilepic: profileImage });
  } catch (error) {
    console.error("Error fetching profile image:", error);
    res.status(500).json({ error: "Internal server error" });
  } finally {
    if (client) {
      await client.close();
    }
  }
});

// Verify password endpoint
app.post("/verify-password", async (req, res) => {
  let client;
  try {
    const { userId, password } = req.body;

    if (!userId || !password) {
      return res.status(400).json({ error: "User ID and password are required" });
    }

    // Connect to the database
    client = await getConnection();
    const users = client.db("Wellcheck2").collection("User");

    // Fetch the user document
    const userDoc = await users.findOne({ _id: userId });

    if (!userDoc) {
      return res.status(404).json({ error: "User not found" });
    }

    // Compare passwords using bcrypt
    const isPasswordValid = await bcrypt.compare(password, userDoc.password);
    if (isPasswordValid) {
      return res.status(200).json({ message: "Password verified successfully" });
    } else {
      return res.status(401).json({ error: "Invalid password" });
    }
  } catch (error) {
    console.error("Error verifying password:", error);
    res.status(500).json({ error: "Internal server error" });
  } finally {
    if (client) {
      await client.close();
    }
  }
});

// Logout endpoint
app.post("/logout", (req, res) => {
  const token = req.headers.authorization?.split(" ")[1];
  if (!token) {
    return res.status(401).json({ error: "No token provided" });
  }

  try {
    // Add token to blacklist
    tokenBlacklist.add(token);
    res.json({ message: "Logged out successfully" });
  } catch (error) {
    res.status(500).json({ error: "Failed to logout" });
  }
});

// Add health check endpoint
app.get("/health", (req, res) => {
  res.json({ 
    status: "Server is running", 
    port: port,
    database: "Wellcheck2",
    timestamp: new Date().toISOString()
  });
});

// Test database connection endpoint
app.get("/test-db", async (req, res) => {
  let client;
  try {
    client = await getConnection();
    const db = client.db("Wellcheck2");
    
    // Test collections
    const collections = await db.listCollections().toArray();
    const collectionNames = collections.map(col => col.name);
    
    res.json({ 
      status: "Database connected successfully",
      database: "Wellcheck2",
      collections: collectionNames
    });
  } catch (error) {
    console.error("Database connection error:", error);
    res.status(500).json({ 
      error: "Database connection failed", 
      details: error.message 
    });
  } finally {
    if (client) {
      await client.close();
    }
  }
});

// Add this shutdown handler
process.on('SIGINT', async () => {
  console.log('Shutting down server...');
  process.exit();
});

// SINGLE SERVER START
app.listen(port, () => {
  console.log(`✅ WellCheck Server is running on http://localhost:${port}`);
  console.log(`🔍 Health check: http://localhost:${port}/health`);
  console.log(`🗄️  Database test: http://localhost:${port}/test-db`);
  console.log(`🔐 Login endpoint: http://localhost:${port}/login`);
  console.log(`📊 Database: Wellcheck2`);
  console.log(`⚡ Ready to accept connections...`);
});