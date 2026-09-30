/// The POS-side order lifecycle and the status name Cartivo expects for each
/// (mirrors the backend's `cartivo/statusMap.js`). The status route does no
/// translation, so callers must send [cartivoName].
enum PosOrderStatus {
  pending('confirmed'),
  preparing('processing'),
  ready('ready_for_pickup'),
  fulfilled('completed'),
  cancelled('cancelled');

  const PosOrderStatus(this.cartivoName);

  final String cartivoName;
}
