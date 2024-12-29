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

  app.post('/predictions2', async (req, res) => {
    try {
        const token = req.headers.authorization?.split(" ")[1];
        if (!token) {
            return res.status(401).json({ error: "Unauthorized" });
        }
  
        jwt.verify(token, secretKey, async (err, decoded) => {
            if (err) {
                return res.status(401).json({ error: "Invalid token" });
            }
  
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
        });
    } catch (error) {
        console.error("Error saving prediction:", error);
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

//Get hospitals
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

// Get hospital by name and fields
app.get('/hospitals/:name/fields', async (req, res) => {
  try {
    const hospital = await Hospital.findOne({ name: req.params.name });
    
    if (!hospital) {
      console.log(`Hospital not found for name: ${req.params.name}`);
      return res.status(404).json({ message: 'Hospital not found' });
    }
    
    const responseFields = hospital.fields.map(field => ({
      label: field.label,
      type: field.type,
      options: field.options || [], // Ensure options default to an empty array if none exist
      required: field.required,
    }));
    
    res.json({ fields: responseFields });
  } catch (error) {
    console.error('Error getting hospital fields:', error);
    res.status(500).json({ message: 'Error getting hospital fields', error });
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

/// Endpoint for adding a new appointment
// Endpoint for adding a new appointment
app.post("/appointments", async (req, res) => {
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
      additionalNotes, // Optional field
      email,
      insuranceProvider,
      insurancePolicyNumber,
      appointmentCost, // New field for cost
      statusPayment = "Not Paid",
      statusAppointment = "Not Approved",
      
    } = req.body;

    const userId = decoded.userId; // Assuming userId is in the JWT payload

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
      await client.connect();
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
        additionalNotes: additionalNotes || null, // If additionalNotes is empty or undefined, set to null
        insuranceProvider:   insuranceProvider || null,
        insurancePolicyNumber:  insurancePolicyNumber || null,
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


// Fetch user details endpoint
app.get("/user/:userId", async (req, res) => {
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
      const users = client.db("Wellcheck2").collection("User");

      // Fetch the user document and access the nested data
      const userDoc = await users.findOne({ _id: userId });

      if (!userDoc || !userDoc[userId]) {
        return res.status(404).json({ error: "User not found" });
      }

      const user = userDoc[userId];  // Access the nested user data
      res.json({
        password: user.password,
        userId: user.userId
      });
    });
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: "Internal server error" });
  }
});

// Update patient details endpoint
app.put("/patient/:userId", async (req, res) => {
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
      const updates = req.body;
      
      await client.connect();
      const patients = client.db("Wellcheck2").collection("Patient");

      // Get the existing patient data
      const existingPatient = await patients.findOne({ _id: userId });

      if (!existingPatient) {
        return res.status(404).json({ error: "Patient not found" });
      }

      // Prepare update object by adding only the fields present in the update request
      const updateData = {};
      
      // Update top-level fields if provided in the request
      if (updates.address) updateData["A1.address"] = updates.address;
      if (updates.contact) updateData["A1.contact"] = updates.contact;
      if (updates.emergencyContact) updateData["A1.emergencyContact"] = updates.emergencyContact;
      if (updates.name) updateData["A1.name"] = updates.name;

      // Optionally, you can update HealthStatus or Prescription fields if provided
      if (updates.HealthStatus) {
        // You can add logic to update specific health status attributes
        updateData["A1.HealthStatus"] = updates.HealthStatus;
      }

      if (updates.Prescription) {
        // You can add logic to update specific prescription attributes
        updateData["A1.Prescription"] = updates.Prescription;
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
    });
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: "Internal server error" });
  }
});

// Update user details endpoint
app.put("/user/:userId", async (req, res) => {
  let connection = null;
  
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
    });

    // Get database connection
    connection = await getConnection();
    const userId = req.params.userId;
    const updates = req.body;

    const userCollection = connection.db("Wellcheck2").collection("User");

    // Create update object for changed fields
    const updateFields = {};
    Object.keys(updates).forEach(key => {
      updateFields[`${userId}.${key}`] = updates[key];
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
    
    // If there's a connection error, reset the client
    if (error.code === 'ECONNRESET') {
      client = null;
    }
  }
});

// Image upload endpoint
app.put("/user/uploadImage/:userId", async (req, res) => {
  try {
    const userId = req.params.userId;
    const { profilepic } = req.body;  // Base64 image data

    if (!profilepic) {
      return res.status(400).json({ error: "Profile picture is required" });
    }

    await client.connect();
    const users = client.db("Wellcheck2").collection("User");

    const fieldPath = `${userId}.profilepic`;
    
    const result = await users.updateOne(
      { _id: userId },
      { $set: { [fieldPath]: profilepic } }
    );

    if (result.matchedCount === 0) {
      return res.status(404).json({ error: "User not found" });
    }

    res.json({ message: "Profile picture updated successfully" });
  } catch (error) {
    console.error("Upload Error:", error);
    res.status(500).json({ error: "Internal server error" });
  }
});

// Increase the payload size limit (e.g., 10MB)
app.use(bodyParser.json({ limit: "50mb" }));
app.use(bodyParser.urlencoded({ limit: "50mb", extended: true }));

app.get("/user/profileImage/:userId", async (req, res) => {
  try {
    const userId = req.params.userId;

    // Connect to the database
    await client.connect();
    const users = client.db("Wellcheck2").collection("User");

    // Fetch user by _id
    const userDoc = await users.findOne({ _id: userId });

    if (!userDoc || !userDoc[userId] || !userDoc[userId].profilepic) {
      return res.status(404).json({ error: "Profile image not found" });
    }

    // Return the Base64 image
    const profileImage = userDoc[userId].profilepic;
    res.json({ profilepic: profileImage });
  } catch (error) {
    console.error("Error fetching profile image:", error);
    res.status(500).json({ error: "Internal server error" });
  } finally {
    await client.close();
  }
});

// Add this shutdown handler
process.on('SIGINT', async () => {
  if (client) {
    await client.close();
  }
  process.exit();
})

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
