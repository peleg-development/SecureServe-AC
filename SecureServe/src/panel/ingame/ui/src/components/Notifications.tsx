import { Check, AlertTriangle, Info, X, XCircle } from 'lucide-react'
import type { Notification } from '../types'

interface NotificationsProps {
  notifications: Notification[]
  onRemove: (id: number) => void
}

const icons = {
  success: Check,
  error: XCircle,
  warning: AlertTriangle,
  info: Info,
}

const colors = {
  success: 'bg-emerald-500/20 text-emerald-400 border-emerald-500/30',
  error: 'bg-red-500/20 text-red-400 border-red-500/30',
  warning: 'bg-amber-500/20 text-amber-400 border-amber-500/30',
  info: 'bg-blue-500/20 text-blue-400 border-blue-500/30',
}

export function Notifications({ notifications, onRemove }: NotificationsProps) {
  return (
    <div className="fixed bottom-4 right-4 z-[100] flex flex-col gap-2 max-w-xs">
      {notifications.map((notification) => {
        const Icon = icons[notification.type]
        return (
          <div
            key={notification.id}
            className={`
              animate-slide-in glass-panel rounded-xl p-3 flex items-start gap-2.5 
              border ${colors[notification.type]}
            `}
          >
            <div className="p-1.5 rounded-lg bg-current/10">
              <Icon className="w-3.5 h-3.5" />
            </div>
            <p className="flex-1 text-xs text-white/80 leading-relaxed pt-0.5">{notification.message}</p>
            <button
              onClick={() => onRemove(notification.id)}
              className="p-1 rounded text-white/30 hover:text-white/60 transition-colors"
            >
              <X className="w-3 h-3" />
            </button>
          </div>
        )
      })}
    </div>
  )
}

