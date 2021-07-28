#pragma once
#include <QString>
#include <QUrl>
#include <QDir>
// nim_standart_library-like working with file system
//TODO: implement

inline QString operator/(QString l, QString r) {
  return QDir::cleanPath(l + "/" + r);
}

struct SplitedPath {
  QString protocol, path, name, extension;

  operator QString() { return ((protocol + ":")/path/name) + "." + extension; }
  operator QUrl() { return {(QString)(*this)}; }
};

inline SplitedPath splitFile(QString path) {
  return {}; //TODO
}

inline SplitedPath splitPath(QString path) {
  return {}; //TODO
}

inline QString currentDir() {
  return {}; //TODO
}

inline QString absoletePath(QString path) {
  return {}; //TODO
}

inline QString relativePath(QString path) {
  return {}; //TODO
}

inline bool fileExists(QString path) {
  QFileInfo check_file(path);
  return check_file.exists() && check_file.isFile();
}

inline bool dirExists(QString path) {
  QFileInfo check_file(path);
  return check_file.exists() && check_file.isDir();
}

inline bool symlinkExists(QString path) {
  QFileInfo check_file(path);
  return check_file.exists() && check_file.isSymLink();
}

inline void mkdir(QString path) {
  //TODO
}

inline void writeFile(QString path, QString text) {
  //TODO
}

inline QString readFile(QString path) {
  return {}; //TODO
}

inline void deleteFile(QString path) {
  //TODO
}

inline void copyFile(QString from, QString to) {
  //TODO
}

inline void copyDir(QString from, QString to) {
  //TODO
}

inline void createSymlink(QString path, QString to) {
  //TODO
}
