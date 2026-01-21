import { useEffect } from 'react'

/**
 * Hook to listen for keyboard events
 */
export function useKeyboard(key: string, handler: () => void) {
  useEffect(() => {
    const listener = (e: KeyboardEvent) => {
      if (e.key === key) {
        handler()
      }
    }

    window.addEventListener('keydown', listener)
    return () => window.removeEventListener('keydown', listener)
  }, [key, handler])
}

