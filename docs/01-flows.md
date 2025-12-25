# Unitana — Flows and Navigation (MVP)

## 1. First-run routing

- If no default Place exists → First Run
- Else → Dashboard

---

## 2. First Run (wizard, not skippable)

### Step order (4 steps)
1. Welcome (profile name)
2. Home
3. Destination
4. Review

### Step 1: Welcome
- Optional profile name
- Single primary CTA: Start
- No skip

### Step 2: Home
- City picker (city-based only)
- Unit system
- Clock preference

### Step 3: Destination
- City picker
- Unit system
- Clock preference
- Binary choices default opposite of Home until user changes them

### Step 4: Review
- Profile tile (tappable)
- Home card (tappable)
- Destination card (tappable)
- Confirm persists Places and enters Dashboard
- No Reset action here

---

## City picker rules (explicit)
- Cancel closes picker without mutating state
- Clear (X) clears search input only
- No forced selection

---

## Dashboard
- Default landing after setup
- Place chip opens Place Switcher
- Settings icon opens Settings
- Pull-to-refresh is rate-limited and honest

---

## Place management
- Always exactly one default Place
- Default Place cannot be deleted
- Default can be changed

---

## Widgets
- Configured in-app
- Read cached snapshots
- Paywall triggered on exceeding free allowance

---

## Paywall
- Primary trigger: widgets
- Never promise free trials
- Restore always available
