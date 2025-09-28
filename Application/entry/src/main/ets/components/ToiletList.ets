import { ToiletPoi } from '../common/types';

@Component
export struct ToiletList {
  @Link toilets: ToiletPoi[];

  build() {
    List() {
      ForEach(this.toilets, (item: ToiletPoi) => {
        ListItem() {
          Text(`${item.name} - ${item.distance}m`)
        }
      })
    }
  }
}