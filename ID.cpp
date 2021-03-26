#include "ID.hpp"
#include "IClient.hpp"

QString ID::toString()
{
  if (kind == dkNone)
    return client->identity() + '/' + QString::number(id);
  else
    return client->identity() + '/' + ::toString(kind) + '/' + QString::number(id);
}
