# Demo Video Script — JacMind (3 minutes max)

## Opening (0:00 - 0:20)
"JacMind is a graph-memory research agent built entirely in Jac.
It doesn't just answer questions — it builds a persistent knowledge graph
through multi-step reasoning."

## Show the Code (0:20 - 0:50)
- Open main.jac
- Highlight: "This is the ENTIRE agent — 400 lines, single file"
- Point out: node definitions (knowledge structure)
- Point out: byLLM functions (9 AI capabilities, zero prompt engineering)
- Point out: walkers (4 specialized reasoning agents)
- Point out: tool calling (web_search as a tool)

## Run the Demo (0:50 - 2:00)
- Terminal: `jac run demo.jac`
- Show question decomposition happening
- Show sub-questions being researched
- Show connections being found
- Show synthesis with confidence levels
- Show final knowledge graph stats (17 nodes!)

## Show the Graph Growing (2:00 - 2:30)
- Run again with a DIFFERENT question
- Show graph stats growing (more nodes, more connections)
- "Each question builds on prior research — the graph persists"

## Architecture Recap (2:30 - 2:50)
- Show the architecture diagram from README
- "Walker → byLLM → Tool → Graph Node → Synthesis"
- "This is what Jac was MADE for — graph-native AI agents"

## Closing (2:50 - 3:00)
"JacMind: graph-based memory for AI agents.
Built with Jac. No framework. No boilerplate. Just intelligence."
