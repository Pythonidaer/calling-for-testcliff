<!-- Source: Pythonidaer/llm-instruction-toolkit, synced 2026-11-09 -->
# Agent working rules
- Stay inside the requested change. Do not reformat, rename, or restructure unrelated code. Exception: a task that explicitly says to refactor or clean up a named file authorizes restructuring within that file only.
- Read current behavior before editing. Do not invent a product, API, or style decision; ask when the task and code do not settle it.
- Vanilla JavaScript (ES modules, Node 22). Run npm test before finishing. Preserve behavior; prefer existing tests over new ones that restate the implementation.
- For writing, reviewing, or refactoring code, apply .cursor/rules/clean-code.mdc.
- New and rewritten code follows .cursor/rules/ts-js-style.mdc. Do not copy the compact layout of older code.
- In the summary, name the rules you applied and any you skipped.
