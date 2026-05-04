# website

Static landing page for the `nestjs-auth-bootstrap` plugin.

## Local preview

```bash
# any static server works
npx serve .
# or
python -m http.server 5173
```

## Deploy to Vercel

```bash
vercel --cwd website
```

No build step. `vercel.json` adds basic security headers and cache rules.

## Deploy to GitHub Pages

Point Pages at `/website` on the default branch (Settings → Pages → Source → branch `main`, folder `/website`).
