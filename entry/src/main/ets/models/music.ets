export interface SongItem {
  id: string
  title: string
  artist: string
  album: string
  duration: number  // 毫秒
  uri: string       // 本地文件 URI
  coverUri?: string // 封面 URI（可选）
  dateAdded: number // 添加时间戳
}

export type RepeatMode = 'single' | 'list' | 'none'

export interface Playlist {
  id: string
  name: string
  songIds: string[]
  coverUri?: string
}
