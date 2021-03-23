#include "Log.hpp"
#include <QDebug>

QTextStream& qStdOut()
{
    static QTextStream ts(stdout);
    return ts;
}
QTextStream& qStdErr()
{
    static QTextStream ts(stderr);
    return ts;
}

Log& Log::message(QString s)
{
  qStdOut() << s << "\n";
  return *this;
}

Log& Log::info(QString s)
{
  qStdOut() << "-- " << s << "\n";
  return *this;
}

Log& Log::warning(QString s)
{
  qStdOut() << "Warning: " << s << "\n";
  return *this;
}

Log& Log::error(QString s)
{
  qStdErr() << s << "\n";
  return *this;
}
