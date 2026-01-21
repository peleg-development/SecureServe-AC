import { Shield, LayoutDashboard, Users, Sliders, Server, Ban } from 'lucide-react'
import type { Section } from '../types'

interface SidebarProps {
  section: Section
  onSelect: (section: Section) => void
}

const navItems: { id: Section; label: string; icon: typeof Shield }[] = [
  { id: 'dashboard', label: 'Dashboard', icon: LayoutDashboard },
  { id: 'players', label: 'Players', icon: Users },
  { id: 'player-options', label: 'Options', icon: Sliders },
  { id: 'server', label: 'Server', icon: Server },
  { id: 'bans', label: 'Bans', icon: Ban },
]

export function Sidebar({ section, onSelect }: SidebarProps) {
  return (
    <div className="w-16 flex flex-col items-center py-4 border-r border-white/8 bg-white/3">
      <div className="mb-6 p-2 rounded-xl bg-gradient-to-br from-blue-500/20 to-cyan-500/20 border border-blue-400/20">
        <Shield className="w-6 h-6 text-blue-400" />
      </div>
      
      <nav className="flex-1 flex flex-col gap-1">
        {navItems.map(({ id, label, icon: Icon }) => {
          const isActive = section === id
          return (
            <button
              key={id}
              onClick={() => onSelect(id)}
              className={`
                relative w-10 h-10 flex items-center justify-center rounded-xl transition-all duration-200
                ${isActive 
                  ? 'bg-white/12 text-white shadow-lg shadow-white/5' 
                  : 'text-white/40 hover:text-white/70 hover:bg-white/6'
                }
              `}
              title={label}
            >
              <Icon className="w-5 h-5" />
              {isActive && (
                <div className="absolute left-0 top-1/2 -translate-y-1/2 w-0.5 h-5 bg-blue-400 rounded-r" />
              )}
            </button>
          )
        })}
      </nav>

      <div className="text-[10px] text-white/20 font-medium tracking-wider">v1.5</div>
    </div>
  )
}

