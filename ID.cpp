#include "ID.hpp"
#include "IClient.hpp"

QString ID::serialize()
{
  if (kind == dkNone)
    if (containerKind == dkNone)
      return toString(client) + "/" + QString::number(id);
    else
      return toString(client) + "/" + toString(containerKind) + ":" + QString::number(container) + "/" + QString::number(id);
  else
    if (containerKind == dkNone)
      return toString(client) + "/" + toString(kind) + ":" + QString::number(id);
    else
      return toString(client) + "/" + toString(containerKind) + ":" + QString::number(container) + "/" + toString(kind) + ":" + QString::number(id);
}

ID ID::deseralize(QString s)
{
  return {};
  //TODO
}
