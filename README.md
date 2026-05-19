# JacMind Health — Graph-Based AI Triage Agent

> An autonomous medical triage agent that builds a patient knowledge graph and reasons over it through walker-based differential diagnosis. Not a chatbot — a reasoning engine where the graph IS the clinical logic.

[![Built with Jac](https://img.shields.io/badge/Built%20with-Jac-blue)](https://jaseci.org)
[![JacHacks Spring 2026](https://img.shields.io/badge/JacHacks-Spring%202026-purple)](https://jachacks-spring.devpost.com)

## The Problem

Current AI health tools are **black boxes** — you describe symptoms, an LLM gives you a diagnosis with no explanation of its reasoning. You can't see what it considered, what it ruled out, or why.

Real clinical reasoning is a **graph traversal** — symptoms point to conditions, conditions interact with medications, risk factors amplify certain paths. Doctors reason by following these connections.

## What JacMind Health Does

JacMind Health builds a **medical knowledge graph** for each patient and uses **walker agents** to traverse it for diagnosis:

```
Patient → [Presents] → Symptom → [IndicatesCondition] → Condition
                                                              ↓
Risk Factor → [IncreasesRisk] → Condition → [TreatedBy] → Treatment
                                                              ↓
                                    [ContraindicatedWith] → Patient Condition
```

### The 4-Phase Pipeline:

1. **Symptom Extraction** — `SymptomCollector` walker parses natural language into structured symptoms with severity, duration, and body system
2. **Differential Diagnosis** — `DiagnosticReasoner` walker traverses symptom→condition paths, checks red flags, ranks by likelihood
3. **Contraindication Check** — `ContraindicationChecker` walker finds dangerous drug interactions in the patient's medication graph
4. **Triage Report** — `TriageReportGenerator` walker synthesizes all graph evidence into actionable guidance with urgency level

### Why This Can't Be Done With a Prompt

A simple "here are my symptoms, diagnose me" prompt **cannot**:
- Detect that Drug A treats Condition X but is contraindicated with Condition Y (which the patient also has) — this requires **graph traversal**
- Propagate risk factors through relationship chains (smoking → cardiovascular risk → worsens hypertension → increases stroke risk)
- Show the reasoning path as auditable edges (which symptoms led to which diagnosis and why)
- Build persistent patient history that grows across consultations

## Why Jac?

| Jac Feature | Medical Use |
|---|---|
| **Graph Nodes** | `Patient`, `Symptom`, `Condition`, `Treatment`, `RiskFactor` — the medical ontology IS the data structure |
| **Typed Edges** | `Presents`, `IndicatesCondition`, `TreatedBy`, `ContraindicatedWith`, `IncreasesRisk` — relationships have meaning |
| **Walkers** | Each diagnostic phase is a walker that traverses the graph — `SymptomCollector`, `DiagnosticReasoner`, `ContraindicationChecker`, `TriageReportGenerator` |
| **byLLM** | 8 AI functions for medical reasoning — symptom extraction, differential generation, red flag detection, drug interaction checking |
| **Enums** | `Severity`, `Urgency`, `Likelihood`, `BodySystem` — constrain LLM outputs to valid medical categories |
| **sem annotations** | Guide LLM to use proper medical terminology and clinical reasoning |
| **walker:pub** | Instant REST API — deploy as a triage service with one command |
| **Persistence** | Patient graph persists across sessions — longitudinal health tracking |

## Quick Start

```bash
# Install
pip install jaseci

# Clone
git clone https://github.com/kaushiksaravanan/jacmind.git
cd jacmind

# Run demo (no API key needed)
jac run demo.jac

# Run with live AI (needs API key)
export GEMINI_API_KEY=your_key_here  # or GROQ_API_KEY
jac run main.jac

# Deploy as REST API
jac start main.jac
```

### API Usage

```bash
curl -X POST http://localhost:8000/walker/triage \
  -H "Content-Type: application/json" \
  -d '{
    "description": "Persistent headaches, blurry vision, dizziness, numbness in left hand",
    "patient_name": "Sarah",
    "patient_age": 45,
    "patient_sex": "female",
    "medical_history": ["hypertension", "diabetes"],
    "medications": ["metformin", "lisinopril"],
    "allergies": ["penicillin"]
  }'
```

## Example Output

```
============================================================
JacMind Health — AI Triage Agent
============================================================

Patient: Sarah Chen, Age 45, Female
Chief complaint: Persistent headaches, blurry vision, dizziness, left hand numbness

[1/4] Extracting symptoms...
  Extracted 5 symptoms:
    - Persistent headache [MODERATE] (1 week) [NEUROLOGICAL]
    - Blurred vision [MODERATE] (intermittent) [NEUROLOGICAL]
    - Orthostatic dizziness [MODERATE] (1 week) [CARDIOVASCULAR]
    - Left hand numbness [MODERATE] (1 day) [NEUROLOGICAL]
    - Retro-orbital pain [MODERATE] (1 week) [NEUROLOGICAL]

[2/4] Generating differential diagnosis...
  !! RED FLAGS DETECTED:
     !! Unilateral numbness with headache — rule out cerebrovascular event

  Urgency Level: URGENT

  Differential Diagnosis (4 conditions):
    [PROBABLE] Hypertensive crisis
    [POSSIBLE] Transient ischemic attack (TIA)
    [POSSIBLE] Migraine with aura
    [UNLIKELY] Diabetic neuropathy + medication side effect

[3/4] Checking drug interactions...
    !! INTERACTION: metformin + lisinopril: monitor for hypoglycemia

[4/4] Generating triage report...

Knowledge Graph: 1 patients, 5 symptoms, 4 conditions, 4 diagnoses
```

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     TriagePipeline Walker                     │
├───────────────┬────────────────┬──────────────┬─────────────┤
│SymptomCollector│DiagnosticReasoner│Contraindication│TriageReport│
│    Walker     │     Walker      │   Checker     │  Generator  │
├───────────────┴────────────────┴──────────────┴─────────────┤
│                  Patient Knowledge Graph                      │
│  [Patient]─Presents─→[Symptom]─IndicatesCondition─→[Condition]│
│      │                                                  │     │
│      └─Medications─→[Treatment]─ContraindicatedWith─────┘     │
│                                                               │
│  [RiskFactor]─IncreasesRisk─→[Condition]                     │
├─────────────────────────────────────────────────────────────┤
│           byLLM Functions (8 medical reasoning)              │
│  extract_symptoms | generate_differential | assess_urgency   │
│  identify_red_flags | check_drug_interaction | ...           │
├─────────────────────────────────────────────────────────────┤
│           Medical Search (DuckDuckGo API)                    │
└─────────────────────────────────────────────────────────────┘
```

## What Makes This Different

1. **Graph IS the reasoning** — not a chatbot with a graph database behind it. The walker traversal paths ARE the clinical reasoning chain.
2. **Contraindication detection through graph structure** — the system finds dangerous drug interactions by traversing edges between treatments and patient conditions. This requires graph reasoning, not just prompting.
3. **Red flag escalation** — walker detects emergency symptoms and immediately escalates urgency level before completing diagnosis.
4. **Auditable** — every diagnosis has a visible path: Symptom → Edge → Condition. A doctor can trace exactly why the AI suggested something.
5. **Persistent** — the patient's graph grows across consultations. New symptoms connect to old conditions.

## What Surprised Us

- Medical ontology maps PERFECTLY to Jac's graph primitives — the language was made for this
- Walker-based phases (collect → diagnose → check → report) mirror actual clinical workflow
- `sem` annotations make LLMs use proper medical terminology without explicit prompting
- Contraindication detection is trivial with typed edges but nearly impossible with flat prompts

## What's Next

- Connect to real medical knowledge bases (SNOMED-CT, ICD-10)
- Multi-session patient history (graph persists, conditions evolve)
- React frontend with graph visualization showing reasoning paths
- Integration with wearable data (heart rate, blood glucose → automatic risk factor nodes)
- Multi-patient epidemiological patterns (shared conditions across population graph)

## Built With

- Jac (jaclang 0.15.2) — AI-native programming language
- byllm — LLM integration plugin
- Groq/Gemini (via litellm) — fast inference
- DuckDuckGo API — medical information search

## Tracks

- **Primary**: Consumer Healthcare ($600/$400)
- **Sub-tracks**: Best Use of Jac ($300), Best Demo ($200)

## Important Disclaimer

This is a hackathon project for educational and demonstration purposes only. It is NOT a medical device, NOT clinically validated, and should NEVER be used for actual medical decisions. Always consult qualified healthcare professionals.

## License

MIT
