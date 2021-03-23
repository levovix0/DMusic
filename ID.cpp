#include "ID.hpp"
#include "IClient.hpp"

QString ID::toString()
{
  if (path.isEmpty())
    return client->identity() + '/' + QString::number(id);
  else
    return client->identity() + '/' + path + '/' + QString::number(id);
}
