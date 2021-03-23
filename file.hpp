#pragma once
#include <QString>
#include <iostream>
#include <fstream>
#include <QFileInfo>
#include <QJsonDocument>
#include <QJsonObject>

enum FileMode {
  fmRead = QFile::ReadOnly,
  fmWrite = QFile::WriteOnly | QFile::Truncate,
  fmReadWrite = QFile::ReadWrite,
  fmText = QFile::Text,
  fmAppend = QFile::Append,
  fmReplace = QFile::Truncate,
};

struct File
{
  File(QString filename, int mode = fmRead);
  ~File();

  QFile fs;

  QString all();
  QJsonDocument allJson();

  void writeAll(QByteArray const& data);
  void writeAll(QString const& data);
  void writeAll(QJsonDocument const& data, QJsonDocument::JsonFormat format = QJsonDocument::Compact);
  void writeAll(QJsonObject const& data, QJsonDocument::JsonFormat format = QJsonDocument::Compact);
  void writeAll(QJsonArray const& data, QJsonDocument::JsonFormat format = QJsonDocument::Compact);

  void close();
  void needOpen();
  void needOpen(QFile::OpenMode om);

  bool openned = false;
  QFile::OpenMode mode;
};

template<class T>
File& operator<<(File&& o, T const& v) {
  o.fs.write(v);
  return o;
}

inline File::File(QString filename, int mode) : fs(filename), mode(mode)
{}

inline File::~File()
{
  if (openned) fs.close();
}

inline QString File::all()
{
  needOpen(QFile::ReadOnly | QFile::Text);
  auto res = fs.readAll();
  close();
  return res;
}

inline QJsonDocument File::allJson()
{
  needOpen(QFile::ReadOnly | QFile::Text);
  auto res = QJsonDocument::fromJson(fs.readAll());
  close();
  return res;
}

inline void File::writeAll(QByteArray const& data)
{
  needOpen(QFile::WriteOnly | QFile::Truncate);
  fs.write(data);
  close();
}

inline void File::writeAll(const QString& data)
{
  needOpen(QFile::WriteOnly | QFile::Truncate | QFile::Text);
  fs.write(data.toUtf8());
  close();
}

inline void File::writeAll(const QJsonDocument& data, QJsonDocument::JsonFormat format)
{
  needOpen(QFile::WriteOnly | QFile::Truncate | QFile::Text);
  fs.write(data.toJson(format));
  close();
}

inline void File::writeAll(const QJsonObject& data, QJsonDocument::JsonFormat format)
{
  writeAll(QJsonDocument(data), format);
}

inline void File::writeAll(const QJsonArray& data, QJsonDocument::JsonFormat format)
{
  writeAll(QJsonDocument(data), format);
}

inline void File::close()
{
  if (openned) fs.close();
  openned = false;
}

inline void File::needOpen()
{
  if (!openned) fs.open(mode);
  openned = true;
}

inline void File::needOpen(QIODevice::OpenMode om)
{
  if (mode != om) {
    if (openned) fs.close();
    fs.open(om);
    mode = om;
    openned = true;
  } else if (!openned) {
    fs.open(om);
    openned = true;
  }
}

inline std::ostream& operator<<(std::ostream& o, QString const& s) {
  return o << s.toUtf8().data();
}

inline bool fileExists(QString path) {
  QFileInfo check_file(path);
  return check_file.exists() && check_file.isFile();
}
inline bool exists(QString path) {
  QFileInfo check_file(path);
  return check_file.exists();
}
