# Quickstart


- Main repo: https://github.com/weftspun/weftspun-3d-studio
- Upstream attribution: https://github.com/M3-org/CharacterStudio (M3-org avatar-trait foundation)


```bash
# Clone the repo and change directory into it
git clone https://github.com/weftspun/weftspun-3d-studio
cd Weftspun3DStudio

# Install dependencies with legacy peer deps flag to ignore React errors
npm install --legacy-peer-deps
npm run dev

# Or use yarn
yarn install
yarn run dev
```

## Troubleshooting

Most tests of this project use node v16. Install nvm to change
version quickly. See https://github.com/nvm-sh/nvm.

Copy custom asset packs to the `public/` folder. To mod or reskin
the project, change the files there.

If the assets do not show, check the `.env` file. Point it at a
remote host, such as https://m3-org.github.io/loot-assets/loot/. A
GitHub Pages host also works. Or point it at a path in the public
directory, such as `VITE_ASSET_PATH=./loot-assets`.

If you change the project name, also change these files:

- `vite.config.js`
- `package.json`
