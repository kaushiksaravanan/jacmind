"""
JacMind Health — Demo Mode (no API calls needed)
Shows the full triage pipeline with pre-computed medical reasoning.
"""

import json;

# ============================================================
# Medical Enums
# ============================================================

enum Severity { MILD, MODERATE, SEVERE, CRITICAL }
sem Severity.MILD = "Minor discomfort, does not interfere with daily activities";
sem Severity.MODERATE = "Noticeable impact on daily life, may need intervention";
sem Severity.SEVERE = "Significant impairment, requires prompt medical attention";
sem Severity.CRITICAL = "Life-threatening, requires immediate emergency care";

enum Urgency { ROUTINE, SOON, URGENT, EMERGENCY }
enum Likelihood { UNLIKELY, POSSIBLE, PROBABLE, VERY_LIKELY }
enum BodySystem { NEUROLOGICAL, CARDIOVASCULAR, RESPIRATORY, GASTROINTESTINAL, MUSCULOSKELETAL, ENDOCRINE, DERMATOLOGICAL, PSYCHIATRIC, IMMUNOLOGICAL, OTHER }

# ============================================================
# Graph Nodes
# ============================================================

node Patient {
    has name: str;
    has age: int = 0;
    has sex: str = "";
    has medical_history: list[str] = [];
    has current_medications: list[str] = [];
    has allergies: list[str] = [];
}

node Symptom {
    has name: str;
    has severity: Severity = Severity.MILD;
    has duration: str = "";
    has body_system: BodySystem = BodySystem.OTHER;
}

node Condition {
    has name: str;
    has severity: Severity = Severity.MODERATE;
    has urgency: Urgency = Urgency.ROUTINE;
}

node DiagnosisResult {
    has condition_name: str;
    has likelihood: Likelihood = Likelihood.POSSIBLE;
    has reasoning: str = "";
    has matching_symptoms: list[str] = [];
    has recommended_tests: list[str] = [];
    has urgency: Urgency = Urgency.ROUTINE;
}

node TriageReport {
    has summary: str;
    has urgency: Urgency = Urgency.ROUTINE;
    has differential: list[str] = [];
    has recommended_actions: list[str] = [];
    has warnings: list[str] = [];
}

# ============================================================
# Typed Edges
# ============================================================

edge Presents { has onset: str = ""; has severity: Severity = Severity.MILD; }
edge IndicatesCondition { has strength: Likelihood = Likelihood.POSSIBLE; }
edge ContraindicatedWith { has reason: str = ""; }
edge IncreasesRisk { has magnitude: str = "moderate"; }

# ============================================================
# Demo Walker — Full Triage with Pre-computed Data
# ============================================================

walker DemoTriage {
    can start with Root entry {
        print(f"\n{'='*60}");
        print("JacMind Health — AI Triage Agent");
        print(f"{'='*60}");

        # Patient info
        print("\nPatient: Sarah Chen, Age 45, Female");
        print("Chief complaint: Persistent headaches for a week, behind eyes.");
        print("  Blurry vision, dizziness when standing, numbness in left hand.");
        print("History: hypertension, type 2 diabetes");
        print("Medications: metformin, lisinopril, aspirin");
        print("Allergies: penicillin");

        # Phase 1: Symptom extraction
        print(f"\n[1/4] Extracting symptoms...");

        patient = Patient(
            name="Sarah Chen",
            age=45,
            sex="female",
            medical_history=["hypertension", "type 2 diabetes"],
            current_medications=["metformin", "lisinopril", "aspirin"],
            allergies=["penicillin"]
        );
        root ++> patient;

        symptoms_data = [
            ("Persistent headache", Severity.MODERATE, "1 week", BodySystem.NEUROLOGICAL),
            ("Blurred vision", Severity.MODERATE, "intermittent, 1 week", BodySystem.NEUROLOGICAL),
            ("Orthostatic dizziness", Severity.MODERATE, "1 week", BodySystem.CARDIOVASCULAR),
            ("Left hand numbness", Severity.MODERATE, "1 day", BodySystem.NEUROLOGICAL),
            ("Retro-orbital pain", Severity.MODERATE, "1 week", BodySystem.NEUROLOGICAL)
        ];

        print(f"\n  Extracted {len(symptoms_data)} symptoms:");
        for (name, sev, dur, sys) in symptoms_data {
            s = Symptom(name=name, severity=sev, duration=dur, body_system=sys);
            patient +>:Presents(onset=dur, severity=sev):+> s;
            root ++> s;
            print(f"    - {name} [{sev}] ({dur}) [{sys}]");
        }

        # Phase 2: Differential diagnosis
        print(f"\n[2/4] Generating differential diagnosis...");

        # Red flags check
        print("\n  !! RED FLAGS DETECTED:");
        print("     !! Unilateral numbness with headache — rule out cerebrovascular event");
        print("     !! New neurological symptoms in patient with hypertension — assess for hypertensive emergency");

        differential = [
            ("Hypertensive crisis", Likelihood.PROBABLE,
             "Patient has known hypertension. New headache + visual changes + dizziness + unilateral numbness is classic presentation of dangerously elevated BP causing end-organ damage.",
             ["persistent headache", "blurred vision", "dizziness", "left hand numbness"],
             ["Blood pressure measurement (STAT)", "Basic metabolic panel", "CT head without contrast", "Fundoscopic exam"]),
            ("Transient ischemic attack (TIA)", Likelihood.POSSIBLE,
             "Unilateral numbness is concerning for focal neurological deficit. Patient has vascular risk factors (hypertension, diabetes). Duration of numbness (1 day) fits TIA window.",
             ["left hand numbness", "blurred vision", "dizziness"],
             ["MRI brain with diffusion", "CT angiography head/neck", "Carotid ultrasound", "ECG"]),
            ("Migraine with aura", Likelihood.POSSIBLE,
             "Retro-orbital headache with visual disturbance (blurry vision) and sensory symptoms (numbness) can represent migraine with complex aura. However, new onset at age 45 requires ruling out secondary causes first.",
             ["persistent headache", "blurred vision", "retro-orbital pain", "left hand numbness"],
             ["Neurological exam", "MRI brain to rule out structural cause"]),
            ("Diabetic neuropathy + medication side effect", Likelihood.UNLIKELY,
             "Numbness could be diabetic neuropathy, but acute onset and combination with headache/vision changes makes this less likely as the unifying diagnosis. Lisinopril can cause dizziness.",
             ["left hand numbness", "dizziness"],
             ["HbA1c", "Nerve conduction studies", "Review medication timing"])
        ];

        urgency = Urgency.URGENT;
        print(f"\n  Urgency Level: {urgency}");
        print(f"\n  Differential Diagnosis ({len(differential)} conditions):");

        for (name, likelihood, reasoning, symptoms, tests) in differential {
            condition = Condition(name=name, urgency=urgency);
            root ++> condition;

            dx = DiagnosisResult(
                condition_name=name,
                likelihood=likelihood,
                reasoning=reasoning,
                matching_symptoms=symptoms,
                recommended_tests=tests,
                urgency=urgency
            );
            root ++> dx;
            patient +>:IndicatesCondition(strength=likelihood):+> dx;

            print(f"    [{likelihood}] {name}");
            print(f"         Reasoning: {reasoning}");
            print(f"         Key symptoms: {', '.join(symptoms)}");
            print(f"         Tests: {', '.join(tests)}");
        }

        # Phase 3: Drug interactions
        print(f"\n[3/4] Checking drug interactions...");
        print("  Checking 3 medications for interactions...");
        print("    !! INTERACTION: metformin + lisinopril: Both can lower blood glucose; monitor for hypoglycemia");
        print("    !! ALLERGY: Patient allergic to penicillin — avoid penicillin-class antibiotics and cephalosporins (cross-reactivity risk)");

        # Phase 4: Triage report
        print(f"\n[4/4] Generating triage report...");

        summary = """Based on the combination of persistent headache, visual disturbances, orthostatic dizziness, and NEW unilateral numbness in a 45-year-old woman with known hypertension and diabetes, this presentation requires URGENT evaluation.

The most concerning possibility is a hypertensive crisis with end-organ effects, given the patient's history and the constellation of neurological symptoms. A transient ischemic attack (TIA) must also be ruled out given the unilateral numbness — if confirmed, this represents a medical emergency with high stroke risk in the following 48 hours.

While migraine with aura could explain several symptoms, new-onset complex neurological symptoms at this age MUST be investigated with imaging before attributing to a benign cause.""";

        actions = [
            "URGENT: Seek medical attention within the next few hours",
            "Check blood pressure immediately (home monitor or pharmacy)",
            "If BP > 180/120 OR numbness worsens OR new weakness/speech changes: CALL 911",
            "Request: Blood pressure measurement (STAT), CT head, Basic metabolic panel",
            "Request: MRI brain with diffusion, CT angiography if TIA suspected",
            "DO NOT drive yourself — have someone else drive or call ambulance",
            "Bring medication list to the ER/urgent care",
            "Manage blood sugar closely — stress can cause fluctuations"
        ];

        print(f"\n{'='*60}");
        print("TRIAGE REPORT");
        print(f"{'='*60}");
        print(f"\nPatient: Sarah Chen, Age 45, Female");
        print(f"Urgency: {urgency}");
        print(f"\n{summary}");
        print(f"\nDifferential Diagnosis:");
        for (name, likelihood, _, _, _) in differential {
            print(f"  - {name} ({likelihood})");
        }
        print(f"\nRecommended Actions:");
        for a in actions {
            print(f"  - {a}");
        }
        print(f"\nKnowledge Graph Built:");
        patients = [root-->][?:Patient];
        symptoms_nodes = [root-->][?:Symptom];
        conditions_nodes = [root-->][?:Condition];
        diagnoses_nodes = [root-->][?:DiagnosisResult];
        print(f"  Patients: {len(patients)}");
        print(f"  Symptoms: {len(symptoms_nodes)}");
        print(f"  Conditions: {len(conditions_nodes)}");
        print(f"  Diagnoses: {len(diagnoses_nodes)}");
        print(f"  Total graph nodes: {len(patients) + len(symptoms_nodes) + len(conditions_nodes) + len(diagnoses_nodes)}");
        print(f"  Edges: Presents, IndicatesCondition, ContraindicatedWith, IncreasesRisk");

        print(f"\n{'='*60}");
        print("DISCLAIMER: This is an AI triage tool for informational purposes only.");
        print("It does NOT replace professional medical diagnosis or treatment.");
        print("Always consult a qualified healthcare provider.");
        print(f"{'='*60}");
    }
}

# ============================================================
# Entry Point
# ============================================================

with entry {
    root spawn DemoTriage();
}
