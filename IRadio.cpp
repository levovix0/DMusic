#include "IRadio.hpp"

std::optional<_refTrack> IRadio::getNext()
{
  return {};
}

std::optional<_refTrack> IRadio::getPrev()
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
