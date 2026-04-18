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
        const { diagnosisList, probabilityList, symptomsList, timestamp, approved, rejected } = req.body;

        if (!diagnosisList || !probabilityList || !symptomsList) {
          return res.status(400).json({ error: "Missing required fields" });
        }

        const predictionID = uuidv4();
        const newPrediction = {
          predictionID,                                           // 1st
          symptomsList,                                           // 2nd
          diagnosisList,                                          // 3rd
          probabilityList,                                        // 4th
          timestamp: timestamp ? new Date(timestamp) : new Date(), // 5th - Date object
          approved: approved ?? false,                            // 6th
          rejected: rejected ?? false,                            // 7th
        };

        const existingPatient = await patients.findOne({ _id: userId });
        if (!existingPatient) {
          return res.status(404).json({ error: "Patient not found" });
        }

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

// Add health status endpoint (called from mobile after prediction)
app.post("/add-healthstatus", async (req, res) => {
  let client;
  try {
    const token = req.headers.authorization?.split(" ")[1];
    if (!token) return res.status(401).json({ error: "Unauthorized" });

    jwt.verify(token, secretKey, async (err, decoded) => {
      if (err) return res.status(401).json({ error: "Invalid token" });

      try {
        const userId = decoded.userId;
        const { additionalNotes, diagnosisList } = req.body; // ← add diagnosisList

        client = await getConnection();
        const patients = client.db("Wellcheck2").collection("Patient");
        const healthStatusCollection = client.db("Wellcheck2").collection("HealthStatus");

        const patient = await patients.findOne({ _id: userId });
        if (!patient) return res.status(404).json({ error: "Patient not found" });

        const doctorId = patient.assigned_doctor || "";

        const newHealthStatus = {
          healthStatusId: uuidv4(), // ← use existing uuidv4, not require()
          userId,
          doctorId,
          additionalNotes: additionalNotes || "",
          diagnosisList: diagnosisList || [], // ← add this
          timestamp: new Date(),
        };

        await healthStatusCollection.insertOne(newHealthStatus);

        res.status(200).json({
          message: "Health status saved successfully",
          healthStatus: newHealthStatus,
        });
      } catch (error) {
        console.error("Error saving health status:", error);
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
      statusPayment = "Not Paid",
      statusAppointment = "Not Approved",
    } = req.body;

    const userId = decoded.userId;

    if (!appointmentDate || !appointmentTime || !duration || !typeOfSickness || !email) {
      return res.status(400).json({ error: "Missing required fields" });
    }

    try {
      client = await getConnection();
      const patients = client.db("Wellcheck2").collection("Patient");

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
        costItems: [],       // ✅ Clinic Assistant fills this later
        drugCost: 0,         // ✅ Doctor fills this via prescription
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

// Billing endpoint - aggregates drug, consultation, equipment costs from appointments
app.get("/api/billing/:userId", async (req, res) => {
  let client;
  try {
    const token = req.headers.authorization?.split(" ")[1];
    if (!token) return res.status(401).json({ error: "Unauthorized" });

    jwt.verify(token, secretKey, async (err, decoded) => {
      if (err) return res.status(401).json({ error: "Invalid token" });

      try {
        const userId = req.params.userId;
        console.log("BILLING: looking up userId =", userId); // ✅ debug

        client = await getConnection();
        const appointments = client.db("Wellcheck2").collection("appointments");

        const userAppointments = await appointments.find({
          userId,
          statusAppointment: "Approved", // ✅ only approved
        }).toArray();

        console.log("BILLING: found appointments =", userAppointments.length); // ✅ debug

        if (!userAppointments.length) {
          return res.status(404).json({ error: "No appointments found for this user" });
        }

        const billings = userAppointments.map((appt) => {
          const label = appt.typeOfSickness || "General";
          const date = appt.appointmentDate
            ? new Date(appt.appointmentDate).toLocaleDateString("en-MY")
            : "";

          // Drug cost stays separate — comes from prescription, not clinic assistant
          const drugCosts = [];
          if (appt.drugCost && appt.drugCost > 0) {
            drugCosts.push({ name: `Drug - ${label} (${date})`, amount: appt.drugCost });
          }

          // Dynamic cost items from clinic assistant
          const costItems = (appt.costItems || []).map(item => ({
            name: item.label || "Charge",
            amount: typeof item.amount === "number" ? item.amount : parseFloat(item.amount) || 0,
          }));

          const totalCost = [
            ...drugCosts,
            ...costItems,
          ].reduce((sum, item) => sum + item.amount, 0);

          return {
            billingId: appt.appointmentId,
            userId,
            drugCosts,
            costItems,
            totalCost,
            statusPayment: appt.statusPayment || "Not Paid",
            timestamp: appt.timestamp || new Date().toISOString(),
            appointmentDate: appt.appointmentDate ?? null,
            appointmentTime: appt.appointmentTime ?? null,
            duration: appt.duration ?? null,
            registeredHospital: appt.registeredHospital ?? null,
            typeOfSickness: appt.typeOfSickness ?? null,
          };
        });

        res.json(billings);
      } catch (error) {
        console.error("Billing error:", error);
        res.status(500).json({ error: "Internal server error" });
      } finally {
        if (client) await client.close();
      }
    });
  } catch (error) {
    console.error("Billing error:", error);
    res.status(500).json({ error: "Internal server error" });
  }
});

// Mark all appointments as paid
app.post("/api/billing/pay", async (req, res) => {
  let client;
  try {
    const token = req.headers.authorization?.split(" ")[1];
    if (!token) return res.status(401).json({ error: "Unauthorized" });

    jwt.verify(token, secretKey, async (err, decoded) => {
      if (err) return res.status(401).json({ error: "Invalid token" });

      try {
        const { userId } = req.body;
        client = await getConnection();
        const appointments = client.db("Wellcheck2").collection("appointments");

        await appointments.updateMany(
          { userId, statusPayment: "Not Paid" },
          { $set: { statusPayment: "Paid", statusAppointment: "Paid" } }
        );

        res.json({ message: "All appointments marked as paid" });
      } catch (error) {
        console.error("Pay billing error:", error);
        res.status(500).json({ error: "Internal server error" });
      } finally {
        if (client) await client.close();
      }
    });
  } catch (error) {
    res.status(500).json({ error: "Internal server error" });
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

// ── Get all doctors endpoint (for Flutter doctor picker) ──────────────
app.get("/doctors", async (req, res) => {
  let client;
  try {
    const token = req.headers.authorization?.split(" ")[1];
    if (!token) return res.status(401).json({ error: "Unauthorized" });

    jwt.verify(token, secretKey, async (err, decoded) => {
      if (err) return res.status(401).json({ error: "Invalid token" });

      try {
        client = await getConnection();
        const schedules = client.db("Wellcheck2").collection("Doctor Schedule");

        // Only return active doctors that have a schedule
        const doctorSchedules = await schedules.find({ isActive: true }).toArray();

        const doctors = doctorSchedules.map(doc => ({
          doctorId: doc._id,
          doctorName: doc.doctorName,
          workingDays: doc.workingDays,
          workingHours: doc.workingHours,
          slotDurationMinutes: doc.slotDurationMinutes,
        }));

        res.json(doctors);
      } catch (error) {
        console.error("Error fetching doctors:", error);
        res.status(500).json({ error: "Internal server error" });
      } finally {
        if (client) await client.close();
      }
    });
  } catch (error) {
    res.status(500).json({ error: "Internal server error" });
  }
});

// ── Get doctor availability by date ───────────────────────────────────
// GET /doctors/:doctorId/availability?date=2026-04-20
app.get("/doctors/:doctorId/availability", async (req, res) => {
  let client;
  try {
    const token = req.headers.authorization?.split(" ")[1];
    if (!token) return res.status(401).json({ error: "Unauthorized" });

    jwt.verify(token, secretKey, async (err, decoded) => {
      if (err) return res.status(401).json({ error: "Invalid token" });

      try {
        const { doctorId } = req.params;
        const { date } = req.query; // e.g. "2026-04-20"

        if (!date) {
          return res.status(400).json({ error: "date query param is required (e.g. ?date=2026-04-20)" });
        }

        client = await getConnection();
        const schedules = client.db("Wellcheck2").collection("Doctor Schedule");
        const appointments = client.db("Wellcheck2").collection("appointments");

        // 1. Load the doctor's schedule
        const schedule = await schedules.findOne({ _id: doctorId });
        if (!schedule) {
          return res.status(404).json({ error: "No schedule found for this doctor" });
        }

        if (!schedule.isActive) {
          return res.status(400).json({ error: "Doctor is not currently active" });
        }

        // 2. Check if requested date falls on a working day
        const requestedDate = new Date(date + "T00:00:00.000Z");
        const dayName = requestedDate.toLocaleDateString("en-US", { weekday: "long", timeZone: "UTC" });

        if (!schedule.workingDays.includes(dayName)) {
          return res.json({
            doctorId,
            date,
            dayName,
            isWorkingDay: false,
            slots: [],
            message: `Doctor does not work on ${dayName}`,
          });
        }

        // 3. Generate all time slots for that day
        const slotDuration = schedule.slotDurationMinutes || 30;
        const [startHour, startMin] = schedule.workingHours.start.split(":").map(Number);
        const [endHour, endMin] = schedule.workingHours.end.split(":").map(Number);

        const startTotal = startHour * 60 + startMin;
        const endTotal = endHour * 60 + endMin;

        // Parse break times
        const breaks = (schedule.breakTimes || []).map(b => {
          const [bsh, bsm] = b.start.split(":").map(Number);
          const [beh, bem] = b.end.split(":").map(Number);
          return { start: bsh * 60 + bsm, end: beh * 60 + bem };
        });

        const allSlots = [];
        for (let t = startTotal; t < endTotal; t += slotDuration) {
          const h = Math.floor(t / 60).toString().padStart(2, "0");
          const m = (t % 60).toString().padStart(2, "0");
          const timeStr = `${h}:${m}`;

          // Check if slot falls within any break
          const isDuringBreak = breaks.some(b => t >= b.start && t < b.end);
          if (!isDuringBreak) {
            allSlots.push(timeStr);
          }
        }

        // 4. Find booked slots for this doctor on this date
        // appointments store appointmentDate as "2026-04-20" string
        const bookedAppointments = await appointments.find({
          doctorId,
          appointmentDate: date,
          statusAppointment: { $in: ["Approved", "Not Approved"] }, // block pending too
        }).toArray();

        const bookedTimes = new Set(bookedAppointments.map(a => a.appointmentTime));

        // 5. Build final slot list
        const slots = allSlots.map(time => ({
          time,
          available: !bookedTimes.has(time),
        }));

        res.json({
          doctorId,
          doctorName: schedule.doctorName,
          date,
          dayName,
          isWorkingDay: true,
          slotDurationMinutes: slotDuration,
          slots,
        });

      } catch (error) {
        console.error("Error fetching availability:", error);
        res.status(500).json({ error: "Internal server error" });
      } finally {
        if (client) await client.close();
      }
    });
  } catch (error) {
    res.status(500).json({ error: "Internal server error" });
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