# Mori Web

`www` contains four related surfaces that share one TypeScript/Vite workspace:

- The marketing web app served at `/`, with its entry point in `src/main.tsx`.
- The interactive Mori v2 product prototype served at `/mori-v2` and nested `/mori-v2/*` paths.
- The reusable React component library exported from `src/index.ts`.
- The Vercel serverless Pulse endpoints `/api/pulse/daily` and `/api/pulse/follow-up`, backed by the provider-neutral code in `server/pulse`.

The web workspace uses Node.js 20 and the pinned package manager declared in `package.json`: `pnpm@11.7.0`. Run commands from this directory unless noted otherwise.

## Set up

```sh
corepack enable
corepack prepare pnpm@11.7.0 --activate
pnpm install --frozen-lockfile
```

Copy `.env.example` to `.env.local` only when exercising the Pulse API locally. Never commit local environment files or provider credentials.

## Develop and verify

```sh
# Start the Vite development server.
pnpm dev

# Run the Vitest suite once.
pnpm test

# Type-check and build the deployable app into dist/.
pnpm build:app

# Type-check and build the distributable component library and declarations.
pnpm build:library
```

`pnpm build` is an alias for `pnpm build:library`. The app and library builds both use `dist/`, so run the command for the artifact you intend to consume.

## Deploy

Vercel is the deployment target. Configure the Vercel project with `www` as its Root Directory; `vercel.json` pins the install command, app build command, output directory, and `/mori-v2/*` rewrite. The normal production path is the Vercel Git integration on `main`, not a nested GitHub Actions workflow.

For an authorized manual deployment from this directory:

```sh
pnpm dlx vercel@50.28.0 link --yes --project <project> --scope <team>
pnpm build:app
pnpm dlx vercel@50.28.0 --prod
```

Use the explicit project and team identifiers to avoid linking the wrong account. Keep deployment tokens and generated `.vercel/` metadata local.
