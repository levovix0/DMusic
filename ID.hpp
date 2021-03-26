#pragma once
#include "types.hpp"

struct ID
{
  refClient client;
  qint64 id = 0;
  DataKind kind = dkNone;

  QString toString();
};

