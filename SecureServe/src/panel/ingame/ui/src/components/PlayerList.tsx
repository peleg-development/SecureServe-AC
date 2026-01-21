import { useState } from 'react'
import { Search, UserX, Ban, Camera, Eye, Wifi } from 'lucide-react'
import type { Player } from '../types'

interface PlayerListProps {
  players: Player[]
  onKick: (id: number) => void
  onBan: (id: number) => void
  onScreenshot: (id: number) => void
  onSpectate: (id: number) => void
}

export function PlayerList({ players, onKick, onBan, onScreenshot, onSpectate }: PlayerListProps) {
  const [search, setSearch] = useState('')

  const filtered = players.filter((p) =>
    p.name.toLowerCase().includes(search.toLowerCase()) ||
    p.steamId?.toLowerCase().includes(search.toLowerCase())
  )

  return (
    <div className="h-full flex flex-col gap-3">
      <div className="relative">
        <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-white/30" />
        <input
          type="text"
          placeholder="Search players..."
          value={search}
          onChange={(e) => setSearch(e.target.value)}
          className="glass-input w-full pl-9 text-sm"
        />
      </div>

      <div className="flex-1 overflow-y-auto space-y-1.5">
        {filtered.length === 0 ? (
          <div className="flex flex-col items-center justify-center h-32 text-white/30">
            <p className="text-sm">No players found</p>
          </div>
        ) : (
          filtered.map((player) => (
            <div
              key={player.id}
              className="glass-card p-3 flex items-center gap-3 group hover:bg-white/8 transition-colors"
            >
              <div className="w-2 h-2 rounded-full bg-emerald-400 shadow-lg shadow-emerald-500/30" />
              
              <div className="flex-1 min-w-0">
                <p className="text-sm font-medium text-white/90 truncate">{player.name}</p>
                <p className="text-[11px] text-white/40 font-mono truncate">{player.steamId || 'No Steam ID'}</p>
              </div>

              <div className="flex items-center gap-1 text-white/30 text-xs">
                <Wifi className="w-3 h-3" />
                <span>{player.ping}ms</span>
              </div>

              <div className="flex gap-1 opacity-0 group-hover:opacity-100 transition-opacity">
                <ActionBtn icon={Eye} onClick={() => onSpectate(player.id)} title="Spectate" color="text-blue-400 hover:bg-blue-500/20" />
                <ActionBtn icon={Camera} onClick={() => onScreenshot(player.id)} title="Screenshot" color="text-cyan-400 hover:bg-cyan-500/20" />
                <ActionBtn icon={UserX} onClick={() => onKick(player.id)} title="Kick" color="text-amber-400 hover:bg-amber-500/20" />
                <ActionBtn icon={Ban} onClick={() => onBan(player.id)} title="Ban" color="text-red-400 hover:bg-red-500/20" />
              </div>
            </div>
          ))
        )}
      </div>

      <div className="text-[11px] text-white/30 text-center">
        {filtered.length} player{filtered.length !== 1 ? 's' : ''} online
      </div>
    </div>
  )
}

function ActionBtn({ icon: Icon, onClick, title, color }: { icon: typeof Eye; onClick: () => void; title: string; color: string }) {
  return (
    <button
      onClick={onClick}
      title={title}
      className={`p-1.5 rounded-lg transition-colors ${color}`}
    >
      <Icon className="w-3.5 h-3.5" />
    </button>
  )
}

