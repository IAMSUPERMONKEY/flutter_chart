import 'dart:async';
import 'dart:math';

import 'package:example/style.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chart/chart/chart/line_chart.dart';
import 'package:flutter_chart/chart/common/base_layout_config.dart';
import 'package:flutter_chart/chart/common/chart_gesture_view.dart';
import 'package:flutter_chart/chart/common/gesture_delegate.dart';
import 'package:flutter_chart/chart/impl/line/line_canvas_impl.dart';
import 'package:flutter_chart/chart/impl/line/line_layout_impl.dart';
import 'package:flutter_chart/chart/model/chart_data_model.dart';
import 'package:intl/intl.dart';

/// 拖拽&长按 的 Charts,横坐标依据数据长度而定。
/// 适合排列场景：07-1 、07-02、07-03、07-04...
/// 即：每个x轴刻度间的距离相同，x轴刻度之间只允许绘制一个点。
class DraggableLineChart extends StatefulWidget {
  const DraggableLineChart({Key? key}) : super(key: key);

  @override
  State<DraggableLineChart> createState() => _DraggableLineChartState();
}

class _DraggableLineChartState extends State<DraggableLineChart> {
  late Timer _timer;
  final List<ChartDataModel> data = [];

  Size? size;
  final margin = const EdgeInsets.symmetric(horizontal: 10);
  int position = 0;
  GestureDelegate? _delegate;
  @override
  void initState() {
    super.initState();
    _begin();
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _begin() {
    int hour = 0;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        data.add(ChartDataModel(
          xAxis: getHour(hour: hour),
          yAxis: Random().nextInt(200).toDouble(),
          hasBubble: Random(0).nextBool(),
        ));
      });
      if (hour == 10) _timer.cancel();
      hour += 1;
    });
  }

  static DateTime getHour({int hour = 0}) {
    var milliseconds = (1656302400 + 3600 * hour) * 1000;
    return DateTime.fromMillisecondsSinceEpoch(milliseconds);
  }

  @override
  Widget build(BuildContext context) {
    var pixel = MediaQuery.of(context).size.width;
    size ??= Size(pixel, 264);

    return Column(
      children: [
        Container(
          width: double.infinity,
          margin: margin,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
          ),
          child: ChartGestureView<ChartDataModel>(
              initConfig: LineLayoutConfig(
                data: data,
                size: Size(pixel - margin.horizontal, 264),
                delegate: CommonLineAxisDelegate.copyWith(
                  xAxisFormatter: _xAxisFormatter,
                  yAxisFormatter: _yAxisFormatter,
                  lineStyle: CommonLineAxisDelegate.lineStyle?.copyWith(
                    color: Colors.green,
                  ),
                ),
                // popupSpec: CommonPopupSpec.copyWith(
                //   textFormatter: _textFormatter,
                //   // popupShouldDraw: _popupShouldShow,
                //   // bubbleShouldDraw: _popupBubbleShouldShow,
                //   lineStyle: CommonPopupSpec.lineStyle?.copyWith(
                //     color: Colors.lightGreen,
                //   ),
                // ),
                gestureDelegate: _delegate,
              ),
              builder: (_, newConfig) {
                position = newConfig.endOffset.dx.toInt();
                _delegate = newConfig.gestureDelegate?.copyWith(initializeOffset: Offset(position.toDouble(), 0));
                return CustomPaint(
                  size: size!,
                  painter: LineChart(
                    data: data,
                    contentCanvas: LineCanvasImpl(),
                    layoutConfig: newConfig.copyWith(initializePosition: position),
                  ),
                );
              }),
        ),
        TextButton(
            onPressed: () {
              // _pressMove();
            },
            child: Text("abc"))
      ],
    );
  }

  void _pressMove() async {
    const PointerEvent addPointer = PointerAddedEvent(pointer: 1, position: Offset(122.8, 200));
    const PointerEvent downPointer = PointerDownEvent(pointer: 1, position: Offset(122.8, 200));
    GestureBinding.instance.handlePointerEvent(addPointer);
    GestureBinding.instance.handlePointerEvent(downPointer);

    double dx = 20;
    double updateCount = 20;
    for (int i = 0; i < 20; i++) {
      // tag1
      await Future.delayed(const Duration(milliseconds: 6));
      PointerEvent movePointer = PointerMoveEvent(pointer: 1, delta: Offset(dx, 0), position: Offset(dx * -i, 0));
      GestureBinding.instance.handlePointerEvent(movePointer);
    }

    PointerEvent upPointer = PointerUpEvent(pointer: 1, position: Offset(dx * -updateCount, 0));
    GestureBinding.instance.handlePointerEvent(upPointer);
  }

  /// 悬浮框内容
  InlineSpan _textFormatter(ChartDataModel data) {
    var xAxis = DateFormat('HH:mm').format(data.xAxis);

    /// 是否为异常数据
    var normalValue = 20;
    bool isException = data.yAxis > normalValue;
    Color color = isException ? Colors.red : Colors.black;
    return TextSpan(
      text: '$xAxis\n',
      style: const TextStyle(fontSize: 12, color: Colors.black),
      children: [
        TextSpan(
          text: isException ? '气温：大于' : '气温: ',
          style: TextStyle(fontSize: 12, color: color),
        ),
        TextSpan(
          text: isException ? normalValue.toString() : '${data.yAxis.toInt()}',
          style: const TextStyle(
            fontSize: 16,
            color: Colors.red,
            fontWeight: FontWeight.w500,
          ),
        ),
        TextSpan(
          text: '°c',
          style: TextStyle(fontSize: 14, color: color),
        ),
      ],
    );
  }

  /// x轴坐标数据格式化
  String _xAxisFormatter(int index) {
    return DateFormat('HH:mm').format(data[index].xAxis);
  }

  /// y轴坐标数据格式化
  String _yAxisFormatter(num data, int index) {
    return data.toInt().toString();
  }
}
