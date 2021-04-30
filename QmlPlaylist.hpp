#pragma once
#include <QObject>
#include "IPlaylist.hpp"
#include "QmlRadio.hpp"

class QmlPlaylist : public QObject
{
  Q_OBJECT
public:
  explicit QmlPlaylist(QObject *parent = nullptr);
  explicit QmlPlaylist(_refPlaylist const& ref, QObject *parent = nullptr);
  Q_ENUM(IPlaylistRadio::NextMode)
  Q_ENUM(IPlaylistRadio::LoopMode)
  Q_PROPERTY(QString name READ name NOTIFY nameChanged)
  Q_PROPERTY(QString description READ description NOTIFY descriptionChanged)
  Q_PROPERTY(QString cover READ cover NOTIFY coverChanged)

  QString name();
  QString description();
  QString cover();

  _refPlaylist get();
  void set(_refPlaylist ref);

public slots:
  QmlRadio* radio(int pos, IPlaylistRadio::NextMode nextMode = IPlaylistRadio::NextSequence, IPlaylistRadio::LoopMode loopMode = IPlaylistRadio::LoopNone);
  QmlRadio* radio(IPlaylistRadio::NextMode nextMode = IPlaylistRadio::NextSequence, IPlaylistRadio::LoopMode loopMode = IPlaylistRadio::LoopNone)
  { return radio(-1, nextMode, loopMode); }

signals:
  void nameChanged();
  void descriptionChanged();
  void coverChanged();

private:
  _refPlaylist ref{};
};
