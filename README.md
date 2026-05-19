# JacMind — Graph-Memory Research Agent

> An autonomous research agent that builds persistent knowledge graphs through multi-step reasoning, demonstrating the full power of Jac's AI-native programming model.

[![Built with Jac](https://img.shields.io/badge/Built%20with-Jac-blue)](https://jaseci.org)
[![JacHacks Spring 2026](https://img.shields.io/badge/JacHacks-Spring%202026-purple)](https://jachacks-spring.devpost.com)

## What It Does

JacMind takes a complex research question and:

1. **Decomposes** it into focused sub-questions using `byLLM` classification
2. **Researches** each sub-question autonomously via tool-calling (web search)
3. **Stores findings** as graph nodes with typed relationships
4. **Identifies connections** between findings across sub-questions
5. **Synthesizes** a comprehensive answer by traversing the knowledge graph

The result is not just an answer — it's a **persistent, queryable knowledge graph** that grows with each research session.

## Why Jac?

JacMind is purpose-built to showcase what makes Jac unique for agentic AI:

| Jac Feature | How JacMind Uses It |
|---|---|
| **byLLM** | 9 AI functions with type-safe structured outputs — no prompt engineering |
| **Graph Nodes** | Knowledge stored as `ResearchQuestion → SubQuestion → Finding → Synthesis` |
| **Typed Edges** | `DecomposesTo`, `AnsweredBy`, `Supports`, `RelatesTo`, `Contradicts` |
| **Walkers** | `Decomposer`, `Researcher`, `Connector`, `Synthesizer` traverse the graph |
| **Semantic Annotations** | `sem` keyword guides LLM behavior without prompt hacking |
| **Enums** | `Confidence`, `QuestionType`, `Relevance` constrain LLM outputs to valid values |
| **Tool Calling** | `web_search` tool given to LLM via `by llm(tools=[...])` |
| **Auto API** | `walker:pub` makes the agent accessible as REST endpoints |
| **Persistence** | Knowledge graph persists across sessions via `root` connection |

**This is not a wrapper around an API call.** It's a multi-agent system where walkers coordinate through the graph structure itself.

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    ResearchPipeline Walker                    │
├──────────┬──────────┬──────────────┬────────────────────────┤
│Decomposer│Researcher│  Connector   │     Synthesizer        │
│  Walker  │  Walker  │   Walker     │       Walker           │
├──────────┴──────────┴──────────────┴────────────────────────┤
│                    Knowledge Graph                            │
│  [Question] --DecomposesTo--> [SubQ] --AnsweredBy--> [Finding]│
│                                                    ↕ RelatesTo│
│  [Question] --Supports--> [Synthesis] <-- [Finding]          │
├─────────────────────────────────────────────────────────────┤
│              byLLM Functions (9 AI capabilities)              │
│  classify | decompose | extract | assess | synthesize | ...  │
├─────────────────────────────────────────────────────────────┤
│              Tools: web_search (DuckDuckGo API)              │
└─────────────────────────────────────────────────────────────┘
```

## Quick Start

### Prerequisites
- Python 3.10+
- A Gemini API key (or any LLM provider supported by byllm)

### Install & Run

```bash
# Install Jac
pip install jaseci

# Clone this repo
git clone https://github.com/YOUR_USERNAME/jacmind.git
cd jacmind

# Set your API key
export GEMINI_API_KEY=your_key_here

# Run the demo
jac run main.jac

# Or start as REST API
jac start main.jac
```

### API Usage

Once running with `jac start`, the following endpoints are available:

```bash
# Research a question
curl -X POST http://localhost:8000/walker/research \
  -H "Content-Type: application/json" \
  -d '{"question": "How do graph neural networks compare to transformers for knowledge representation?"}'

# Check knowledge graph status
curl -X POST http://localhost:8000/walker/graph_status

# Get all findings
curl -X POST http://localhost:8000/walker/get_findings
```

## Example Output

```
============================================================
JacMind Research Agent
============================================================

Question: What are the key advantages of graph-based memory for AI agents?

[1/4] Decomposing question...
  Decomposed into 4 sub-questions

[2/4] Researching sub-questions...
  Researching: How do graph structures represent relationships between concepts?
    Found 3 facts
  Researching: What limitations do vector databases have for multi-hop reasoning?
    Found 4 facts
  Researching: How do knowledge graphs enable compositional reasoning?
    Found 3 facts
  Researching: What are real-world examples of graph-based AI memory systems?
    Found 2 facts

[3/4] Identifying connections...

[4/4] Synthesizing answer...
  Synthesis complete (12 findings -> answer)

============================================================
RESEARCH COMPLETE
============================================================

Knowledge Graph: 1 questions, 4 sub-questions, 12 findings, 1 syntheses
```

## Project Structure

```
jacmind/
├── main.jac          # Complete agent implementation (single file!)
├── jac.toml          # Project configuration
├── .env              # API keys (not committed)
├── .gitignore
└── README.md
```

## Key Design Decisions

1. **Single-file architecture**: The entire agent fits in one `.jac` file, demonstrating Jac's expressiveness
2. **Graph-first memory**: Knowledge is stored as a graph, not a flat list — enabling relationship reasoning
3. **Walker coordination**: Each research phase is a separate walker, communicating through the shared graph
4. **Structured outputs everywhere**: Enums and objects constrain LLM outputs — no parsing failures
5. **Real tool use**: The agent actually searches the web, not simulated data

## What Surprised Us

- Jac's `sem` annotations eliminated 90% of prompt engineering — the function signature IS the specification
- Walker-based traversal is a natural fit for multi-step research — each walker has a single responsibility
- Typed edges (`DecomposesTo`, `RelatesTo`, `Contradicts`) make the knowledge graph self-documenting
- The auto-generated REST API from `walker:pub` means zero boilerplate for deployment

## What We'd Do Next

- Add `Contradicts` edge detection for conflicting findings
- Implement recursive decomposition (sub-questions that spawn further sub-questions)
- Build a React frontend using Jac's `cl` codespace for graph visualization
- Add multi-session memory (the graph persists, so subsequent questions build on prior research)
- Implement confidence propagation through the graph

## Built For

- **Track**: Agentic AI
- **Sub-tracks**: Best Use of Jac, Best Demo

## Team

Built during JacHacks Spring 2026 (May 15-19, 2026)

## License

MIT
