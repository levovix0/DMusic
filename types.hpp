#pragma once
#include <QSharedPointer>

class ITrack;
class IArtist;
class IPlaylst;
class IRadio;
class IPlaylstRadio;
class IClient;

using refTrack = QSharedPointer<ITrack>;
using refArtist = QSharedPointer<IArtist>;
using refPlaylist = QSharedPointer<IPlaylst>;
using refRadio = QSharedPointer<IRadio>;
using refPlaylistRadio = QSharedPointer<IPlaylstRadio>;
using refClient = QSharedPointer<IClient>;
