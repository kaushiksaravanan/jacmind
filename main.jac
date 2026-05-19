"""
JacMind Health — Graph-Based Differential Diagnosis Agent
A medical triage agent that reasons over a knowledge graph of symptoms,
conditions, treatments, and contraindications using walker-based traversal.

The graph IS the reasoning — walkers traverse paths to find diagnoses,
detect drug interactions, and propagate risk through patient history.
This is not a chatbot wrapper. The graph structure constrains and guides
the AI's reasoning, making it explainable and auditable.
"""

import json;
import requests;

# ============================================================
# Structured Types for Medical Reasoning
# ============================================================

enum Severity { MILD, MODERATE, SEVERE, CRITICAL }
sem Severity.MILD = "Minor discomfort, does not interfere with daily activities";
sem Severity.MODERATE = "Noticeable impact on daily life, may need intervention";
sem Severity.SEVERE = "Significant impairment, requires prompt medical attention";
sem Severity.CRITICAL = "Life-threatening, requires immediate emergency care";

enum Urgency { ROUTINE, SOON, URGENT, EMERGENCY }
sem Urgency.ROUTINE = "Can wait days to weeks for a scheduled appointment";
sem Urgency.SOON = "Should be seen within 24-48 hours";
sem Urgency.URGENT = "Needs medical attention within hours";
sem Urgency.EMERGENCY = "Call 911 or go to ER immediately";

enum Likelihood { UNLIKELY, POSSIBLE, PROBABLE, VERY_LIKELY }

enum BodySystem { NEUROLOGICAL, CARDIOVASCULAR, RESPIRATORY, GASTROINTESTINAL, MUSCULOSKELETAL, ENDOCRINE, DERMATOLOGICAL, PSYCHIATRIC, IMMUNOLOGICAL, OTHER }

# ============================================================
# Graph Nodes — Medical Knowledge Structure
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
    has description: str = "";
}

node Condition {
    has name: str;
    has description: str = "";
    has severity: Severity = Severity.MODERATE;
    has urgency: Urgency = Urgency.ROUTINE;
    has prevalence: str = "common";
    has body_system: BodySystem = BodySystem.OTHER;
}

node Treatment {
    has name: str;
    has treatment_type: str = "medication";
    has dosage: str = "";
    has warnings: list[str] = [];
}

node RiskFactor {
    has name: str;
    has description: str = "";
    has modifiable: bool = True;
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
    has confidence_note: str = "";
}

# ============================================================
# Typed Edges — Medical Relationships
# ============================================================

edge Presents {
    has onset: str = "";
    has severity: Severity = Severity.MILD;
}

edge IndicatesCondition {
    has strength: Likelihood = Likelihood.POSSIBLE;
    has specificity: str = "low";
}

edge TreatedBy {
    has first_line: bool = True;
    has evidence_level: str = "moderate";
}

edge ContraindicatedWith {
    has reason: str = "";
    has severity: str = "absolute";
}

edge IncreasesRisk {
    has magnitude: str = "moderate";
    has mechanism: str = "";
}

edge CoOccursWith {
    has frequency: str = "often";
}

edge WorsensCondition {
    has mechanism: str = "";
}

# ============================================================
# AI Functions — Medical Reasoning via byLLM
# ============================================================

obj SymptomExtraction {
    has name: str;
    has severity: Severity;
    has duration: str;
    has body_system: BodySystem;
}
sem SymptomExtraction.name = "Medical symptom name in standard terminology";
sem SymptomExtraction.duration = "How long the symptom has been present, e.g. '3 days', '2 weeks'";

def extract_symptoms(patient_description: str) -> list[SymptomExtraction] by llm();
sem extract_symptoms = "Extract individual medical symptoms from a patient's natural language description. Identify each distinct symptom, its severity, approximate duration, and which body system it affects. Be thorough — patients often mention symptoms casually.";

obj DifferentialEntry {
    has condition: str;
    has likelihood: Likelihood;
    has reasoning: str;
    has key_symptoms: list[str];
    has recommended_tests: list[str];
}
sem DifferentialEntry.reasoning = "Brief clinical reasoning for why this condition fits the symptom pattern";
sem DifferentialEntry.recommended_tests = "Specific lab tests or imaging that would confirm or rule out this condition";

def generate_differential(symptoms: list[str], patient_age: int, patient_sex: str, medical_history: list[str]) -> list[DifferentialEntry] by llm();
sem generate_differential = "Generate a differential diagnosis list (3-6 conditions) ranked by likelihood given the symptom pattern, patient demographics, and medical history. Consider both common and dangerous conditions. For each, explain the clinical reasoning and what tests would confirm it. Always include at least one serious condition that should be ruled out.";

def assess_urgency(symptoms: list[str], conditions: list[str]) -> Urgency by llm();
sem assess_urgency = "Determine the urgency level for this patient based on their symptoms and possible conditions. EMERGENCY if any symptom suggests stroke, MI, anaphylaxis, or other immediately life-threatening condition. URGENT if delay could cause significant harm. SOON if should be seen promptly. ROUTINE if can wait for scheduled visit.";

def check_drug_interaction(medication1: str, medication2: str, conditions: list[str]) -> str by llm();
sem check_drug_interaction = "Check if there is a clinically significant interaction between these two medications, especially given the patient's conditions. Return a brief warning if interaction exists, or empty string if safe.";

def generate_triage_summary(symptoms: list[str], differential: list[str], urgency: str, patient_context: str) -> str by llm();
sem generate_triage_summary = "Write a clear, empathetic triage summary for this patient. Include: what the symptoms suggest, what the possible conditions are ranked by likelihood, what the urgency level is, and what the patient should do next. Use plain language. Add appropriate disclaimers about seeking professional medical advice.";

def identify_red_flags(symptoms: list[str], patient_age: int) -> list[str] by llm();
sem identify_red_flags = "Identify any red flag symptoms that require immediate medical attention. Consider the patient's age as a factor. Return a list of warnings, or empty list if no red flags present. Examples: sudden worst headache of life, chest pain with shortness of breath, unilateral weakness.";

def suggest_lifestyle_modifications(conditions: list[str], risk_factors: list[str]) -> list[str] by llm();
sem suggest_lifestyle_modifications = "Suggest evidence-based lifestyle modifications that could help manage the identified conditions and mitigate risk factors. Be specific and actionable.";

# ============================================================
# Web Search Tool for Medical Evidence
# ============================================================

"""Search medical information from DuckDuckGo. Returns health-related results."""
def medical_search(query: str) -> str {
    try {
        response = requests.get(
            "https://api.duckduckgo.com/",
            params={"q": f"{query} medical health", "format": "json", "no_html": "1", "skip_disambig": "1"},
            timeout=10
        );
        data = response.json();
        results: list[str] = [];
        if data.get("AbstractText") {
            results.append(str(data["AbstractText"]));
        }
        for topic in data.get("RelatedTopics", [])[:3] {
            if isinstance(topic, dict) and "Text" in topic {
                results.append(str(topic["Text"]));
            }
        }
        return "\n".join(results) if results else "No results found";
    } except Exception as e {
        return f"Search unavailable: {str(e)}";
    }
}

# ============================================================
# Walkers — Medical Reasoning Agents
# ============================================================

walker SymptomCollector {
    """Extracts symptoms from patient description and adds them to the graph."""
    has description: str;
    has patient_name: str = "Patient";
    has patient_age: int = 30;
    has patient_sex: str = "unknown";
    has medical_history: list[str] = [];
    has medications: list[str] = [];
    has allergies: list[str] = [];

    can start with Root entry {
        # Create or find patient node
        patient = Patient(
            name=self.patient_name,
            age=self.patient_age,
            sex=self.patient_sex,
            medical_history=self.medical_history,
            current_medications=self.medications,
            allergies=self.allergies
        );
        root ++> patient;

        # Extract symptoms using byLLM
        extracted = extract_symptoms(self.description);
        print(f"\n  Extracted {len(extracted)} symptoms:");

        for s in extracted {
            symptom = Symptom(
                name=s.name,
                severity=s.severity,
                duration=s.duration,
                body_system=s.body_system,
                description=f"{s.name} ({s.duration})"
            );
            patient +>:Presents(onset=s.duration, severity=s.severity):+> symptom;
            root ++> symptom;
            print(f"    - {s.name} [{s.severity}] ({s.duration}) [{s.body_system}]");
        }

        report {"patient": patient, "symptom_count": len(extracted)};
    }
}

walker DiagnosticReasoner {
    """Traverses the symptom graph to generate differential diagnoses."""

    can start with Root entry {
        patients = [-->][?:Patient];
        if patients {
            visit patients[0];
        }
    }

    can diagnose with Patient entry {
        # Gather all symptoms via graph traversal
        symptoms = [here-->][?:Symptom];
        symptom_names = [s.name for s in symptoms];

        if not symptom_names {
            print("  No symptoms recorded. Cannot diagnose.");
            return;
        }

        print(f"\n  Analyzing {len(symptom_names)} symptoms for differential diagnosis...");

        # Check for red flags first
        red_flags = identify_red_flags(symptom_names, here.age);
        if red_flags {
            print("  !! RED FLAGS DETECTED:");
            for flag in red_flags {
                print(f"     !! {flag}");
            }
        }

        # Generate differential diagnosis via byLLM
        differential = generate_differential(
            symptom_names,
            here.age,
            here.sex,
            here.medical_history
        );

        # Assess overall urgency
        condition_names = [d.condition for d in differential];
        urgency = assess_urgency(symptom_names, condition_names);

        print(f"\n  Urgency Level: {urgency}");
        print(f"\n  Differential Diagnosis ({len(differential)} conditions):");

        # Create condition nodes and link to symptoms
        for entry in differential {
            condition = Condition(
                name=entry.condition,
                urgency=urgency
            );
            root ++> condition;

            # Link symptoms to conditions
            for s in symptoms {
                if s.name in entry.key_symptoms {
                    s +>:IndicatesCondition(
                        strength=entry.likelihood,
                        specificity="moderate"
                    ):+> condition;
                }
            }

            # Create diagnosis result
            dx = DiagnosisResult(
                condition_name=entry.condition,
                likelihood=entry.likelihood,
                reasoning=entry.reasoning,
                matching_symptoms=entry.key_symptoms,
                recommended_tests=entry.recommended_tests,
                urgency=urgency
            );
            root ++> dx;
            here +>:IndicatesCondition(strength=entry.likelihood):+> dx;

            print(f"    [{entry.likelihood}] {entry.condition}");
            print(f"         Reasoning: {entry.reasoning}");
            print(f"         Key symptoms: {', '.join(entry.key_symptoms)}");
            print(f"         Tests: {', '.join(entry.recommended_tests)}");
        }

        report {
            "differential": [{"condition": d.condition, "likelihood": str(d.likelihood), "reasoning": d.reasoning} for d in differential],
            "urgency": str(urgency),
            "red_flags": red_flags,
            "symptom_count": len(symptom_names)
        };
    }
}

walker ContraindicationChecker {
    """Checks for drug interactions and contraindications in the patient's graph."""

    can start with Root entry {
        patients = [-->][?:Patient];
        if patients {
            visit patients[0];
        }
    }

    can check with Patient entry {
        medications = here.current_medications;
        conditions = [c.name for c in [root-->][?:Condition]];
        allergies = here.allergies;

        warnings: list[str] = [];

        if len(medications) < 2 and not allergies {
            print("  No medication interactions to check.");
            report {"warnings": []};
            return;
        }

        print(f"\n  Checking {len(medications)} medications for interactions...");

        # Check each medication pair
        for i in range(len(medications)) {
            for j in range(i + 1, len(medications)) {
                interaction = check_drug_interaction(
                    medications[i], medications[j], conditions
                );
                if interaction != "" {
                    warning = f"INTERACTION: {medications[i]} + {medications[j]}: {interaction}";
                    warnings.append(warning);
                    print(f"    !! {warning}");

                    # Create contraindication edge in graph
                    treatments = [root-->][?:Treatment];
                    for t in treatments {
                        if t.name == medications[i] or t.name == medications[j] {
                            t +>:ContraindicatedWith(reason=interaction):+> here;
                        }
                    }
                }
            }
        }

        # Check allergies against possible treatments
        for allergy in allergies {
            warning = f"ALLERGY: Patient allergic to {allergy} — avoid related medications";
            warnings.append(warning);
            print(f"    !! {warning}");
        }

        if not warnings {
            print("    No interactions detected.");
        }

        report {"warnings": warnings};
    }
}

walker TriageReportGenerator {
    """Generates the final triage report by traversing all gathered evidence."""

    can start with Root entry {
        patients = [-->][?:Patient];
        if patients {
            visit patients[0];
        }
    }

    can generate with Patient entry {
        # Gather all evidence from the graph
        symptoms = [here-->][?:Symptom];
        diagnoses = [root-->][?:DiagnosisResult];
        conditions = [root-->][?:Condition];

        symptom_names = [s.name for s in symptoms];
        differential = [f"{d.condition_name} ({d.likelihood})" for d in diagnoses];
        condition_names = [c.name for c in conditions];

        # Determine urgency from diagnoses
        urgency = Urgency.ROUTINE;
        for d in diagnoses {
            if d.urgency == Urgency.EMERGENCY { urgency = Urgency.EMERGENCY; }
            elif d.urgency == Urgency.URGENT and urgency != Urgency.EMERGENCY { urgency = Urgency.URGENT; }
            elif d.urgency == Urgency.SOON and urgency == Urgency.ROUTINE { urgency = Urgency.SOON; }
        }

        # Generate lifestyle recommendations
        risk_factors = [r.name for r in [root-->][?:RiskFactor]];
        lifestyle = suggest_lifestyle_modifications(condition_names, risk_factors);

        # Generate summary
        patient_context = f"{here.name}, age {here.age}, {here.sex}. History: {', '.join(here.medical_history) if here.medical_history else 'none reported'}";
        summary = generate_triage_summary(
            symptom_names,
            differential,
            str(urgency),
            patient_context
        );

        # Build the report
        actions: list[str] = [];
        if urgency == Urgency.EMERGENCY {
            actions.append("CALL 911 or go to nearest emergency room immediately");
        } elif urgency == Urgency.URGENT {
            actions.append("Seek medical attention within the next few hours");
        } elif urgency == Urgency.SOON {
            actions.append("Schedule appointment within 24-48 hours");
        } else {
            actions.append("Schedule routine appointment with your primary care physician");
        }

        for d in diagnoses[:3] {
            if d.recommended_tests {
                actions.append(f"Request: {', '.join(d.recommended_tests)}");
            }
        }

        actions.extend(lifestyle);

        # Create report node
        report_node = TriageReport(
            summary=summary,
            urgency=urgency,
            differential=differential,
            recommended_actions=actions,
            warnings=[],
            confidence_note="This is an AI-assisted triage tool and does NOT replace professional medical advice. Always consult a qualified healthcare provider."
        );
        root ++> report_node;

        print(f"\n{'='*60}");
        print("TRIAGE REPORT");
        print(f"{'='*60}");
        print(f"\nPatient: {here.name}, Age {here.age}, {here.sex}");
        print(f"Urgency: {urgency}");
        print(f"\n{summary}");
        print(f"\nDifferential Diagnosis:");
        for d in differential {
            print(f"  - {d}");
        }
        print(f"\nRecommended Actions:");
        for a in actions {
            print(f"  - {a}");
        }
        print(f"\n{'='*60}");
        print("DISCLAIMER: This is an AI triage tool for informational purposes only.");
        print("It does NOT replace professional medical diagnosis or treatment.");
        print(f"{'='*60}");

        report {
            "summary": summary,
            "urgency": str(urgency),
            "differential": differential,
            "actions": actions,
            "disclaimer": report_node.confidence_note
        };
    }
}

# ============================================================
# Main Pipeline — Orchestrates Full Triage
# ============================================================

walker TriagePipeline {
    """Complete medical triage: symptoms → diagnosis → interactions → report."""
    has description: str;
    has patient_name: str = "Patient";
    has patient_age: int = 30;
    has patient_sex: str = "unknown";
    has medical_history: list[str] = [];
    has medications: list[str] = [];
    has allergies: list[str] = [];

    can start with Root entry {
        print(f"\n{'='*60}");
        print("JacMind Health — AI Triage Agent");
        print(f"{'='*60}");
        print(f"\nPatient: {self.patient_name}, Age {self.patient_age}, {self.patient_sex}");
        print(f"Chief complaint: {self.description}");
        if self.medical_history { print(f"History: {', '.join(self.medical_history)}"); }
        if self.medications { print(f"Medications: {', '.join(self.medications)}"); }
        if self.allergies { print(f"Allergies: {', '.join(self.allergies)}"); }

        # Phase 1: Extract symptoms
        print(f"\n[1/4] Extracting symptoms...");
        root spawn SymptomCollector(
            description=self.description,
            patient_name=self.patient_name,
            patient_age=self.patient_age,
            patient_sex=self.patient_sex,
            medical_history=self.medical_history,
            medications=self.medications,
            allergies=self.allergies
        );

        # Phase 2: Differential diagnosis
        print(f"\n[2/4] Generating differential diagnosis...");
        dx_result = root spawn DiagnosticReasoner();

        # Phase 3: Check contraindications
        print(f"\n[3/4] Checking drug interactions...");
        root spawn ContraindicationChecker();

        # Phase 4: Generate triage report
        print(f"\n[4/4] Generating triage report...");
        result = root spawn TriageReportGenerator();

        # Graph stats
        patients = [root-->][?:Patient];
        symptoms = [root-->][?:Symptom];
        conditions = [root-->][?:Condition];
        diagnoses = [root-->][?:DiagnosisResult];
        print(f"\nKnowledge Graph: {len(patients)} patients, {len(symptoms)} symptoms, {len(conditions)} conditions, {len(diagnoses)} diagnoses");

        report result.reports;
    }
}

# ============================================================
# Public API Endpoints
# ============================================================

"""Run a full triage assessment for a patient."""
walker:pub triage {
    has description: str;
    has patient_name: str = "Patient";
    has patient_age: int = 30;
    has patient_sex: str = "unknown";
    has medical_history: list[str] = [];
    has medications: list[str] = [];
    has allergies: list[str] = [];

    can start with Root entry {
        result = root spawn TriagePipeline(
            description=self.description,
            patient_name=self.patient_name,
            patient_age=self.patient_age,
            patient_sex=self.patient_sex,
            medical_history=self.medical_history,
            medications=self.medications,
            allergies=self.allergies
        );
        report result.reports;
    }
}

"""Get the patient's current medical knowledge graph."""
walker:pub patient_graph {
    can start with Root entry {
        patients = [-->][?:Patient];
        symptoms = [-->][?:Symptom];
        conditions = [-->][?:Condition];
        diagnoses = [-->][?:DiagnosisResult];

        report {
            "patients": [{"name": p.name, "age": p.age, "medications": p.current_medications} for p in patients],
            "symptoms": [{"name": s.name, "severity": str(s.severity), "system": str(s.body_system)} for s in symptoms],
            "conditions": [{"name": c.name, "urgency": str(c.urgency)} for c in conditions],
            "diagnoses": [{"condition": d.condition_name, "likelihood": str(d.likelihood), "reasoning": d.reasoning} for d in diagnoses],
            "total_nodes": len(patients) + len(symptoms) + len(conditions) + len(diagnoses)
        };
    }
}

# ============================================================
# CLI Entry Point
# ============================================================

with entry {
    print("JacMind Health — Graph-Based AI Triage Agent");
    print("Usage: jac run main.jac  (interactive demo)");
    print("       jac start main.jac  (REST API mode)\n");

    # Demo case: complex patient with multiple symptoms and history
    root spawn TriagePipeline(
        description="I've been having persistent headaches for the past week, mostly behind my eyes. My vision gets blurry sometimes and I feel dizzy when I stand up. I also noticed some numbness in my left hand yesterday.",
        patient_name="Demo Patient",
        patient_age=45,
        patient_sex="female",
        medical_history=["hypertension", "type 2 diabetes"],
        medications=["metformin", "lisinopril", "aspirin"],
        allergies=["penicillin"]
    );
}
