#pragma once
#include <QString>
#include <filesystem>
#include "file.hpp"

inline fs::path _ym_save_path = "yandex/";
inline int _ym_repeats_if_error = 10;

fs::path ym_save_path() {
  if (!exists(_ym_save_path)) {
    create_directory(_ym_save_path);
  }
  return _ym_save_path;
}

QString ym_track_path(int id) {
  return fs::canonical(ym_save_path() / (std::to_string(id) + ".mp3")).string().c_str();
}
QString ym_cover_path(int id) {
  return fs::canonical(ym_save_path() / (std::to_string(id) + ".png")).string().c_str();
}
QString ym_metadata_path(int id) {
  return fs::canonical(ym_save_path() / (std::to_string(id) + ".json")).string().c_str();
}
QString ym_artist_cover_path(int id) {
  return fs::canonical(ym_save_path() / ("artist-" + std::to_string(id) + ".png")).string().c_str();
}
QString ym_artist_metadata_path(int id) {
  return fs::canonical(ym_save_path() / ("artist-" + std::to_string(id) + ".json")).string().c_str();
}

int ym_repeats_if_error() { return _ym_repeats_if_error; }
