import 'package:flutter/material.dart';

class AppAnimations {
  AppAnimations._();

  // Durations
  static const Duration particleLoop    = Duration(seconds: 12);
  static const Duration pageEntrance    = Duration(milliseconds: 750);
  static const Duration outroSequence   = Duration(milliseconds: 2200);
  static const Duration ripple          = Duration(milliseconds: 500);
  static const Duration pageTransition  = Duration(milliseconds: 380);
  static const Duration outroPostDelay  = Duration(milliseconds: 600);
  static const Duration buttonPress     = Duration(milliseconds: 100);
  static const Duration buttonRelease   = Duration(milliseconds: 420);
  static const Duration navFade         = Duration(milliseconds: 250);
  static const Duration dotIndicator    = Duration(milliseconds: 350);
  static const Duration navItem         = Duration(milliseconds: 200);
  static const Duration microFeedback   = Duration(milliseconds: 200);

  // Curves
  static const Curve pageSlide     = Curves.easeOutCubic;
  static const Curve pageFade      = Curves.easeOut;
  static const Curve buttonScale   = Curves.easeIn;
  static const Curve navTransition = Curves.easeInOut;
  static const Curve dotExpand     = Curves.easeOutBack;
  static const Curve outroSlide    = Curves.easeOutBack;
}
