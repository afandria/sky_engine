import 'package:sky/rendering.dart';
import 'package:test/test.dart';

import 'rendering_tester.dart';

void main() {
  test('Stack can layout with top, right, bottom, left 0.0', () {
    RenderBox size = new RenderConstrainedBox(
      additionalConstraints: new BoxConstraints.tight(const Size(100.0, 100.0)));

    RenderBox red = new RenderDecoratedBox(
      decoration: new BoxDecoration(
        backgroundColor: const Color(0xFFFF0000)
      ),
      child: size);

    RenderBox green = new RenderDecoratedBox(
      decoration: new BoxDecoration(
        backgroundColor: const Color(0xFFFF0000)
      ));

    RenderBox stack = new RenderStack(children: [red, green]);
    (green.parentData as StackParentData)
      ..top = 0.0
      ..right = 0.0
      ..bottom = 0.0
      ..left = 0.0;

    layout(stack, constraints: const BoxConstraints());

    expect(stack.size.width, equals(100.0));
    expect(stack.size.height, equals(100.0));

    expect(red.size.width, equals(100.0));
    expect(red.size.height, equals(100.0));

    expect(green.size.width, equals(100.0));
    expect(green.size.height, equals(100.0));
  });
}
