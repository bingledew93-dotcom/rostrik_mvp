/// Prompt template for the "Import Roster via AI Bridge" feature.
///
/// The user copies this, pastes it into any LLM (ChatGPT, Gemini, Claude, …)
/// along with their raw roster/contract text, and pastes the model's reply back
/// into [ImportAiModal]. It constrains the model to emit ONE line per day in a
/// strict, machine-parseable shape:
///
///     DD/MM/YYYY | Day|Night|Off | HH:MM - HH:MM
///
/// This string is a CONTRACT with `RosterAiParser.parseAiOutput` — the parser's
/// RegExp matches exactly the format described here. If you change the format in
/// this prompt, update the parser (and its tests) in lock-step, or imports break
/// silently.
const String kRosterAiPromptTemplate = '''
I am going to provide my work schedule, roster text, or contract below. Extract my work shifts and reply ONLY with a clean list using this exact format for every single day, with no introductory text, markdown tables, or concluding remarks:

DD/MM/YYYY | [Day/Afternoon/Night/Off] | [HH:MM] - [HH:MM]

Rules:
1. Use 24-hour time format (e.g., 06:00, 18:00).
2. For Off / Rest days, set times to 00:00 - 00:00.
3. Keep day types strictly to: Day, Afternoon, Night, or Off.

Example output:
10/08/2026 | Day | 06:00 - 14:00
11/08/2026 | Afternoon | 14:00 - 22:00
12/08/2026 | Night | 22:00 - 06:00
13/08/2026 | Off | 00:00 - 00:00

Here is my schedule text to extract:
''';
