import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:mkdrawing/painter.dart';
import 'package:mkdrawing/commanid.dart';

void main() => runApp(new MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      home: new HomePage(),
    );
  }
}

class mkCustomBottomAppBar extends StatefulWidget {
  const mkCustomBottomAppBar({this.onTap, this.drawBar});
  final DrawBar? drawBar;
  final Function? onTap;

  _mkCustomBottomAppBarState createState() => new _mkCustomBottomAppBarState();
}

class _mkCustomBottomAppBarState extends State<mkCustomBottomAppBar> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      color: Colors.blue,
      child: IconTheme(
        data: IconThemeData(color: Theme.of(context).colorScheme.onPrimary),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.drawBar != null) widget.drawBar!,
            Row(
              children: <Widget>[
                IconButton(
                  tooltip: 'Undo',
                  icon: const Icon(Icons.unsubscribe_sharp),
                  onPressed: () {
                    widget.onTap?.call(mkCommandID.EXPAND_TOOL);
                  },
                ),
                Spacer(),
                IconButton(
                  tooltip: 'Undo',
                  icon: const Icon(Icons.undo),
                  onPressed: () {
                    widget.onTap?.call(mkCommandID.UNDO);
                  },
                ),
                IconButton(
                  tooltip: 'Clear all',
                  icon: const Icon(Icons.delete),
                  onPressed: () {
                    widget.onTap?.call(mkCommandID.CLEAR_ALL);
                  },
                ),
                Spacer(),
                IconButton(
                  tooltip: 'reset all',
                  icon: const Icon(Icons.fiber_new),
                  onPressed: () {
                    widget.onTap?.call(mkCommandID.RESET_ALL);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => new _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _finished = false;
  PainterController _controller = _newController();
  bool _expanded = true;
  @override
  void initState() {
    super.initState();
  }

  static PainterController _newController() {
    PainterController controller = new PainterController();
    controller.thickness = 5.0;
    controller.backgroundColor = Colors.white;
    return controller;
  }

  void onTab(mkCommandID id) {
    switch (id) {
      case mkCommandID.UNDO:
        if (_controller.isEmpty) {
          return;
        } else {
          _controller.undo();
        }
        break;
      case mkCommandID.CLEAR_ALL:
        _controller.clear();
        break;
      case mkCommandID.PEN_SIZE:
        // TODO: Handle this case.
        break;
      case mkCommandID.PEN_COLOR:
        // TODO: Handle this case.
        break;
      case mkCommandID.BACKGROUND_COLOR:
        // TODO: Handle this case.
        break;
      case mkCommandID.EXPAND_TOOL:
        setState(() {
          _expanded = !_expanded;
        });
        break;
      case mkCommandID.RESET_ALL:
        _show(_controller.finish(), context);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> actions;
    if (_finished) {
      actions = <Widget>[
        new IconButton(
          icon: new Icon(Icons.content_copy),
          tooltip: 'New Painting',
          onPressed: () => setState(() {
            _finished = false;
            _controller = _newController();
          }),
        ),
      ];
    } else {
      actions = <Widget>[
        new IconButton(
            icon: new Icon(
              Icons.undo,
            ),
            tooltip: 'Undo',
            onPressed: () {
              if (_controller.isEmpty) {
                showModalBottomSheet(
                    context: context,
                    builder: (BuildContext context) =>
                        new Text('Nothing to undo'));
              } else {
                _controller.undo();
              }
            }),
        new IconButton(
            icon: new Icon(Icons.delete),
            tooltip: 'Clear',
            onPressed: _controller.clear),
        new IconButton(
            icon: new Icon(Icons.check),
            onPressed: () => _show(_controller.finish(), context)),
      ];
    }
    return SafeArea(
      child: Scaffold(
        // appBar: new AppBar(
        //     actions: actions,
        //     bottom: new PreferredSize(
        //       child: new DrawBar(_controller),
        //       preferredSize: new Size(MediaQuery.of(context).size.width, 20.0),
        //     )),
        body: Center(child: new Painter(_controller)),
        bottomNavigationBar: mkCustomBottomAppBar(
          onTap: this.onTab,
          drawBar: _expanded ? DrawBar(_controller) : null,
        ),
      ),
    );
  }

  void _show(PictureDetails picture, BuildContext context) {
    setState(() {
      _finished = true;
    });
    Navigator.of(context)
        .push(new MaterialPageRoute(builder: (BuildContext context) {
      return new Scaffold(
        appBar: new AppBar(
          title: const Text('View your image'),
        ),
        body: new Container(
            alignment: Alignment.center,
            child: new FutureBuilder<Uint8List>(
              future: picture.toPNG(),
              builder:
                  (BuildContext context, AsyncSnapshot<Uint8List> snapshot) {
                switch (snapshot.connectionState) {
                  case ConnectionState.done:
                    if (snapshot.hasError) {
                      return new Text('Error: ${snapshot.error}');
                    } else {
                      return Image.memory(snapshot.data!);
                    }
                  default:
                    return new Container(
                        child: new FractionallySizedBox(
                      widthFactor: 0.1,
                      child: new AspectRatio(
                          aspectRatio: 1.0,
                          child: new CircularProgressIndicator()),
                      alignment: Alignment.center,
                    ));
                }
              },
            )),
      );
    }));
  }
}

class DrawBar extends StatelessWidget {
  final PainterController _controller;

  DrawBar(this._controller);

  @override
  Widget build(BuildContext context) {
    return new Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        new Flexible(child: new StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
          return new Container(
              child: new Slider(
            value: _controller.thickness,
            onChanged: (double value) => setState(() {
              _controller.thickness = value;
            }),
            min: 1.0,
            max: 20.0,
            activeColor: Colors.white,
          ));
        })),
        new StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
          return new RotatedBox(
              quarterTurns: _controller.eraseMode ? 2 : 0,
              child: IconButton(
                  icon: new Icon(Icons.create),
                  tooltip: (_controller.eraseMode ? 'Disable' : 'Enable') +
                      ' eraser',
                  onPressed: () {
                    setState(() {
                      _controller.eraseMode = !_controller.eraseMode;
                    });
                  }));
        }),
        new ColorPickerButton(_controller, false),
        new ColorPickerButton(_controller, true),
      ],
    );
  }
}

class ColorPickerButton extends StatefulWidget {
  final PainterController _controller;
  final bool _background;

  ColorPickerButton(this._controller, this._background);

  @override
  _ColorPickerButtonState createState() => new _ColorPickerButtonState();
}

class _ColorPickerButtonState extends State<ColorPickerButton> {
  @override
  Widget build(BuildContext context) {
    return new IconButton(
        icon: new Icon(_iconData, color: _color),
        tooltip: widget._background
            ? 'Change background color'
            : 'Change draw color',
        onPressed: _pickColor);
  }

  void _pickColor() {
    Color pickerColor = _color;
    Navigator.of(context)
        .push(new MaterialPageRoute(
            fullscreenDialog: true,
            builder: (BuildContext context) {
              return new Scaffold(
                  appBar: new AppBar(
                    title: const Text('Pick color'),
                  ),
                  body: new Container(
                      alignment: Alignment.center,
                      child: new ColorPicker(
                        pickerColor: pickerColor,
                        onColorChanged: (Color c) => pickerColor = c,
                      )));
            }))
        .then((_) {
      setState(() {
        _color = pickerColor;
      });
    });
  }

  Color get _color => widget._background
      ? widget._controller.backgroundColor
      : widget._controller.drawColor;

  IconData get _iconData =>
      widget._background ? Icons.format_color_fill : Icons.brush;

  set _color(Color color) {
    if (widget._background) {
      widget._controller.backgroundColor = color;
    } else {
      widget._controller.drawColor = color;
    }
  }
}
