# Saraswati LLM Intent Classifier — Implementation Brief

Reference document for the 8-phase intent classifier implementation.
See conversation history for full specification.

## Phases
1. Intent schema (sealed classes + JSON serialization)
2. Intent executor (intent → BaseRepository → markdown)
3. Keyword matcher (refactor 15 handlers to return Intent)
4. Intent cache (SQLite)
5. LLM classifier (Gemini function calling)
6. Chain orchestration (rewrite SaraswatiService.ask())
7. Feedback loop (correctIntent method)
8. Tests (unit + integration + 50-query smoke table)
