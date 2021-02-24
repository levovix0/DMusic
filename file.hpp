#pragma once
#include <QString>
#include <iostream>
#include <fstream>

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
