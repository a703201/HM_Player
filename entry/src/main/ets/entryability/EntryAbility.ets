import { UIAbility } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';
import { scanLocalMusic } from '../services/MusicScanner';
import { MusicStore } from '../services/MusicStore';
import { SongItem } from '../models/music';

const DOMAIN = 0x0000;

export default class EntryAbility extends UIAbility {
  onCreate(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onCreate');
  }

  onDestroy(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onDestroy');
  }

  async onWindowStageCreate(windowStage: window.WindowStage): Promise<void> {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageCreate');

    await this.scanMusic();

    windowStage.loadContent('pages/Index', (err) => {
      if (err.code) {
        hilog.error(DOMAIN, 'testTag', 'Failed to load the content. Cause: %{public}s', JSON.stringify(err));
        return;
      }
      hilog.info(DOMAIN, 'testTag', 'Succeeded in loading the content.');
    });
  }

  private async scanMusic(): Promise<void> {
    try {
      const store: MusicStore = MusicStore.getInstance();
      const songs: SongItem[] = await scanLocalMusic(this.context);
      store.setSongs(songs);
      hilog.info(DOMAIN, 'testTag', `Scanned ${songs.length} songs`);
    } catch (err) {
      hilog.error(DOMAIN, 'testTag', 'Failed to scan music');
    }
  }

  onWindowStageDestroy(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageDestroy');
  }

  onForeground(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onForeground');
  }

  onBackground(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onBackground');
  }
}
