import { Trash2, AlertTriangle } from 'lucide-react'

interface ServerOptionsProps {
  onClearEntities: () => void
}

export function ServerOptions({ onClearEntities }: ServerOptionsProps) {
  return (
    <div className="h-full flex flex-col gap-3">
      <div className="glass-card p-4">
        <h4 className="text-xs font-medium text-white/50 uppercase tracking-wider mb-3">Danger Zone</h4>
        
        <button
          onClick={onClearEntities}
          className="w-full flex items-center justify-between p-3 rounded-xl bg-red-500/10 border border-red-500/20 hover:bg-red-500/20 transition-colors group"
        >
          <div className="flex items-center gap-3">
            <div className="p-2 rounded-lg bg-red-500/20">
              <Trash2 className="w-4 h-4 text-red-400" />
            </div>
            <div className="text-left">
              <p className="text-sm font-medium text-white/90">Clear All Entities</p>
              <p className="text-[11px] text-white/40">Remove all spawned objects, peds, and vehicles</p>
            </div>
          </div>
          <AlertTriangle className="w-4 h-4 text-red-400 opacity-0 group-hover:opacity-100 transition-opacity" />
        </button>
      </div>

      <div className="flex-1 flex items-center justify-center text-white/20 text-sm">
        <p>More options coming soon...</p>
      </div>
    </div>
  )
}

