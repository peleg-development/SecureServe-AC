import { useState } from 'react'
import { Eye, User, Bone, ShieldCheck, Ghost, Move3d, Car, Package, UserCircle } from 'lucide-react'
import type { PlayerOption } from '../types'

interface PlayerOptionsProps {
  options: PlayerOption[]
  onToggle: (name: string, enabled: boolean) => void
  onSpawnVehicle: (name: string) => void
  onSpawnObject: (name: string) => void
  onChangePed: (name: string) => void
}

const optionIcons: Record<string, typeof Eye> = {
  'ESP': Eye,
  'Player Names': User,
  'Bones': Bone,
  'God Mode': ShieldCheck,
  'No Clip': Move3d,
  'Invisibility': Ghost,
}

export function PlayerOptions({ options, onToggle, onSpawnVehicle, onSpawnObject, onChangePed }: PlayerOptionsProps) {
  const [vehicle, setVehicle] = useState('')
  const [object, setObject] = useState('')
  const [ped, setPed] = useState('')

  const miscOptions = options.filter((o) => o.category === 'misc')
  const adminOptions = options.filter((o) => o.category === 'admin')

  return (
    <div className="h-full flex flex-col gap-3 overflow-y-auto">
      <OptionGroup title="Visuals" options={miscOptions} onToggle={onToggle} />
      <OptionGroup title="Admin Powers" options={adminOptions} onToggle={onToggle} />

      <div className="glass-card p-3">
        <h4 className="text-xs font-medium text-white/50 uppercase tracking-wider mb-3">Spawners</h4>
        <div className="space-y-2">
          <SpawnRow
            icon={Car}
            placeholder="Vehicle name..."
            value={vehicle}
            onChange={setVehicle}
            onSpawn={() => { onSpawnVehicle(vehicle); setVehicle('') }}
          />
          <SpawnRow
            icon={Package}
            placeholder="Object name..."
            value={object}
            onChange={setObject}
            onSpawn={() => { onSpawnObject(object); setObject('') }}
          />
          <SpawnRow
            icon={UserCircle}
            placeholder="Ped model..."
            value={ped}
            onChange={setPed}
            onSpawn={() => { onChangePed(ped); setPed('') }}
          />
        </div>
      </div>
    </div>
  )
}

function OptionGroup({ title, options, onToggle }: { title: string; options: PlayerOption[]; onToggle: (name: string, enabled: boolean) => void }) {
  return (
    <div className="glass-card p-3">
      <h4 className="text-xs font-medium text-white/50 uppercase tracking-wider mb-2">{title}</h4>
      <div className="space-y-1">
        {options.map((opt) => {
          const Icon = optionIcons[opt.name] || Eye
          return (
            <div key={opt.name} className="flex items-center justify-between py-2 px-2 rounded-lg hover:bg-white/5 transition-colors">
              <div className="flex items-center gap-2">
                <Icon className="w-4 h-4 text-white/40" />
                <span className="text-sm text-white/80">{opt.name}</span>
              </div>
              <Toggle enabled={opt.enabled} onChange={(v) => onToggle(opt.name, v)} />
            </div>
          )
        })}
      </div>
    </div>
  )
}

function Toggle({ enabled, onChange }: { enabled: boolean; onChange: (v: boolean) => void }) {
  return (
    <button
      onClick={() => onChange(!enabled)}
      className={`
        w-10 h-5 rounded-full transition-all duration-200 relative
        ${enabled ? 'bg-blue-500' : 'bg-white/10'}
      `}
    >
      <div
        className={`
          absolute top-0.5 w-4 h-4 rounded-full bg-white shadow-md transition-all duration-200
          ${enabled ? 'left-5' : 'left-0.5'}
        `}
      />
    </button>
  )
}

function SpawnRow({ icon: Icon, placeholder, value, onChange, onSpawn }: {
  icon: typeof Car
  placeholder: string
  value: string
  onChange: (v: string) => void
  onSpawn: () => void
}) {
  return (
    <div className="flex gap-2">
      <div className="relative flex-1">
        <Icon className="absolute left-2.5 top-1/2 -translate-y-1/2 w-3.5 h-3.5 text-white/30" />
        <input
          type="text"
          placeholder={placeholder}
          value={value}
          onChange={(e) => onChange(e.target.value)}
          onKeyDown={(e) => e.key === 'Enter' && value && onSpawn()}
          className="glass-input w-full pl-8 text-xs py-1.5"
        />
      </div>
      <button
        onClick={onSpawn}
        disabled={!value}
        className="px-3 py-1.5 rounded-lg bg-blue-500/20 text-blue-400 text-xs font-medium hover:bg-blue-500/30 disabled:opacity-40 disabled:cursor-not-allowed transition-colors"
      >
        Spawn
      </button>
    </div>
  )
}

