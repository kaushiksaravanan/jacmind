"""
JacMind Demo Script — Runs with cached data for reliable demonstration.
Shows the knowledge graph growing without needing live API calls.
"""

import json;

# ============================================================
# Enums for Structured AI Output
# ============================================================

enum Confidence { LOW, MEDIUM, HIGH, CERTAIN }
sem Confidence.LOW = "Uncertain, needs more evidence";
sem Confidence.MEDIUM = "Some supporting evidence but not conclusive";
sem Confidence.HIGH = "Strong evidence supports this";
sem Confidence.CERTAIN = "Verified from multiple reliable sources";

enum QuestionType { FACTUAL, ANALYTICAL, COMPARATIVE, CAUSAL, EXPLORATORY }
enum Relevance { CORE, SUPPORTING, TANGENTIAL }

# ============================================================
# Graph Nodes
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
# Typed Edges
# ============================================================

edge DecomposesTo { has reasoning: str = ""; }
edge AnsweredBy { has method: str = "search"; }
edge Supports { has strength: str = "moderate"; }
edge RelatesTo { has relationship: str = ""; }

# ============================================================
# Demo Walker — Shows the full pipeline with pre-computed data
# ============================================================

walker DemoResearch {
    has question: str;

    can start with Root entry {
        print(f"\n{'='*60}");
        print("JacMind Research Agent — Demo Mode");
        print(f"{'='*60}");
        print(f"\nQuestion: {self.question}\n");

        # Step 1: Create research question
        rq = ResearchQuestion(
            question=self.question,
            question_type=QuestionType.COMPARATIVE
        );
        root ++> rq;

        # Step 2: Decompose into sub-questions
        print("[1/4] Decomposing question...");
        sub_questions = [
            ("How do graph structures represent relationships between concepts?",
             "Understanding the structural advantage of graphs"),
            ("What limitations do vector databases have for multi-hop reasoning?",
             "Identifying weaknesses in the alternative approach"),
            ("How do knowledge graphs enable compositional reasoning?",
             "Understanding the core mechanism that makes graphs powerful"),
            ("What are real-world systems using graph-based memory?",
             "Grounding in practical evidence")
        ];

        for (q, r) in sub_questions {
            sub = SubQuestion(question=q, reasoning=r);
            rq +>:DecomposesTo(reasoning=r):+> sub;
            root ++> sub;
        }
        print(f"  Decomposed into {len(sub_questions)} sub-questions");

        # Step 3: Research each sub-question
        print("\n[2/4] Researching sub-questions...");
        findings_data = [
            ("Graph structures natively represent entities as nodes and relationships as edges, preserving semantic connections that flat embeddings lose.", "web_search", Confidence.HIGH, Relevance.CORE),
            ("Knowledge graphs support transitive reasoning (A->B->C implies A->C) without additional training or retrieval steps.", "web_search", Confidence.HIGH, Relevance.CORE),
            ("Vector databases rely on cosine similarity which struggles with negation, temporal ordering, and multi-hop logical chains.", "web_search", Confidence.CERTAIN, Relevance.CORE),
            ("RAG systems using vector stores often retrieve semantically similar but logically irrelevant passages for complex queries.", "arxiv", Confidence.HIGH, Relevance.SUPPORTING),
            ("Graph-based memory enables agents to update beliefs incrementally without re-embedding entire documents.", "web_search", Confidence.MEDIUM, Relevance.SUPPORTING),
            ("Microsoft's GraphRAG (2024) showed 30-70% improvement over naive RAG on multi-hop questions by using community detection on knowledge graphs.", "arxiv", Confidence.CERTAIN, Relevance.CORE),
            ("Neo4j + LLM systems achieve sub-second query times on relationship-heavy queries that vector DBs timeout on.", "benchmark", Confidence.HIGH, Relevance.SUPPORTING),
            ("MemGPT and similar systems use graph structures for long-term agent memory that persists across sessions.", "web_search", Confidence.MEDIUM, Relevance.TANGENTIAL),
            ("Graph schemas are self-documenting: edge types like 'causes', 'precedes', 'contradicts' make reasoning chains interpretable.", "web_search", Confidence.HIGH, Relevance.CORE),
            ("Hybrid approaches combining vector similarity for initial retrieval + graph traversal for reasoning show the best results in benchmarks.", "arxiv", Confidence.HIGH, Relevance.SUPPORTING)
        ];

        all_findings: list[Finding] = [];
        sub_qs = [root-->][?:SubQuestion];
        idx = 0;
        for (content, source, conf, rel) in findings_data {
            f = Finding(content=content, source=source, confidence=conf, relevance=rel);
            root ++> f;
            all_findings.append(f);
            if idx < len(sub_qs) {
                sub_qs[idx % len(sub_qs)] +>:AnsweredBy(method=source):+> f;
            }
            idx += 1;
        }

        for sq in sub_qs {
            print(f"  Researching: {sq.question}");
            related = [sq-->][?:Finding];
            print(f"    Found {len(related)} facts");
        }

        # Step 4: Find connections
        print("\n[3/4] Identifying connections...");
        connections_found = 0;
        for i in range(len(all_findings)) {
            for j in range(i + 1, min(i + 3, len(all_findings))) {
                all_findings[i] +>:RelatesTo(relationship="supports"):+> all_findings[j];
                connections_found += 1;
            }
        }
        print(f"  Found {connections_found} cross-references");

        # Step 5: Synthesize
        print("\n[4/4] Synthesizing answer...");
        synthesis_text = """Graph-based memory systems offer several key advantages over traditional vector databases for AI agents:

1. **Structural Reasoning**: Graphs natively represent relationships (causes, precedes, contradicts) that flat vector embeddings lose. This enables multi-hop reasoning without additional retrieval steps.

2. **Compositional Queries**: Vector similarity struggles with negation, temporal ordering, and logical chains. Graphs support transitive reasoning (A->B->C) directly.

3. **Incremental Updates**: Agents can update beliefs by modifying graph edges without re-embedding entire documents — critical for long-running agents.

4. **Interpretability**: Edge types make reasoning chains transparent and auditable, unlike opaque vector similarity scores.

5. **Proven Performance**: Microsoft's GraphRAG showed 30-70% improvement over naive RAG on complex queries. Hybrid approaches (vector retrieval + graph reasoning) achieve the best results.

The ideal architecture combines vector databases for initial semantic retrieval with knowledge graphs for structured reasoning — leveraging the strengths of both paradigms.""";

        synth = Synthesis(
            summary=synthesis_text,
            key_insights=[f.content for f in all_findings[:5]],
            confidence=Confidence.HIGH,
            gaps=["Long-term scalability of graph memory beyond millions of nodes",
                  "Computational cost comparison for real-time agent decision-making",
                  "Standardized benchmarks for graph-vs-vector agent memory"]
        );
        root ++> synth;
        rq +>:Supports(strength="strong"):+> synth;
        rq.final_answer = synthesis_text;
        rq.status = "complete";
        print(f"  Synthesis complete ({len(all_findings)} findings -> answer)");

        # Print results
        print(f"\n{'='*60}");
        print("RESEARCH COMPLETE");
        print(f"{'='*60}");
        print(f"\nAnswer:\n{synthesis_text}");
        print(f"\nConfidence: {str(synth.confidence)}");
        print(f"Findings used: {len(all_findings)}");
        print("\nRemaining gaps:");
        for gap in synth.gaps {
            print(f"  - {gap}");
        }

        # Graph stats
        questions = [root-->][?:ResearchQuestion];
        sub_qs_final = [root-->][?:SubQuestion];
        findings_final = [root-->][?:Finding];
        syntheses = [root-->][?:Synthesis];
        print(f"\nKnowledge Graph Stats:");
        print(f"  Questions: {len(questions)}");
        print(f"  Sub-questions: {len(sub_qs_final)}");
        print(f"  Findings: {len(findings_final)}");
        print(f"  Syntheses: {len(syntheses)}");
        print(f"  Total nodes: {len(questions) + len(sub_qs_final) + len(findings_final) + len(syntheses)}");
    }
}

# ============================================================
# Entry Point
# ============================================================

with entry {
    root spawn DemoResearch(
        question="What are the key advantages of graph-based memory systems for AI agents compared to traditional vector databases?"
    );
}
