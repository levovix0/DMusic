#pragma once
#include <QString>
#undef log

struct Log
{
  Log& message(QString s);
  Log& info(QString s);
  Log& warning(QString s);
  Log& error(QString s);
};

inline static Log logging;
