#!/usr/bin/env node

import { materializeOpenCodeSkillView } from "../.opencode/lib/pi-agent-setup-core.js";

const target = materializeOpenCodeSkillView(
  process.env.OPENCODE_FIXTURE,
  process.env.OPENCODE_CACHE_BASE,
);
process.send?.(target);
