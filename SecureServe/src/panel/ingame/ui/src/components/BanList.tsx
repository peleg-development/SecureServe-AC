import { useState } from 'react'
import { Search, Undo2, Info, CheckCircle, User } from 'lucide-react'
import type { Ban } from '../types'

interface BanListProps {
  bans: Ban[]
  onUnban: (id: string) => void
  onShowDetails: (ban: Ban) => void
}

export function BanList({ bans, onUnban, onShowDetails }: BanListProps) {
  const [search, setSearch] = useState('')

  const filtered = bans.filter((b) =>
    b.name.toLowerCase().includes(search.toLowerCase()) ||
    b.steam?.toLowerCase().includes(search.toLowerCase()) ||
    b.reason?.toLowerCase().includes(search.toLowerCase())
  )

  return (
    <div className="h-full flex flex-col gap-3">
      <div className="relative">
        <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-white/30" />
        <input
          type="text"
          placeholder="Search bans..."
          value={search}
          onChange={(e) => setSearch(e.target.value)}
          className="glass-input w-full pl-9 text-sm"
        />
      </div>

      <div className="flex-1 overflow-y-auto space-y-2">
        {filtered.length === 0 ? (
          <div className="flex flex-col items-center justify-center h-32 text-white/30 gap-2">
            <CheckCircle className="w-8 h-8 text-emerald-400/50" />
            <p className="text-sm">No bans found</p>
          </div>
        ) : (
          filtered.map((ban) => (
            <div key={ban.id} className="glass-card p-3 hover:bg-white/8 transition-colors">
              <div className="flex items-start gap-3">
                <div className="w-9 h-9 rounded-full bg-red-500/20 flex items-center justify-center flex-shrink-0">
                  <User className="w-4 h-4 text-red-400" />
                </div>
                
                <div className="flex-1 min-w-0">
                  <div className="flex items-start justify-between gap-2">
                    <div className="min-w-0">
                      <p className="text-sm font-medium text-white/90 truncate">{ban.name}</p>
                      <p className="text-[11px] text-white/40 truncate">{ban.expire}</p>
                    </div>
                    <div className="flex gap-1 flex-shrink-0">
                      <button
                        onClick={() => onShowDetails(ban)}
                        className="p-1.5 rounded-lg text-white/40 hover:text-white/80 hover:bg-white/10 transition-colors"
                        title="Details"
                      >
                        <Info className="w-3.5 h-3.5" />
                      </button>
                      <button
                        onClick={() => onUnban(ban.id)}
                        className="p-1.5 rounded-lg text-emerald-400 hover:bg-emerald-500/20 transition-colors"
                        title="Unban"
                      >
                        <Undo2 className="w-3.5 h-3.5" />
                      </button>
                    </div>
                  </div>
                  <p className="text-xs text-white/50 mt-1 line-clamp-1">{ban.reason || 'No reason provided'}</p>
                </div>
              </div>
            </div>
          ))
        )}
      </div>

      <div className="text-[11px] text-white/30 text-center">
        {bans.length} total ban{bans.length !== 1 ? 's' : ''}
      </div>
    </div>
  )
}

