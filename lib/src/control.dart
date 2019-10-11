import 'dart:async';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
// import '../video_player_controller.dart';

typedef YoutubeQualityChangeCallback(String quality, Duration position);
typedef ControlsShowingCallback(bool showing);
class ControlsColor {
  final Color timerColor;
  final Color seekBarPlayedColor;
  final Color seekBarUnPlayedColor;
  final Color buttonColor;
  final Color playPauseColor;
  final Color progressBarPlayedColor;
  final Color progressBarBackgroundColor;
  final Color controlsBackgroundColor;

  ControlsColor({
    this.buttonColor = Colors.white,
    this.playPauseColor = Colors.white,
    this.progressBarPlayedColor = Colors.red,
    this.progressBarBackgroundColor = Colors.transparent,
    this.seekBarUnPlayedColor = Colors.grey,
    this.seekBarPlayedColor = Colors.red,
    this.timerColor = Colors.white,
    this.controlsBackgroundColor = Colors.transparent,
  });
}
class Controls extends StatefulWidget {
  final bool showControls;
  final double width;
  final double height;
  final String defaultQuality;
  final bool defaultCall;

  final VideoPlayerController controller;
  final VoidCallback fullScreenCallback;
  final bool isFullScreen;
  final ControlsShowingCallback controlsShowingCallback;
   ControlsColor controlsColor;
  final bool controlsActiveBackgroundOverlay;
  final Duration controlsTimeOut;

  final bool switchFullScreenOnLongPress;
  final bool hideShareButton;

  Controls({
    this.showControls,
    this.controller,
    this.height,
    this.width,
    this.defaultCall,
    this.defaultQuality = "720p",
    this.fullScreenCallback,
    this.controlsShowingCallback,
    this.isFullScreen = false,
    this.controlsColor,
    this.controlsActiveBackgroundOverlay,
    this.controlsTimeOut,
    this.switchFullScreenOnLongPress,
    this.hideShareButton,
  });

  @override
  _ControlsState createState() => _ControlsState();
}

class _ControlsState extends State<Controls> {
  bool _showControls;
  double currentPosition = 0;
  String _currentPositionString = "00:00";
  String _remainingString = "- 00:00";
  bool _buffering = false;
  Timer _timer;
  int seekCount = 0;

  @override
  void initState() {
    widget.controlsColor = widget.controlsColor ?? ControlsColor();
    widget.controller.addListener(listener);
    _showControls = widget.showControls;
    widget.controlsShowingCallback(_showControls);
    super.initState();
    print("[_ControlsState] initState");
  }

  listener() {
    if (widget.controller.value != null) {
      if (widget.controller.value.position != null &&
          widget.controller.value.duration != null) {
        if (mounted && widget.controller.value.isPlaying) {
          setState(() {
            currentPosition =
                (widget.controller.value.position.inSeconds ?? 0) /
                    widget.controller.value.duration.inSeconds;
            _buffering = widget.controller.value.isBuffering;
            _currentPositionString =
                formatDuration(widget.controller.value.position);
            _remainingString = "- " +
                formatDuration(widget.controller.value.duration -
                    widget.controller.value.position);
          });
        }
      }
    }
  }

  @override
  void didUpdateWidget(Controls oldWidget) {
    super.didUpdateWidget(oldWidget);
    oldWidget.controller.removeListener(listener);
    widget.controller.addListener(listener);
  }

  @override
  void deactivate() {
    widget.controller.removeListener(listener);
    super.deactivate();
  }

  @override
  void dispose() {
    if (!widget.isFullScreen) {
      widget.controller?.setVolume(0);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    print("control build");
//    _playingVideoBloc = BlocProvider.of(context);
    // if (widget.isFullScreen) YoutubePlayer.keepOn(true);

    return Stack(
      children: <Widget>[
        GestureDetector(
          onLongPress: () {
            if (widget.switchFullScreenOnLongPress)
              widget.isFullScreen
                  ? Navigator.pop(context)
                  : widget.fullScreenCallback();
          },
          onTap: (){
            print(">>>>>>>>>>>>>>>>> TAP");
            if (mounted) {
              setState(() {
                _showControls = false;
                widget.controlsShowingCallback(_showControls);
              });
            }
            if (!_buffering) {
              togglePlaying();
            }
          },
          child: Stack(
            children: <Widget>[
              Container(
                // [TODO]: need to fix height here
//                height: 100,
                child: AnimatedOpacity(
                  opacity: _showControls ? 1.0 : 0.0,
                  duration: Duration(milliseconds: 200),
                  child: Material(
                    color: Color(0x88000000),
                    child: Stack(
                      children: <Widget>[

                        Center(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              Expanded(
                                child: _rewind(widget.height,widget.width),
                                flex: 4,
                              ),
                              Expanded(
                                child: _playButton(widget.width),
                                flex: 2,
                              ),
                              Expanded(
                                child: _fastForward(widget.height,widget.width),
                                flex: 4,
                              )
                            ],
                          ),
                        ),
                        Positioned(child: _buildAppBar(context),top: 0,)
                        // _buildBottomControls(),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _fastForward(double _height, double _width) {
    return Stack(
      children: <Widget>[
        GestureDetector(
          onTap: onTapAction,
          onDoubleTap: () {
            if (mounted) {
              setState(() {
                widget.controlsShowingCallback(_showControls);
                seekCount += 10;
              });
              widget.controller.seekTo(
                Duration(seconds: widget.controller.value.position.inSeconds + 5),
              );
              Timer(Duration(seconds: 2), () {
                if (mounted) {
                  setState(() {
                    seekCount = 0;
                  });
                }
              });
            }
          },
          child: Container(
            color: Colors.transparent,
            // width: _width / 2.5,
            // height: _height - 80,
          ),
        ),
        Center(
          child: GestureDetector(
              onTap: (){
//                printLog("Tap _fastForward");
              },
              child: _showControls
                  ? Center(
                      child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                         Icon(
                           Icons.fast_forward,
                           size: 40.0,
                           color: Colors.white,
                         ),
                      ],
                    ))
                  : Container(),
          ),
        )
      ],
    );
  }

  Widget _rewind(double _height, double _width) {
    return Stack(
      children: <Widget>[
        GestureDetector(
          onTap: onTapAction,
          onDoubleTap: () {
            if (mounted) {
              setState(() {
                widget.controlsShowingCallback(_showControls);
                seekCount += 10;
              });
              widget.controller.seekTo(
                Duration(seconds: widget.controller.value.position.inSeconds - 5),
              );
              Timer(Duration(seconds: 2), () {
                if (mounted) {
                  setState(() {
                    seekCount = 0;
                  });
                }
              });
            }
          },
          child: Container(
            color: Colors.transparent,
          ),
        ),
        Center(
          child: GestureDetector(
              onTap: (){
//                printLog("Tap _rewind");
              },
              child: _showControls
                  ? Center(
                      child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                         Icon(
                           Icons.fast_rewind,
                           size: 40.0,
                           color: Colors.white,
                         ),
                      ],
                    ))
                  : Container(),
          ),
        )
      ],
    );
  }

  void onTapAction() {
    if (_timer != null) _timer.cancel();
    if (mounted) {
      setState(() {
        _showControls = !_showControls;
        widget.controlsShowingCallback(_showControls);
      });
    }
    if (_showControls) {
      _timer = Timer(widget.controlsTimeOut, () {
        if (mounted) {
          setState(() {
            _showControls = false;
            widget.controlsShowingCallback(_showControls);
          });
        }
      });
    }
    if (!widget.controller.value.isPlaying) widget.controller.play();
  }

  Widget _playButton(double width) {
    return IgnorePointer(
      ignoring: !_showControls,
      child: Material(
        borderRadius: BorderRadius.circular(100.0),
        color: widget.controlsColor.controlsBackgroundColor,
        child: InkWell(
          splashColor: Colors.grey[350],
          borderRadius: BorderRadius.circular(100.0),
          onTap: () {
            if (mounted) {
              setState(() {
                _showControls = false;
                widget.controlsShowingCallback(_showControls);
              });
            }
            if (!_buffering) {
              togglePlaying();
            }
          },
          child: _buffering
              ? CircularProgressIndicator()
              : Icon(
                  widget.controller.value.isPlaying
                      ? Icons.pause
                      : Icons.play_arrow,
                  color: widget.controlsColor.playPauseColor,
                  size: widget.isFullScreen
                      ? widget.width * 0.06
                      : widget.width * 0.12,
                ),
        ),
      ),
    );
  }

  Widget _buildBottomControls() {
    int totalLength = widget.controller.value.duration.inSeconds ?? 0;
    return Positioned(
      bottom: 0.0,
      child: Container(
        color: widget.controlsColor.controlsBackgroundColor,
        width: widget.width,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.only(left: 10.0),
              child: Text(
                _currentPositionString,
                style: TextStyle(
                    color: widget.controlsColor.timerColor, fontSize: 12.0),
              ),
            ),
            Expanded(
              child: Container(
                padding: EdgeInsets.only(top: 5),
                height: 20,
                child: Slider(
                  activeColor: widget.controlsColor.seekBarPlayedColor,
                  inactiveColor: widget.controlsColor.seekBarUnPlayedColor,
                  value: currentPosition,
                  onChanged: (position) {
                    if (mounted) {
                      setState(() {
                        currentPosition = position;
                      });
                    }
                    widget.controller.seekTo(
                      Duration(
                        seconds: (position * totalLength).floor(),
                      ),
                    );
                    widget.controller.play();
                  },
                ),
              ),
            ),
            Text(
              _remainingString,
              style: TextStyle(
                color: widget.controlsColor.timerColor,
                fontSize: 12.0,
              ),
            ),
            InkWell(
              splashColor: Colors.grey[350],
              onTap: () {
                widget.isFullScreen
                    ? Navigator.pop(context)
                    : widget.fullScreenCallback();
              },
              child: Padding(
                padding: EdgeInsets.all(widget.width <= 200 ? 4.0 : 10.0),
                child:
                Icon(
                  widget.isFullScreen
                      ? Icons.fullscreen_exit
                      : Icons.fullscreen,
                  color: widget.controlsColor.buttonColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void togglePlaying() {
    if (widget.controller.value.isPlaying == true) {
      widget.controller.pause();
      if (mounted) {
        setState(() {
          _showControls = true;
          widget.controlsShowingCallback(_showControls);
        });
      }
    } else {
      widget.controller.play();
    }
  }

  Widget _buildAppBar(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Align(
            alignment: Alignment.topLeft,
            child: GestureDetector(
              onTap: () {
                Navigator.pop(context);
              },
              child: Container(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: <Widget>[
                    IconButton(
                        iconSize: 30,
                        icon: Icon(
                          Icons.chevron_left,
                          color: Colors.white,
                        )),
                    Text(
                      'Detail',
                      style: TextStyle(
                          decoration: TextDecoration.none,
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 16.5),
                    )
                  ],
                ),
              ),
            )),
        // _buildSubtitles(context)
      ],
    );
  }

//  void shareVideo() {
//    final RenderBox box = context.findRenderObject();
//    Share.share("https://youtu.be/${widget.videoId}",
//        sharePositionOrigin: box.localToGlobal(Offset.zero) & box.size);
//  }

  String formatDuration(Duration position) {
    final ms = position.inMilliseconds;
    int seconds = ms ~/ 1000;
    final int hours = seconds ~/ 3600;
    seconds = seconds % 3600;
    var minutes = seconds ~/ 60;
    seconds = seconds % 60;
    final hoursString = hours >= 10 ? '$hours' : hours == 0 ? '00' : '0$hours';
    final minutesString =
        minutes >= 10 ? '$minutes' : minutes == 0 ? '00' : '0$minutes';
    final secondsString =
        seconds >= 10 ? '$seconds' : seconds == 0 ? '00' : '0$seconds';
    final formattedTime =
        '${hoursString == '00' ? '' : hoursString + ':'}$minutesString:$secondsString';
    return formattedTime;
  }
}