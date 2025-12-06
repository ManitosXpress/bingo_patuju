import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../widgets/cartilla_widget.dart';

const Size kCartillaCanvasSize = Size(850, 1220);
const EdgeInsets kCartillaCanvasPadding =
    EdgeInsets.symmetric(vertical: 60, horizontal: 20);

Future<Uint8List> renderCartillaImage({
  required List<List<int>> numbers,
  required String? cardNumber,
  required String? date,
  required String? price,
  Size canvasSize = kCartillaCanvasSize,
  double? contentWidth,
  EdgeInsets padding = kCartillaCanvasPadding,
  double pixelRatio = 1.0,
}) async {
  final cartilla = CartillaWidget(
    numbers: numbers,
    cardNumber: cardNumber,
    date: date,
    price: price,
    compact: false,
    forPrint: true,
  );

  final double effectiveContentWidth =
      contentWidth ?? (canvasSize.width - padding.horizontal);

  final widget = Directionality(
    textDirection: TextDirection.ltr,
    child: MediaQuery(
      data: MediaQueryData(
        size: canvasSize,
        devicePixelRatio: pixelRatio,
      ),
      child: SizedBox(
        width: canvasSize.width,
        height: canvasSize.height,
        child: DecoratedBox(
          decoration: const BoxDecoration(color: Colors.white),
          child: Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: padding,
              child: SizedBox(
                width: effectiveContentWidth,
                child: cartilla,
              ),
            ),
          ),
        ),
      ),
    ),
  );

  return _renderWidgetToImage(widget, canvasSize, pixelRatio: pixelRatio);
}

Future<Uint8List> _renderWidgetToImage(
  Widget widget,
  Size logicalSize, {
  double pixelRatio = 1.0,
}) async {
  final repaintBoundary = RenderRepaintBoundary();

  final BoxConstraints logicalConstraints = BoxConstraints.tight(logicalSize);
  final BoxConstraints physicalConstraints = BoxConstraints.tight(
    Size(logicalSize.width * pixelRatio, logicalSize.height * pixelRatio),
  );

  final renderView = RenderView(
    view: ui.PlatformDispatcher.instance.implicitView!,
    child: RenderPositionedBox(
      alignment: Alignment.center,
      child: repaintBoundary,
    ),
    configuration: ViewConfiguration(
      logicalConstraints: logicalConstraints,
      physicalConstraints: physicalConstraints,
      devicePixelRatio: pixelRatio,
    ),
  );

  final pipelineOwner = PipelineOwner();
  pipelineOwner.rootNode = renderView;
  renderView.prepareInitialFrame();

  final buildOwner = BuildOwner(focusManager: FocusManager());
  final renderObjectToWidget = RenderObjectToWidgetAdapter<RenderBox>(
    container: repaintBoundary,
    child: widget,
  );

  final rootElement = renderObjectToWidget.attachToRenderTree(buildOwner);

  buildOwner.buildScope(rootElement);
  buildOwner.finalizeTree();

  pipelineOwner.flushLayout();
  pipelineOwner.flushCompositingBits();
  pipelineOwner.flushPaint();

  final ui.Image image = await repaintBoundary.toImage(pixelRatio: pixelRatio);
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

  rootElement.detachRenderObject();

  return byteData!.buffer.asUint8List();
}

