#include "Dir.hpp"

Dir::Dir(QString path) : QDir(path)
{

}

Dir::Dir(const char* path) : QDir(path)
{

}

Dir::Dir(QDir const& from) : QDir(from)
{

}

Dir::Dir(const Dir& copy) : QDir(copy)
{

}

Dir::Dir(Dir&& move) : QDir(move)
{

}

Dir& Dir::operator=(Dir const& copy)
{
  QDir::operator=(copy);
  return *this;
}

bool Dir::exists()
{
  return QDir::exists();
}

bool Dir::exists(Dir a)
{
  return a.exists();
}

QString Dir::sub(const QString& path) const
{
  return Dir::cleanPath(this->path() + separator() + path);
}

Dir& Dir::operator=(Dir&& move)
{
  QDir::operator=(move);
  return *this;
}

Dir Dir::operator/(const QString& subdirPath) const
{
  return Dir(sub(subdirPath));
}

Dir Dir::dir(const QString& subdirPath) const
{
  return Dir(sub(subdirPath));
}

File Dir::file(const QString& filename) const
{
  return File(sub(filename));
}

QFile Dir::qfile(const QString& filename) const
{
  return QFile(sub(filename));
}

QUrl Dir::qurl(const QString& filename) const
{
  return QUrl(sub(filename));
}

QUrl Dir::qurl() const
{
  return QUrl(path());
}

Dir Dir::home()
{
  return QDir::home();
}
