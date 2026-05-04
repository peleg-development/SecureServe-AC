import { Users, Ban, Clock, TrendingUp, Info } from 'lucide-react'
import type { DashboardStats } from '../types'

interface DashboardProps {
  stats: DashboardStats
}

const updates = [
  { id: 1, title: 'Client Detections Overhaul', desc: 'Remade most client-side detection systems', date: '01/15/2026' },
  { id: 2, title: 'Module System Fixed', desc: 'Fixed module functionality across all components', date: '01/14/2026' },
  { id: 3, title: 'Anti Give Weapon', desc: 'Fixed anti give weapon detection system', date: '01/13/2026' },
]

export function Dashboard({ stats }: DashboardProps) {
  const statCards = [
    { label: 'Online Players', value: stats.totalPlayers, icon: Users, color: 'text-blue-400', bg: 'from-blue-500/10 to-blue-600/5' },
    { label: 'Active Bans', value: stats.activeCheaters, icon: Ban, color: 'text-red-400', bg: 'from-red-500/10 to-red-600/5' },
    { label: 'Uptime', value: stats.serverUptime, icon: Clock, color: 'text-emerald-400', bg: 'from-emerald-500/10 to-emerald-600/5' },
    { label: 'Peak Players', value: stats.peakPlayers, icon: TrendingUp, color: 'text-amber-400', bg: 'from-amber-500/10 to-amber-600/5' },
  ]

  return (
    <div className="h-full flex flex-col gap-4 overflow-y-auto p-1">
      <div className="grid grid-cols-2 gap-3">
        {statCards.map(({ label, value, icon: Icon, color, bg }) => (
          <div
            key={label}
            className={`glass-card p-4 bg-gradient-to-br ${bg} group hover:scale-[1.02] transition-transform duration-200`}
          >
            <div className="flex items-start justify-between">
              <div>
                <p className="text-[11px] text-white/40 uppercase tracking-wider font-medium">{label}</p>
                <p className="text-2xl font-semibold text-white/90 mt-1">{value}</p>
              </div>
              <div className={`p-2 rounded-lg bg-white/5 ${color}`}>
                <Icon className="w-4 h-4" />
              </div>
            </div>
          </div>
        ))}
      </div>

      <div className="glass-card p-4 flex-1 min-h-0">
        <h3 className="text-sm font-medium text-white/70 mb-3 flex items-center gap-2">
          <Info className="w-4 h-4 text-blue-400" />
          Recent Updates
        </h3>
        <div className="space-y-2 overflow-y-auto max-h-[200px]">
          {updates.map((update) => (
            <div
              key={update.id}
              className="p-3 rounded-lg bg-white/3 border border-white/5 hover:bg-white/5 transition-colors"
            >
              <div className="flex items-start justify-between gap-2">
                <div className="min-w-0">
                  <p className="text-sm font-medium text-white/80 truncate">{update.title}</p>
                  <p className="text-xs text-white/40 mt-0.5 line-clamp-1">{update.desc}</p>
                </div>
                <span className="text-[10px] text-white/30 whitespace-nowrap">{update.date}</span>
              </div>
            </div>
          ))}
        </div>
      </div>
    </div>
  )
}

