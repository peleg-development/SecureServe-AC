# SecureServe Admin Panel UI

Modern React + TypeScript + Tailwind CSS admin panel for SecureServe AntiCheat.

## Development

```bash
cd SecureServe/src/panel/ingame/ui
npm install
npm run dev
```

## Build for Production

```bash
npm run build
```

This will output the compiled files to `../html/` directory:
- `index.html` - Main HTML file
- `app.js` - Compiled JavaScript bundle
- `styles.css` - Compiled CSS

## Features

- **Dashboard** - Server stats, active bans, uptime, peak players
- **Players** - Live player list with kick/ban/screenshot/spectate actions
- **Player Options** - ESP, player names, god mode, noclip, invisibility, bones
- **Server** - Clear entities and more server management options
- **Bans** - Full ban management with search, details modal, and unban

## Design

iOS-inspired glassmorphism design with:
- Frosted glass panels with backdrop blur
- Gray/white/transparent color scheme
- Smooth animations and transitions
- Compact sidebar navigation
- Responsive notifications system

