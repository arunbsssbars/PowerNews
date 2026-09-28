const fs = require('fs');
let code = fs.readFileSync('lib/screens/feed_view.dart', 'utf8');

const customPhysics = `
class SnappyPageScrollPhysics extends PageScrollPhysics {
  const SnappyPageScrollPhysics({super.parent});

  @override
  SnappyPageScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return SnappyPageScrollPhysics(parent: buildParent(ancestor));
  }

  double _getPage(ScrollMetrics position) {
    return position.pixels / position.viewportDimension;
  }

  double _getPixels(ScrollMetrics position, double page) {
    return page * position.viewportDimension;
  }

  @override
  Simulation? createBallisticSimulation(ScrollMetrics position, double velocity) {
    if ((velocity <= 0.0 && position.pixels <= position.minScrollExtent) ||
        (velocity >= 0.0 && position.pixels >= position.maxScrollExtent)) {
      return super.createBallisticSimulation(position, velocity);
    }
    
    final Tolerance tolerance = toleranceFor(position);
    final double page = _getPage(position);
    
    double targetPage;
    if (velocity.abs() > 300.0) {
      targetPage = velocity > 0 ? page.ceilToDouble() : page.floorToDouble();
    } else {
      if (page - page.floor() > 0.2) {
        targetPage = page.ceilToDouble();
      } else if (page.ceil() - page > 0.2) {
        targetPage = page.floorToDouble();
      } else {
        targetPage = page.roundToDouble();
      }
    }
    
    final double targetPixels = _getPixels(position, targetPage);
    
    if (targetPixels != position.pixels) {
      return ScrollSpringSimulation(spring, position.pixels, targetPixels, velocity, tolerance: tolerance);
    }
    return null;
  }
}
`;

code = code.replace(/class _FeedViewState extends State<FeedView> {/, customPhysics + '\nclass _FeedViewState extends State<FeedView> {');
code = code.replace(/physics: const PageScrollPhysics\(\),/g, 'physics: const SnappyPageScrollPhysics(),');

fs.writeFileSync('lib/screens/feed_view.dart', code);
console.log('injected SnappyPageScrollPhysics');
