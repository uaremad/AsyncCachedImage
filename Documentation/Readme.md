# Documentation

Extended changelog and technical documentation for AsyncCachedImage.

## Structure

```
Documentation/
├── README.md                 ← You are here
├── releases/
│   ├── unreleased/           ← Changes for next release
│   │   └── *.md
│   ├── 2025.11.1/            ← Initial release
│   │   └── initial-release.md
│   └── 2025.x.x/             ← Future releases
│       └── *.md
├── architecture/             ← Design documents (optional)
│   └── *.md
└── decisions/                ← ADRs (optional)
    └── ADR-xxx-*.md
```

## Workflow

1. New fixes/features → `releases/unreleased/`
2. On release → rename folder to version number
3. Each MD describes one significant change

## Naming Convention

Files in `releases/` use kebab-case describing the change:

- `sync-memory-cache-prevents-flicker.md`
- `add-progressive-loading.md`
- `fix-memory-leak-on-rapid-scroll.md`

## Note

This folder is ignored by Swift Package Manager. It exists purely for documentation purposes and does not affect the compiled library.
