import { useState, useCallback } from 'react'
import type { Player, Ban, DashboardStats, PlayerOption, Notification, Section } from './types'

const defaultStats: DashboardStats = {
  totalPlayers: 0,
  activeCheaters: 0,
  serverUptime: '0 minutes',
  peakPlayers: 0,
}

const defaultPlayerOptions: PlayerOption[] = [
  { name: 'ESP', enabled: false, category: 'misc' },
  { name: 'Player Names', enabled: false, category: 'misc' },
  { name: 'Bones', enabled: false, category: 'misc' },
  { name: 'God Mode', enabled: false, category: 'admin' },
  { name: 'No Clip', enabled: false, category: 'admin' },
  { name: 'Invisibility', enabled: false, category: 'admin' },
]

export function useAppStore() {
  const [visible, setVisible] = useState(false)
  const [section, setSection] = useState<Section>('dashboard')
  const [stats, setStats] = useState<DashboardStats>(defaultStats)
  const [players, setPlayers] = useState<Player[]>([])
  const [bans, setBans] = useState<Ban[]>([])
  const [playerOptions, setPlayerOptions] = useState<PlayerOption[]>(defaultPlayerOptions)
  const [notifications, setNotifications] = useState<Notification[]>([])
  const [screenshotUrl, setScreenshotUrl] = useState<string | null>(null)
  const [selectedBan, setSelectedBan] = useState<Ban | null>(null)

  const show = useCallback(() => setVisible(true), [])
  const hide = useCallback(() => setVisible(false), [])

  const addNotification = useCallback((message: string, type: Notification['type'] = 'info') => {
    const id = Date.now()
    setNotifications((prev) => [...prev, { id, message, type }])
    setTimeout(() => {
      setNotifications((prev) => prev.filter((n) => n.id !== id))
    }, 4000)
  }, [])

  const removeNotification = useCallback((id: number) => {
    setNotifications((prev) => prev.filter((n) => n.id !== id))
  }, [])

  const togglePlayerOption = useCallback((name: string, enabled: boolean) => {
    setPlayerOptions((prev) =>
      prev.map((opt) => (opt.name === name ? { ...opt, enabled } : opt))
    )
  }, [])

  return {
    visible,
    show,
    hide,
    section,
    setSection,
    stats,
    setStats,
    players,
    setPlayers,
    bans,
    setBans,
    playerOptions,
    togglePlayerOption,
    notifications,
    addNotification,
    removeNotification,
    screenshotUrl,
    setScreenshotUrl,
    selectedBan,
    setSelectedBan,
  }
}

export type AppStore = ReturnType<typeof useAppStore>

