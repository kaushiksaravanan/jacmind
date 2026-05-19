"""
JacMind — Graph-Memory Research Agent
A multi-step reasoning agent that builds persistent knowledge graphs.
Demonstrates: byLLM, graph nodes, walkers, tool calling, structured output, semantic annotations.
"""

import json;
import requests;

# ============================================================
# Enums for Structured AI Output
# ============================================================

enum Confidence { LOW, MEDIUM, HIGH, CERTAIN }
sem Confidence.LOW = "Uncertain, needs more evidence";
sem Confidence.MEDIUM = "Some supporting evidence but not conclusive";
sem Confidence.HIGH = "Strong evidence supports this";
sem Confidence.CERTAIN = "Verified from multiple reliable sources";

enum QuestionType { FACTUAL, ANALYTICAL, COMPARATIVE, CAUSAL, EXPLORATORY }
sem QuestionType.FACTUAL = "Seeking a specific fact or data point";
sem QuestionType.ANALYTICAL = "Requires breaking down a complex topic";
sem QuestionType.COMPARATIVE = "Comparing two or more things";
sem QuestionType.CAUSAL = "Understanding cause and effect";
sem QuestionType.EXPLORATORY = "Open-ended investigation of a topic";

enum Relevance { CORE, SUPPORTING, TANGENTIAL }

# ============================================================
# Graph Nodes — The Knowledge Structure
# ============================================================

node ResearchQuestion {
    has question: str;
    has question_type: QuestionType = QuestionType.EXPLORATORY;
    has status: str = "pending";
    has final_answer: str = "";
}

node SubQuestion {
    has question: str;
    has reasoning: str = "";
    has answer: str = "";
    has confidence: Confidence = Confidence.LOW;
    has sources: list[str] = [];
}

node Finding {
    has content: str;
    has source: str = "";
    has relevance: Relevance = Relevance.SUPPORTING;
    has confidence: Confidence = Confidence.MEDIUM;
}

node Synthesis {
    has summary: str;
    has key_insights: list[str] = [];
    has confidence: Confidence = Confidence.MEDIUM;
    has gaps: list[str] = [];
}

# ============================================================
# Typed Edges — Relationships in the Knowledge Graph
# ============================================================

edge DecomposesTo {
    has reasoning: str = "";
}

edge AnsweredBy {
    has method: str = "search";
}

edge Supports {
    has strength: str = "moderate";
}

edge RelatesTo {
    has relationship: str = "";
}

edge Contradicts {
    has explanation: str = "";
}

# ============================================================
# AI-Powered Functions (byLLM)
# ============================================================

obj SubQuestionPlan {
    has question: str;
    has reasoning: str;
    has search_query: str;
}
sem SubQuestionPlan.reasoning = "Why this sub-question helps answer the main question";
sem SubQuestionPlan.search_query = "The optimal web search query to find the answer";

def decompose_question(question: str, question_type: str) -> list[SubQuestionPlan] by llm();
sem decompose_question = "Break a complex research question into 3-5 focused sub-questions that together would fully answer the main question. Each sub-question should be independently answerable and together they should cover the full scope.";

def classify_question(question: str) -> QuestionType by llm();
sem classify_question = "Classify what type of question this is based on what kind of answer it needs.";

def extract_findings(question: str, search_results: str) -> list[str] by llm();
sem extract_findings = "Extract the key factual findings from search results that are relevant to answering the question. Return 2-5 concise factual statements.";

def assess_confidence(finding: str, source: str) -> Confidence by llm();
sem assess_confidence = "Assess how confident we should be in this finding based on its content and source.";

def assess_relevance(finding: str, main_question: str) -> Relevance by llm();
sem assess_relevance = "Assess how relevant this finding is to answering the main research question.";

def synthesize_answer(question: str, findings: list[str]) -> str by llm();
sem synthesize_answer = "Synthesize all findings into a comprehensive, well-structured answer to the research question. Be thorough but concise. Cite which findings support each point.";

def identify_gaps(question: str, findings: list[str]) -> list[str] by llm();
sem identify_gaps = "Identify what important aspects of the question remain unanswered or need more evidence.";

def find_connections(finding1: str, finding2: str) -> str by llm();
sem find_connections = "Describe the relationship between these two findings. Return empty string if no meaningful connection exists.";

def answer_subquestion(question: str, search_results: str) -> str by llm();
sem answer_subquestion = "Given search results about a topic, provide a clear and comprehensive answer to the research sub-question. Cite specific facts from the search results.";

# ============================================================
# Tools — External Data Access
# ============================================================

"""Search the web for information on a topic. Returns relevant search results."""
def web_search(query: str) -> str {
    try {
        response = requests.get(
            "https://api.duckduckgo.com/",
            params={"q": query, "format": "json", "no_html": "1", "skip_disambig": "1"},
            timeout=10
        );
        data = response.json();
        results: list[str] = [];
        if data.get("AbstractText") {
            results.append(f"Summary: {data['AbstractText']}");
        }
        for topic in data.get("RelatedTopics", [])[:5] {
            if isinstance(topic, dict) and "Text" in topic {
                results.append(str(topic["Text"]));
            }
        }
        if not results {
            results.append(f"No detailed results found for: {query}");
        }
        return "\n".join(results);
    } except Exception as e {
        return f"Search failed: {str(e)}";
    }
}

"""Get the current knowledge graph state as a summary."""
def get_graph_state() -> str {
    questions = [root-->][?:ResearchQuestion];
    findings = [root-->][?:Finding];
    syntheses = [root-->][?:Synthesis];
    return json.dumps({
        "total_questions": len(questions),
        "total_findings": len(findings),
        "total_syntheses": len(syntheses)
    });
}

# ============================================================
# Walkers — Graph Traversal Agents
# ============================================================

walker Decomposer {
    """Visits a ResearchQuestion and creates sub-questions."""
    has depth: int = 0;

    can start with Root entry {
        visit [-->][?:ResearchQuestion];
    }

    can decompose with ResearchQuestion entry {
        if here.status != "pending" {
            return;
        }
        here.question_type = classify_question(here.question);
        here.status = "decomposing";

        plans = decompose_question(here.question, str(here.question_type));

        for plan in plans {
            sub = SubQuestion(
                question=plan.question,
                reasoning=plan.reasoning
            );
            here +>:DecomposesTo(reasoning=plan.reasoning):+> sub;
            root ++> sub;
        }
        here.status = "decomposed";
        print(f"  Decomposed into {len(plans)} sub-questions");
    }
}

walker Researcher {
    """Visits SubQuestions and finds answers using tool calling."""

    can start with Root entry {
        visit [-->][?:SubQuestion];
    }

    can research with SubQuestion entry {
        if here.answer != "" {
            return;
        }
        print(f"  Researching: {here.question}");

        # Walker orchestrates: search first, then reason over results
        search_results = web_search(here.question);
        answer = answer_subquestion(here.question, search_results);
        here.answer = answer;
        here.confidence = Confidence.MEDIUM;

        findings_text = extract_findings(here.question, answer);
        for text in findings_text {
            conf = assess_confidence(text, "web_search");
            finding = Finding(
                content=text,
                source="web_search",
                confidence=conf
            );
            here +>:AnsweredBy(method="web_search"):+> finding;
            root ++> finding;
        }
        print(f"    Found {len(findings_text)} facts");
    }
}

walker Connector {
    """Traverses findings and identifies cross-references."""

    can start with Root entry {
        visit [-->][?:Finding];
    }

    can connect with Finding entry {
        all_findings = [root-->][?:Finding];
        for other in all_findings {
            if other != here {
                relationship = find_connections(here.content, other.content);
                if relationship != "" {
                    here +>:RelatesTo(relationship=relationship):+> other;
                }
            }
        }
    }
}

walker Synthesizer {
    """Collects all findings and creates a synthesis."""
    has main_question: str = "";

    can start with Root entry {
        questions = [-->][?:ResearchQuestion];
        if questions {
            self.main_question = questions[0].question;
        }
        visit [-->][?:ResearchQuestion];
    }

    can synthesize with ResearchQuestion entry {
        all_findings = [root-->][?:Finding];
        if not all_findings {
            print("  No findings to synthesize yet.");
            return;
        }

        finding_texts = [f.content for f in all_findings];

        answer = synthesize_answer(here.question, finding_texts);
        gaps = identify_gaps(here.question, finding_texts);

        key_insights = finding_texts[:5];

        synth = Synthesis(
            summary=answer,
            key_insights=key_insights,
            confidence=Confidence.HIGH if len(all_findings) > 3 else Confidence.MEDIUM,
            gaps=gaps
        );
        root ++> synth;
        here +>:Supports(strength="strong"):+> synth;
        here.final_answer = answer;
        here.status = "complete";

        print(f"  Synthesis complete ({len(all_findings)} findings -> answer)");
        report {
            "answer": answer,
            "confidence": str(synth.confidence),
            "findings_used": len(all_findings),
            "knowledge_gaps": gaps
        };
    }
}

# ============================================================
# Main Research Pipeline
# ============================================================

walker ResearchPipeline {
    """Orchestrates the full research process."""
    has question: str;

    can start with Root entry {
        print(f"\n{'='*60}");
        print("JacMind Research Agent");
        print(f"{'='*60}");
        print(f"\nQuestion: {self.question}\n");

        # Step 1: Create the research question node
        rq = ResearchQuestion(question=self.question);
        root ++> rq;
        print("[1/4] Decomposing question...");

        # Step 2: Decompose
        root spawn Decomposer();

        # Step 3: Research each sub-question
        print("\n[2/4] Researching sub-questions...");
        root spawn Researcher();

        # Step 4: Find connections
        print("\n[3/4] Identifying connections...");
        root spawn Connector();

        # Step 5: Synthesize
        print("\n[4/4] Synthesizing answer...");
        result = root spawn Synthesizer();

        print(f"\n{'='*60}");
        print("RESEARCH COMPLETE");
        print(f"{'='*60}");

        if result.reports {
            data = result.reports[0];
            print(f"\nAnswer:\n{data['answer']}");
            print(f"\nConfidence: {data['confidence']}");
            print(f"Findings used: {data['findings_used']}");
            if data['knowledge_gaps'] {
                print("\nRemaining gaps:");
                for gap in data['knowledge_gaps'] {
                    print(f"  - {gap}");
                }
            }
        }

        # Report graph stats
        questions = [root-->][?:ResearchQuestion];
        sub_qs = [root-->][?:SubQuestion];
        findings = [root-->][?:Finding];
        syntheses = [root-->][?:Synthesis];
        print(f"\nKnowledge Graph: {len(questions)} questions, {len(sub_qs)} sub-questions, {len(findings)} findings, {len(syntheses)} syntheses");

        report result.reports;
    }
}

# ============================================================
# Public API Endpoints (for jac start)
# ============================================================

"""Ask a research question and get a comprehensive answer with knowledge graph."""
walker:pub research {
    has question: str;

    can start with Root entry {
        result = root spawn ResearchPipeline(question=self.question);
        report result.reports;
    }
}

"""Get the current state of the knowledge graph."""
walker:pub graph_status {
    can start with Root entry {
        questions = [-->][?:ResearchQuestion];
        sub_qs = [-->][?:SubQuestion];
        findings = [-->][?:Finding];
        syntheses = [-->][?:Synthesis];

        report {
            "questions": [{"question": q.question, "status": q.status, "type": str(q.question_type)} for q in questions],
            "sub_questions": [{"question": sq.question, "answer": sq.answer[:100], "confidence": str(sq.confidence)} for sq in sub_qs],
            "findings_count": len(findings),
            "syntheses_count": len(syntheses),
            "total_nodes": len(questions) + len(sub_qs) + len(findings) + len(syntheses)
        };
    }
}

"""Get all findings in the knowledge graph."""
walker:pub get_findings {
    can start with Root entry {
        findings = [-->][?:Finding];
        report [{"content": f.content, "source": f.source, "confidence": str(f.confidence), "relevance": str(f.relevance)} for f in findings];
    }
}

# ============================================================
# CLI Entry Point
# ============================================================

with entry {
    print("JacMind — Graph-Memory Research Agent");
    print("Usage: jac run main.jac  (interactive demo)");
    print("       jac start main.jac  (REST API mode)\n");

    # Demo: Research a question
    root spawn ResearchPipeline(
        question="What are the key advantages of graph-based memory systems for AI agents compared to traditional vector databases?"
    );
}
