#pragma once
#include <QString>
#include <filesystem>
#include "file.hpp"

inline fs::path _ym_save_path = "./yandex/";
inline int _ym_repeats_if_error = 10;

fs::path ym_save_path() {
  if (!exists(_ym_save_path)) {
    create_directory(_ym_save_path);
  }
  return fs::canonical(_ym_save_path);
}

int ym_repeats_if_error() { return _ym_repeats_if_error; }
