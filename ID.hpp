#pragma once
#include "types.hpp"

struct ID
{
  refClient client;
  qint64 id = 0;
  QString path = "";

  QString toString();
};

