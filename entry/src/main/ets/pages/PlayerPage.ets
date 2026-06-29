import { AudioRendererController } from '../utils/AudioRendererController';
import { BreakpointConstants } from '../common/constants/BreakpointConstants';
import { BreakpointSystem } from '../common/utils/BreakpointSystem';
import { PlayerInfoComponent } from '../components/PlayerInfoComponent';
import { MusicStore } from '../services/MusicStore';


@Builder
export function PlayerPageBuilder() {
  PlayerPage();
}

@Entry
@Component
struct PlayerPage {
  @StorageLink('selectIndex') selectIndex: number = 0;
  @State isShowPlay: boolean = false;
  @StorageProp(BreakpointConstants.CURRENT_BREAKPOINT) currentBreakpoint: string = BreakpointConstants.BREAKPOINT_SM;
  private breakpointSystem: BreakpointSystem = new BreakpointSystem();

  aboutToAppear(): void {
    const store = MusicStore.getInstance();
    const savedIndex = AppStorage.get('selectIndex') as number ?? 0;
    if (savedIndex >= 0 && savedIndex < store.songs.length) {
      store.currentIndex = savedIndex;
    }
    AppStorage.setOrCreate('songList', store.songs);
    AppStorage.setOrCreate('selectIndex', store.currentIndex);
    AudioRendererController.getInstance();
    this.breakpointSystem.register();
  }

  aboutToDisappear(): void {
    this.breakpointSystem.unregister();
    AudioRendererController.getInstance().release();
  }

  build() {
    NavDestination() {
      PlayerInfoComponent({ isShowPlay: this.isShowPlay });
    }
    .ignoreLayoutSafeArea([LayoutSafeAreaType.SYSTEM], [LayoutSafeAreaEdge.TOP, LayoutSafeAreaEdge.BOTTOM])
    .hideTitleBar(true)
  }
}
