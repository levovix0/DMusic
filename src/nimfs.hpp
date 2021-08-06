#pragma once
#include <QString>
#include <QUrl>
#include <QDir>
// nim_standart_library-like working with file system

inline QString operator/(QString l, QString r) {
  return QDir::cleanPath(l + "/" + r);
}

struct SplitedPath {
  QString protocol, path, name, extension;

  operator QString() { return ((protocol + ":")/path/name) + "." + extension; }
  operator QUrl() { return {(QString)(*this)}; }
};

inline SplitedPath splitFile(QString const& path) {
  return {}; //TODO
}

inline SplitedPath splitPath(QString const& path) {
  return {}; //TODO
}

inline QString currentDir() {
  return {}; //TODO
}

inline QString absoletePath(QString const& path) {
  return {}; //TODO
}

inline QString relativePath(QString const& path) {
  return {}; //TODO
}

inline bool fileExists(QString const& path) {
  QFileInfo check_file(path);
  return check_file.exists() && check_file.isFile();
}

inline bool dirExists(QString const& path) {
  QFileInfo check_file(path);
  return check_file.exists() && check_file.isDir();
}

inline bool symlinkExists(QString const& path) {
  QFileInfo check_file(path);
  return check_file.exists() && check_file.isSymLink();
}

inline void mkdir(QString const& path) {
  //TODO
}

inline void writeFile(QString const& path, QString const& text) {
  //TODO: create dir if needed
  QFile f(path);
  f.open(QFile::WriteOnly | QFile::Truncate);
  f.write(text.toUtf8());
  f.close();
}

inline void writeFile(QString const& path, QByteArray const& data) {
  //TODO: create dir if needed
  QFile f(path);
  f.open(QFile::WriteOnly | QFile::Truncate);
  f.write(data);
  f.close();
}

inline QString readFile(QString const& path) {
  return {}; //TODO
}

inline void removeFile(QString const& path) {
  QFile::remove(path);
}

inline void removeDir(QString const& path) {
  QDir(path).removeRecursively();
}

inline void copyFile(QString const& from, QString const& to) {
  //TODO: create dir if needed
  QFile::copy(from, to);
}

inline void copyDir(QString const& from, QString const& to) {
  //TODO
}

inline void createSymlink(QString const& path, QString const& to) {
  //TODO
}
