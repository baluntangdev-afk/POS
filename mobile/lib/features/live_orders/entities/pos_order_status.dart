/// The POS-side order lifecycle and the status name Cartivo expects for each
/// (mirrors the backend's `cartivo/statusMap.js`). The status route does no
/// translation, so callers must send [cartivoName].
enum PosOrderStatus {
  pending('confirmed'),
  preparing('preparing'),
  ready('ready'),
  fulfilled('fulfilled'),
  cancelled('cancelled');
  const PosOrderStatus(this.cartivoName);

  final String cartivoName;
}
