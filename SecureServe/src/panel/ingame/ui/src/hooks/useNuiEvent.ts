import { useEffect, useRef } from 'react'

interface NuiMessage<T = unknown> {
  action: string
  [key: string]: T | string
}

/**
 * Hook to listen for NUI messages from the client
 */
export function useNuiEvent<T = unknown>(action: string, handler: (data: NuiMessage<T>) => void) {
  const savedHandler = useRef(handler)

  useEffect(() => {
    savedHandler.current = handler
  }, [handler])

  useEffect(() => {
    const eventListener = (event: MessageEvent<NuiMessage<T>>) => {
      if (event.data.action === action) {
        savedHandler.current(event.data)
      }
    }

    window.addEventListener('message', eventListener)
    return () => window.removeEventListener('message', eventListener)
  }, [action])
}

