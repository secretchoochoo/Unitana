# NEXT_CHAT_HANDOFF (2025-12-30d)

## What shipped

- Dashboard tiles support edit actions via long-press for user-added tiles:
  - Replace tile (choose a different tool)
  - Remove tile (delete tile and free the slot)
- Tool tiles now have stable keys: `ValueKey('dashboard_item_<itemId>')`.
- Regression test added: remove flow plus persistence across rebuild.
