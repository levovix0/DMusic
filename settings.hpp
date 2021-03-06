#pragma once
#include <QString>
#include <filesystem>
#include "file.hpp"

inline fs::path _ym_save_path = "yandex/";
inline int _ym_repeats_if_error = 10;

inline fs::path ym_save_path() {
  if (!exists(_ym_save_path)) {
    create_directory(_ym_save_path);
  }
  return canonical(_ym_save_path);
}

inline QString ym_track_path(int id) {
  return (ym_save_path() / (std::to_string(id) + ".mp3")).string().c_str();
}
inline QString ym_cover_path(int id) {
  return (ym_save_path() / (std::to_string(id) + ".png")).string().c_str();
}
inline QString ym_metadata_path(int id) {
  return (ym_save_path() / (std::to_string(id) + ".json")).string().c_str();
}
inline QString ym_artist_cover_path(int id) {
  return (ym_save_path() / ("artist-" + std::to_string(id) + ".png")).string().c_str();
}
inline QString ym_artist_metadata_path(int id) {
  return (ym_save_path() / ("artist-" + std::to_string(id) + ".json")).string().c_str();
}

inline int ym_repeats_if_error() { return _ym_repeats_if_error; }
