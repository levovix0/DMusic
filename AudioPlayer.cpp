#include "AudioPlayer.hpp"

AudioPlayer::AudioPlayer(QObject *parent) : QObject(parent)
{

}

QmlTrack* AudioPlayer::currentTrack()
{
  return _currentTrackQml;
}
