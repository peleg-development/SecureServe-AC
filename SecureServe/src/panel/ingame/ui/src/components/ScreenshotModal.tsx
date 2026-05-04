import { X } from 'lucide-react'

interface ScreenshotModalProps {
  imageUrl: string
  onClose: () => void
}

export function ScreenshotModal({ imageUrl, onClose }: ScreenshotModalProps) {
  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4" onClick={onClose}>
      <div className="absolute inset-0 bg-black/70 backdrop-blur-sm" />
      
      <div
        className="relative glass-panel rounded-2xl max-w-3xl w-full animate-scale-in overflow-hidden"
        onClick={(e) => e.stopPropagation()}
      >
        <div className="p-3 border-b border-white/8 flex items-center justify-between">
          <h3 className="text-sm font-medium text-white/90">Screenshot</h3>
          <button
            onClick={onClose}
            className="p-1.5 rounded-lg text-white/40 hover:text-white/80 hover:bg-white/10 transition-colors"
          >
            <X className="w-4 h-4" />
          </button>
        </div>
        
        <div className="p-3">
          <img
            src={imageUrl}
            alt="Player Screenshot"
            className="w-full rounded-lg border border-white/10"
          />
        </div>
      </div>
    </div>
  )
}

