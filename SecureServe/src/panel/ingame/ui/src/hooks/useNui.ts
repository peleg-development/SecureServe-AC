import { useCallback } from 'react'

declare function GetParentResourceName(): string

export function fetchNui<T = unknown>(eventName: string, data: unknown = {}): Promise<T> {
  const resourceName = (window as unknown as { GetParentResourceName?: () => string }).GetParentResourceName?.() ?? 'secureserve'
  
  return fetch(`https://${resourceName}/${eventName}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(data),
  }).then((resp) => resp.json())
}

export function useNui() {
  const send = useCallback(<T = unknown>(eventName: string, data: unknown = {}): Promise<T> => {
    return fetchNui<T>(eventName, data)
  }, [])

  return { send }
}
