const express = require("express");
const bodyParser = require("body-parser");
const cors = require("cors");
const jwt = require("jsonwebtoken");
const bcrypt = require("bcrypt");
const { MongoClient, ObjectId } = require("mongodb");
const { v4: uuidv4 } = require("uuid");

const app = express();

app.use(bodyParser.json({ limit: "50mb" }));
app.use(bodyParser.urlencoded({ limit: "50mb", extended: true }));
app.use(cors());

const port = 5001;

const uri = "mongodb+srv://admin:admin@atlascluster.htlbqbu.mongodb.net/Wellcheck2?retryWrites=true&w=majority";
const secretKey = "your_secret_key";

const tokenBlacklist = new Set();

async function getConnection() {
  const client = new MongoClient(uri, { useNewUrlParser: true, useUnifiedTopology: true });
  await client.connect();
  return client;
}

// Middleware to check blacklisted tokens
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
    console.log("Login attempt for userId:", userId);

    client = await getConnection();
    const users = client.db("Wellcheck2").collection("User");

    const user = await users.findOne({ _id: userId });
    if (!user) {
      return res.status(404).json({ error: "User not found" });
    }

    if (user.role !== "PATIENT") {
      return res.status(403).json({ error: "Access restricted to patients" });
    }

    const isPasswordValid = await bcrypt.compare(password, user.password);
    if (!isPasswordValid) {
      return res.status(401).json({ error: "Invalid password" });
    }

    const token = jwt.sign({ userId: user._id }, secretKey);
    console.log("Login successful for user:", userId);
    res.json({ token });
  } catch (error) {
    console.error("Login error:", error);
    res.status(500).json({ error: "Internal server error" });
  } finally {
    if (client) await client.close();
  }
});

// Fetch patient details endpoint
app.get("/patient/:userId", async (req, res) => {
  let client;
  try {
    const token = req.headers.authorization?.split(" ")[1];
    if (!token) return res.status(401).json({ error: "Unauthorized" });

    jwt.verify(token, secretKey, async (err, decoded) => {
      if (err) return res.status(401).json({ error: "Invalid token" });

      try {
        const userId = req.params.userId;
        client = await getConnection();
        const patients = client.db("Wellcheck2").collection("Patient");

        // Flat structure — no nested key
        const patientDoc = await patients.findOne({ _id: userId });
        if (!patientDoc) {
          return res.status(404).json({ error: "Patient not found" });
        }

        res.json({
          name: patientDoc.name,
          address: patientDoc.address,
          contact: patientDoc.contact,
          emergencyContact: patientDoc.emergencyContact,
          assigned_doctor: patientDoc.assigned_doctor,
        });
      } catch (error) {
        console.error(error);
        res.status(500).json({ error: "Internal server error" });
      } finally {
        if (client) await client.close();
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
    if (!token) return res.status(401).json({ error: "Unauthorized" });

    jwt.verify(token, secretKey, async (err, decoded) => {
      if (err) return res.status(401).json({ error: "Invalid token" });

      try {
        const userId = req.params.userId;
        client = await getConnection();
        const patients = client.db("Wellcheck2").collection("Patient");

        // Flat structure — prescription is lowercase
        const patientDoc = await patients.findOne({ _id: userId });
        if (!patientDoc) {
          return res.status(404).json({ error: "Patient not found" });
        }

        if (!patientDoc.prescription || Object.keys(patientDoc.prescription).length === 0) {
          return res.status(404).json({ error: "No prescriptions found for this patient." });
        }

        const prescriptions = Object.values(patientDoc.prescription);
        res.json(prescriptions);
      } catch (error) {
        console.error(error);
        res.status(500).json({ error: "Internal server error" });
      } finally {
        if (client) await client.close();
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
    if (!token) return res.status(401).json({ error: "Unauthorized" });

    jwt.verify(token, secretKey, async (err, decoded) => {
      if (err) return res.status(401).json({ error: "Invalid token" });

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

        const existingPatient = await patients.findOne({ _id: userId });
        if (!existingPatient) {
          return res.status(404).json({ error: "Patient not found" });
        }

        // Flat structure — prediction is lowercase
        await patients.updateOne(
          { _id: userId },
          { $set: { [`prediction.${predictionID}`]: newPrediction } }
        );

        const updatedPatient = await patients.findOne({ _id: userId });
        res.status(200).json({
          message: "Prediction saved successfully",
          predictionID,
          patient: updatedPatient,
        });
      } catch (error) {
        console.error("Error saving prediction:", error);
        res.status(500).json({ error: "Internal server error" });
      } finally {
        if (client) await client.close();
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
    if (!token) return res.status(401).json({ error: "Unauthorized" });

    jwt.verify(token, secretKey, async (err, decoded) => {
      if (err) return res.status(401).json({ error: "Invalid token" });

      try {
        const userId = req.params.userId;
        client = await getConnection();

        // HealthStatus is a separate collection in the new DB
        const healthStatusCollection = client.db("Wellcheck2").collection("HealthStatus");
        const healthStatusList = await healthStatusCollection.find({ userId }).toArray();

        if (!healthStatusList || healthStatusList.length === 0) {
          return res.status(404).json({ error: "No healthstatus found for this patient" });
        }

        res.json(healthStatusList);
      } catch (error) {
        console.error(error);
        res.status(500).json({ error: "Internal server error" });
      } finally {
        if (client) await client.close();
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
    if (!token) return res.status(401).json({ error: "Unauthorized" });

    jwt.verify(token, secretKey, async (err, decoded) => {
      if (err) return res.status(401).json({ error: "Invalid token" });

      try {
        const { userId, healthStatusId } = req.params;
        client = await getConnection();
        const healthStatusCollection = client.db("Wellcheck2").collection("HealthStatus");

        const result = await healthStatusCollection.deleteOne({ userId, healthStatusId });

        if (result.deletedCount === 0) {
          return res.status(404).json({ error: "Health status entry not found" });
        }

        res.json({ message: "Health status entry deleted" });
      } catch (error) {
        console.error(error);
        res.status(500).json({ error: "Internal server error" });
      } finally {
        if (client) await client.close();
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
    if (!token) return res.status(401).json({ error: "Unauthorized" });

    jwt.verify(token, secretKey, async (err, decoded) => {
      if (err) return res.status(401).json({ error: "Invalid token" });

      try {
        const { symptomDescription } = req.body;
        const userId = decoded.userId;

        client = await getConnection();
        const patients = client.db("Wellcheck2").collection("Patient");

        // Flat structure — assigned_doctor at top level
        const patient = await patients.findOne({ _id: userId });
        if (!patient) {
          return res.status(404).json({ error: "Patient not found" });
        }

        const doctorId = patient.assigned_doctor;
        if (!doctorId) {
          return res.status(404).json({ error: "Assigned doctor not found" });
        }

        const symptomId = uuidv4();
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
        if (client) await client.close();
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
    if (!token) return res.status(401).json({ error: "Unauthorized" });

    jwt.verify(token, secretKey, async (err, decoded) => {
      if (err) return res.status(401).json({ error: "Invalid token" });

      try {
        const userId = req.params.userId;
        client = await getConnection();
        const symptoms = client.db("Wellcheck2").collection("Symptom");
        const userSymptoms = await symptoms.find({ userId }).toArray();
        res.json(userSymptoms);
      } catch (error) {
        console.error(error);
        res.status(500).json({ error: "Internal server error" });
      } finally {
        if (client) await client.close();
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
    if (!token) return res.status(401).json({ error: "Unauthorized" });

    jwt.verify(token, secretKey, async (err, decoded) => {
      if (err) return res.status(401).json({ error: "Invalid token" });

      try {
        const { symptomId, symptomDescription } = req.body;
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
        if (client) await client.close();
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
    if (!token) return res.status(401).json({ error: "Unauthorized" });

    jwt.verify(token, secretKey, async (err, decoded) => {
      if (err) return res.status(401).json({ error: "Invalid token" });

      try {
        const symptomId = req.params.symptomId;
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
        if (client) await client.close();
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
    if (client) await client.close();
  }
});

// Get medicines endpoint
app.get("/medicines", async (req, res) => {
  let client;
  try {
    client = await getConnection();
    const medicineCollection = client.db("Wellcheck2").collection("Medicine");
    const medicineDocs = await medicineCollection.find().toArray();

    // Flatten the Firebase-style nested structure
    const medicines = medicineDocs.map(doc => {
      const key = Object.keys(doc).find(k => k !== '_id');
      return doc[key];
    });

    res.json(medicines);
  } catch (error) {
    console.error("Error fetching medicines:", error.message);
    res.status(500).json({ error: "Failed to fetch medicines" });
  } finally {
    if (client) await client.close();
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
    if (client) await client.close();
  }
});

// Get hospital by ID endpoint
app.get("/hospitals/:hospitalId", async (req, res) => {
  let client;
  try {
    client = await getConnection();
    const hospitalsCollection = client.db("Wellcheck2").collection("hospitals");
    const hospitalId = req.params.hospitalId;
    const hospital = await hospitalsCollection.findOne({ _id: new ObjectId(hospitalId) });

    if (!hospital) {
      return res.status(404).json({ error: "Hospital not found" });
    }

    res.json(hospital.form_fields);
  } catch (error) {
    console.error("Error fetching hospital fields:", error);
    res.status(500).json({ error: "Failed to fetch hospital fields" });
  } finally {
    if (client) await client.close();
  }
});

// Get appointments endpoint
app.get("/appointments/:userId", async (req, res) => {
  let client;
  try {
    const token = req.headers.authorization?.split(" ")[1];
    if (!token) return res.status(401).json({ error: "Unauthorized" });

    jwt.verify(token, secretKey, async (err, decoded) => {
      if (err) return res.status(401).json({ error: "Invalid token" });

      try {
        const userId = req.params.userId;
        client = await getConnection();
        const appointments = client.db("Wellcheck2").collection("appointments");
        const userAppointments = await appointments.find({ userId }).toArray();
        res.json(userAppointments);
      } catch (dbError) {
        console.error("Database Error:", dbError);
        res.status(500).json({ error: "Failed to fetch appointments" });
      } finally {
        if (client) await client.close();
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
    const token = req.headers.authorization?.split(" ")[1];
    if (!token) return res.status(401).json({ error: "Unauthorized" });

    let decoded;
    try {
      decoded = jwt.verify(token, secretKey);
    } catch (err) {
      return res.status(401).json({ error: "Invalid token" });
    }

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
      consultationCost = 0.00,
      equipmentCost = 0.00,
      statusPayment = "Not Paid",
      statusAppointment = "Not Approved",
    } = req.body;

    const userId = decoded.userId;

    if (!appointmentDate || !appointmentTime || !duration || !typeOfSickness || !email || appointmentCost == null) {
      return res.status(400).json({ error: "Missing required fields" });
    }

    try {
      client = await getConnection();
      const patients = client.db("Wellcheck2").collection("Patient");

      // Flat structure — assigned_doctor at top level
      const patient = await patients.findOne({ _id: userId });
      if (!patient) {
        return res.status(404).json({ error: "Patient not found" });
      }

      const doctorId = patient.assigned_doctor;
      if (!doctorId) {
        return res.status(404).json({ error: "Assigned doctor not found" });
      }

      const appointmentId = uuidv4();
      const appointments = client.db("Wellcheck2").collection("appointments");

      const existingAppointment = await appointments.findOne({ userId, appointmentDate, appointmentTime });
      if (existingAppointment) {
        return res.status(400).json({ error: "Appointment already exists for the selected date and time" });
      }

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
        consultationCost,
        equipmentCost,
        statusPayment,
        statusAppointment,
        timestamp: new Date(appointmentDate),
      };

      const result = await appointments.insertOne(newAppointment);
      if (result.acknowledged) {
        res.status(201).json({ message: "Appointment created successfully", appointment: newAppointment });
      } else {
        res.status(500).json({ error: "Failed to create appointment" });
      }
    } catch (mongoError) {
      console.error("MongoDB Error:", mongoError.message);
      res.status(500).json({ error: "Database error occurred", details: mongoError.message });
    } finally {
      if (client) await client.close();
    }
  } catch (error) {
    console.error("Error:", error);
    res.status(500).json({ error: "Internal server error" });
  }
});

// Update appointment endpoint
app.put("/update-appointment/:appointmentId", async (req, res) => {
  let client;
  try {
    const token = req.headers.authorization?.split(" ")[1];
    if (!token) return res.status(401).json({ error: "Unauthorized" });

    const { appointmentDate, appointmentTime, duration, typeOfSickness } = req.body;
    const { appointmentId } = req.params;

    if (!appointmentDate || !appointmentTime || !duration || !typeOfSickness) {
      return res.status(400).json({ error: "Missing required fields" });
    }

    const fullAppointmentDateTime = new Date(`${appointmentDate}T${appointmentTime}:00.000Z`);

    try {
      client = await getConnection();
      const appointments = client.db("Wellcheck2").collection("appointments");

      const result = await appointments.updateOne(
        { appointmentId },
        { $set: { appointmentDate: fullAppointmentDateTime, appointmentTime, duration, typeOfSickness } }
      );

      if (result.modifiedCount === 0) {
        return res.status(404).json({ error: "Appointment not found" });
      }

      res.status(200).json({ message: "Appointment updated successfully", appointmentId });
    } finally {
      if (client) await client.close();
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
      { $set: { statusPayment, statusAppointment } }
    );

    if (result.modifiedCount === 0) {
      return res.status(404).json({ error: "Appointment not found" });
    }

    res.status(200).json({ message: "Appointment status updated successfully" });
  } catch (error) {
    console.error("Error updating appointment:", error);
    res.status(500).json({ error: "Internal server error" });
  } finally {
    if (client) await client.close();
  }
});

// Delete appointment endpoint
app.delete('/delete-appointment/:appointmentId', async (req, res) => {
  let client;
  try {
    const token = req.headers.authorization?.split(" ")[1];
    if (!token) return res.status(401).json({ error: "Unauthorized" });

    jwt.verify(token, secretKey, async (err, decoded) => {
      if (err) return res.status(401).json({ error: "Invalid token" });

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
        if (client) await client.close();
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
    if (!token) return res.status(401).json({ error: "Unauthorized" });

    jwt.verify(token, secretKey, async (err, decoded) => {
      if (err) return res.status(401).json({ error: "Invalid token" });

      try {
        const userId = req.params.userId;
        const updates = req.body;

        client = await getConnection();
        const patients = client.db("Wellcheck2").collection("Patient");

        // Flat structure — update fields directly
        const updateData = {};
        if (updates.address) updateData.address = updates.address;
        if (updates.contact) updateData.contact = updates.contact;
        if (updates.emergencyContact) updateData.emergencyContact = updates.emergencyContact;
        if (updates.name) updateData.name = updates.name;

        const result = await patients.updateOne({ _id: userId }, { $set: updateData });

        if (result.matchedCount === 0) {
          return res.status(404).json({ error: "Patient not found" });
        }

        res.json({ message: "Patient updated successfully" });
      } catch (error) {
        console.error(error);
        res.status(500).json({ error: "Internal server error" });
      } finally {
        if (client) await client.close();
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
    const token = req.headers.authorization?.split(" ")[1];
    if (!token) return res.status(401).json({ error: "Unauthorized" });

    jwt.verify(token, secretKey, async (err, decoded) => {
      if (err) return res.status(401).json({ error: "Invalid token" });

      try {
        client = await getConnection();
        const userId = req.params.userId;
        const updates = req.body;
        const userCollection = client.db("Wellcheck2").collection("User");

        const updateFields = {};
        Object.keys(updates).forEach(key => { updateFields[key] = updates[key]; });

        const result = await userCollection.updateOne({ _id: userId }, { $set: updateFields });

        if (result.modifiedCount === 0) {
          return res.status(404).json({ error: "User not found" });
        }

        res.json({ message: "User updated successfully" });
      } catch (error) {
        console.error('Error:', error);
        res.status(500).json({ error: "Internal server error" });
      } finally {
        if (client) await client.close();
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
    if (!token) return res.status(401).json({ error: "Unauthorized" });

    jwt.verify(token, secretKey, async (err, decoded) => {
      if (err) return res.status(401).json({ error: "Invalid token" });

      try {
        const userId = req.params.userId;
        const { newPassword } = req.body;

        if (!newPassword) {
          return res.status(400).json({ error: "New password is required" });
        }

        client = await getConnection();
        const users = client.db("Wellcheck2").collection("User");
        const hashedPassword = await bcrypt.hash(newPassword, 10);

        const updateResult = await users.updateOne(
          { _id: userId },
          { $set: { password: hashedPassword } }
        );

        if (updateResult.matchedCount === 0) {
          return res.status(404).json({ error: "User not found" });
        }

        res.json({ message: "Password updated successfully" });
      } catch (error) {
        console.error("Error:", error);
        res.status(500).json({ error: "Internal server error" });
      } finally {
        if (client) await client.close();
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
    const { profilepic } = req.body;

    if (!profilepic) {
      return res.status(400).json({ error: "Profile picture is required" });
    }

    client = await getConnection();
    const users = client.db("Wellcheck2").collection("User");
    const result = await users.updateOne({ _id: userId }, { $set: { profilepic } });

    if (result.matchedCount === 0) {
      return res.status(404).json({ error: "User not found" });
    }

    res.json({ message: "Profile picture updated successfully" });
  } catch (error) {
    console.error("Upload Error:", error);
    res.status(500).json({ error: "Internal server error" });
  } finally {
    if (client) await client.close();
  }
});

// Get profile image endpoint
app.get("/user/profileImage/:userId", async (req, res) => {
  let client;
  try {
    const userId = req.params.userId;
    client = await getConnection();
    const users = client.db("Wellcheck2").collection("User");
    const userDoc = await users.findOne({ _id: userId });

    if (!userDoc || !userDoc.profilepic) {
      return res.status(404).json({ error: "Profile image not found" });
    }

    res.json({ profilepic: userDoc.profilepic });
  } catch (error) {
    console.error("Error fetching profile image:", error);
    res.status(500).json({ error: "Internal server error" });
  } finally {
    if (client) await client.close();
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

    client = await getConnection();
    const users = client.db("Wellcheck2").collection("User");
    const userDoc = await users.findOne({ _id: userId });

    if (!userDoc) {
      return res.status(404).json({ error: "User not found" });
    }

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
    if (client) await client.close();
  }
});

// Logout endpoint
app.post("/logout", (req, res) => {
  const token = req.headers.authorization?.split(" ")[1];
  if (!token) return res.status(401).json({ error: "No token provided" });

  try {
    tokenBlacklist.add(token);
    res.json({ message: "Logged out successfully" });
  } catch (error) {
    res.status(500).json({ error: "Failed to logout" });
  }
});

// Health check endpoint
app.get("/health", (req, res) => {
  res.json({
    status: "Server is running",
    port,
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
    const collections = await db.listCollections().toArray();
    const collectionNames = collections.map(col => col.name);
    res.json({ status: "Database connected successfully", database: "Wellcheck2", collections: collectionNames });
  } catch (error) {
    console.error("Database connection error:", error);
    res.status(500).json({ error: "Database connection failed", details: error.message });
  } finally {
    if (client) await client.close();
  }
});

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