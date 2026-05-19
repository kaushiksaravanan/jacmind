# Devpost Submission — JacMind

## Project Title
JacMind — Graph-Memory Research Agent

## Tagline
An autonomous agent that builds persistent knowledge graphs through multi-step reasoning, showcasing the full power of Jac's AI-native paradigm.

## Inspiration
Traditional RAG systems retrieve similar text but can't reason over relationships. We asked: what if an AI agent's memory was a graph it actively builds and traverses? Jac's graph-native design makes this natural — nodes are knowledge, edges are relationships, and walkers are reasoning agents.

## What it does
JacMind takes a complex research question and autonomously:
1. Classifies the question type (factual, analytical, comparative, causal, exploratory)
2. Decomposes it into focused sub-questions with reasoning about why each matters
3. Researches each sub-question using web search via tool calling
4. Stores findings as graph nodes with confidence assessments and relevance scoring
5. Identifies cross-references and connections between findings
6. Synthesizes a comprehensive answer by reasoning over the full knowledge graph
7. Reports knowledge gaps that need further investigation

The knowledge graph persists across sessions — each new question builds on prior research.

## How we built it
100% Jac, leveraging every core feature of the language:
- **9 byLLM functions** with structured outputs (enums, objects) — zero prompt engineering
- **5 node types** with typed edges forming a queryable knowledge graph
- **4 specialized walkers** (Decomposer, Researcher, Connector, Synthesizer)
- **Tool calling** for real web search via DuckDuckGo API
- **Semantic annotations** (`sem`) to guide LLM behavior declaratively
- **Auto REST API** via `walker:pub` — instant deployment with `jac start`

Single file. No framework. No boilerplate. Pure Jac.

## Challenges we ran into
- Understanding walker traversal patterns and how they interact with the graph state
- Debugging tool calling within byLLM when the LLM decides not to use available tools
- Getting the right model configuration through litellm/byllm plugin system
- Balancing between too many LLM calls (expensive/slow) and too few (shallow reasoning)

## Accomplishments that we're proud of
- The entire agent fits in ONE .jac file — 400 lines, full multi-agent research system
- Graph structure is self-documenting: edge types like DecomposesTo, AnsweredBy, RelatesTo, Contradicts tell you what the agent learned
- Zero prompt engineering — sem annotations and type signatures do all the work
- The knowledge graph genuinely persists and grows across sessions

## What we learned
- Jac's `sem` keyword eliminates 90% of prompt engineering — function signatures ARE specifications
- Walker-based architecture maps perfectly to multi-step agent workflows
- Typed edges make reasoning chains interpretable and auditable
- Graph-native persistence means agent memory is automatic, not a feature to implement

## What's next for JacMind
- Recursive decomposition (sub-questions that spawn further sub-questions for deep research)
- Contradiction detection via `Contradicts` edges when findings conflict
- React frontend using Jac's `cl` codespace for live graph visualization
- Multi-user collaborative research graphs
- Integration with academic APIs (arXiv, Semantic Scholar) via additional tools

## Built With
- Jac (jaclang 0.15.2)
- byllm (LLM integration plugin)
- Gemini 2.0 Flash (via litellm)
- DuckDuckGo API (web search tool)

## Tracks
- Primary: Agentic AI
- Sub-tracks: Best Use of Jac, Best Demo

## Links
- GitHub: https://github.com/kaushiksaravanan/jacmind
- Demo video: [TO BE RECORDED]
