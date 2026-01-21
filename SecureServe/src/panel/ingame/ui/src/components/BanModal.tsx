import { X, Copy, User, Undo2 } from 'lucide-react'
import type { Ban } from '../types'

interface BanModalProps {
  ban: Ban
  onClose: () => void
  onUnban: (id: string) => void
  onCopy: (text: string) => void
}

export function BanModal({ ban, onClose, onUnban, onCopy }: BanModalProps) {
  const fields = [
    { label: 'Steam ID', value: ban.steam },
    { label: 'Discord', value: ban.discord },
    { label: 'IP Address', value: ban.ip },
    { label: 'HWID', value: ban.hwid1 },
  ]

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4" onClick={onClose}>
      <div className="absolute inset-0 bg-black/60 backdrop-blur-sm" />
      
      <div
        className="relative glass-panel rounded-2xl w-full max-w-md animate-scale-in"
        onClick={(e) => e.stopPropagation()}
      >
        <div className="p-4 border-b border-white/8 flex items-center justify-between">
          <h3 className="text-sm font-medium text-white/90">Ban Details</h3>
          <button
            onClick={onClose}
            className="p-1.5 rounded-lg text-white/40 hover:text-white/80 hover:bg-white/10 transition-colors"
          >
            <X className="w-4 h-4" />
          </button>
        </div>

        <div className="p-4">
          <div className="flex items-center gap-3 mb-4">
            <div className="w-12 h-12 rounded-full bg-red-500/20 flex items-center justify-center">
              <User className="w-5 h-5 text-red-400" />
            </div>
            <div>
              <p className="font-medium text-white/90">{ban.name}</p>
              <span className="text-[11px] px-2 py-0.5 rounded-full bg-red-500/20 text-red-400">Banned</span>
            </div>
          </div>

          <div className="space-y-2.5">
            {fields.map(({ label, value }) => (
              <div key={label} className="p-2.5 rounded-lg bg-white/5 border border-white/5">
                <p className="text-[10px] text-white/40 uppercase tracking-wider mb-1">{label}</p>
                <div className="flex items-center justify-between gap-2">
                  <p className="text-xs text-white/70 font-mono truncate">{value || 'N/A'}</p>
                  {value && (
                    <button
                      onClick={() => onCopy(value)}
                      className="p-1 rounded text-white/30 hover:text-white/60 transition-colors"
                    >
                      <Copy className="w-3 h-3" />
                    </button>
                  )}
                </div>
              </div>
            ))}

            <div className="p-2.5 rounded-lg bg-white/5 border border-white/5">
              <p className="text-[10px] text-white/40 uppercase tracking-wider mb-1">Expires</p>
              <p className="text-xs text-white/70">{ban.expire}</p>
            </div>

            <div className="p-2.5 rounded-lg bg-white/5 border border-white/5">
              <p className="text-[10px] text-white/40 uppercase tracking-wider mb-1">Reason</p>
              <p className="text-xs text-white/70 leading-relaxed">{ban.reason || 'No reason provided'}</p>
            </div>
          </div>
        </div>

        <div className="p-4 border-t border-white/8 flex gap-2">
          <button
            onClick={onClose}
            className="flex-1 py-2 px-3 rounded-lg bg-white/8 text-white/70 text-sm font-medium hover:bg-white/12 transition-colors"
          >
            Close
          </button>
          <button
            onClick={() => { onUnban(ban.id); onClose() }}
            className="flex-1 py-2 px-3 rounded-lg bg-emerald-500/20 text-emerald-400 text-sm font-medium hover:bg-emerald-500/30 transition-colors flex items-center justify-center gap-2"
          >
            <Undo2 className="w-4 h-4" />
            Unban
          </button>
        </div>
      </div>
    </div>
  )
}

