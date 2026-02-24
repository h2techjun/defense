// 전체화면 웹 구현 (dart:html 사용)
// ignore_for_file: avoid_web_libraries_in_flutter

import 'dart:html' as html;

bool isWebFullscreen() {
  return html.document.fullscreenElement != null;
}

void webEnterFullscreen() {
  html.document.documentElement?.requestFullscreen();
}

void webExitFullscreen() {
  html.document.exitFullscreen();
}
