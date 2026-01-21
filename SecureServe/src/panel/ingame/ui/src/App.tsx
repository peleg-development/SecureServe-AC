import { useCallback, useEffect, useState } from 'react'
import { useAppStore } from './store'
import { useNuiEvent } from './hooks/useNuiEvent'
import { useKeyboard } from './hooks/useKeyboard'
import { fetchNui } from './hooks/useNui'
import type { Player, Ban, DashboardStats } from './types'
import { 
   Users, Settings, Ban as BanIcon, 
  Search, UserX, Camera, Eye, X, Copy, Undo2,
  ChevronRight, Clock, TrendingUp, AlertCircle,
  Car, Package, User, Wifi, Activity, Sparkles
} from 'lucide-react'

export default function App() {
  const store = useAppStore()

  const closePanel = useCallback(() => {
    store.hide()
    fetchNui('close', {})
  }, [store])

  useKeyboard('Escape', () => {
    if (store.screenshotUrl) store.setScreenshotUrl(null)
    else if (store.selectedBan) store.setSelectedBan(null)
    else if (store.visible) closePanel()
  })

  useNuiEvent('open', () => {
    store.show()
    fetchNui<{ players: Player[] }>('getPlayers', {}).then((r) => store.setPlayers(r?.players || []))
    fetchNui<{ bans: Ban[] }>('getBans', {}).then((r) => store.setBans(r?.bans || []))
    fetchNui<DashboardStats>('getDashboardStats', {}).then((r) => { if (r) store.setStats(r) })
  })

  useNuiEvent('players', (d) => store.setPlayers((d as { players?: Player[] }).players || []))
  useNuiEvent('bans', (d) => store.setBans((d as { bans?: Ban[] }).bans || []))
  useNuiEvent('dashboardStats', (d) => {
    const data = d as Partial<DashboardStats>
    store.setStats({
      totalPlayers: data.totalPlayers ?? 0,
      activeCheaters: data.activeCheaters ?? 0,
      serverUptime: data.serverUptime ?? '0 min',
      peakPlayers: data.peakPlayers ?? 0,
    })
  })
  useNuiEvent('displayScreenshot', (d) => {
    const data = d as { imageUrl?: string }
    if (data.imageUrl) store.setScreenshotUrl(data.imageUrl)
  })
  useNuiEvent('notification', (d) => {
    const data = d as { message?: string }
    if (data.message) store.addNotification(data.message, 'info')
  })

  useEffect(() => {
    if (!store.visible) return
    const interval = setInterval(() => {
      fetchNui<{ players: Player[] }>('getPlayers', {}).then((r) => store.setPlayers(r?.players || []))
      fetchNui<{ bans: Ban[] }>('getBans', {}).then((r) => store.setBans(r?.bans || []))
      fetchNui<DashboardStats>('getDashboardStats', {}).then((r) => { if (r) store.setStats(r) })
    }, 8000)
    return () => clearInterval(interval)
  }, [store.visible])

  if (!store.visible) return null

  return (
    <div className="fixed inset-0 flex items-center justify-center">
      {/* Main Panel */}
      <div className="w-[720px] h-[540px] bg-[#12141a] rounded-2xl overflow-hidden animate-scale-in panel-shadow flex">
        {/* Sidebar */}
        <div className="w-[200px] bg-[#0d0f14] flex flex-col border-r border-white/[0.04]">
          {/* Logo */}
          <div className="p-5 border-b border-white/[0.04]">
            <div className="flex items-center gap-3">
              <div>
                <h1 className="text-[17px] font-semibold text-white">SecureServe</h1>
                <p className="text-[14px] text-white/40">Admin Panel</p>
              </div>
            </div>
          </div>
          
          {/* Navigation */}
          <div className="flex-1 p-3">
            <div className="space-y-1">
              {[
                { id: 'dashboard', icon: Activity, label: 'Dashboard' },
                { id: 'players', icon: Users, label: 'Players' },
                { id: 'player-options', icon: Settings, label: 'Options' },
                { id: 'bans', icon: BanIcon, label: 'Bans' },
              ].map(({ id, icon: Icon, label }) => (
                <button
                  key={id}
                  onClick={() => store.setSection(id as typeof store.section)}
                  className={`w-full flex items-center gap-3 px-3 py-2.5 rounded-lg text-[13px] font-medium transition-all ${
                    store.section === id 
                      ? 'bg-white/10 text-white' 
                      : 'text-white/50 hover:text-white/70 hover:bg-white/[0.04]'
                  }`}
                >
                  <Icon className={`w-[18px] h-[18px] ${store.section === id ? 'text-white' : ''}`} />
                  <span>{label}</span>
                  {store.section === id && (
                    <div className="ml-auto w-1.5 h-1.5 rounded-full bg-white" />
                  )}
                </button>
              ))}
            </div>
          </div>

          {/* Close Button */}
          <div className="p-3 border-t border-white/[0.04]">
            <button 
              onClick={closePanel} 
              className="w-full flex items-center justify-center gap-2 py-2.5 rounded-lg bg-white/[0.04] text-white/50 text-[13px] font-medium hover:bg-white/[0.06] hover:text-white/70 transition-all"
            >
              <X className="w-4 h-4" />
              Close Panel
            </button>
          </div>
        </div>

        {/* Content Area */}
        <div className="flex-1 overflow-y-auto p-5 bg-[#12141a]">
          {store.section === 'dashboard' && <DashboardView stats={store.stats} />}
          {store.section === 'players' && (
            <PlayersView 
              players={store.players}
              onKick={(id) => { fetchNui('kickPlayer', { playerId: id }); store.addNotification('Player kicked', 'success') }}
              onBan={(id) => { fetchNui('banPlayer', { playerId: id }); store.addNotification('Player banned', 'success') }}
              onScreenshot={(id) => { fetchNui('screenshotPlayer', { playerId: id }); store.addNotification('Screenshot requested', 'info') }}
              onSpectate={(id) => fetchNui('spectatePlayer', { playerId: id })}
            />
          )}
          {store.section === 'player-options' && (
            <OptionsView 
              options={store.playerOptions}
              onToggle={(name, enabled) => { store.togglePlayerOption(name, enabled); fetchNui('toggleOptiona', { option: name, enabled }) }}
              onSpawnVehicle={(v) => { fetchNui('spawnVehicle', { vehicleName: v }); store.addNotification(`Spawning ${v}`, 'success') }}
              onSpawnObject={(o) => { fetchNui('spawnObject', { objectName: o }); store.addNotification(`Spawning ${o}`, 'success') }}
              onChangePed={(p) => { fetchNui('changePed', { pedModel: p }); store.addNotification(`Changing ped`, 'success') }}
              onClearEntities={() => { fetchNui('clearAllEntities', {}); store.addNotification('Entities cleared', 'success') }}
            />
          )}
          {store.section === 'bans' && (
            <BansView 
              bans={store.bans}
              onShowDetails={store.setSelectedBan}
            />
          )}
        </div>
      </div>

      {/* Ban Detail Modal */}
      {store.selectedBan && (
        <BanModal 
          ban={store.selectedBan} 
          onClose={() => store.setSelectedBan(null)}
          onUnban={(id) => { fetchNui('unbanPlayer', { banId: id }); store.setBans(store.bans.filter(b => b.id !== id)); store.setSelectedBan(null); store.addNotification('Player unbanned', 'success') }}
          onCopy={(t) => { navigator.clipboard.writeText(t); store.addNotification('Copied to clipboard', 'success') }}
        />
      )}

      {/* Screenshot Modal */}
      {store.screenshotUrl && (
        <div className="fixed inset-0 bg-black/80 backdrop-blur-md flex items-center justify-center z-50" onClick={() => store.setScreenshotUrl(null)}>
          <div className="bg-[#1a1d26] rounded-2xl p-2 shadow-2xl max-w-2xl animate-scale-in" onClick={e => e.stopPropagation()}>
            <img src={store.screenshotUrl} alt="Screenshot" className="rounded-xl max-h-[70vh]" />
          </div>
        </div>
      )}

      {/* Notifications */}
      <div className="fixed bottom-6 left-1/2 -translate-x-1/2 flex flex-col gap-2 z-50">
        {store.notifications.map((n) => (
          <div 
            key={n.id} 
            className="px-5 py-3 bg-[#1a1d26] text-white/90 text-[13px] font-medium rounded-xl shadow-xl animate-slide-up border border-white/[0.06]"
          >
            {n.message}
          </div>
        ))}
      </div>
    </div>
  )
}

/**
 * Dashboard view component displaying server statistics
 */
function DashboardView({ stats }: { stats: DashboardStats }) {
  return (
    <div className="space-y-5">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h2 className="text-xl font-semibold text-white">Dashboard</h2>
          <p className="text-sm text-white/40 mt-0.5">Server overview & statistics</p>
        </div>
        <div className="flex items-center gap-2 px-3 py-1.5 rounded-lg bg-emerald-500/10 border border-emerald-500/20">
          <div className="w-2 h-2 rounded-full bg-emerald-400 animate-pulse-soft" />
          <span className="text-xs font-medium text-emerald-400">Online</span>
        </div>
      </div>

      {/* Stats Grid */}
      <div className="grid grid-cols-2 gap-3">
        <StatCard 
          label="Online Players" 
          value={stats.totalPlayers} 
          icon={Users}
          color="blue"
        />
        <StatCard 
          label="Active Bans" 
          value={stats.activeCheaters} 
          icon={BanIcon}
          color="rose"
        />
        <StatCard 
          label="Server Uptime" 
          value={stats.serverUptime} 
          icon={Clock}
          color="emerald"
        />
        <StatCard 
          label="Peak Today" 
          value={stats.peakPlayers} 
          icon={TrendingUp}
          color="amber"
        />
      </div>

      {/* Recent Activity */}
      <div className="bg-[#1a1d26] rounded-xl overflow-hidden border border-white/[0.04]">
        <div className="px-4 py-3 border-b border-white/[0.04] flex items-center gap-2">
          <Sparkles className="w-4 h-4 text-white/40" />
          <h3 className="text-sm font-medium text-white/80">Recent Updates</h3>
        </div>
        <div className="divide-y divide-white/[0.04]">
          {[
            { title: 'Client Detections Overhaul', date: 'Today', type: 'feature' },
            { title: 'Module System Fixed', date: 'Yesterday', type: 'fix' },
            { title: 'Anti Weapon Protection', date: '2 days ago', type: 'security' },
          ].map((update, i) => (
            <div key={i} className="px-4 py-3 flex items-center justify-between hover:bg-white/[0.02] transition-colors">
              <div className="flex items-center gap-3">
                <div className="w-8 h-8 rounded-lg bg-white/10 flex items-center justify-center">
                  <AlertCircle className="w-4 h-4 text-white/70" />
                </div>
                <span className="text-sm text-white/80">{update.title}</span>
              </div>
              <span className="text-xs text-white/30">{update.date}</span>
            </div>
          ))}
        </div>
      </div>
    </div>
  )
}

/**
 * Stat card component for dashboard metrics
 */
function StatCard({ label, value, icon: Icon, color }: {
  label: string
  value: number | string
  icon: React.ComponentType<{ className?: string }>
  color: 'blue' | 'rose' | 'emerald' | 'amber'
}) {
  const colors = {
    blue: { bg: 'bg-blue-500/10', text: 'text-blue-400', border: 'border-blue-500/20' },
    rose: { bg: 'bg-rose-500/10', text: 'text-rose-400', border: 'border-rose-500/20' },
    emerald: { bg: 'bg-emerald-500/10', text: 'text-emerald-400', border: 'border-emerald-500/20' },
    amber: { bg: 'bg-amber-500/10', text: 'text-amber-400', border: 'border-amber-500/20' },
  }
  const c = colors[color]

  return (
    <div className={`bg-[#1a1d26] rounded-xl p-4 border border-white/[0.04] hover:border-white/[0.08] transition-colors`}>
      <div className="flex items-center gap-4">
        <div className={`w-12 h-12 rounded-xl ${c.bg} flex items-center justify-center shrink-0`}>
          <Icon className={`w-6 h-6 ${c.text}`} />
        </div>
        <div className="flex-1 min-w-0">
          <p className="text-xs text-white/40 mb-0.5">{label}</p>
          <p className="text-xl font-bold text-white tracking-tight truncate">{value}</p>
        </div>
      </div>
    </div>
  )
}

/**
 * Players list view component
 */
function PlayersView({ players, onKick, onBan, onScreenshot, onSpectate }: {
  players: Player[]
  onKick: (id: number) => void
  onBan: (id: number) => void
  onScreenshot: (id: number) => void
  onSpectate: (id: number) => void
}) {
  const [search, setSearch] = useState('')
  const filtered = players.filter(p => p.name.toLowerCase().includes(search.toLowerCase()))

  return (
    <div className="space-y-4">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h2 className="text-xl font-semibold text-white">Players</h2>
          <p className="text-sm text-white/40 mt-0.5">{players.length} online</p>
        </div>
      </div>

      {/* Search */}
      <div className="relative">
        <Search className="absolute left-3.5 top-1/2 -translate-y-1/2 w-4 h-4 text-white/30" />
        <input
          type="text"
          placeholder="Search players..."
          value={search}
          onChange={(e) => setSearch(e.target.value)}
          className="w-full bg-[#1a1d26] border border-white/[0.04] rounded-xl pl-10 pr-4 py-2.5 text-sm text-white placeholder:text-white/30 focus:outline-none focus:border-white/20 transition-colors"
        />
      </div>

      {/* Players List */}
      <div className="bg-[#1a1d26] rounded-xl overflow-hidden border border-white/[0.04]">
        {filtered.length === 0 ? (
          <div className="py-12 text-center">
            <Users className="w-10 h-10 text-white/20 mx-auto mb-3" />
            <p className="text-sm text-white/40">No players online</p>
          </div>
        ) : (
          <div className="divide-y divide-white/[0.04]">
            {filtered.map((player) => (
              <div 
                key={player.id} 
                className="px-4 py-3 flex items-center gap-4 hover:bg-white/[0.02] transition-colors"
              >
                <div className="w-2 h-2 rounded-full bg-emerald-400" />
                <div className="flex-1 min-w-0">
                  <p className="text-sm font-medium text-white truncate">{player.name}</p>
                  <p className="text-xs text-white/40 flex items-center gap-1.5 mt-0.5">
                    <Wifi className="w-3 h-3" /> {player.ping}ms
                  </p>
                </div>
                <div className="flex gap-1">
                  <ActionButton icon={Eye} onClick={() => onSpectate(player.id)} color="white" tooltip="Spectate" />
                  <ActionButton icon={Camera} onClick={() => onScreenshot(player.id)} color="white" tooltip="Screenshot" />
                  <ActionButton icon={UserX} onClick={() => onKick(player.id)} color="amber" tooltip="Kick" />
                  <ActionButton icon={BanIcon} onClick={() => onBan(player.id)} color="rose" tooltip="Ban" />
                </div>
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  )
}

/**
 * Action button for player actions
 */
function ActionButton({ icon: Icon, onClick, color, tooltip }: {
  icon: React.ComponentType<{ className?: string }>
  onClick: () => void
  color: 'white' | 'amber' | 'rose'
  tooltip: string
}) {
  const colors = {
    white: 'text-white/70 hover:bg-white/10',
    amber: 'text-amber-400 hover:bg-amber-500/15',
    rose: 'text-rose-400 hover:bg-rose-500/15',
  }

  return (
    <button 
      onClick={onClick} 
      title={tooltip}
      className={`w-8 h-8 rounded-lg flex items-center justify-center transition-colors ${colors[color]}`}
    >
      <Icon className="w-4 h-4" />
    </button>
  )
}

/**
 * Options view for admin controls
 */
function OptionsView({ options, onToggle, onSpawnVehicle, onSpawnObject, onChangePed, onClearEntities }: {
  options: { name: string; enabled: boolean; category: string }[]
  onToggle: (name: string, enabled: boolean) => void
  onSpawnVehicle: (name: string) => void
  onSpawnObject: (name: string) => void
  onChangePed: (name: string) => void
  onClearEntities: () => void
}) {
  const [vehicle, setVehicle] = useState('')
  const [object, setObject] = useState('')
  const [ped, setPed] = useState('')

  return (
    <div className="space-y-4">
      {/* Header */}
      <div>
        <h2 className="text-xl font-semibold text-white">Options</h2>
        <p className="text-sm text-white/40 mt-0.5">Admin controls & spawners</p>
      </div>

      {/* Toggle Options */}
      <div className="bg-[#1a1d26] rounded-xl overflow-hidden border border-white/[0.04]">
        <div className="px-4 py-2.5 border-b border-white/[0.04]">
          <span className="text-xs font-medium text-white/40 uppercase tracking-wider">Player Options</span>
        </div>
        <div className="divide-y divide-white/[0.04]">
          {options.map((opt) => (
            <div key={opt.name} className="px-4 py-3 flex items-center justify-between">
              <span className="text-sm text-white/80">{opt.name}</span>
              <button
                onClick={() => onToggle(opt.name, !opt.enabled)}
                className={`w-11 h-6 rounded-full transition-all relative ${opt.enabled ? 'bg-emerald-500' : 'bg-white/10'}`}
              >
                <div className={`absolute top-0.5 w-5 h-5 rounded-full bg-white shadow-sm transition-all ${opt.enabled ? 'left-[22px]' : 'left-0.5'}`} />
              </button>
            </div>
          ))}
        </div>
      </div>

      {/* Spawners */}
      <div className="bg-[#1a1d26] rounded-xl overflow-hidden border border-white/[0.04]">
        <div className="px-4 py-2.5 border-b border-white/[0.04]">
          <span className="text-xs font-medium text-white/40 uppercase tracking-wider">Spawners</span>
        </div>
        <div className="divide-y divide-white/[0.04]">
          {[
            { icon: Car, placeholder: 'Vehicle name (e.g. adder)', value: vehicle, set: setVehicle, spawn: onSpawnVehicle },
            { icon: Package, placeholder: 'Object name', value: object, set: setObject, spawn: onSpawnObject },
            { icon: User, placeholder: 'Ped model', value: ped, set: setPed, spawn: onChangePed },
          ].map(({ icon: Icon, placeholder, value, set, spawn }, i) => (
            <div key={i} className="px-4 py-3 flex items-center gap-3">
              <Icon className="w-4 h-4 text-white/30" />
              <input
                type="text"
                placeholder={placeholder}
                value={value}
                onChange={(e) => set(e.target.value)}
                onKeyDown={(e) => e.key === 'Enter' && value && spawn(value)}
                className="flex-1 text-sm text-white placeholder:text-white/30 bg-transparent outline-none"
              />
              <button 
                onClick={() => value && spawn(value)}
                disabled={!value}
                className="px-3 py-1.5 bg-white/10 text-white/80 text-xs font-medium rounded-lg disabled:opacity-30 hover:bg-white/15 transition-all"
              >
                Spawn
              </button>
            </div>
          ))}
        </div>
      </div>

      {/* Danger Zone */}
      <button 
        onClick={onClearEntities} 
        className="w-full bg-[#1a1d26] rounded-xl px-4 py-3.5 flex items-center justify-between hover:bg-rose-500/5 border border-white/[0.04] hover:border-rose-500/20 transition-all group"
      >
        <div className="flex items-center gap-3">
          <div className="w-8 h-8 rounded-lg bg-rose-500/10 flex items-center justify-center">
            <AlertCircle className="w-4 h-4 text-rose-400" />
          </div>
          <span className="text-sm text-rose-400 font-medium">Clear All Entities</span>
        </div>
        <ChevronRight className="w-4 h-4 text-white/20 group-hover:text-rose-400 transition-colors" />
      </button>
    </div>
  )
}

/**
 * Bans list view component
 */
function BansView({ bans, onShowDetails }: {
  bans: Ban[]
  onShowDetails: (ban: Ban) => void
}) {
  const [search, setSearch] = useState('')
  const filtered = bans.filter(b => 
    b.name.toLowerCase().includes(search.toLowerCase()) || 
    b.reason?.toLowerCase().includes(search.toLowerCase())
  )

  return (
    <div className="space-y-4">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h2 className="text-xl font-semibold text-white">Bans</h2>
          <p className="text-sm text-white/40 mt-0.5">{bans.length} total bans</p>
        </div>
      </div>

      {/* Search */}
      <div className="relative">
        <Search className="absolute left-3.5 top-1/2 -translate-y-1/2 w-4 h-4 text-white/30" />
        <input
          type="text"
          placeholder="Search bans..."
          value={search}
          onChange={(e) => setSearch(e.target.value)}
          className="w-full bg-[#1a1d26] border border-white/[0.04] rounded-xl pl-10 pr-4 py-2.5 text-sm text-white placeholder:text-white/30 focus:outline-none focus:border-white/20 transition-colors"
        />
      </div>

      {/* Bans List */}
      <div className="bg-[#1a1d26] rounded-xl overflow-hidden border border-white/[0.04]">
        {filtered.length === 0 ? (
          <div className="py-12 text-center">
            <BanIcon className="w-10 h-10 text-white/20 mx-auto mb-3" />
            <p className="text-sm text-white/40">No bans found</p>
          </div>
        ) : (
          <div className="divide-y divide-white/[0.04]">
            {filtered.map((ban) => (
              <div 
                key={ban.id} 
                onClick={() => onShowDetails(ban)}
                className="px-4 py-3 flex items-center gap-4 cursor-pointer hover:bg-white/[0.02] transition-colors"
              >
                <div className="w-9 h-9 rounded-lg bg-rose-500/10 flex items-center justify-center">
                  <User className="w-4 h-4 text-rose-400" />
                </div>
                <div className="flex-1 min-w-0">
                  <p className="text-sm font-medium text-white truncate">{ban.name}</p>
                  <p className="text-xs text-white/40 truncate mt-0.5">{ban.reason || 'No reason specified'}</p>
                </div>
                <ChevronRight className="w-4 h-4 text-white/20" />
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  )
}

/**
 * Modal component for ban details
 */
function BanModal({ ban, onClose, onUnban, onCopy }: {
  ban: Ban
  onClose: () => void
  onUnban: (id: string) => void
  onCopy: (text: string) => void
}) {
  const fields = [
    { label: 'Steam ID', value: ban.steam },
    { label: 'Discord', value: ban.discord },
    { label: 'IP Address', value: ban.ip },
    { label: 'HWID', value: ban.hwid1 },
    { label: 'Expires', value: ban.expire },
    { label: 'Reason', value: ban.reason },
  ]

  return (
    <div 
      className="fixed inset-0 bg-black/60 backdrop-blur-sm flex items-center justify-center z-50" 
      onClick={onClose}
    >
      <div 
        className="w-[380px] bg-[#1a1d26] rounded-2xl shadow-2xl overflow-hidden animate-scale-in border border-white/[0.06]" 
        onClick={e => e.stopPropagation()}
      >
        {/* Header */}
        <div className="bg-[#12141a] px-5 py-5 text-center border-b border-white/[0.04]">
          <div className="w-14 h-14 rounded-xl bg-rose-500/15 flex items-center justify-center mx-auto mb-3">
            <User className="w-7 h-7 text-rose-400" />
          </div>
          <h3 className="text-lg font-semibold text-white">{ban.name}</h3>
          <span className="inline-block mt-2 px-2.5 py-1 bg-rose-500/15 text-rose-400 text-xs font-medium rounded-md">
            Banned
          </span>
        </div>

        {/* Fields */}
        <div className="p-4 space-y-2 max-h-[260px] overflow-y-auto">
          {fields.map(({ label, value }) => value && (
            <div key={label} className="bg-[#12141a] rounded-lg px-3.5 py-2.5 border border-white/[0.04]">
              <p className="text-[10px] text-white/40 uppercase font-medium tracking-wider mb-1">{label}</p>
              <div className="flex items-center justify-between gap-2">
                <p className="text-sm text-white/80 truncate font-mono">{value}</p>
                <button 
                  onClick={() => onCopy(value)} 
                  className="text-white/60 hover:text-white transition-colors p-1 shrink-0"
                >
                  <Copy className="w-3.5 h-3.5" />
                </button>
              </div>
            </div>
          ))}
        </div>

        {/* Actions */}
        <div className="p-4 pt-2 flex gap-2 border-t border-white/[0.04]">
          <button 
            onClick={onClose} 
            className="flex-1 py-2.5 bg-white/[0.06] rounded-lg text-sm font-medium text-white/70 hover:bg-white/[0.08] transition-colors"
          >
            Close
          </button>
          <button 
            onClick={() => onUnban(ban.id)} 
            className="flex-1 py-2.5 bg-emerald-500/15 rounded-lg text-sm font-medium text-emerald-400 flex items-center justify-center gap-2 hover:bg-emerald-500/25 transition-colors"
          >
            <Undo2 className="w-4 h-4" /> Unban
          </button>
        </div>
      </div>
    </div>
  )
}
