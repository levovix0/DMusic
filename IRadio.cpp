#include "IRadio.hpp"

std::optional<refTrack> IRadio::getNext()
{
  return {};
}

std::optional<refTrack> IRadio::getPrev()
{
  return {};
}

bool IRadio::hasCurrent()
{
  return true;
}

bool IRadio::hasNext()
{
  return false;
}

bool IRadio::hasPrevious()
{
  return false;
}
