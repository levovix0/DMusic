#include "ITrack.hpp"

bool ITrack::exists()
{
  return false;
}

ID ITrack::id()
{
  return {client(), 0};
}
