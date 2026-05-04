# Rostrik - Master Architecture Document

## Core Objective
A highly reliable, offline-first lifestyle OS and alarm ecosystem specifically designed for shift workers.

## Tech Stack & Constraints
- **Framework:** Native Flutter.
- **State Management:** (Wait for Claude's MVP recommendation, but keep it simple, e.g., Provider).
- **Data Storage:** STRICTLY LOCAL. No cloud databases (Firebase, Supabase, etc.), no external login systems. All user rosters and alarm data must live on the device.

## Architectural Rules (Non-Negotiable)
1. **Separation of Concerns:** Business logic (saving data, calculating shift rotations, triggering alarms) must be 100% separated from UI code.
2. **No UI Bloat:** Build the underlying logic and data models first. UI is only implemented after the logic is proven to work.
3. **Hardware Constraints:** Background alarm triggering must work reliably without relying on complex, battery-draining hardware sensors (e.g., no accelerometer/shake-to-wake logic for V1).

## V1 MVP Scope
- **Storage:** Reliable local database setup.
- **Roster:** A calendar/timeline view to add, edit, and delete basic shift blocks (Day, Night, Afternoon, Off).
- **Alarms:** Core engine that reads the local calendar and fires an alarm at a user-defined time before a scheduled shift. Basic device ringtones only.