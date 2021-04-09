#include "IArtist.hpp"

IArtist::IArtist(QObject *parent) : QObject(parent)
{

}

std::optional<QString> IArtist::name()
{
  return {};
}
