---
name: frontend-design
description: Influences frontend output towards distinctive, production-grade design. Use when building web components, pages, or applications — any task that produces visible UI. Do NOT activate for code review, debugging, or performance auditing.
---

## Essential Principles

Before coding, understand the context and commit to a clear aesthetic direction:

- **Purpose**: What problem does this interface solve? Who uses it?
- **Tone**: Pick an extreme — brutally minimal, maximalist chaos, retro-futuristic, organic/natural, luxury/refined, playful/toy-like, editorial/magazine, brutalist/raw, art deco/geometric, industrial/utilitarian. Use these for inspiration but design one true to the chosen direction.
- **Constraints**: Technical requirements (framework, performance, accessibility).
- **Differentiation**: What makes this unforgettable? What's the one thing someone will remember?

Choose a clear conceptual direction and execute it with precision. Bold maximalism and refined minimalism both work — uncommitted aesthetics read as generic. The key is intentionality, not intensity.

**Aesthetics:**

- **Typography**: Choose distinctive, characterful fonts — unexpected pairings that elevate the design. Pair a display font with a refined body font. Avoid overused defaults (Inter, Roboto, Arial, system fonts) because they signal "no thought was given to this."
- **Colour & Theme**: Commit to a cohesive palette. Use CSS variables for consistency. Dominant colours with sharp accents outperform timid, evenly-distributed palettes.
- **Motion**: Prioritise CSS-only solutions for HTML; use Motion (framer-motion) for React when the project includes it, because coordinated timeline animations need orchestration CSS alone can't provide. One well-orchestrated page load with staggered reveals creates more delight than scattered micro-interactions. Use scroll-triggering and hover states that surprise.
- **Spatial Composition**: Unexpected layouts. Asymmetry. Overlap. Diagonal flow. Grid-breaking elements. Generous negative space OR controlled density.
- **Backgrounds & Visual Details**: Create atmosphere and depth rather than defaulting to solid colours. Gradient meshes, noise textures, geometric patterns, layered transparencies, dramatic shadows, decorative borders, custom cursors, grain overlays — whatever serves the aesthetic.

Match implementation complexity to the vision. Maximalist designs need elaborate code with extensive animations and effects. Minimalist designs need restraint, precision, and careful attention to spacing and typography.

## Quick Start

1. Identify purpose and audience
2. Choose a distinctive aesthetic direction
3. Select fonts, palette, and layout approach that serve that direction
4. Implement production-grade code with the aesthetic baked in — not bolted on
5. Refine details: spacing, transitions, hover states, load sequence

## Process

1. **Discover** — Clarify the interface's purpose, audience, and technical constraints.
2. **Direct** — Commit to a specific aesthetic tone. Name it explicitly (e.g. "brutalist editorial") so every subsequent choice has a reference point.
3. **Compose** — Select typography, palette, spatial layout, and motion strategy that reinforce the direction. Each choice should have a reason tied to the concept.
4. **Build** — Implement working code that is:
   - Production-grade and functional, because prototypes that break on edge cases erode trust in the design itself
   - Visually striking and memorable, because forgettable UI fails its core job of engaging users
   - Cohesive with a clear aesthetic point-of-view, because mixed signals make interfaces feel unfinished
   - Meticulously refined in every detail, because polish is what separates "designed" from "assembled"
5. **Verify** — Check against Success Criteria below. Adjust until every item passes.

## Success Criteria

- [ ] Aesthetic direction is nameable and consistent across all elements
- [ ] Typography, palette, and layout all reinforce the chosen direction
- [ ] No overused defaults (Inter, Roboto, purple gradients, card grids)
- [ ] Motion is intentional — enhances comprehension or delight, not decorative noise
- [ ] Code is production-grade: accessible, responsive, performant
- [ ] Result looks meaningfully different from the last generation

## Anti-Patterns

| Anti-Pattern | Why It Fails | Instead |
|--------------|-------------|---------|
| Overused font families (Inter, Roboto, Space Grotesk) | Signals "AI-generated" immediately | Pick fonts with character that match the aesthetic direction |
| Purple gradients on white backgrounds | Clichéd AI aesthetic | Commit to a palette that serves the concept |
| Predictable card-grid layouts | Every AI output looks like this | Use asymmetry, overlap, editorial composition |
| Cookie-cutter component patterns | Generic, context-free | Design for the specific purpose and audience |
| Same aesthetic across generations | Reveals lack of creative range | Vary themes, fonts, colour, and layout approach every time |
| Unthinking Tailwind/component library defaults | Produces homogeneous output | Style deliberately — defaults are a starting point, not a destination |
