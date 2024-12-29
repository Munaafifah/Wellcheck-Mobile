const express = require("express");
const bodyParser = require("body-parser");
const cors = require("cors");
const jwt = require("jsonwebtoken");
const bcrypt = require("bcrypt");
const { MongoClient } = require("mongodb");

const app = express();
app.use(bodyParser.json());
app.use(cors());
const port = 5001;



const uri = "mongodb+srv://admin:admin@atlascluster.htlbqbu.mongodb.net/";
const client = new MongoClient(uri);
const secretKey = "your_secret_key"; // Replace with your secure key

// Login endpoint
app.post("/login", async (req, res) => {
  try {
    const { userId, password } = req.body;

    // Connect to the database
    await client.connect();
    const users = client.db("Wellcheck2").collection("User");

    // Find the user by _id and nested key
    const userDoc = await users.findOne({ _id: userId });
    if (!userDoc || !userDoc[userId]) {
      return res.status(404).json({ error: "User not found" });
    }

    const user = userDoc[userId]; // Access the nested user data

    // Check if the user is a patient
    if (user.role !== "PATIENT") {
      return res.status(403).json({ error: "Access restricted to patients" });
    }

    // Validate the password
    const isPasswordValid = password === user.password; // If using bcrypt, update this logic
    if (!isPasswordValid) {
      return res.status(401).json({ error: "Invalid password" });
    }

    // Generate a JWT token
    const token = jwt.sign({ userId: user.userId }, "your_secret_key");
    res.json({ token });
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: "Internal server error" });
  }
});

// Fetch patient details endpoint
app.get("/patient/:userId", async (req, res) => {
  try {
    const token = req.headers.authorization?.split(" ")[1];
    if (!token) {
      return res.status(401).json({ error: "Unauthorized" });
    }

    // Verify token
    jwt.verify(token, "your_secret_key", async (err, decoded) => {
      if (err) {
        return res.status(401).json({ error: "Invalid token" });
      }

      const userId = req.params.userId;
      await client.connect();
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
    });
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: "Internal server error" });
  }
});

app.get("/prescriptions/:userId", async (req, res) => {
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

      const userId = req.params.userId;
      await client.connect();
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
    });
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: "Internal server error" });
  }
});
  
  const { v4: uuidv4 } = require("uuid"); // Add this for unique ID generation

  app.get("/predictions/:userId", async (req, res) => {
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
  
        const userId = req.params.userId;
        await client.connect();
        const patients = client.db("Wellcheck2").collection("Patient");
  
        // Fetch the patient document
        const patientDoc = await patients.findOne({ _id: userId });
        if (!patientDoc || !patientDoc[userId]) {
          return res.status(404).json({ error: "Patient not found" });
        }
  
        const patient = patientDoc[userId];
        // Access predictions data in the patient document
        if (!patient.Prediction || Object.keys(patient.Prediction).length === 0) {
          return res
            .status(404)
            .json({ error: "No predictions found for this patient" });
        }
  
        // Return all predictions as an array
        const predictions = Object.values(patient.Prediction);
        res.json(predictions);
      });
    } catch (error) {
      console.error(error);
      res.status(500).json({ error: "Internal server error" });
    }
  });

  app.get("/healthstatus/:userId", async (req, res) => {
    try {
      const token = req.headers.authorization?.split(" ")[1];
      if (!token) {
        return res.status(401).json({ error: "Unauthorized" });
      }
  
      jwt.verify(token, secretKey, async (err, decoded) => {
        if (err) {
          return res.status(401).json({ error: "Invalid token" });
        }
  
        const userId = req.params.userId;
        await client.connect();
        const patients = client.db("Wellcheck2").collection("Patient");
  
        const patientDoc = await patients.findOne({ _id: userId });
        if (!patientDoc || !patientDoc[userId]) {
          return res.status(404).json({ error: "Patient not found" });
        }
  
        const patient = patientDoc[userId];
        // Changed from Healthstatus to HealthStatus
        if (!patient.HealthStatus || Object.keys(patient.HealthStatus).length === 0) {
          return res
            .status(404)
            .json({ error: "No healthstatus found for this patient" });
        }
  
        // Changed from Healthstatus to HealthStatus
        const healthstatusList = Object.values(patient.HealthStatus);
        res.json(healthstatusList);
      });
    } catch (error) {
      console.error(error);
      res.status(500).json({ error: "Internal server error" });
    }
  });
  
  // server.js
  app.delete("/healthstatus/:userId/:healthStatusId", async (req, res) => {
    try {
      const token = req.headers.authorization?.split(" ")[1];
      if (!token) {
        return res.status(401).json({ error: "Unauthorized" });
      }
  
      jwt.verify(token, secretKey, async (err, decoded) => {
        if (err) {
          return res.status(401).json({ error: "Invalid token" });
        }
  
        const userId = req.params.userId;
        const healthStatusId = req.params.healthStatusId;
  
        await client.connect();
        const patients = client.db("Wellcheck2").collection("Patient");
  
        const patientDoc = await patients.findOne({ _id: userId });
        if (!patientDoc || !patientDoc[userId]) {
          return res.status(404).json({ error: "Patient not found" });
        }
  
        const patient = patientDoc[userId];
        if (!patient.HealthStatus || !patient.HealthStatus[healthStatusId]) {
          return res
            .status(404)
            .json({ error: "Health status entry not found" });
        }
  
        // Remove the health status entry from the HealthStatus object
        delete patient.HealthStatus[healthStatusId];
  
        // Update the patient document with the modified HealthStatus
        await patients.updateOne(
          { _id: userId },
          { $set: { [userId]: patient } }
        );
  
        res.json({ message: "Health status entry deleted" });
      });
    } catch (error) {
      console.error(error);
      res.status(500).json({ error: "Internal server error" });
    }
  });

  app.post("/add-symptom", async (req, res) => {
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
  
        const { symptomDescription } = req.body;
        const userId = decoded.userId;
  
        // Fetch patient details
        await client.connect();
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
          symptomId, // Add symptomId
          userId,
          doctorId,
          symptomDescription,
          timestamp: new Date(),
        };
        await symptoms.insertOne(newSymptom);
  
        res.json({ message: "Symptom added successfully", symptom: newSymptom });
      });
    } catch (error) {
      res.status(500).json({ error: "Internal server error" });
    }
  });



  app.get("/symptoms/:userId", async (req, res) => {
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
  
        const userId = req.params.userId;
  
        // Fetch symptoms for the user
        await client.connect();
        const symptoms = client.db("Wellcheck2").collection("Symptom");
        const userSymptoms = await symptoms.find({ userId }).toArray();
  
        res.json(userSymptoms);
      });
    } catch (error) {
      res.status(500).json({ error: "Internal server error" });
    }
  });
  
  
  app.put("/update-symptom", async (req, res) => {
    try {
      const token = req.headers.authorization?.split(" ")[1];
      if (!token) {
        return res.status(401).json({ error: "Unauthorized" });
      }
  
      jwt.verify(token, secretKey, async (err, decoded) => {
        if (err) {
          return res.status(401).json({ error: "Invalid token" });
        }
  
        const { symptomId, symptomDescription } = req.body;
  
        // Update the symptom
        await client.connect();
        const symptoms = client.db("Wellcheck").collection("symptoms");
        const result = await symptoms.updateOne(
          { symptomId },
          { $set: { symptomDescription } }
        );
  
        if (result.modifiedCount === 0) {
          return res.status(404).json({ error: "Symptom not found" });
        }
  
        res.json({ message: "Symptom updated successfully" });
      });
    } catch (error) {
      res.status(500).json({ error: "Internal server error" });
    }
  });
  
  app.delete("/delete-symptom/:symptomId", async (req, res) => {
    try {
      const token = req.headers.authorization?.split(" ")[1];
      if (!token) {
        return res.status(401).json({ error: "Unauthorized" });
      }
  
      jwt.verify(token, secretKey, async (err, decoded) => {
        if (err) {
          return res.status(401).json({ error: "Invalid token" });
        }
  
        const symptomId = req.params.symptomId;
  

        // Delete the symptom
        await client.connect();
        const symptoms = client.db("Wellcheck").collection("symptoms");
        const result = await symptoms.deleteOne({ symptomId });
  
        if (result.deletedCount === 0) {
          return res.status(404).json({ error: "Symptom not found" });
        }
  
        res.json({ message: "Symptom deleted successfully" });
      });
    } catch (error) {
      res.status(500).json({ error: "Internal server error" });
    }
  });

  const tokenBlacklist = new Set(); // In-memory blacklist (use Redis for production)

  

  app.get("/sickness", async (req, res) => {
  try {
    await client.connect();
    const sicknessCollection = client.db("Wellcheck2").collection("sickness"); // Adjust collection name accordingly
    const sicknesses = await sicknessCollection.find().toArray(); // Fetch all sickness records

    res.json(sicknesses);
  } catch (dbError) {
    console.error("Database Error:", dbError);
    res.status(500).json({ error: "Failed to fetch sickness records" });
  } finally {
    await client.close(); // Ensure database connection is closed
  }
});

app.get("/hospitals", async (req, res) => {
  let client;
  try {
    client = await MongoClient.connect(uri, { useNewUrlParser: true, useUnifiedTopology: true });
    const hospitalsCollection = client.db("Wellcheck2").collection("hospitals");
    const hospitals = await hospitalsCollection.find().toArray();

    if (!hospitals.length) {
      return res.status(404).json({ error: "No hospitals found" });
    }

    res.json(hospitals);
  } catch (error) {
    console.error("Error fetching hospitals:", error.message); // Enhanced log to show actual error message
    res.status(500).json({ error: "Failed to fetch hospitals. Details: " + error.message });
  } finally {
    if (client) {
      await client.close(); // Ensure client connection is closed
    }
  }
});

// Endpoint to fetch fields for a specific hospital
app.get("/hospitals/:hospitalId", async (req, res) => {
  try {
    await client.connect();
    const hospitalsCollection = client.db("Wellcheck2").collection("hospitals");

    const hospitalId = req.params.hospitalId;

    // Fetch the hospital by ID, converting the id to ObjectId
    const hospital = await hospitalsCollection.findOne({ _id: ObjectId(hospitalId) });

    if (!hospital) {
      return res.status(404).json({ error: "Hospital not found" }); // Adjusted error response
    }

    // Return the hospital's dynamic form fields
    res.json(hospital.form_fields);
  } catch (error) {
    console.error("Error fetching hospital fields:", error);
    res.status(500).json({ error: "Failed to fetch hospital fields" });
  } finally {
    await client.close(); // Ensure client connection is closed
  }
});

app.get("/appointments/:userId", async (req, res) => {
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

      const userId = req.params.userId;

      // Fetch appointments for the user
      try {
        await client.connect();
        const appointments = client.db("Wellcheck2").collection("appointments");
        const userAppointments = await appointments.find({ userId }).toArray();

        res.json(userAppointments);
      } catch (dbError) {
        console.error("Database Error:", dbError);
        res.status(500).json({ error: "Failed to fetch appointments" });
      } finally {
        await client.close(); // Ensure database connection is closed
      }
    });
  } catch (error) {
    console.error("Error:", error);
    res.status(500).json({ error: "Internal server error" });
  }
});


// Endpoint for adding a new appointment
app.post("/appointments", async (req, res) => {
  try {
    // Extract the token from the Authorization header
    const token = req.headers.authorization?.split(" ")[1];
    if (!token) {
      return res.status(401).json({ error: "Unauthorized" });
    }

    // Verify the JWT
    let decoded;
    try {
      decoded = jwt.verify(token, secretKey); // Ensure secretKey is set up correctly
    } catch (err) {
      return res.status(401).json({ error: "Invalid token" });
    }

    // Extract data from the request body
    const {
      appointmentDate,
      appointmentTime,
      duration,
      typeOfSickness,
      additionalNotes,
      email,
      insuranceProvider,
      insurancePolicyNumber,
      appointmentCost,
      hospitalId, // Ensure this is included in the request body
      statusPayment = "Not Paid",
      statusAppointment = "Not Approved",
    } = req.body;

    const userId = decoded.userId; // Get userId from the JWT payload

    // Validate required fields
    if (
      !appointmentDate ||
      !appointmentTime ||
      !duration ||
      !typeOfSickness ||
      !email
      
    ) {
      return res.status(400).json({ error: "Missing required fields" });
    }

    try {
      await client.connect(); // Connect to MongoDB
      console.log("Connected to MongoDB");

      // Fetch patient details to get the assigned doctor
      const patients = client.db("Wellcheck2").collection("Patient");
      const patient = await patients.findOne({ _id: userId });

      if (!patient) {
        return res.status(404).json({ error: "Patient not found" });
      }

      const appointmentId = uuidv4(); // Generate a new appointment ID
      const doctorId = patient[userId]?.assigned_doctor; // Access the assigned doctor

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
        hospitalId, // Store the hospital ID here
        appointmentDate,
        appointmentTime,
        duration,
        typeOfSickness,
        additionalNotes: additionalNotes || null,
        insuranceProvider: insuranceProvider || null,
        insurancePolicyNumber: insurancePolicyNumber || null,
        email,
        appointmentCost,
        statusPayment,
        statusAppointment,
        timestamp: new Date(appointmentDate), // Ensure timestamp is set correctly
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
      console.error("MongoDB Error:", mongoError);
      res.status(500).json({ error: "Database error occurred" });
    } finally {
      await client.close(); // Ensure the client connection is closed
      console.log("Disconnected from MongoDB");
    }
  } catch (error) {
    console.error("Error:", error);
    res.status(500).json({ error: "Internal server error" });
  }
});







  // Start the server
  app.listen(port, () => {
    console.log(`Server is running on http://localhost:${port}`);
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

// Middleware to check for blacklisted tokens
app.use((req, res, next) => {
  const token = req.headers.authorization?.split(" ")[1];
  if (token && tokenBlacklist.has(token)) {
    return res.status(401).json({ error: "Token is invalid or expired" });
  }
  next();
});

  
const PORT = 5000;
app.listen(PORT, () => console.log(`Server running on port ${PORT}`));
