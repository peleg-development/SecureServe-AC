export interface Player {
  id: number
  name: string
  steamId: string
  ping: number
}

export interface Ban {
  id: string
  name: string
  reason: string
  steam: string
  discord: string
  ip: string
  hwid1: string
  expire: string
}

export interface DashboardStats {
  totalPlayers: number
  activeCheaters: number
  serverUptime: string
  peakPlayers: number
}

export interface PlayerOption {
  name: string
  enabled: boolean
  category: 'misc' | 'admin'
}

export interface Notification {
  id: number
  message: string
  type: 'success' | 'error' | 'warning' | 'info'
}

export type Section = 'dashboard' | 'players' | 'player-options' | 'server' | 'bans'

