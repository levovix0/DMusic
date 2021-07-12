#pragma once
#include <QDir>
#include "file.hpp"

class Dir : public QDir
{
public:
  Dir(QString path = ".");
  Dir(const char* path);
  Dir(QDir const& from);
  Dir(Dir const& copy);
  Dir(Dir&& move);

  Dir& operator=(Dir const& copy);
  Dir& operator=(Dir&& move);

  bool exists();
  static bool exists(Dir);

  void create();
  void create(QString subPath);

  QString sub(QString const& path) const;
  Dir operator/(QString const& subdirPath) const;
  Dir dir(QString const& subdirPath) const;
  File file(QString const& filename) const;
  QFile qfile(QString const& filename) const;
  QUrl qurl(QString const& filename) const;
  QUrl qurl() const;

  static Dir home();
};

