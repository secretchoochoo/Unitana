# Unitana UI Contracts (stable keys)

This document lists widget `Key` values that are treated as stable contracts between UI and tests (and are safe to depend on for automation).

## First-run wizard

### Navigation

- `first_run_nav_prev` (left chevron)
- `first_run_nav_next` (right chevron)
- `first_run_finish_button` (Finish on final step)

### Step containers

These are helpful for future UI tests and analytics instrumentation.

- `first_run_step_welcome`
- `first_run_step_profile`
- `first_run_step_home`
- `first_run_step_destination`
- `first_run_step_review`

### Profile

- `first_run_profile_name_field` (TextField)

### Places

- `first_run_home_city_button` (opens home city picker)
- `first_run_dest_city_button` (opens destination city picker)

## Dashboard

- `dashboard_reset_button` (clears app state, for testing)
