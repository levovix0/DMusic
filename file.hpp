#pragma once
#include <QString>
#include <iostream>
#include <fstream>
#include <filesystem>

namespace fs = std::filesystem;

enum FileMode {
  fmRead = std::ios::in,
  fmOut = std::ios::out,
  fmBinary = std::ios::binary,
  fmAppend = std::ios::app,
  fmReplace = std::ios::trunc,

  fmWrite = std::ios::out | std::ios::trunc,
};

struct File
{
  File(QString filename, int mode = fmRead);
  ~File();

  std::fstream fs;
};

template<class T>
File& operator<<(File&& o, T const& v) {
  o.fs << v;
  return o;
}

template<class T>
File& operator>>(File&& o, T& v) {
  o.fs >> v;
  return o;
}

inline File::File(QString filename, int mode)
{
  fs.open(filename.toUtf8().data(), std::ios_base::openmode(mode));
}

inline File::~File()
{
  fs.close();
}

inline std::ostream& operator<<(std::ostream& o, QString const& s) {
  return o << s.toUtf8().data();
}

inline fs::path operator/(fs::path a, QString b) {
  return a / std::string(b.toUtf8().data());
}
inline fs::path operator/(QString a, fs::path b) {
  return std::string(a.toUtf8().data()) / b;
}
